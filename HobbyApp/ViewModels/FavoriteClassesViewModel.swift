import Foundation
import SwiftUI

@MainActor
final class FavoriteClassesViewModel: ObservableObject {
    @Published var favoriteClasses: [HobbyClass] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var filters = FavoritesFilters()
    @Published var sortOption: SortOption = .recent
    
    var filteredClasses: [HobbyClass] {
        var classes = favoriteClasses
        
        // Apply search filter
        if !searchQuery.isEmpty {
            classes = classes.filter { hobbyClass in
                hobbyClass.title.localizedCaseInsensitiveContains(searchQuery) ||
                hobbyClass.instructor.name.localizedCaseInsensitiveContains(searchQuery) ||
                hobbyClass.venue.name.localizedCaseInsensitiveContains(searchQuery) ||
                hobbyClass.category.rawValue.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply category filter
        if !filters.categories.isEmpty {
            classes = classes.filter { filters.categories.contains($0.category) }
        }
        
        // Apply difficulty filter
        if !filters.difficulties.isEmpty {
            classes = classes.filter { filters.difficulties.contains($0.difficulty) }
        }
        
        // Apply price filter
        classes = classes.filter { hobbyClass in
            hobbyClass.price >= filters.minPrice && hobbyClass.price <= filters.maxPrice
        }
        
        // Apply availability filters
        if filters.onlyUpcoming {
            classes = classes.filter { $0.startDate > Date() }
        }
        
        if filters.onlyAvailable {
            classes = classes.filter { $0.enrolledCount < $0.maxParticipants }
        }
        
        // Apply sorting
        return sortClasses(classes, by: sortOption)
    }
    
    func loadFavorites() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Generate sample favorite classes
            favoriteClasses = generateSampleFavorites()
            
        } catch {
            errorMessage = "Failed to load favorite classes"
        }
        
        isLoading = false
    }
    
    func removeFavorite(_ hobbyClass: HobbyClass) async {
        // Optimistically remove from UI
        favoriteClasses.removeAll { $0.id == hobbyClass.id }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // In a real app, you would call your API to remove the favorite
        // If the API call fails, you would re-add the class to the array
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
    }
    
    func applyFilters(_ newFilters: FavoritesFilters) {
        filters = newFilters
    }
    
    func sortBy(_ option: SortOption) {
        sortOption = option
    }
    
    private func sortClasses(_ classes: [HobbyClass], by option: SortOption) -> [HobbyClass] {
        switch option {
        case .recent:
            // Sort by when they were added to favorites (simulated with random order for now)
            return classes.shuffled()
        case .alphabetical:
            return classes.sorted { $0.title < $1.title }
        case .price:
            return classes.sorted { $0.price < $1.price }
        case .rating:
            return classes.sorted { $0.averageRating > $1.averageRating }
        case .date:
            return classes.sorted { $0.startDate < $1.startDate }
        }
    }
    
