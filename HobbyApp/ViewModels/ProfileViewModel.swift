import Foundation
import Combine
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isEditing: Bool = false
    @Published var editedFullName: String = ""
    @Published var editedBio: String = ""
    @Published var editedPhoneNumber: String = ""
    @Published var selectedImage: UIImage?
    @Published var isLoadingProfile: Bool = false
    @Published var isUpdatingProfile: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var statistics: UserStatistics?
    @Published var preferences: UserPreferences = UserPreferences()
    @Published var bookingHistory: [Booking] = []
    @Published var favoriteClasses: [HobbyClass] = []
    @Published var achievements: [Achievement] = []
    @Published var notificationSettings: NotificationSettings = NotificationSettings()

    private let authManager: AuthenticationManager
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthenticationManager? = nil) {
        self.authManager = authManager ?? AuthenticationManager.shared
        setupBindings()
        Task { await loadProfile() }
    }
    
    private func setupBindings() {
        // Listen for user updates from AuthenticationManager
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
                if let user = user {
                    self?.editedFullName = user.name
                    self?.editedBio = ""
                    self?.editedPhoneNumber = ""
                }
            }
            .store(in: &cancellables)
    }
    
    func loadProfile() async {
        guard let currentUser = await authManager.getCurrentUser() else { return }

        isLoadingProfile = true
        errorMessage = nil

        // For now, use the current user from AuthenticationManager
        // In a real app, this would fetch additional profile data from the backend
        user = currentUser
        editedFullName = currentUser.name
        editedBio = ""
        editedPhoneNumber = ""

        // Load mock profile data for demo
        await loadMockProfileData()

        isLoadingProfile = false
    }
    
    private func loadMockProfileData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Load mock data for demonstration
        statistics = UserStatistics(
            totalBookings: 12,
            totalSpent: 450.00,
            classesAttended: 10,
            favoriteCategory: .fitness,
            memberSince: Date().addingTimeInterval(-86400 * 30),
            lastActiveDate: Date(),
            upcomingClasses: 2,
            completedClasses: 10,
            cancelledClasses: 2,
            averageRating: 4.8,
            totalReviews: 8
        )

        bookingHistory = []
        favoriteClasses = []
        achievements = []
    }
    
    func startEditing() {
        isEditing = true
        errorMessage = nil
        successMessage = nil
    }
    
    func cancelEditing() {
        isEditing = false
        // Reset to original values
        if let user = user {
            editedFullName = user.name
            editedBio = ""
            editedPhoneNumber = ""
        }
        selectedImage = nil
        errorMessage = nil
    }

    func saveProfile() async {
        guard let currentUser = user else { return }

        isUpdatingProfile = true
        errorMessage = nil
        successMessage = nil

        // Simulate profile update
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // For demo purposes, just show success
        isEditing = false
        successMessage = "Profile updated successfully"
        selectedImage = nil
        isUpdatingProfile = false
    }
    
    func updatePreferences(_ preferences: UserPreferences) async {
        errorMessage = nil
        self.preferences = preferences
        successMessage = "Preferences updated"
    }

    func updateNotificationSettings(_ settings: NotificationSettings) async {
        errorMessage = nil
        self.notificationSettings = settings
        successMessage = "Notification settings updated"
    }

    func deleteAccount() async {
        errorMessage = nil
        do {
            try await authManager.signOut()
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }

    func exportUserData() async -> URL? {
        errorMessage = nil
        successMessage = "Data export feature coming soon"
        return nil
    }
}

