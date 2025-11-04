import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var tabContentOffset: CGFloat = 0
    @State private var previousTabIndex: Int = 0

    var body: some View {
        TabView(selection: Binding(
            get: { navigationManager.currentTab.index },
            set: { newIndex in
                let newTab = MainTab.allCases[newIndex]
                navigationManager.switchTab(to: newTab)
            }
        )) {
            // Home Tab
            NavigationStack(path: $navigationManager.homeNavigationPath) {
                HomeView()
                    .navigationTransition(.fade)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                TabIconView(
                    tab: .home,
                    currentTab: navigationManager.currentTab,
                    switchDirection: navigationManager.tabSwitchDirection
                )
            }
            .tag(0)

            // Search Tab
            NavigationStack(path: $navigationManager.searchNavigationPath) {
                SearchView()
                    .navigationTransition(.slide)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                TabIconView(
                    tab: .search,
                    currentTab: navigationManager.currentTab,
                    switchDirection: navigationManager.tabSwitchDirection
                )
            }
            .tag(1)

            // Bookings Tab
            NavigationStack(path: $navigationManager.bookingsNavigationPath) {
                BookingsView()
                    .navigationTransition(.scale)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                TabIconView(
                    tab: .bookings,
                    currentTab: navigationManager.currentTab,
                    switchDirection: navigationManager.tabSwitchDirection
                )
            }
            .tag(2)

            // Profile Tab
            NavigationStack(path: $navigationManager.profileNavigationPath) {
                ProfileView()
                    .navigationTransition(.fade)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                TabIconView(
                    tab: .profile,
                    currentTab: navigationManager.currentTab,
                    switchDirection: navigationManager.tabSwitchDirection
                )
            }
            .tag(3)
        }
        .accentColor(.blue)
        .animation(.easeInOut(duration: 0.2), value: navigationManager.currentTab)
    }

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .classDetail(let classID):
            Text("Class Detail: \(classID)")
                .navigationTitle("Class Details")
        case .profile:
            ProfileView()
        case .settings:
            Text("Settings")
                .navigationTitle("Settings")
        case .credits:
            Text("Credits")
                .navigationTitle("Credits")
        case .store(let category):
            StoreView(initialCategory: category)
                .navigationTitle("Store")
        case .outOfCredits(let creditsNeeded):
            OutOfCreditsView(requiredAdditionalCredits: creditsNeeded)
        case .rewards:
            RewardsView()
                .navigationTitle("Rewards")
        case .bookingFlow(let classID):
            Text("Booking Flow for: \(classID)")
                .navigationTitle("Book Class")
        case .feedback:
            Text("Feedback")
                .navigationTitle("Feedback")
        case .following:
            Text("Following")
                .navigationTitle("Following")
        case .marketplace:
            Text("Marketplace")
                .navigationTitle("Marketplace")
        }
    }
}

// MARK: - Animated Tab Icon Component

struct TabIconView: View {
    let tab: MainTab
    let currentTab: MainTab
    let switchDirection: TabSwitchDirection

    @State private var isAnimating = false
    @State private var bounceScale: CGFloat = 1.0

    private var isSelected: Bool {
        currentTab == tab
    }

    private var iconName: String {
        isSelected ? tab.filledSystemImage : tab.systemImage
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background indicator for selected tab
                if isSelected {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .scaleEffect(bounceScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceScale)
                }

                // Tab icon with morphing animation
                Image(systemName: iconName)
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
            }

            // Tab label
            Text(tab.rawValue)
                .font(BrandConstants.Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .gray)
                .scaleEffect(isSelected ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                // Trigger bounce animation when tab becomes selected
                bounceScale = 1.2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    bounceScale = 1.0
                }
            }
        }
        .onChange(of: switchDirection) { direction in
            guard isSelected && direction != .none else { return }

            // Animate based on switch direction
            withAnimation(.easeInOut(duration: 0.1)) {
                isAnimating = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isAnimating = false
                }
            }
        }
        .offset(y: isAnimating ? (switchDirection == .forward ? -2 : 2) : 0)
    }
}

struct MainHomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var homeViewModel = HomeViewModel()
    
    // Performance optimization: Computed property to prevent unnecessary updates
    private var userName: String {
        authManager.currentUser?.fullName ?? "Hobbyist"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(BrandConstants.Typography.title2)
                            .foregroundColor(.secondary)
                        
                        Text(userName)
                            .font(BrandConstants.Typography.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Stats Cards
                    HStack(spacing: 16) {
                        MainTabStatCard(
                            icon: "trophy.fill",
                            value: "12",
                            label: "Classes Completed",
                            color: .yellow
                        )

                        MainTabStatCard(
                            icon: "star.fill",
                            value: "48",
                            label: "Points Earned",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Upcoming Classes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Classes")
                            .font(BrandConstants.Typography.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(0..<3, id: \.self) { index in
                                    SimpleClassCard()
                                        .id("upcoming-\(index)")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recommended for You
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended for You")
                            .font(BrandConstants.Typography.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(0..<5, id: \.self) { index in
                                    RecommendationCard()
                                        .id("recommendation-\(index)")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

struct MainTabStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    // Performance optimization: Pre-computed frame for consistent layout
    private let cardFrame = CGSize(width: 160, height: 120)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(BrandConstants.Typography.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SimpleClassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [.accentColor.opacity(0.6), .accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Morning Yoga")
                    .font(BrandConstants.Typography.headline)
                
                Text("Tomorrow at 9:00 AM")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                Text("with Sarah Johnson")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 200)
    }
}

struct RecommendationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: "paintbrush.fill")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Watercolor Painting")
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.yellow)
                    
                    Text("4.8")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• $35")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 140)
    }
}







struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationManager.shared)
    }
}