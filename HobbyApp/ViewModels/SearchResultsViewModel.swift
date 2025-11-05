import Foundation
import SwiftUI

@MainActor
final class SearchResultsViewModel: ObservableObject {
    @Published var allResults: [SearchResult] = []
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var errorMessage: String?
    @Published var filters = SearchFilters()
    @Published var suggestedQueries: [String] = []
    @Published var searchSuggestions: [String] = []
    
    private var currentQuery = ""
    
    var filteredResults: [SearchResult] {
        var results = allResults
        
        // Apply category filter
        if !filters.categories.isEmpty {
            results = results.filter { result in
                switch result {
                case .class(let hobbyClass):
                    return filters.categories.contains(hobbyClass.category)
                case .instructor(let instructor):
                    return instructor.specialties.contains { specialty in
                        filters.categories.contains { category in
                            specialty.localizedCaseInsensitiveContains(category.rawValue)
                        }
                    }
                case .venue:
                    return true // Venues don't have categories, so include all
                }
            }
        }
        
        // Apply price filter
        results = results.compactMap { result in
            switch result {
            case .class(let hobbyClass):
                let price = hobbyClass.price
                if price == 0 && !filters.includeFree {
                    return nil
                }
                if price < filters.minPrice || price > filters.maxPrice {
                    return nil
                }
                return result
            case .instructor, .venue:
                return result // Keep instructors and venues regardless of price filter
            }
        }
        
        // Apply availability filters
        if filters.onlyUpcoming || filters.onlyAvailable {
            results = results.compactMap { result in
                switch result {
                case .class(let hobbyClass):
                    if filters.onlyUpcoming && hobbyClass.startDate <= Date() {
                        return nil
                    }
                    if filters.onlyAvailable && hobbyClass.enrolledCount >= hobbyClass.maxParticipants {
                        return nil
                    }
                    return result
                case .instructor, .venue:
                    return result // Keep instructors and venues regardless of availability filter
                }
            }
        }
        
        // Apply sorting
        return sortResults(results, by: filters.sortBy)
    }
    
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            hasSearched = false
            allResults = []
            return
        }
        
        currentQuery = query
        isLoading = true
        hasSearched = false
        errorMessage = nil
        
        do {
            // Simulate search delay
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Generate search results
            allResults = generateSearchResults(for: query)
            suggestedQueries = generateSuggestedQueries(for: query)
            searchSuggestions = generateSearchSuggestions(for: query)
            hasSearched = true
            
        } catch {
            errorMessage = "Search failed. Please try again."
        }
        
        isLoading = false
    }
    
    func resultCount(for filter: SearchFilter) -> Int {
        switch filter {
        case .all:
            return filteredResults.count
        case .classes:
            return filteredResults.filter { if case .class = $0 { return true }; return false }.count
        case .instructors:
            return filteredResults.filter { if case .instructor = $0 { return true }; return false }.count
        case .venues:
            return filteredResults.filter { if case .venue = $0 { return true }; return false }.count
        }
    }
    
    func resultsForFilter(_ filter: SearchFilter) -> [SearchResult] {
        switch filter {
        case .all:
            return filteredResults
        case .classes:
            return filteredResults.filter { if case .class = $0 { return true }; return false }
        case .instructors:
            return filteredResults.filter { if case .instructor = $0 { return true }; return false }
        case .venues:
            return filteredResults.filter { if case .venue = $0 { return true }; return false }
        }
    }
    
    func applyFilters(_ newFilters: SearchFilters) {
        filters = newFilters
    }
    
    private func sortResults(_ results: [SearchResult], by option: SearchSortOption) -> [SearchResult] {
        switch option {
        case .relevance:
            return results.sorted { result1, result2 in
                // Prioritize exact matches, then by type (classes first)
                if result1.isExactMatch && !result2.isExactMatch {
                    return true
                } else if !result1.isExactMatch && result2.isExactMatch {
                    return false
                } else {
                    return result1.typeOrder < result2.typeOrder
                }
            }
        case .alphabetical:
            return results.sorted { $0.title < $1.title }
        case .price:
            return results.sorted { result1, result2 in
                let price1 = result1.price ?? Double.infinity
                let price2 = result2.price ?? Double.infinity
                return price1 < price2
            }
        case .rating:
            return results.sorted { result1, result2 in
                let rating1 = result1.rating ?? 0
                let rating2 = result2.rating ?? 0
                return rating1 > rating2
            }
        case .date:
            return results.sorted { result1, result2 in
                let date1 = result1.nextDate ?? Date.distantFuture
                let date2 = result2.nextDate ?? Date.distantFuture
                return date1 < date2
            }
        }
    }
    
    private func generateSearchResults(for query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        let lowercaseQuery = query.lowercased()
        
        // Generate class results
        let classResults = generateClassResults(for: lowercaseQuery)
        results.append(contentsOf: classResults)
        
        // Generate instructor results
        let instructorResults = generateInstructorResults(for: lowercaseQuery)
        results.append(contentsOf: instructorResults)
        
        // Generate venue results
        let venueResults = generateVenueResults(for: lowercaseQuery)
        results.append(contentsOf: venueResults)
        
        return results
    }
    
    private func generateClassResults(for query: String) -> [SearchResult] {
        let sampleClasses = [
            ("Pottery & Ceramics Workshop", ClassCategory.arts, "pottery", "ceramics", "clay"),
            ("Watercolor Painting Basics", ClassCategory.arts, "watercolor", "painting", "art"),
            ("Digital Photography", ClassCategory.photography, "photography", "photo", "camera"),
            ("Italian Cooking Class", ClassCategory.cooking, "cooking", "italian", "cuisine"),
            ("Guitar for Beginners", ClassCategory.music, "guitar", "music", "strings"),
            ("Jewelry Making", ClassCategory.jewelry, "jewelry", "making", "crafts"),
            ("Creative Writing Workshop", ClassCategory.writing, "writing", "creative", "stories"),
            ("Woodworking Fundamentals", ClassCategory.woodworking, "woodworking", "wood", "carpentry"),
            ("Yoga and Mindfulness", ClassCategory.fitness, "yoga", "mindfulness", "wellness"),
            ("Bread Baking Masterclass", ClassCategory.cooking, "baking", "bread", "pastry")
        ]
        
        return sampleClasses.compactMap { (title, category, keyword1, keyword2, keyword3) in
            let keywords = [keyword1, keyword2, keyword3, title.lowercased()]
            let isMatch = keywords.contains { $0.contains(query) } || query.contains(keyword1) || query.contains(keyword2)
            
            guard isMatch else { return nil }
            
            let isExactMatch = title.lowercased().contains(query) || keywords.contains(query)
            
            let startDate = Date().addingTimeInterval(TimeInterval(86400 * Int.random(in: 1...30)))
            
            let hobbyClass = HobbyClass(
                id: UUID().uuidString,
                title: title,
                description: "Learn \(title.lowercased()) in this comprehensive workshop designed for all skill levels.",
                category: category,
                difficulty: DifficultyLevel.allCases.randomElement() ?? .beginner,
                price: Double.random(in: 0...150),
                startDate: startDate,
                endDate: startDate.addingTimeInterval(7200),
                duration: Int.random(in: 60...180),
                maxParticipants: Int.random(in: 8...20),
                enrolledCount: Int.random(in: 0...15),
                instructor: InstructorInfo(
                    id: UUID().uuidString,
                    name: ["Sarah Chen", "Michael Park", "Emma Wilson"].randomElement() ?? "Instructor",
                    bio: nil,
                    profileImageUrl: nil,
                    rating: Double.random(in: 4.0...5.0),
                    totalClasses: Int.random(in: 10...100),
                    totalStudents: Int.random(in: 50...500),
                    specialties: [category.rawValue],
                    certifications: [],
                    yearsOfExperience: Int.random(in: 2...15),
                    socialLinks: nil
                ),
                venue: VenueInfo(
                    id: UUID().uuidString,
                    name: ["Creative Studio", "Maker Space", "Art Center"].randomElement() ?? "Studio",
                    address: "123 Main St",
                    city: "Vancouver",
                    state: "BC",
                    zipCode: "V6B 1A1",
                    latitude: 49.2827,
                    longitude: -123.1207,
                    amenities: ["WiFi", "Parking"],
                    parkingInfo: nil,
                    publicTransit: nil,
                    imageUrls: nil,
                    accessibilityInfo: nil
                ),
                imageUrl: nil,
                thumbnailUrl: nil,
                averageRating: Double.random(in: 4.0...5.0),
                totalReviews: Int.random(in: 5...50),
                tags: [],
                requirements: [],
                whatToBring: [],
                cancellationPolicy: "",
                isOnline: false,
                meetingUrl: nil
            )
            
            return SearchResult.class(hobbyClass, isExactMatch: isExactMatch)
        }
    }
    
    private func generateInstructorResults(for query: String) -> [SearchResult] {
        let sampleInstructors = [
            ("Sarah Chen", ["pottery", "ceramics", "sculpture"], "pottery"),
            ("Michael Rodriguez", ["painting", "watercolor", "art"], "painting"),
            ("Emma Thompson", ["photography", "digital", "portrait"], "photography"),
            ("David Kim", ["cooking", "korean", "cuisine"], "cooking"),
            ("Lisa Park", ["music", "guitar", "piano"], "music"),
            ("James Wilson", ["woodworking", "furniture", "crafts"], "woodworking")
        ]
        
        return sampleInstructors.compactMap { (name, specialties, mainSpecialty) in
            let nameMatch = name.lowercased().contains(query)
            let specialtyMatch = specialties.contains { $0.contains(query) }
            
            guard nameMatch || specialtyMatch else { return nil }
            
            let instructor = Instructor(
                id: UUID(),
                userId: UUID(),
                firstName: name.components(separatedBy: " ").first ?? "First",
                lastName: name.components(separatedBy: " ").last ?? "Last",
                email: "instructor@example.com",
                phone: nil,
                bio: "Experienced \(mainSpecialty) instructor passionate about teaching and sharing knowledge.",
                specialties: specialties,
                certificationInfo: nil,
                rating: Decimal(Double.random(in: 4.2...5.0)),
                totalReviews: Int.random(in: 10...100),
                profileImageUrl: nil,
                yearsOfExperience: Int.random(in: 3...20),
                socialLinks: nil,
                availability: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: nil
            )
            
            return SearchResult.instructor(instructor, isExactMatch: nameMatch)
        }
    }
    
    private func generateVenueResults(for query: String) -> [SearchResult] {
        let sampleVenues = [
            ("Creative Arts Studio", ["studio", "art", "creative"]),
            ("Downtown Maker Space", ["maker", "downtown", "workshop"]),
            ("Vancouver Art Center", ["art", "center", "gallery"]),
            ("Community Kitchen", ["kitchen", "cooking", "community"]),
            ("Music Learning Hub", ["music", "learning", "studio"]),
            ("Craft Workshop Collective", ["craft", "workshop", "collective"])
        ]
        
        return sampleVenues.compactMap { (name, keywords) in
            let nameMatch = name.lowercased().contains(query)
            let keywordMatch = keywords.contains { $0.contains(query) }
            
            guard nameMatch || keywordMatch else { return nil }
            
            let venue = Venue(
                id: UUID(),
                name: name,
                address: "\(Int.random(in: 100...999)) \(["Main St", "Oak Ave", "Broadway"].randomElement() ?? "Main St")",
                city: "Vancouver",
                state: "BC",
                zipCode: "V6B 1A1",
                latitude: 49.2827 + Double.random(in: -0.02...0.02),
                longitude: -123.1207 + Double.random(in: -0.02...0.02),
                amenities: ["WiFi", "Parking", "Materials Provided"].shuffled().prefix(Int.random(in: 1...3)).map(String.init),
                parkingInfo: "Street parking available",
                publicTransit: "Near transit",
                imageUrls: nil,
                accessibilityInfo: "Wheelchair accessible"
            )
            
            return SearchResult.venue(venue, isExactMatch: nameMatch)
        }
    }
    
    private func generateSuggestedQueries(for query: String) -> [String] {
        let suggestions = [
            "pottery classes",
            "cooking workshops",
            "photography basics",
            "art classes",
            "music lessons",
            "woodworking",
            "jewelry making",
            "creative writing"
        ]
        
        return suggestions.filter { !$0.localizedCaseInsensitiveContains(query) }.prefix(3).map(String.init)
    }
    
    private func generateSearchSuggestions(for query: String) -> [String] {
        let baseSuggestions = [
            "Try broader terms like 'art' or 'cooking'",
            "Check the spelling of your search term",
            "Search for instructor names or studio locations"
        ]
        
        let categorySuggestions = ClassCategory.allCases.map { $0.rawValue.lowercased() }
        
        return baseSuggestions + categorySuggestions.prefix(3).map { $0.capitalized }
    }
}

