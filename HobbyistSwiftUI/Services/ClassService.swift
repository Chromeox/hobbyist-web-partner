import Foundation
import Combine

// MARK: - ClassService
class ClassService: ObservableObject {
    static let shared = ClassService()
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Fetch Classes
    
    func fetchClasses() async throws -> [HobbyClass] {
        // For now, return sample data - replace with actual API call
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume(returning: SampleData.sampleClasses)
            }
        }
    }
    
    func fetchMoreClasses(offset: Int) async throws -> [HobbyClass] {
        // Return additional sample data for pagination
        return []
    }
    
    func fetchClass(id: String) async throws -> HobbyClass? {
        let classes = try await fetchClasses()
        return classes.first { $0.id == id }
    }
    
    func searchClasses(query: String) async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        return allClasses.filter { hobbyClass in
            hobbyClass.title.localizedCaseInsensitiveContains(query) ||
            hobbyClass.description.localizedCaseInsensitiveContains(query) ||
            hobbyClass.instructor.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchFeaturedClasses() async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        return Array(allClasses.prefix(3))
    }
    
    func fetchRecommendedClasses() async throws -> [HobbyClass] {
        let allClasses = try await fetchClasses()
        return Array(allClasses.suffix(3))
    }
    
    func fetchUpcomingClasses() async throws -> [ClassItem] {
        // Convert HobbyClass to ClassItem for compatibility
        return ClassItem.hobbyClassSamples
    }
    
    func searchClasses(query: String) async throws -> [ClassItem] {
        let all = ClassItem.hobbyClassSamples
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - Sample Data
struct SampleData {
    static let sampleInstructor = Instructor(
        id: "instructor-1",
        name: "Maria Chen",
        bio: "Experienced pottery instructor with 10 years of teaching experience.",
        profileImageUrl: nil,
        rating: 4.9,
        totalClasses: 150,
        totalStudents: 800,
        specialties: ["Pottery", "Ceramics", "Wheel Throwing"],
        certifications: ["Certified Pottery Instructor"],
        yearsOfExperience: 10,
        socialLinks: nil
    )
    
    static let sampleVenue = Venue(
        id: "venue-1",
        name: "Clay Mates Ceramics Studio",
        address: "1234 Main St",
        city: "Vancouver",
        state: "BC",
        zipCode: "V6B 2V5",
        latitude: 49.2827,
        longitude: -123.1207,
        amenities: ["Parking", "Wheelchair Accessible", "Tools Provided"],
        parkingInfo: "Free parking available",
        publicTransit: "Bus stop nearby",
        imageUrls: [],
        accessibilityInfo: "Wheelchair accessible entrance"
    )
    
    static let sampleClasses: [HobbyClass] = [
        HobbyClass(
            id: "pottery-1",
            title: "Beginner Pottery Wheel",
            description: "Learn the fundamentals of pottery on the wheel. This hands-on class covers centering clay, pulling walls, and creating your first bowl.",
            category: .arts,
            difficulty: .beginner,
            price: 45.0,
            startDate: Date().addingTimeInterval(86400),
            endDate: Date().addingTimeInterval(91800),
            duration: 90,
            maxParticipants: 8,
            enrolledCount: 2,
            instructor: sampleInstructor,
            venue: sampleVenue,
            imageUrl: nil,
            thumbnailUrl: nil,
            averageRating: 4.9,
            totalReviews: 89,
            tags: ["beginner", "pottery", "hands-on"],
            requirements: ["Comfortable clothes that can get dirty", "Closed-toe shoes"],
            whatToBring: ["Apron (optional)"],
            cancellationPolicy: "Cancel up to 24 hours before for full refund",
            isOnline: false,
            meetingUrl: nil
        ),
        HobbyClass(
            id: "pottery-2",
            title: "Advanced Ceramics Workshop",
            description: "Take your pottery skills to the next level with advanced techniques and glazing methods.",
            category: .arts,
            difficulty: .advanced,
            price: 85.0,
            startDate: Date().addingTimeInterval(172800),
            endDate: Date().addingTimeInterval(183600),
            duration: 180,
            maxParticipants: 6,
            enrolledCount: 4,
            instructor: sampleInstructor,
            venue: sampleVenue,
            imageUrl: nil,
            thumbnailUrl: nil,
            averageRating: 4.8,
            totalReviews: 45,
            tags: ["advanced", "glazing", "techniques"],
            requirements: ["Previous pottery experience required"],
            whatToBring: ["Apron", "Personal tools (optional)"],
            cancellationPolicy: "Cancel up to 48 hours before for full refund",
            isOnline: false,
            meetingUrl: nil
        )
    ]
}