    private func generateSampleFavorites() -> [HobbyClass] {
        let sampleData = [
            ("Pottery & Ceramics Basics", ClassCategory.arts, "Learn the fundamentals of working with clay", "Sarah Chen", "Creative Arts Studio", 75.0),
            ("Watercolor Landscape Painting", ClassCategory.arts, "Paint beautiful landscapes with watercolors", "Michael Rodriguez", "Downtown Art Center", 65.0),
            ("Italian Cooking Masterclass", ClassCategory.cooking, "Master authentic Italian cuisine", "Maria Rossi", "Culinary Institute", 95.0),
            ("Photography Composition", ClassCategory.photography, "Improve your photo composition skills", "David Kim", "Photo Workshop Space", 80.0),
            ("Beginner Guitar", ClassCategory.music, "Learn to play your first songs", "James Wilson", "Music Learning Hub", 60.0),
            ("Jewelry Making Workshop", ClassCategory.jewelry, "Create stunning handmade jewelry", "Lisa Park", "Maker Studio", 55.0),
            ("Digital Art Fundamentals", ClassCategory.arts, "Digital painting and illustration basics", "Emma Thompson", "Tech Creative Space", 70.0),
            ("Woodworking Basics", ClassCategory.woodworking, "Introduction to woodworking tools and techniques", "Robert Brown", "Workshop Collective", 85.0),
            ("Creative Writing Workshop", ClassCategory.writing, "Develop your creative writing skills", "Jennifer Lee", "Writers Circle", 45.0),
            ("Morning Yoga Flow", ClassCategory.fitness, "Energizing morning yoga practice", "Angela Martinez", "Wellness Center", 25.0)
        ]
        
        return sampleData.enumerated().map { index, data in
            let (title, category, description, instructorName, venueName, price) = data
            
            // Create random future dates for some classes
            let daysFromNow = Int.random(in: 1...60)
            let startDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
            
            return HobbyClass(
                id: "favorite-\(index)",
                title: title,
                description: description,
                category: category,
                difficulty: DifficultyLevel.allCases.randomElement() ?? .beginner,
                price: price,
                startDate: startDate,
                endDate: startDate.addingTimeInterval(TimeInterval(Int.random(in: 60...180) * 60)), // 1-3 hours
                duration: Int.random(in: 60...180),
                maxParticipants: Int.random(in: 8...20),
                enrolledCount: Int.random(in: 2...15),
                instructor: InstructorInfo(
                    id: UUID().uuidString,
                    name: instructorName,
                    bio: "Experienced instructor passionate about teaching \(category.rawValue.lowercased())",
                    profileImageUrl: nil,
                    rating: Double.random(in: 4.2...5.0),
                    totalClasses: Int.random(in: 20...100),
                    totalStudents: Int.random(in: 100...500),
                    specialties: [category.rawValue],
                    certifications: [],
                    yearsOfExperience: Int.random(in: 3...15),
                    socialLinks: nil
                ),
                venue: VenueInfo(
                    id: UUID().uuidString,
                    name: venueName,
                    address: "\(Int.random(in: 100...999)) \(["Main St", "Oak Ave", "Broadway", "First St"].randomElement() ?? "Main St")",
                    city: "Vancouver",
                    state: "BC",
                    zipCode: "V6B 1A1",
                    latitude: 49.2827 + Double.random(in: -0.05...0.05),
                    longitude: -123.1207 + Double.random(in: -0.05...0.05),
                    amenities: ["WiFi", "Parking", "Materials Provided"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                    parkingInfo: "Street parking available",
                    publicTransit: "Near transit station",
                    imageUrls: nil,
                    accessibilityInfo: "Wheelchair accessible"
                ),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: Double.random(in: 4.0...5.0),
                totalReviews: Int.random(in: 5...50),
                tags: ["beginner-friendly", "hands-on"],
                requirements: ["No experience required"],
                whatToBring: ["Enthusiasm", "Notebook"],
                cancellationPolicy: "Free cancellation up to 24 hours before class",
                isOnline: Bool.random() && Bool.random(), // 25% chance of being online
                meetingUrl: nil
            )
        }
    }
}

// MARK: - Supporting Models

struct FavoritesFilters {
    var categories: Set<ClassCategory> = []
    var difficulties: Set<DifficultyLevel> = []
    var minPrice: Double = 0
    var maxPrice: Double = 500
    var onlyUpcoming: Bool = false
    var onlyAvailable: Bool = false
}

enum SortOption: String, CaseIterable {
    case recent = "Recently Added"
    case alphabetical = "Alphabetical"
    case price = "Price"
    case rating = "Rating"
    case date = "Date"
    
    var systemImage: String {
        switch self {
        case .recent:
            return "clock"
        case .alphabetical:
            return "textformat.abc"
        case .price:
            return "dollarsign.circle"
        case .rating:
            return "star"
        case .date:
            return "calendar"
        }
    }
}

// MARK: - Extensions

extension ClassCategory {
    var color: Color {
        switch self {
        case .arts:
            return BrandConstants.Colors.Category.arts
        case .cooking:
            return BrandConstants.Colors.Category.cooking
        case .photography:
            return BrandConstants.Colors.Category.photography
        case .music:
            return BrandConstants.Colors.Category.music
        case .jewelry:
            return BrandConstants.Colors.Category.jewelry
        case .woodworking:
            return BrandConstants.Colors.Category.woodworking
        case .writing:
            return BrandConstants.Colors.Category.writing
        case .fitness:
            return Color.green
        }
    }
    
    var iconName: String {
        switch self {
        case .arts:
            return "paintbrush.fill"
        case .cooking:
            return "fork.knife"
        case .photography:
            return "camera.fill"
        case .music:
            return "music.note"
        case .jewelry:
            return "crown.fill"
        case .woodworking:
            return "hammer.fill"
        case .writing:
            return "pencil"
        case .fitness:
            return "figure.run"
        }
    }
}