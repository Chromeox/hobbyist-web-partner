import SwiftUI

struct FollowingView: View {
    @StateObject private var viewModel = FollowingViewModel()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showUserProfile: FollowingProfile?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Following Type", selection: $selectedTab) {
                    Text("Following").tag(0)
                    Text("Followers").tag(1)
                    Text("Discover").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search users...")
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        FollowingListView(
                            profiles: filteredFollowing,
                            isLoading: viewModel.isLoadingFollowing,
                            onProfileTap: { profile in
                                showUserProfile = profile
                            },
                            onUnfollow: { profile in
                                viewModel.unfollow(profile)
                            }
                        )
                    case 1:
                        FollowersListView(
                            profiles: filteredFollowers,
                            isLoading: viewModel.isLoadingFollowers,
                            onProfileTap: { profile in
                                showUserProfile = profile
                            },
                            onFollow: { profile in
                                viewModel.follow(profile)
                            }
                        )
                    case 2:
                        DiscoverPeopleView(
                            profiles: filteredSuggestions,
                            isLoading: viewModel.isLoadingSuggestions,
                            onProfileTap: { profile in
                                showUserProfile = profile
                            },
                            onFollow: { profile in
                                viewModel.follow(profile)
                            }
                        )
                    default:
                        EmptyView()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Social")
            .navigationBarItems(
                trailing: NavigationLink(destination: ActivityFeedView()) {
                    Image(systemName: "bell")
                }
            )
            .sheet(item: $showUserProfile) { profile in
                UserProfileView(profile: profile)
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    private var filteredFollowing: [FollowingProfile] {
        if searchText.isEmpty {
            return viewModel.following
        }
        return viewModel.following.filter { profile in
            profile.name.localizedCaseInsensitiveContains(searchText) ||
            (profile.username?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredFollowers: [FollowingProfile] {
        if searchText.isEmpty {
            return viewModel.followers
        }
        return viewModel.followers.filter { profile in
            profile.name.localizedCaseInsensitiveContains(searchText) ||
            (profile.username?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var filteredSuggestions: [FollowingProfile] {
        if searchText.isEmpty {
            return viewModel.suggestions
        }
        return viewModel.suggestions.filter { profile in
            profile.name.localizedCaseInsensitiveContains(searchText) ||
            (profile.username?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - Following List View
struct FollowingListView: View {
    let profiles: [FollowingProfile]
    let isLoading: Bool
    let onProfileTap: (FollowingProfile) -> Void
    let onUnfollow: (FollowingProfile) -> Void
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else if profiles.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Following Yet",
                    message: "Start following instructors and venues to see their updates"
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(profiles) { profile in
                        FollowingRowView(
                            profile: profile,
                            buttonTitle: "Following",
                            buttonStyle: .secondary,
                            onProfileTap: { onProfileTap(profile) },
                            onButtonTap: { onUnfollow(profile) }
                        )
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }
}

// MARK: - Followers List View
struct FollowersListView: View {
    let profiles: [FollowingProfile]
    let isLoading: Bool
    let onProfileTap: (FollowingProfile) -> Void
    let onFollow: (FollowingProfile) -> Void
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else if profiles.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Followers Yet",
                    message: "Share your activities to gain followers"
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(profiles) { profile in
                        FollowingRowView(
                            profile: profile,
                            buttonTitle: profile.isFollowing ? "Following" : "Follow",
                            buttonStyle: profile.isFollowing ? .secondary : .primary,
                            onProfileTap: { onProfileTap(profile) },
                            onButtonTap: { onFollow(profile) }
                        )
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }
}

// MARK: - Discover People View
struct DiscoverPeopleView: View {
    let profiles: [FollowingProfile]
    let isLoading: Bool
    let onProfileTap: (FollowingProfile) -> Void
    let onFollow: (FollowingProfile) -> Void
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    // Suggested Instructors
                    SuggestedSection(
                        title: "Popular Instructors",
                        profiles: profiles.filter { $0.type == .instructor },
                        onProfileTap: onProfileTap,
                        onFollow: onFollow
                    )
                    
                    // Suggested Users
                    SuggestedSection(
                        title: "People You May Know",
                        profiles: profiles.filter { $0.type == .user },
                        onProfileTap: onProfileTap,
                        onFollow: onFollow
                    )
                    
                    // Suggested Venues
                    SuggestedSection(
                        title: "Trending Venues",
                        profiles: profiles.filter { $0.type == .venue },
                        onProfileTap: onProfileTap,
                        onFollow: onFollow
                    )
                }
                .padding(.vertical)
            }
        }
    }
}

// MARK: - Supporting Views
struct FollowingRowView: View {
    let profile: FollowingProfile
    let buttonTitle: String
    let buttonStyle: ButtonStyle
    let onProfileTap: () -> Void
    let onButtonTap: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onProfileTap) {
                HStack(spacing: 12) {
                    // Profile image
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(profile.name.prefix(2))
                                .font(.headline)
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 8) {
                            Label("\(profile.followersCount)", systemImage: "person.2")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if profile.type == .instructor {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onButtonTap) {
                Text(buttonTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        buttonStyle == .primary ? Color.blue : Color(.systemGray5)
                    )
                    .foregroundColor(
                        buttonStyle == .primary ? .white : .primary
                    )
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct SuggestedSection: View {
    let title: String
    let profiles: [FollowingProfile]
    let onProfileTap: (FollowingProfile) -> Void
    let onFollow: (FollowingProfile) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(profiles.prefix(5)) { profile in
                        SuggestedCard(
                            profile: profile,
                            onTap: { onProfileTap(profile) },
                            onFollow: { onFollow(profile) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SuggestedCard: View {
    let profile: FollowingProfile
    let onTap: () -> Void
    let onFollow: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(profile.name.prefix(2))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    )
                
                Text(profile.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("\(profile.followersCount) followers")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Button(action: onFollow) {
                    Text(profile.isFollowing ? "Following" : "Follow")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(profile.isFollowing ? .primary : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(profile.isFollowing ? Color(.systemGray5) : Color.blue)
                        .cornerRadius(15)
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - User Profile View
struct UserProfileView: View {
    let profile: FollowingProfile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(profile.name.prefix(2))
                                    .font(.largeTitle)
                                    .fontWeight(.medium)
                            )
                        
                        Text(profile.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(profile.followersCount)")
                                    .font(.headline)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack {
                                Text("\(profile.followingCount)")
                                    .font(.headline)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Bio
                        if let bio = profile.bio {
                            Text(bio)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Follow button
                        Button(action: {
                            // Toggle follow
                        }) {
                            Text(profile.isFollowing ? "Following" : "Follow")
                                .fontWeight(.medium)
                                .foregroundColor(profile.isFollowing ? .primary : .white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(profile.isFollowing ? Color(.systemGray5) : Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

#Preview {
    FollowingView()
}