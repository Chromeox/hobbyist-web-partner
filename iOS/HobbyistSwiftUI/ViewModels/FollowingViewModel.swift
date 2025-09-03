import Foundation
import Combine

class FollowingViewModel: ObservableObject {
    @Published var following: [FollowingProfile] = []
    @Published var followers: [FollowingProfile] = []
    @Published var suggestions: [FollowingProfile] = []
    @Published var isLoadingFollowing = false
    @Published var isLoadingFollowers = false
    @Published var isLoadingSuggestions = false
    @Published var errorMessage: String?
    
    private let followingService = FollowingService()
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadData() {
        loadFollowing()
        loadFollowers()
        loadSuggestions()
    }
    
    func loadFollowing() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoadingFollowing = true
        errorMessage = nil
        
        Task {
            do {
                let profiles = try await followingService.getFollowing(for: userId)
                await MainActor.run {
                    self.following = profiles
                    self.isLoadingFollowing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingFollowing = false
                }
            }
        }
    }
    
    func loadFollowers() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoadingFollowers = true
        errorMessage = nil
        
        Task {
            do {
                let profiles = try await followingService.getFollowers(for: userId)
                await MainActor.run {
                    self.followers = profiles
                    self.isLoadingFollowers = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingFollowers = false
                }
            }
        }
    }
    
    func loadSuggestions() {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoadingSuggestions = true
        errorMessage = nil
        
        Task {
            do {
                let profiles = try await followingService.getSuggestions(for: userId)
                await MainActor.run {
                    self.suggestions = profiles
                    self.isLoadingSuggestions = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoadingSuggestions = false
                }
            }
        }
    }
    
    func follow(_ profile: FollowingProfile) {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                try await followingService.follow(
                    userId: userId,
                    targetId: profile.id,
                    targetType: profile.type
                )
                
                await MainActor.run {
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
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func unfollow(_ profile: FollowingProfile) {
        guard let userId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                try await followingService.unfollow(
                    userId: userId,
                    targetId: profile.id,
                    targetType: profile.type
                )
                
                await MainActor.run {
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
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}