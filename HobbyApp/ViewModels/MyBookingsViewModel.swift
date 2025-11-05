import Foundation
import SwiftUI
import EventKit

@MainActor
final class MyBookingsViewModel: ObservableObject {
    @Published var allBookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = BookingFilters()
    
    var upcomingBookings: [Booking] {
        filteredBookings.filter { 
            $0.status == .confirmed && $0.classDate > Date()
        }.sorted { $0.classDate < $1.classDate }
    }
    
    var pastBookings: [Booking] {
        filteredBookings.filter { 
            $0.status == .completed || ($0.classDate < Date() && $0.status == .confirmed)
        }.sorted { $0.classDate > $1.classDate }
    }
    
    var cancelledBookings: [Booking] {
        filteredBookings.filter { 
            $0.status == .cancelled || $0.status == .noShow
        }.sorted { $0.classDate > $1.classDate }
    }
    
    private var filteredBookings: [Booking] {
        allBookings.filter { booking in
            // Date range filter
            let bookingDate = Calendar.current.startOfDay(for: booking.classDate)
            let startDate = Calendar.current.startOfDay(for: filters.startDate)
            let endDate = Calendar.current.startOfDay(for: filters.endDate)
            
            guard bookingDate >= startDate && bookingDate <= endDate else {
                return false
            }
            
            // Status filter
            guard filters.statuses.isEmpty || filters.statuses.contains(booking.status) else {
                return false
            }
            
            // Price filter
            guard booking.totalAmount >= filters.minPrice && booking.totalAmount <= filters.maxPrice else {
                return false
            }
            
            return true
        }
    }
    
    func loadBookings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Generate sample bookings
            allBookings = generateSampleBookings()
            
        } catch {
            errorMessage = "Failed to load bookings"
        }
        
        isLoading = false
    }
    
    func cancelBooking(_ booking: Booking) async {
        guard let index = allBookings.firstIndex(where: { $0.id == booking.id }) else { return }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        allBookings[index] = Booking(
            id: booking.id,
            classTitle: booking.classTitle,
            classDate: booking.classDate,
            duration: booking.duration,
            instructor: booking.instructor,
            venue: booking.venue,
            totalAmount: booking.totalAmount,
            status: .cancelled,
            bookedAt: booking.bookedAt,
            cancelledAt: Date(),
            notes: booking.notes
        )
    }
    
    func rescheduleBooking(_ booking: Booking) async {
        // In a real app, this would open a reschedule flow
        // For now, just simulate the action
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func writeReview(for booking: Booking) async {
        // In a real app, this would open a review writing flow
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func addToCalendar(_ booking: Booking) {
        let eventStore = EKEventStore()
        
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = booking.classTitle
                    event.startDate = booking.classDate
                    event.endDate = booking.classDate.addingTimeInterval(TimeInterval(booking.duration * 60))
                    event.location = "\(booking.venue.name), \(booking.venue.address)"
                    event.notes = "Instructor: \(booking.instructor.fullName)\nBooking ID: \(booking.id.uuidString.prefix(8))"
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    
                    try? eventStore.save(event, span: .thisEvent)
                }
            }
        }
    }
    
    func shareBooking(_ booking: Booking) {
        let shareText = """
        I'm attending \(booking.classTitle) with \(booking.instructor.fullName) on \(DateFormatter.shareDate.string(from: booking.classDate)) at \(booking.venue.name)!
        """
        
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    func applyFilters(_ newFilters: BookingFilters) {
        filters = newFilters
    }
    
    private func generateSampleBookings() -> [Booking] {
        let classTypes = [
            "Pottery Basics", "Watercolor Painting", "Photography Workshop", 
            "Italian Cooking", "Yoga Flow", "Guitar Fundamentals",
            "Creative Writing", "Jewelry Making", "Digital Art",
            "Woodworking Basics"
        ]
        
        let instructors = [
            "Sarah Chen", "Michael Park", "Emma Thompson", "David Rodriguez",
            "Lisa Wang", "James Wilson", "Maria Garcia", "Robert Kim"
        ]
        
        let venues = [
            "Creative Arts Studio", "Downtown Workshop", "Maker Space",
            "Community Center", "Art Collective", "Learning Hub"
        ]
        
        let statuses: [BookingStatus] = [.confirmed, .completed, .cancelled, .pending]
        
        return (0..<15).map { index in
            let randomDaysOffset = Int.random(in: -60...30) // 60 days ago to 30 days from now
            let classDate = Calendar.current.date(byAdding: .day, value: randomDaysOffset, to: Date()) ?? Date()
            
            let status: BookingStatus
            if classDate < Date() {
                status = [.completed, .cancelled, .noShow].randomElement() ?? .completed
            } else {
                status = [.confirmed, .pending].randomElement() ?? .confirmed
            }
            
            let instructor = Instructor(
                id: UUID(),
                userId: UUID(),
                firstName: instructors.randomElement()?.components(separatedBy: " ").first ?? "John",
                lastName: instructors.randomElement()?.components(separatedBy: " ").last ?? "Doe",
                email: "instructor@example.com",
                phone: nil,
                bio: nil,
                specialties: [],
                certificationInfo: nil,
                rating: Decimal(4.5),
                totalReviews: 10,
                profileImageUrl: nil,
                yearsOfExperience: 5,
                socialLinks: nil,
                availability: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            )
            
            let venue = Venue(
                id: UUID(),
                name: venues.randomElement() ?? "Studio",
                address: "\(Int.random(in: 100...999)) \(["Main St", "Oak Ave", "First St", "Broadway"].randomElement() ?? "Main St")",
                city: "Vancouver",
                state: "BC",
                zipCode: "V6B 1A1",
                latitude: 49.2827,
                longitude: -123.1207,
                amenities: ["WiFi", "Parking"],
                parkingInfo: "Street parking available",
                publicTransit: "Near transit",
                imageUrls: nil,
                accessibilityInfo: "Accessible"
            )
            
            return Booking(
                id: UUID(),
                classTitle: classTypes.randomElement() ?? "Creative Class",
                classDate: classDate,
                duration: [60, 90, 120, 180].randomElement() ?? 120,
                instructor: instructor,
                venue: venue,
                totalAmount: Double.random(in: 25...150),
                status: status,
                bookedAt: Date().addingTimeInterval(-TimeInterval.random(in: 86400...2592000)),
                cancelledAt: status == .cancelled ? Date().addingTimeInterval(-TimeInterval.random(in: 0...86400)) : nil,
                notes: nil
            )
        }
    }
}

// MARK: - Supporting Models

struct BookingFilters {
    var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    var endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var statuses: Set<BookingStatus> = []
    var minPrice: Double = 0
    var maxPrice: Double = 500
}

extension DateFormatter {
    static let shareDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}