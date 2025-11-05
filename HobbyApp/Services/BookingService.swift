import Foundation
import Combine
import Supabase

// MARK: - Booking Service

@MainActor
final class BookingService: ObservableObject {
    static let shared = BookingService()
    
    @Published var userBookings: [Booking] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let supabaseService = SimpleSupabaseService.shared
    private let paymentService = PaymentService.shared
    private let creditService = CreditService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Create a new booking with payment processing
    func createBooking(request: BookingRequest) async throws -> Booking {
        guard let userId = supabaseService.currentUser?.id else {
            throw BookingError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Validate class availability
            try await validateClassAvailability(classId: request.classId, participantCount: request.participantCount)
            
            // Step 2: Process payment if required
            let paymentResult = try await processPaymentForBooking(request: request)
            
            // Step 3: Create booking record
            let booking = try await createBookingRecord(request: request, paymentResult: paymentResult)
            
            // Step 4: Apply credits if used
            if let creditsUsed = request.creditsUsed, creditsUsed > 0 {
                try await applyCreditPayment(creditsUsed: creditsUsed, bookingId: booking.id)
            }
            
            // Step 5: Send confirmation notifications
            try await sendBookingConfirmation(booking: booking)
            
            // Step 6: Update local state
            userBookings.append(booking)
            
            isLoading = false
            return booking
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Load user's bookings
    func loadUserBookings() async {
        guard let userId = supabaseService.currentUser?.id else {
            userBookings = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabaseService.client
                .from("bookings")
                .select("""
                    *,
                    venues:venue_id (*),
                    instructors:instructor_id (*)
                """)
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            userBookings = try decoder.decode([Booking].self, from: response.data)
            
        } catch {
            print("⚠️ Failed to load user bookings: \(error)")
            errorMessage = "Failed to load your bookings"
        }
        
        isLoading = false
    }
    
    /// Cancel a booking
    func cancelBooking(_ booking: Booking) async throws -> Booking {
        guard booking.canBeCancelled else {
            throw BookingError.cancellationNotAllowed
        }
        
        isLoading = true
        
        do {
            // Step 1: Update booking status
            let updatedBooking = try await updateBookingStatus(bookingId: booking.id, status: .cancelled)
            
            // Step 2: Process refund if applicable
            if booking.canBeRefunded {
                try await processRefund(booking: booking)
            }
            
            // Step 3: Restore credits if applicable
            if booking.paidWithCredits, let creditsUsed = booking.creditsUsed {
                try await restoreCredits(amount: creditsUsed, reason: "Booking cancellation")
            }
            
            // Step 4: Update local state
            if let index = userBookings.firstIndex(where: { $0.id == booking.id }) {
                userBookings[index] = updatedBooking
            }
            
            // Step 5: Send cancellation notification
            try await sendCancellationNotification(booking: updatedBooking)
            
            isLoading = false
            return updatedBooking
            
        } catch {
            isLoading = false
            throw error
        }
    }
    
    /// Modify a booking
    func modifyBooking(_ booking: Booking, newDate: Date?, newParticipantCount: Int?) async throws -> Booking {
        guard booking.canBeModified else {
            throw BookingError.modificationNotAllowed
        }
        
        isLoading = true
        
        do {
            // Create modification request
            let modificationRequest = BookingModificationRequest(
                bookingId: booking.id,
                newDate: newDate,
                newParticipantCount: newParticipantCount
            )
            
            // Process modification
            let updatedBooking = try await processBookingModification(request: modificationRequest)
            
            // Update local state
            if let index = userBookings.firstIndex(where: { $0.id == booking.id }) {
                userBookings[index] = updatedBooking
            }
            
            isLoading = false
            return updatedBooking
            
        } catch {
            isLoading = false
            throw error
        }
    }
    
    /// Get booking by confirmation code
    func getBookingByConfirmationCode(_ confirmationCode: String) async throws -> Booking? {
        do {
            let response = try await supabaseService.client
                .from("bookings")
                .select("""
                    *,
                    venues:venue_id (*),
                    instructors:instructor_id (*)
                """)
                .eq("confirmation_code", value: confirmationCode)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(Booking.self, from: response.data)
            
        } catch {
            print("⚠️ Failed to find booking with code \(confirmationCode): \(error)")
            return nil
        }
    }
    
    /// Get upcoming bookings
    var upcomingBookings: [Booking] {
        let now = Date()
        return userBookings.filter { 
            $0.classStartDate > now && ($0.status == .confirmed || $0.status == .pending)
        }.sorted { $0.classStartDate < $1.classStartDate }
    }
    
    /// Get past bookings
    var pastBookings: [Booking] {
        let now = Date()
        return userBookings.filter { 
            $0.classStartDate <= now || $0.status == .completed || $0.status == .cancelled
        }.sorted { $0.classStartDate > $1.classStartDate }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Listen for authentication changes
        supabaseService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if user != nil {
                    Task {
                        await self?.loadUserBookings()
                    }
                } else {
                    self?.userBookings = []
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateClassAvailability(classId: String, participantCount: Int) async throws {
        // Check if class has enough spots available
        let response = try await supabaseService.client
            .from("classes")
            .select("available_spots, total_spots")
            .eq("id", value: classId)
            .single()
            .execute()
        
        let classData = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
        let availableSpots = classData?["available_spots"] as? Int ?? 0
        
        if availableSpots < participantCount {
            throw BookingError.classFullyBooked
        }
    }
    
    private func processPaymentForBooking(request: BookingRequest) async throws -> PaymentResult? {
        // If paying only with credits, no Stripe payment needed
        if request.paymentMethod == .credits && request.creditsUsed == Int(request.totalAmount) {
            return PaymentResult(
                success: true,
                paymentIntentId: "credits_only_\(UUID().uuidString)",
                error: nil,
                paymentMethod: .credits
            )
        }
        
        // Process payment through PaymentService
        let remainingAmount = request.totalAmount - Double(request.creditsUsed ?? 0)
        
        if remainingAmount > 0 {
            let paymentIntent = try await paymentService.createBookingPaymentIntent(
                amount: remainingAmount,
                classId: request.classId,
                participantCount: request.participantCount
            )
            
            paymentService.configurePaymentSheet(for: paymentIntent)
            let result = await paymentService.presentPaymentSheet()
            
            if !result.success {
                throw BookingError.invalidPayment
            }
            
            // Confirm payment with backend
            if let paymentIntentId = result.paymentIntentId {
                let confirmed = try await paymentService.confirmPayment(paymentIntentId: paymentIntentId)
                if !confirmed {
                    throw BookingError.invalidPayment
                }
            }
            
            return result
        }
        
        return nil
    }
    
    private func createBookingRecord(request: BookingRequest, paymentResult: PaymentResult?) async throws -> Booking {
        // Create booking in Supabase
        let bookingData: [String: Any] = [
            "class_id": request.classId,
            "user_id": request.userId,
            "participant_count": request.participantCount,
            "special_requests": request.specialRequests as Any,
            "payment_id": paymentResult?.paymentIntentId ?? UUID().uuidString,
            "total_amount": request.totalAmount,
            "status": BookingStatus.confirmed.rawValue,
            "payment_method": request.paymentMethod.rawValue,
            "payment_intent_id": paymentResult?.paymentIntentId as Any,
            "paid_with_credits": request.creditsUsed != nil && request.creditsUsed! > 0,
            "credits_used": request.creditsUsed as Any,
            "discount_applied": request.discountApplied as Any,
            "processing_fee": request.processingFee as Any,
            "participant_names": request.participantNames as Any,
            "emergency_contact": try JSONSerialization.data(withJSONObject: [
                "name": request.emergencyContact?.name ?? "",
                "phone": request.emergencyContact?.phone ?? ""
            ]),
            "equipment_rental": request.equipmentRental as Any,
            "experience_level": request.experienceLevel as Any,
            "confirmation_code": generateConfirmationCode()
        ]
        
        let response = try await supabaseService.client
            .from("bookings")
            .insert(bookingData)
            .select("""
                *,
                venues:venue_id (*),
                instructors:instructor_id (*)
            """)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Booking.self, from: response.data)
    }
    
    private func applyCreditPayment(creditsUsed: Int, bookingId: String) async throws {
        // Deduct credits through CreditService
        await withCheckedContinuation { continuation in
            creditService.useCredits(amount: creditsUsed, for: "Booking Payment") { success in
                continuation.resume()
            }
        }
        
        // Record credit transaction in database
        let transactionData: [String: Any] = [
            "user_id": supabaseService.currentUser?.id.uuidString ?? "",
            "booking_id": bookingId,
            "amount": -creditsUsed,
            "transaction_type": "booking_payment",
            "description": "Payment for class booking"
        ]
        
        try await supabaseService.client
            .from("credit_transactions")
            .insert(transactionData)
            .execute()
    }
    
    private func sendBookingConfirmation(booking: Booking) async throws {
        // Send confirmation via Supabase Edge Function
        let notificationData: [String: Any] = [
            "action": "send_booking_confirmation",
            "booking_id": booking.id,
            "user_id": booking.userId,
            "confirmation_code": booking.confirmationCode
        ]
        
        try await supabaseService.client
            .functions
            .invoke("send-notification", with: notificationData)
    }
    
    private func updateBookingStatus(bookingId: String, status: BookingStatus) async throws -> Booking {
        let updateData: [String: Any] = [
            "status": status.rawValue,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response = try await supabaseService.client
            .from("bookings")
            .update(updateData)
            .eq("id", value: bookingId)
            .select("""
                *,
                venues:venue_id (*),
                instructors:instructor_id (*)
            """)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Booking.self, from: response.data)
    }
    
    private func processRefund(booking: Booking) async throws {
        // Process refund through payment service or manual process
        let refundData: [String: Any] = [
            "action": "process_refund",
            "booking_id": booking.id,
            "payment_intent_id": booking.paymentIntentId as Any,
            "refund_amount": booking.refundAmount
        ]
        
        try await supabaseService.client
            .functions
            .invoke("payments", with: refundData)
    }
    
    private func restoreCredits(amount: Int, reason: String) async throws {
        // Restore credits through credit service
        // This would typically involve adding credits back to the user's account
        let transactionData: [String: Any] = [
            "user_id": supabaseService.currentUser?.id.uuidString ?? "",
            "amount": amount,
            "transaction_type": "refund",
            "description": reason
        ]
        
        try await supabaseService.client
            .from("credit_transactions")
            .insert(transactionData)
            .execute()
        
        // Reload credit balance
        await creditService.loadCreditSummary()
    }
    
    private func sendCancellationNotification(booking: Booking) async throws {
        let notificationData: [String: Any] = [
            "action": "send_cancellation_notification",
            "booking_id": booking.id,
            "user_id": booking.userId
        ]
        
        try await supabaseService.client
            .functions
            .invoke("send-notification", with: notificationData)
    }
    
    private func processBookingModification(request: BookingModificationRequest) async throws -> Booking {
        // Process booking modification
        var updateData: [String: Any] = [
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let newDate = request.newDate {
            updateData["class_start_date"] = ISO8601DateFormatter().string(from: newDate)
        }
        
        if let newParticipantCount = request.newParticipantCount {
            updateData["participant_count"] = newParticipantCount
        }
        
        let response = try await supabaseService.client
            .from("bookings")
            .update(updateData)
            .eq("id", value: request.bookingId)
            .select("""
                *,
                venues:venue_id (*),
                instructors:instructor_id (*)
            """)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Booking.self, from: response.data)
    }
    
    private func generateConfirmationCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        
        var code = ""
        
        // Add 2 letters
        for _ in 0..<2 {
            code += String(letters.randomElement()!)
        }
        
        // Add 4 numbers
        for _ in 0..<4 {
            code += String(numbers.randomElement()!)
        }
        
        return code
    }
}

// MARK: - Supporting Types

struct BookingModificationRequest {
    let bookingId: String
    let newDate: Date?
    let newParticipantCount: Int?
}

// MARK: - Mock Data Extension

extension BookingService {
    /// Load mock bookings for development
    func loadMockBookings() {
        userBookings = [
            // Upcoming booking
            Booking(
                id: "1",
                classId: "class_1",
                className: "Pottery Basics",
                userId: "user_1",
                participantCount: 1,
                specialRequests: nil,
                paymentId: "payment_1",
                totalAmount: 45.0,
                status: .confirmed,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                classStartDate: Date().addingTimeInterval(86400), // Tomorrow
                classEndDate: Date().addingTimeInterval(86400 + 7200), // Tomorrow + 2 hours
                venue: Venue(
                    id: "venue_1",
                    name: "Clay Studio Vancouver",
                    address: "123 Art Street",
                    city: "Vancouver",
                    province: "BC",
                    postalCode: "V6B 1A1",
                    latitude: 49.2827,
                    longitude: -123.1207
                ),
                instructor: Instructor(
                    id: "instructor_1",
                    name: "Sarah Chen",
                    bio: "Expert pottery instructor with 10+ years experience",
                    rating: 4.9,
                    reviewCount: 156,
                    specialties: ["Pottery", "Ceramics"],
                    avatar: nil
                ),
                confirmationCode: "AB1234",
                qrCode: nil,
                paymentMethod: .card,
                paymentIntentId: "pi_test_123",
                paidWithCredits: false,
                creditsUsed: nil,
                discountApplied: nil,
                processingFee: 1.35,
                refundableAmount: 36.0,
                availableSpotsAtBooking: 5,
                waitlistPosition: nil,
                isWaitlisted: false,
                remindersSent: nil,
                cancellationDeadline: Date().addingTimeInterval(86400 - 86400) // 24 hours before
            ),
            
            // Past booking
            Booking(
                id: "2",
                classId: "class_2",
                className: "Photography Walk",
                userId: "user_1",
                participantCount: 2,
                specialRequests: "Beginner level please",
                paymentId: "payment_2",
                totalAmount: 60.0,
                status: .completed,
                createdAt: Date().addingTimeInterval(-604800), // 1 week ago
                updatedAt: Date().addingTimeInterval(-604800),
                classStartDate: Date().addingTimeInterval(-259200), // 3 days ago
                classEndDate: Date().addingTimeInterval(-259200 + 10800), // 3 days ago + 3 hours
                venue: Venue(
                    id: "venue_2",
                    name: "Urban Photography Studio",
                    address: "456 Photo Ave",
                    city: "Vancouver",
                    province: "BC",
                    postalCode: "V6C 2B2",
                    latitude: 49.2827,
                    longitude: -123.1207
                ),
                instructor: Instructor(
                    id: "instructor_2",
                    name: "Alex Kim",
                    bio: "Professional photographer and educator",
                    rating: 4.8,
                    reviewCount: 203,
                    specialties: ["Photography", "Street Photography"],
                    avatar: nil
                ),
                confirmationCode: "CD5678",
                qrCode: nil,
                paymentMethod: .credits,
                paymentIntentId: nil,
                paidWithCredits: true,
                creditsUsed: 60,
                discountApplied: 10.0,
                processingFee: 0.0,
                refundableAmount: 0.0,
                availableSpotsAtBooking: 3,
                waitlistPosition: nil,
                isWaitlisted: false,
                remindersSent: [Date().addingTimeInterval(-345600)], // 4 days ago
                cancellationDeadline: Date().addingTimeInterval(-345600) // 4 days ago
            )
        ]
    }
}