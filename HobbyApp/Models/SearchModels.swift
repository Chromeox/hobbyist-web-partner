import Foundation
import CoreLocation

// MARK: - Search Parameters
struct SearchParameters {
    let query: String
    let scope: SearchViewModel.SearchScope
    let location: CLLocation?
    let radius: Double?
    let offset: Int
    let limit: Int
}

// MARK: - Search Result
struct SearchResult: Identifiable {
    let id: UUID
    let type: SearchResultType
    let title: String
    let subtitle: String?
    let imageUrl: String?
    let startDate: Date?
    let endDate: Date?
    let location: String?
    let rating: Double?
    let price: Double?
    let distance: Double?
    let relevanceScore: Double
    
    enum SearchResultType {
        case hobbyClass
        case instructor
        case venue
    }
}

// MARK: - Trending Category
struct TrendingCategory: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let classCount: Int
    let trendingScore: Double
}

// MARK: - Location Filter
enum LocationFilter: String, CaseIterable {
    case anywhere = "Anywhere"
    case nearby = "Nearby"
    case withinCity = "Within City"
    case custom = "Custom Range"
}

// MARK: - Helpers

extension SearchResult {
    init(hobbyClass: HobbyClass) {
        self.id = UUID()
        self.type = .hobbyClass
        self.title = hobbyClass.title
        self.subtitle = hobbyClass.instructor.name
        self.imageUrl = hobbyClass.imageUrl
        self.startDate = hobbyClass.startDate
        self.endDate = hobbyClass.endDate
        self.location = hobbyClass.isOnline ? "Online" : (hobbyClass.venue.name.isEmpty ? hobbyClass.venue.city : hobbyClass.venue.name)
        self.rating = hobbyClass.averageRating
        self.price = hobbyClass.price
        self.distance = nil
        self.relevanceScore = 1.0
    }
}

extension SearchParameters {
    func matches(_ result: SearchResult) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerQuery = query.lowercased()
        if result.title.lowercased().contains(lowerQuery) { return true }
        if let subtitle = result.subtitle?.lowercased(), subtitle.contains(lowerQuery) { return true }
        if let location = result.location?.lowercased(), location.contains(lowerQuery) { return true }
        return false
    }
}
