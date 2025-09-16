import Foundation
import CoreLocation

class SearchService: ObservableObject {
    static let shared = SearchService()

    private init() {}

    func search(with parameters: SearchParameters) async throws -> [SearchResult] {
        // Mock implementation for TestFlight
        return []
    }

    func fetchAutocompleteSuggestions(for query: String) async throws -> [String] {
        // Mock autocomplete suggestions
        return ["yoga", "pottery", "cooking", "photography"].filter { $0.contains(query.lowercased()) }
    }

    func fetchRecentSearches() async throws -> [String] {
        // Mock recent searches
        return []
    }

    func fetchPopularSearches() async throws -> [String] {
        // Mock popular searches
        return ["yoga", "pottery", "cooking", "photography", "painting", "dance"]
    }

    func fetchSuggestedClasses() async throws -> [HobbyClass] {
        // Mock suggested classes
        return []
    }

    func fetchNearbyClasses(location: CLLocation, radius: Double) async throws -> [HobbyClass] {
        // Mock nearby classes
        return []
    }

    func fetchTrendingCategories() async throws -> [TrendingCategory] {
        // Mock trending categories
        return []
    }

    func saveRecentSearches(_ searches: [String]) async throws {
        // Mock save to persistent storage
    }

    func clearRecentSearches() async throws {
        // Mock clear storage
    }
}

// MARK: - Supporting Types
struct SearchParameters {
    let query: String
    let location: CLLocation?
    let radius: Double?
    let category: String?
    let difficulty: String?
    let priceRange: ClosedRange<Double>?
}

struct SearchResult: Identifiable {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let imageUrl: String?
}

enum SearchResultType {
    case hobbyClass
    case instructor
    case venue
}

struct TrendingCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let count: Int
}
