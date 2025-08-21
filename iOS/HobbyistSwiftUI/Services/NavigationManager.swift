import SwiftUI

// MARK: - Navigation Manager

@MainActor
final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: Tab = .home
    @Published var navigationPath = NavigationPath()
    @Published var isShowingDetail = false
    @Published var selectedClass: Class?
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case classes = "Classes"
        case bookings = "Bookings"
        case profile = "Profile"
        
        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .classes: return "calendar"
            case .bookings: return "book.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    private init() {}
    
    func navigateToTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func navigateToClass(_ classItem: Class) {
        selectedClass = classItem
        isShowingDetail = true
    }
    
    func dismissDetail() {
        isShowingDetail = false
        selectedClass = nil
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    func push<V: Hashable>(_ value: V) {
        navigationPath.append(value)
    }
}