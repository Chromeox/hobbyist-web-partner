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