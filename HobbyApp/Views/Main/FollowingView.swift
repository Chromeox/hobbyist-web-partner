import SwiftUI

struct FollowingView: View {
    @StateObject private var viewModel = FollowingViewModel()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingSearchResults = false
    
    private let tabs = ["Following", "Followers", "Discover"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Picker
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(tabs[index])
                                    .font(BrandConstants.Typography.subheadline)
                                    .fontWeight(selectedTab == index ? .semibold : .regular)
                                    .foregroundColor(selectedTab == index ? BrandConstants.Colors.primary : .secondary)
                                
                                // Tab indicator
                                Rectangle()
                                    .fill(selectedTab == index ? BrandConstants.Colors.primary : Color.clear)
                                    .frame(height: 2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .background(BrandConstants.Colors.surface)
                
                Divider()
                
                // Search Bar (only for Discover tab)
                if selectedTab == 2 {
                    SearchBar(text: $searchText, isSearching: $showingSearchResults)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Content
                TabView(selection: $selectedTab) {
                    // Following Tab
                    FollowingListView(
                        profiles: viewModel.following,
                        isLoading: viewModel.isLoadingFollowing,
                        emptyMessage: "You're not following anyone yet",
                        emptyDescription: "Follow other hobbyists, instructors, and venues to see their updates here.",
                        onUnfollow: { profile in
                            viewModel.unfollow(profile)
                        }
                    )
                    .tag(0)
                    
                    // Followers Tab
                    FollowingListView(
                        profiles: viewModel.followers,
                        isLoading: viewModel.isLoadingFollowers,
                        emptyMessage: "No followers yet",
                        emptyDescription: "Share your hobby journey and connect with others to grow your network.",
                        showFollowButton: false
                    )
                    .tag(1)
                    
                    // Discover Tab
                    DiscoverView(
                        suggestions: viewModel.suggestions,
                        isLoading: viewModel.isLoadingSuggestions,
                        searchText: searchText,
                        onFollow: { profile in
                            viewModel.follow(profile)
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

// MARK: - Following List View

struct FollowingListView: View {
    let profiles: [FollowingProfile]
    let isLoading: Bool
    let emptyMessage: String
    let emptyDescription: String
    var showFollowButton = true
    var onFollow: ((FollowingProfile) -> Void)? = nil
    var onUnfollow: ((FollowingProfile) -> Void)? = nil
    
    var body: some View {
        Group {
            if isLoading && profiles.isEmpty {
                LoadingView()
            } else if profiles.isEmpty {
                EmptyStateView(
                    message: emptyMessage,
                    description: emptyDescription,
                    iconName: "person.2.circle"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(profiles) { profile in
                            FollowingProfileCard(
                                profile: profile,
                                showFollowButton: showFollowButton,
                                onFollow: onFollow,
                                onUnfollow: onUnfollow
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Discover View

struct DiscoverView: View {
    let suggestions: [FollowingProfile]
    let isLoading: Bool
    let searchText: String
    let onFollow: (FollowingProfile) -> Void
    
    private var filteredSuggestions: [FollowingProfile] {
        if searchText.isEmpty {
            return suggestions
        } else {
            return suggestions.filter { profile in
                profile.name.localizedCaseInsensitiveContains(searchText) ||
                (profile.username?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (profile.bio?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        Group {
            if isLoading && suggestions.isEmpty {
                LoadingView()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // Categories Section
                        if searchText.isEmpty {
                            DiscoverCategoriesView()
                        }
                        
                        // Suggested People
                        VStack(alignment: .leading, spacing: 12) {
                            Text(searchText.isEmpty ? "Suggested for You" : "Search Results")
                                .font(BrandConstants.Typography.headline)
                                .padding(.horizontal)
                            
                            if filteredSuggestions.isEmpty {
                                EmptyStateView(
                                    message: searchText.isEmpty ? "No suggestions available" : "No results found",
                                    description: searchText.isEmpty ? "Check back later for new suggestions" : "Try adjusting your search terms",
                                    iconName: "magnifyingglass"
                                )
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredSuggestions) { profile in
                                        FollowingProfileCard(
                                            profile: profile,
                                            showFollowButton: true,
                                            onFollow: onFollow
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

// MARK: - Discover Categories

struct DiscoverCategoriesView: View {
    private let categories = [
        ("person.2.fill", "Other Hobbyists", "Connect with fellow enthusiasts"),
        ("person.circle.fill", "Instructors", "Follow your favorite teachers"),
        ("building.2.fill", "Venues", "Stay updated on new classes"),
        ("star.circle.fill", "Featured", "Trending profiles this week")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover")
                .font(BrandConstants.Typography.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.1) { icon, title, subtitle in
                        DiscoverCategoryCard(
                            icon: icon,
                            title: title,
                            subtitle: subtitle
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DiscoverCategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(BrandConstants.Colors.primary)
            
            Text(title)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 140, alignment: .leading)
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Profile Card

struct FollowingProfileCard: View {
    let profile: FollowingProfile
    var showFollowButton: Bool = true
    var onFollow: ((FollowingProfile) -> Void)? = nil
    var onUnfollow: ((FollowingProfile) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: profile.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(BrandConstants.Colors.primary.opacity(0.3))
                    .overlay(
                        Text(String(profile.name.prefix(1)))
                            .font(BrandConstants.Typography.title2)
                            .foregroundColor(BrandConstants.Colors.primary)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.semibold)
                    
                    ProfileTypeIcon(type: profile.type)
                }
                
                if let username = profile.username {
                    Text("@\(username)")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                if let bio = profile.bio {
                    Text(bio)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    FollowCountView(count: profile.followersCount, label: "followers")
                    FollowCountView(count: profile.followingCount, label: "following")
                }
            }
            
            Spacer()
            
            // Follow/Unfollow Button
            if showFollowButton {
                Button(action: {
                    if profile.isFollowing {
                        onUnfollow?(profile)
                    } else {
                        onFollow?(profile)
                    }
                }) {
                    Text(profile.isFollowing ? "Following" : "Follow")
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(profile.isFollowing ? .secondary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(profile.isFollowing ? Color.gray.opacity(0.2) : BrandConstants.Colors.primary)
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
}

// MARK: - Supporting Views

struct ProfileTypeIcon: View {
    let type: FollowingType
    
    var body: some View {
        Group {
            switch type {
            case .instructor:
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.blue)
            case .venue:
                Image(systemName: "building.2.fill")
                    .foregroundColor(.green)
            case .user:
                EmptyView()
            }
        }
        .font(BrandConstants.Typography.caption)
    }
}

struct FollowCountView: View {
    let count: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(count)")
                .font(BrandConstants.Typography.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search people, instructors, venues...", text: $text)
                .onTapGesture {
                    isSearching = true
                }
        }
        .padding(12)
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.sm)
    }
}

struct EmptyStateView: View {
    let message: String
    let description: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FollowingView()
}