import Foundation
import Combine

@MainActor
class FollowingViewModel: ObservableObject {
    @Published var following: [FollowingProfile] = []
    @Published var followers: [FollowingProfile] = []
    @Published var suggestions: [FollowingProfile] = []
    @Published var isLoadingFollowing = false
    @Published var isLoadingFollowers = false
    @Published var isLoadingSuggestions = false
    @Published var errorMessage: String?
    
    private let followingService = FollowingService.shared
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() {
        loadFollowing()
        loadFollowers()
        loadSuggestions()
    }
    
    func loadFollowing() {
        isLoadingFollowing = true
        errorMessage = nil

        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                self.isLoadingFollowing = false
                return
            }

            do {
                let profiles = try await followingService.getFollowing(for: userId.uuidString)
                self.following = profiles as? [FollowingProfile] ?? []
                self.isLoadingFollowing = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingFollowing = false
            }
        }
    }
    
    func loadFollowers() {
        isLoadingFollowers = true
        errorMessage = nil

        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                self.isLoadingFollowers = false
                return
            }

            do {
                let profiles = try await followingService.getFollowers(for: userId.uuidString)
                self.followers = profiles as? [FollowingProfile] ?? []
                self.isLoadingFollowers = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingFollowers = false
            }
        }
    }
    
    func loadSuggestions() {
        isLoadingSuggestions = true
        errorMessage = nil

        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                self.isLoadingSuggestions = false
                return
            }

            do {
                let profiles = try await followingService.getSuggestions(for: userId.uuidString)
                self.suggestions = profiles as? [FollowingProfile] ?? []
                self.isLoadingSuggestions = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingSuggestions = false
            }
        }
    }
    
    func follow(_ profile: FollowingProfile) {
        Task {
            guard let userId = await authManager.getCurrentUserId() else { return }
            do {
                try await followingService.follow(
                    userId: userId.uuidString,
                    targetUserId: profile.id.uuidString
                )
                
                // Update UI state
                if let index = self.suggestions.firstIndex(where: { $0.id == profile.id }) {
                    self.suggestions[index] = FollowingProfile(
                        id: profile.id,
                        name: profile.name,
                        username: profile.username,
                        imageUrl: profile.imageUrl,
                        bio: profile.bio,
                        followersCount: profile.followersCount + 1,
                        followingCount: profile.followingCount,
                        isFollowing: true,
                        type: profile.type
                    )
                }
                
                // Add to following list
                let updatedProfile = FollowingProfile(
                    id: profile.id,
                    name: profile.name,
                    username: profile.username,
                    imageUrl: profile.imageUrl,
                    bio: profile.bio,
                    followersCount: profile.followersCount,
                    followingCount: profile.followingCount,
                    isFollowing: true,
                    type: profile.type
                )
                self.following.append(updatedProfile)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func unfollow(_ profile: FollowingProfile) {
        Task {
            guard let userId = await authManager.getCurrentUserId() else { return }
            do {
                try await followingService.unfollow(
                    userId: userId.uuidString,
                    targetUserId: profile.id.uuidString
                )
                
                // Remove from following list
                self.following.removeAll { $0.id == profile.id }
                
                // Update suggestions if present
                if let index = self.suggestions.firstIndex(where: { $0.id == profile.id }) {
                    self.suggestions[index] = FollowingProfile(
                        id: profile.id,
                        name: profile.name,
                        username: profile.username,
                        imageUrl: profile.imageUrl,
                        bio: profile.bio,
                        followersCount: profile.followersCount - 1,
                        followingCount: profile.followingCount,
                        isFollowing: false,
                        type: profile.type
                    )
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}