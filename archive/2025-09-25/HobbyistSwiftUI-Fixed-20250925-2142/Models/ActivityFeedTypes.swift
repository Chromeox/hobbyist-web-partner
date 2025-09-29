import Foundation

struct ActivityFeedView {
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case following = "Following"
        case popular = "Popular"
        case recent = "Recent"
    }
}