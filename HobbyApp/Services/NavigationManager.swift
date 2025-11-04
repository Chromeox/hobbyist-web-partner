import SwiftUI
import Combine

// MARK: - Enhanced Navigation Manager for Phase 3

@MainActor
final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()

    // Legacy compatibility
    @Published var selectedTab: Tab = .home
    @Published var navigationPath = NavigationPath()
    @Published var isShowingDetail = false
    @Published var selectedClass: HobbyClass?

    // Phase 3 Enhanced Navigation
    @Published var currentTab: MainTab = .home
    @Published var isNavigating = false
    @Published var navigationProgress: Double = 0.0

    // Navigation stack states for each tab
    @Published var homeNavigationPath = NavigationPath()
    @Published var searchNavigationPath = NavigationPath()
    @Published var bookingsNavigationPath = NavigationPath()
    @Published var profileNavigationPath = NavigationPath()

    // Animation configurations
    @Published var currentTransition: NavigationTransition = .slide
    @Published var isModalPresented = false
    @Published var tabSwitchDirection: TabSwitchDirection = .none

    private var hapticService = HapticFeedbackService.shared

    // Legacy Tab enum for backward compatibility
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

    init() {}

    // MARK: - Legacy Methods (Maintained for compatibility)

    func navigateToTab(_ tab: Tab) {
        selectedTab = tab
        // Update new tab system
        switch tab {
        case .home: currentTab = .home
        case .classes: currentTab = .search
        case .bookings: currentTab = .bookings
        case .profile: currentTab = .profile
        }
    }

    func navigateToClass(_ classItem: HobbyClass) {
        selectedClass = classItem
        isShowingDetail = true
    }

    func dismissDetail() {
        isShowingDetail = false
        selectedClass = nil
    }

    func popToRoot() {
        navigationPath = NavigationPath()
        popToRoot(for: currentTab)
    }

    func push<V: Hashable>(_ value: V) {
        navigationPath.append(value)
    }

    // MARK: - Phase 3 Enhanced Navigation Actions

    func switchTab(to tab: MainTab, withHaptic: Bool = true) {
        guard currentTab != tab else { return }

        // Determine animation direction
        let oldIndex = currentTab.index
        let newIndex = tab.index
        tabSwitchDirection = newIndex > oldIndex ? .forward : .backward

        if withHaptic {
            hapticService.playLight()
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentTab = tab
            // Update legacy selectedTab for backward compatibility
            selectedTab = tab.legacyTab
        }

        // Reset direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.tabSwitchDirection = .none
        }
    }

    func navigateToClassDetail(classID: String, from tab: MainTab? = nil) {
        let targetTab = tab ?? currentTab

        // Switch to target tab if needed
        if currentTab != targetTab {
            switchTab(to: targetTab, withHaptic: false)
        }

        // Add class detail to navigation stack
        switch targetTab {
        case .home:
            homeNavigationPath.append(NavigationDestination.classDetail(classID))
        case .search:
            searchNavigationPath.append(NavigationDestination.classDetail(classID))
        case .bookings:
            bookingsNavigationPath.append(NavigationDestination.classDetail(classID))
        case .profile:
            profileNavigationPath.append(NavigationDestination.classDetail(classID))
        }

        // Haptic feedback for navigation
        hapticService.playSelection()
    }

    func popToRoot(for tab: MainTab) {
        switch tab {
        case .home:
            if !homeNavigationPath.isEmpty {
                homeNavigationPath.removeLast(homeNavigationPath.count)
            }
        case .search:
            if !searchNavigationPath.isEmpty {
                searchNavigationPath.removeLast(searchNavigationPath.count)
            }
        case .bookings:
            if !bookingsNavigationPath.isEmpty {
                bookingsNavigationPath.removeLast(bookingsNavigationPath.count)
            }
        case .profile:
            if !profileNavigationPath.isEmpty {
                profileNavigationPath.removeLast(profileNavigationPath.count)
            }
        }

        hapticService.playLight()
    }

    func presentModal() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isModalPresented = true
        }
        hapticService.playSelection()
    }

    func dismissModal() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            isModalPresented = false
        }
        hapticService.playLight()
    }

    // MARK: - Animation Coordination

    func setTransitionStyle(_ transition: NavigationTransition) {
        currentTransition = transition
    }

    func animateNavigation(duration: Double = 0.3, completion: (() -> Void)? = nil) {
        withAnimation(.easeInOut(duration: duration)) {
            isNavigating = true
            navigationProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.1)) {
                self.isNavigating = false
                self.navigationProgress = 0.0
            }
            completion?()
        }
    }
}

// MARK: - Phase 3 Navigation Models

public enum MainTab: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case bookings = "Bookings"
    case profile = "Profile"

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .bookings: return "calendar"
        case .profile: return "person"
        }
    }

    var filledSystemImage: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .bookings: return "calendar.circle.fill"
        case .profile: return "person.fill"
        }
    }

    var index: Int {
        switch self {
        case .home: return 0
        case .search: return 1
        case .bookings: return 2
        case .profile: return 3
        }
    }

    // Convert to legacy tab for compatibility
    var legacyTab: NavigationManager.Tab {
        switch self {
        case .home: return .home
        case .search: return .classes
        case .bookings: return .bookings
        case .profile: return .profile
        }
    }
}

public enum NavigationDestination: Hashable {
    case classDetail(String)
    case profile
    case settings
    case credits
    case store(StoreCategory = .creditPacks)
    case outOfCredits(Int)
    case rewards
    case bookingFlow(String)
    case feedback
    case following
    case marketplace

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .classDetail(let id):
            hasher.combine("classDetail")
            hasher.combine(id)
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        case .credits:
            hasher.combine("credits")
        case .store(let category):
            hasher.combine("store")
            hasher.combine(category)
        case .outOfCredits(let needed):
            hasher.combine("outOfCredits")
            hasher.combine(needed)
        case .rewards:
            hasher.combine("rewards")
        case .bookingFlow(let id):
            hasher.combine("bookingFlow")
            hasher.combine(id)
        case .feedback:
            hasher.combine("feedback")
        case .following:
            hasher.combine("following")
        case .marketplace:
            hasher.combine("marketplace")
        }
    }
}

public enum NavigationTransition {
    case slide
    case fade
    case scale
    case push
    case modal

    var animation: Animation {
        switch self {
        case .slide:
            return .easeInOut(duration: 0.3)
        case .fade:
            return .easeInOut(duration: 0.25)
        case .scale:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .push:
            return .easeOut(duration: 0.25)
        case .modal:
            return .spring(response: 0.5, dampingFraction: 0.8)
        }
    }
}

public enum TabSwitchDirection {
    case none
    case forward
    case backward
}

// MARK: - Navigation Transition Modifier

public struct NavigationTransitionModifier: ViewModifier {
    let transition: NavigationTransition
    @State private var isVisible = false

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(transition.animation, value: isVisible)
            .onAppear {
                withAnimation(transition.animation) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

public extension View {
    func navigationTransition(_ transition: NavigationTransition) -> some View {
        self.modifier(NavigationTransitionModifier(transition: transition))
    }
}