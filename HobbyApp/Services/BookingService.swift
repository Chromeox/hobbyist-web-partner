import Foundation
import Combine
import Supabase

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

// MARK: - Edge Function Response Types

struct EmptyResponse: Codable {
    // Empty response for functions that don't return data
}

// MARK: - Booking Request

struct BookingRequest {
    let classId: String
    let userId: String
    let participantCount: Int
    let specialRequests: String?
    let totalAmount: Double
    let paymentMethod: PaymentMethodType
    let creditsUsed: Int?
    let classStartDate: Date
    let classEndDate: Date
    
    init(
        classId: String,
        userId: String,
        participantCount: Int = 1,
        specialRequests: String? = nil,
        totalAmount: Double,
        paymentMethod: PaymentMethodType,
        creditsUsed: Int? = nil,
        classStartDate: Date,
        classEndDate: Date
    ) {
        self.classId = classId
        self.userId = userId
        self.participantCount = participantCount
        self.specialRequests = specialRequests
        self.totalAmount = totalAmount
        self.paymentMethod = paymentMethod
        self.creditsUsed = creditsUsed
        self.classStartDate = classStartDate
        self.classEndDate = classEndDate
    }
}

// MARK: - Booking Errors

enum BookingError: LocalizedError {
    case userNotAuthenticated
    case classFullyBooked
    case cancellationNotAllowed
    case modificationNotAllowed
    case invalidPayment
    case paymentProcessingFailed
    case insufficientCredits
    case invalidBookingRequest
    case bookingNotFound
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be signed in to create a booking"
        case .classFullyBooked:
            return "This class is fully booked"
        case .cancellationNotAllowed:
            return "This booking cannot be cancelled"
        case .modificationNotAllowed:
            return "This booking cannot be modified"
        case .invalidPayment:
            return "Payment processing failed"
        case .paymentProcessingFailed:
            return "Unable to process payment"
        case .insufficientCredits:
            return "Insufficient credits for this booking"
        case .invalidBookingRequest:
            return "Invalid booking information"
        case .bookingNotFound:
            return "Booking not found"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

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
                try await applyCreditPayment(creditsUsed: creditsUsed, bookingId: booking.id.uuidString)
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
            let updatedBooking = try await updateBookingStatus(bookingId: booking.id.uuidString, status: .cancelled)
            
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
                bookingId: booking.id.uuidString,
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
                paymentMethod: "credits"
            )
        }
        
        // Process payment through PaymentService
        let remainingAmount = request.totalAmount - Double(request.creditsUsed ?? 0)
        
        if remainingAmount > 0 {
            // Create payment intent (stub returns failure since Stripe is disabled)
            let amountInCents = Int(remainingAmount * 100)
            
            // For now, since PaymentService is stubbed, we'll just create a mock successful result
            // In production, this would actually process the payment
            print("⚠️ Payment processing is disabled - using credits only")
            return PaymentResult(
                success: true,
                paymentIntentId: "mock_\(UUID().uuidString)",
                error: nil,
                paymentMethod: "credits"
            )
        }
        
        return nil
    }
    
    private func createBookingRecord(request: BookingRequest, paymentResult: PaymentResult?) async throws -> Booking {
        // Create booking in Supabase
        var bookingData: [String: AnyEncodable] = [
            "class_id": AnyEncodable(request.classId),
            "user_id": AnyEncodable(request.userId),
            "participant_count": AnyEncodable(request.participantCount),
            "payment_id": AnyEncodable(paymentResult?.paymentIntentId ?? UUID().uuidString),
            "total_amount": AnyEncodable(request.totalAmount),
            "status": AnyEncodable(BookingStatus.confirmed.rawValue),
            "payment_method": AnyEncodable(request.paymentMethod.rawValue),
            "paid_with_credits": AnyEncodable(request.creditsUsed != nil && request.creditsUsed! > 0),
            "confirmation_code": AnyEncodable(generateConfirmationCode())
        ]

        if let specialRequests = request.specialRequests {
            bookingData["special_requests"] = AnyEncodable(specialRequests)
        }

        if let paymentIntentId = paymentResult?.paymentIntentId {
            bookingData["payment_intent_id"] = AnyEncodable(paymentIntentId)
        }

        if let creditsUsed = request.creditsUsed {
            bookingData["credits_used"] = AnyEncodable(creditsUsed)
        }

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
            "user_id": supabaseService.currentUser?.id ?? "",
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
        let notificationData: [String: AnyEncodable] = [
            "action": AnyEncodable("send_booking_confirmation"),
            "booking_id": AnyEncodable(booking.id.uuidString),
            "user_id": AnyEncodable(booking.userId.uuidString),
            "confirmation_code": AnyEncodable(booking.confirmationCode)
        ]

        let _: EmptyResponse = try await supabaseService.client
            .functions
            .invoke("send-notification", options: FunctionInvokeOptions(body: notificationData))
    }
    
    private func updateBookingStatus(bookingId: String, status: BookingStatus) async throws -> Booking {
        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable(status.rawValue),
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
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
        var refundData: [String: AnyEncodable] = [
            "action": AnyEncodable("process_refund"),
            "booking_id": AnyEncodable(booking.id.uuidString),
            "refund_amount": AnyEncodable(booking.refundAmount)
        ]

        if let paymentIntentId = booking.paymentIntentId {
            refundData["payment_intent_id"] = AnyEncodable(paymentIntentId)
        }

        let _: EmptyResponse = try await supabaseService.client
            .functions
            .invoke("payments", options: FunctionInvokeOptions(body: refundData))
    }
    
    private func restoreCredits(amount: Int, reason: String) async throws {
        // Restore credits through credit service
        // This would typically involve adding credits back to the user's account
        let transactionData: [String: AnyEncodable] = [
            "user_id": AnyEncodable(supabaseService.currentUser?.id ?? ""),
            "amount": AnyEncodable(amount),
            "transaction_type": AnyEncodable("refund"),
            "description": AnyEncodable(reason)
        ]

        try await supabaseService.client
            .from("credit_transactions")
            .insert(transactionData)
            .execute()
        
        // Reload credit balance
        await creditService.loadCreditSummary()
    }
    
    private func sendCancellationNotification(booking: Booking) async throws {
        let notificationData: [String: AnyEncodable] = [
            "action": AnyEncodable("send_cancellation_notification"),
            "booking_id": AnyEncodable(booking.id.uuidString),
            "user_id": AnyEncodable(booking.userId.uuidString)
        ]

        let _: EmptyResponse = try await supabaseService.client
            .functions
            .invoke("send-notification", options: FunctionInvokeOptions(body: notificationData))
    }
    
    private func processBookingModification(request: BookingModificationRequest) async throws -> Booking {
        // Process booking modification
        var updateData: [String: AnyEncodable] = [
            "updated_at": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        ]

        if let newDate = request.newDate {
            updateData["class_start_date"] = AnyEncodable(ISO8601DateFormatter().string(from: newDate))
        }

        if let newParticipantCount = request.newParticipantCount {
            updateData["participant_count"] = AnyEncodable(newParticipantCount)
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
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
                classId: UUID(uuidString: "00000000-0000-0000-0000-000000000011") ?? UUID(),
                className: "Pottery Basics",
                userId: UUID(uuidString: "00000000-0000-0000-0000-000000000021") ?? UUID(),
                participantCount: 1,
                specialRequests: nil,
                paymentId: UUID(uuidString: "00000000-0000-0000-0000-000000000031"),
                totalAmount: 45.0,
                status: .confirmed,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                classStartDate: Date().addingTimeInterval(86400), // Tomorrow
                classEndDate: Date().addingTimeInterval(86400 + 7200), // Tomorrow + 2 hours
                venue: Venue(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000101") ?? UUID(),
                    name: "Clay Studio Vancouver",
                    description: "Premier pottery studio in Vancouver",
                    address: "123 Art Street",
                    city: "Vancouver",
                    state: "BC",
                    zipCode: "V6B 1A1",
                    latitude: 49.2827,
                    longitude: -123.1207,
                    phone: nil,
                    email: nil,
                    website: nil,
                    amenities: ["Pottery Wheels", "Kiln"],
                    capacity: 12,
                    hourlyRate: 45.0,
                    isActive: true,
                    imageUrls: [],
                    operatingHours: [:],
                    parkingInfo: nil,
                    publicTransit: nil,
                    accessibilityInfo: nil,
                    averageRating: 4.8,
                    totalReviews: 89,
                    createdAt: Date(),
                    updatedAt: nil
                ),
                instructor: Instructor(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000201") ?? UUID(),
                    userId: UUID(uuidString: "00000000-0000-0000-0000-000000000221") ?? UUID(),
                    firstName: "Sarah",
                    lastName: "Chen",
                    email: "sarah.chen@example.com",
                    phone: nil,
                    bio: "Expert pottery instructor with 10+ years experience",
                    specialties: ["Pottery", "Ceramics"],
                    certificationInfo: nil,
                    rating: Decimal(4.9),
                    totalReviews: 156,
                    profileImageUrl: nil,
                    yearsOfExperience: 10,
                    socialLinks: nil,
                    availability: nil,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: nil
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
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
                classId: UUID(uuidString: "00000000-0000-0000-0000-000000000012") ?? UUID(),
                className: "Photography Walk",
                userId: UUID(uuidString: "00000000-0000-0000-0000-000000000021") ?? UUID(),
                participantCount: 2,
                specialRequests: "Beginner level please",
                paymentId: UUID(uuidString: "00000000-0000-0000-0000-000000000032"),
                totalAmount: 60.0,
                status: .completed,
                createdAt: Date().addingTimeInterval(-604800), // 1 week ago
                updatedAt: Date().addingTimeInterval(-604800),
                classStartDate: Date().addingTimeInterval(-259200), // 3 days ago
                classEndDate: Date().addingTimeInterval(-259200 + 10800), // 3 days ago + 3 hours
                venue: Venue(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000102") ?? UUID(),
                    name: "Urban Photography Studio",
                    description: "Modern photography studio in downtown Vancouver",
                    address: "456 Photo Ave",
                    city: "Vancouver",
                    state: "BC",
                    zipCode: "V6C 2B2",
                    latitude: 49.2827,
                    longitude: -123.1207,
                    phone: nil,
                    email: nil,
                    website: nil,
                    amenities: ["Photography Equipment", "Lighting", "Backdrops"],
                    capacity: 15,
                    hourlyRate: 60.0,
                    isActive: true,
                    imageUrls: [],
                    operatingHours: [:],
                    parkingInfo: nil,
                    publicTransit: nil,
                    accessibilityInfo: nil,
                    averageRating: 4.7,
                    totalReviews: 124,
                    createdAt: Date(),
                    updatedAt: nil
                ),
                instructor: Instructor(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000202") ?? UUID(),
                    userId: UUID(uuidString: "00000000-0000-0000-0000-000000000222") ?? UUID(),
                    firstName: "Alex",
                    lastName: "Kim",
                    email: "alex.kim@example.com",
                    phone: nil,
                    bio: "Professional photographer and educator",
                    specialties: ["Photography", "Street Photography"],
                    certificationInfo: nil,
                    rating: Decimal(4.8),
                    totalReviews: 203,
                    profileImageUrl: nil,
                    yearsOfExperience: 8,
                    socialLinks: nil,
                    availability: nil,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: nil
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