// MARK: - Supporting Models

enum SearchResult: Identifiable {
    case class(HobbyClass, isExactMatch: Bool = false)
    case instructor(Instructor, isExactMatch: Bool = false)
    case venue(Venue, isExactMatch: Bool = false)
    
    var id: String {
        switch self {
        case .class(let hobbyClass, _):
            return "class-\(hobbyClass.id)"
        case .instructor(let instructor, _):
            return "instructor-\(instructor.id)"
        case .venue(let venue, _):
            return "venue-\(venue.id)"
        }
    }
    
    var title: String {
        switch self {
        case .class(let hobbyClass, _):
            return hobbyClass.title
        case .instructor(let instructor, _):
            return instructor.fullName
        case .venue(let venue, _):
            return venue.name
        }
    }
    
    var isExactMatch: Bool {
        switch self {
        case .class(_, let isExact):
            return isExact
        case .instructor(_, let isExact):
            return isExact
        case .venue(_, let isExact):
            return isExact
        }
    }
    
    var typeLabel: String {
        switch self {
        case .class:
            return "Class"
        case .instructor:
            return "Instructor"
        case .venue:
            return "Venue"
        }
    }
    
    var typeIcon: String {
        switch self {
        case .class:
            return "book.fill"
        case .instructor:
            return "person.circle.fill"
        case .venue:
            return "building.2.fill"
        }
    }
    
