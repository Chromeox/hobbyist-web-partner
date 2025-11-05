import Foundation
import SwiftUI

@MainActor
final class StudioProfileViewModel: ObservableObject {
    @Published var studio: Venue?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFollowing = false
    @Published var studioClasses: [ClassItem] = []
    @Published var reviews: [Review] = []
    @Published var studioPhotos: [String] = []
    @Published var averageRating: Double = 0.0
    @Published var totalReviews = 0
    @Published var totalClasses = 0
    @Published var totalInstructors = 0
    @Published var hoursOpen = 0
    @Published var operatingHours: [OperatingHours] = []
    @Published var studioDescription: String?
    @Published var studioPhone: String?
    @Published var studioEmail: String?
    @Published var studioWebsite: String?
    
    func loadStudio(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Create sample studio data
            studio = createSampleStudio(id: id)
            
            // Load additional data
            await loadStudioData()
            
        } catch {
            errorMessage = "Failed to load studio profile"
        }
        
        isLoading = false
    }
    
    private func loadStudioData() async {
        guard let studio = studio else { return }
        
        // Load classes
        studioClasses = createSampleClasses(for: studio)
        
        // Load reviews
        reviews = createSampleReviews(for: studio)
        
        // Load photos
        studioPhotos = createSamplePhotos()
        
        // Generate operating hours
        operatingHours = createOperatingHours()
        
        // Calculate stats
        averageRating = Double.random(in: 4.0...5.0)
        totalReviews = reviews.count + Int.random(in: 10...50)
        totalClasses = studioClasses.count + Int.random(in: 5...30)
        totalInstructors = Int.random(in: 3...15)
        hoursOpen = operatingHours.reduce(0) { total, hours in
            if hours.isClosed {
                return total
            } else {
                return total + calculateHours(from: hours.openTime, to: hours.closeTime)
            }
        }
        
        // Studio details
        studioDescription = createStudioDescription(for: studio)
        studioPhone = "+1 (604) \(Int.random(in: 100...999))-\(Int.random(in: 1000...9999))"
        studioEmail = "\(studio.name.lowercased().replacingOccurrences(of: " ", with: ""))@studio.com"
        studioWebsite = "https://\(studio.name.lowercased().replacingOccurrences(of: " ", with: "")).com"
        
        // Check if following (mock data)
        isFollowing = Bool.random()
    }
    
    func toggleFollow() async {
        guard studio != nil else { return }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        isFollowing.toggle()
    }
    
    private func createSampleStudio(id: String) -> Venue {
        let studioNames = [
            "Creative Arts Studio Vancouver",
            "Downtown Maker Space",
            "Artisan Workshop Collective",
            "Vancouver Creative Hub",
            "Craftworks Studio",
            "The Art Loft",
            "Maker's Corner",
            "Creative Commons Studio",
            "Artistic Expressions",
            "The Workshop Space"
        ]
        
        let addresses = [
            "123 Granville Street",
            "456 Robson Street",
            "789 Main Street",
            "321 Commercial Drive",
            "654 West Broadway",
            "987 Hastings Street",
            "147 Fraser Street",
            "258 Cambie Street",
            "369 Oak Street",
            "741 Kingsway"
        ]
        
        let amenitiesList = [
            ["Free WiFi", "Parking Available", "Materials Provided", "Wheelchair Accessible"],
            ["Parking Available", "Storage Lockers", "Changing Room", "Coffee Bar"],
            ["Free WiFi", "Materials Provided", "Wheelchair Accessible", "Air Conditioning"],
            ["Parking Available", "Materials Provided", "Changing Room", "Free WiFi"],
            ["Storage Lockers", "Wheelchair Accessible", "Coffee Bar", "Materials Provided"]
        ]
        
        return Venue(
            id: UUID(),
            name: studioNames.randomElement() ?? "Creative Studio",
            address: addresses.randomElement() ?? "123 Main Street",
            city: "Vancouver",
            state: "BC",
            zipCode: "V\(Int.random(in: 5...6))\(Character(UnicodeScalar(65 + Int.random(in: 0...25))!))\(Int.random(in: 1...9))\(Character(UnicodeScalar(65 + Int.random(in: 0...25))!))\(Int.random(in: 0...9))",
            latitude: Double.random(in: 49.2000...49.3000),
            longitude: Double.random(in: -123.2000...-123.1000),
            amenities: amenitiesList.randomElement() ?? ["WiFi", "Parking"],
            parkingInfo: "Free street parking available, paid lot across the street",
            publicTransit: "5 minute walk from \(["Commercial-Broadway", "Main Street-Science World", "Stadium-Chinatown", "Granville"].randomElement() ?? "Main Street") Station",
            imageUrls: nil,
            accessibilityInfo: "Fully wheelchair accessible with elevator access to all floors"
        )
    }
    
    private func createSampleClasses(for studio: Venue) -> [ClassItem] {
        let classTypes = [
            "Pottery & Ceramics", "Watercolor Painting", "Photography Basics", 
            "Jewelry Making", "Woodworking", "Digital Art", "Creative Writing",
            "Yoga & Wellness", "Cooking Classes", "Music Production"
        ]
        
        let instructorNames = [
            "Sarah Chen", "Michael Park", "Emma Thompson", "David Rodriguez",
            "Lisa Wang", "James Wilson", "Maria Garcia", "Robert Kim",
            "Jennifer Lee", "Christopher Brown"
        ]
        
        return (0..<Int.random(in: 3...8)).map { index in
            let startDate = Date().addingTimeInterval(TimeInterval(86400 * Int.random(in: 1...30))) // 1-30 days from now
            
            return ClassItem(
                id: UUID().uuidString,
                title: classTypes.randomElement() ?? "Creative Class",
                description: "Learn new creative skills in our well-equipped studio space.",
                price: Double.random(in: 30...150),
                duration: [60, 90, 120, 180].randomElement() ?? 120,
                instructorName: instructorNames.randomElement() ?? "Instructor",
                venueName: studio.name,
                startDate: startDate,
                endDate: startDate.addingTimeInterval(7200) // 2 hours later
            )
        }
    }
    
    private func createSampleReviews(for studio: Venue) -> [Review] {
        let reviewTexts = [
            "Amazing studio with great facilities and helpful staff!",
            "Love the creative atmosphere here. Perfect for learning new skills.",
            "Well-equipped studio with friendly instructors. Highly recommend!",
            "Great location and excellent classes. The space is inspiring.",
            "Fantastic studio with top-notch equipment and knowledgeable staff.",
            "Perfect space for creativity. Clean, organized, and welcoming.",
            "Wonderful studio with a great community feel. Love coming here!",
            "Excellent facilities and very professional instructors."
        ]
        
        let userNames = [
            "Alex K.", "Jamie L.", "Taylor M.", "Jordan P.", "Casey R.",
            "Riley S.", "Avery T.", "Morgan W.", "Quinn Z.", "Sage B."
        ]
        
        return (0..<Int.random(in: 4...10)).map { _ in
            Review(
                id: UUID().uuidString,
                userName: userNames.randomElement() ?? "Anonymous",
                rating: Int.random(in: 4...5),
                comment: reviewTexts.randomElement() ?? "Great studio!",
                date: Date().addingTimeInterval(-TimeInterval.random(in: 86400...2592000)), // Random date in past month
                classTitle: "Studio Experience",
                isVerifiedPurchase: Bool.random()
            )
        }
    }
    
    private func createSamplePhotos() -> [String] {
        // Mock photo URLs - in a real app these would be actual image URLs
        return [
            "https://example.com/studio1.jpg",
            "https://example.com/studio2.jpg",
            "https://example.com/studio3.jpg",
            "https://example.com/studio4.jpg",
            "https://example.com/studio5.jpg",
            "https://example.com/studio6.jpg"
        ]
    }
    
    private func createOperatingHours() -> [OperatingHours] {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        return days.map { day in
            let isClosed = (day == "Sunday" && Bool.random()) || (day == "Monday" && Bool.random())
            
            if isClosed {
                return OperatingHours(day: day, openTime: "", closeTime: "", isClosed: true)
            } else {
                let openHour = Int.random(in: 8...10)
                let closeHour = Int.random(in: 17...21)
                
                return OperatingHours(
                    day: day,
                    openTime: String(format: "%d:00 AM", openHour),
                    closeTime: String(format: "%d:00 PM", closeHour - 12),
                    isClosed: false
                )
            }
        }
    }
    
    private func createStudioDescription(for studio: Venue) -> String {
        let descriptions = [
            "A vibrant creative space dedicated to fostering artistic expression and learning. Our studio features state-of-the-art equipment and inspiring environments for artists of all levels.",
            "Vancouver's premier destination for creative learning and artistic exploration. We offer a welcoming space where creativity thrives and community connections are made.",
            "A modern studio space designed for makers, artists, and creators. With professional-grade equipment and expert instruction, we help bring your creative visions to life.",
            "Our studio combines traditional craftsmanship with contemporary techniques. We're passionate about providing a supportive environment for creative growth and artistic discovery.",
            "A collaborative workspace where artists, makers, and learners come together. Our mission is to make creative education accessible and inspiring for everyone."
        ]
        
        return descriptions.randomElement() ?? "A creative studio space for artists and makers."
    }
    
    private func calculateHours(from startTime: String, to endTime: String) -> Int {
        // Simple calculation for demo purposes
        // In a real app, you'd parse the time strings properly
        return Int.random(in: 8...12)
    }
}

// MARK: - Supporting Models

struct OperatingHours {
    let day: String
    let openTime: String
    let closeTime: String
    let isClosed: Bool
}