    var typeColor: Color {
        switch self {
        case .class:
            return BrandConstants.Colors.primary
        case .instructor:
            return BrandConstants.Colors.teal
        case .venue:
            return BrandConstants.Colors.coral
        }
    }
    
    var typeOrder: Int {
        switch self {
        case .class:
            return 1
        case .instructor:
            return 2
        case .venue:
            return 3
        }
    }
    
    var price: Double? {
        switch self {
        case .class(let hobbyClass, _):
            return hobbyClass.price
        case .instructor, .venue:
            return nil
        }
    }
    
    var rating: Double? {
        switch self {
        case .class(let hobbyClass, _):
            return hobbyClass.averageRating
        case .instructor(let instructor, _):
            return NSDecimalNumber(decimal: instructor.rating).doubleValue
        case .venue:
            return nil
        }
    }
    
    var nextDate: Date? {
        switch self {
        case .class(let hobbyClass, _):
            return hobbyClass.startDate > Date() ? hobbyClass.startDate : nil
        case .instructor, .venue:
            return nil
        }
    }
}

enum SearchFilter: String, CaseIterable {
    case all = "All"
    case classes = "Classes"
    case instructors = "Instructors"
    case venues = "Venues"
    
    var displayName: String {
        return rawValue
    }
}

struct SearchFilters {
    var categories: Set<ClassCategory> = []
    var minPrice: Double = 0
    var maxPrice: Double = 500
    var includeFree: Bool = true
    var onlyUpcoming: Bool = false
    var onlyAvailable: Bool = false
    var sortBy: SearchSortOption = .relevance
}

enum SearchSortOption: String, CaseIterable {
    case relevance = "Relevance"
    case alphabetical = "Alphabetical"
    case price = "Price"
    case rating = "Rating"
    case date = "Date"
    
    var displayName: String {
        return rawValue
    }
}