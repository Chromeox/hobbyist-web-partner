import Foundation
import Combine
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
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
    
    private let authService: AuthenticationService
    private let profileService: ProfileService
    private let bookingService: BookingService
    private let favoritesService: FavoritesService
    private let storageService: StorageService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        authService: AuthenticationService = AuthenticationService.shared,
        profileService: ProfileService = ProfileService.shared,
        bookingService: BookingService = BookingService.shared,
        favoritesService: FavoritesService = FavoritesService.shared,
        storageService: StorageService = StorageService.shared
    ) {
        self.authService = authService
        self.profileService = profileService
        self.bookingService = bookingService
        self.favoritesService = favoritesService
        self.storageService = storageService
        setupBindings()
        Task { await loadProfile() }
    }
    
    private func setupBindings() {
        // Listen for user updates
        authService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
                if user != nil {
                    Task { await self?.loadProfileData() }
                }
            }
            .store(in: &cancellables)
        
        // Update edited fields when user changes
        $user
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.editedFullName = user.fullName
                self?.editedBio = user.bio ?? ""
                self?.editedPhoneNumber = user.phoneNumber ?? ""
            }
            .store(in: &cancellables)
    }
    
    func loadProfile() async {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoadingProfile = true
        errorMessage = nil
        
        do {
            // Load user profile
            user = try await profileService.fetchProfile(userId: userId)
            
            // Load additional profile data
            await loadProfileData()
            
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        
        isLoadingProfile = false
    }
    
    private func loadProfileData() async {
        guard let userId = user?.id else { return }
        
        await withTaskGroup(of: Void.self) { group in
            // Load statistics
            group.addTask { [weak self] in
                do {
                    self?.statistics = try await self?.profileService.fetchUserStatistics(userId: userId)
                } catch {
                    print("Failed to load statistics: \(error)")
                }
            }
            
            // Load preferences
            group.addTask { [weak self] in
                do {
                    self?.preferences = try await self?.profileService.fetchUserPreferences(userId: userId)
                } catch {
                    print("Failed to load preferences: \(error)")
                }
            }
            
            // Load booking history
            group.addTask { [weak self] in
                do {
                    self?.bookingHistory = try await self?.bookingService.fetchUserBookings(userId: userId)
                } catch {
                    print("Failed to load booking history: \(error)")
                }
            }
            
            // Load favorite classes
            group.addTask { [weak self] in
                do {
                    self?.favoriteClasses = try await self?.favoritesService.fetchFavoriteClasses(userId: userId)
                } catch {
                    print("Failed to load favorite classes: \(error)")
                }
            }
            
            // Load achievements
            group.addTask { [weak self] in
                do {
                    self?.achievements = try await self?.profileService.fetchAchievements(userId: userId)
                } catch {
                    print("Failed to load achievements: \(error)")
                }
            }
            
            // Load notification settings
            group.addTask { [weak self] in
                do {
                    self?.notificationSettings = try await self?.profileService.fetchNotificationSettings(userId: userId)
                } catch {
                    print("Failed to load notification settings: \(error)")
                }
            }
        }
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
            editedFullName = user.fullName
            editedBio = user.bio ?? ""
            editedPhoneNumber = user.phoneNumber ?? ""
        }
        selectedImage = nil
        errorMessage = nil
    }
    
    func saveProfile() async {
        guard let userId = user?.id else { return }
        
        isUpdatingProfile = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Upload profile image if changed
            var profileImageUrl: String? = user?.profileImageUrl
            if let image = selectedImage {
                profileImageUrl = try await storageService.uploadProfileImage(
                    image: image,
                    userId: userId
                )
            }
            
            // Update profile
            let updatedProfile = ProfileUpdate(
                fullName: editedFullName,
                bio: editedBio.isEmpty ? nil : editedBio,
                phoneNumber: editedPhoneNumber.isEmpty ? nil : editedPhoneNumber,
                profileImageUrl: profileImageUrl
            )
            
            user = try await profileService.updateProfile(
                userId: userId,
                updates: updatedProfile
            )
            
            isEditing = false
            successMessage = "Profile updated successfully"
            selectedImage = nil
            
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isUpdatingProfile = false
    }
    
    func updatePreferences(_ preferences: UserPreferences) async {
        guard let userId = user?.id else { return }
        
        errorMessage = nil
        
        do {
            self.preferences = try await profileService.updatePreferences(
                userId: userId,
                preferences: preferences
            )
            successMessage = "Preferences updated"
        } catch {
            errorMessage = "Failed to update preferences: \(error.localizedDescription)"
        }
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) async {
        guard let userId = user?.id else { return }
        
        errorMessage = nil
        
        do {
            self.notificationSettings = try await profileService.updateNotificationSettings(
                userId: userId,
                settings: settings
            )
            successMessage = "Notification settings updated"
        } catch {
            errorMessage = "Failed to update notification settings: \(error.localizedDescription)"
        }
    }
    
    func deleteAccount() async {
        guard let userId = user?.id else { return }
        
        errorMessage = nil
        
        do {
            // Delete user data
            try await profileService.deleteAccount(userId: userId)
            
            // Sign out
            try await authService.signOut()
            
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }
    
    func exportUserData() async -> URL? {
        guard let userId = user?.id else { return nil }
        
        errorMessage = nil
        
        do {
            return try await profileService.exportUserData(userId: userId)
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Supporting Models
struct UserStatistics: Codable {
    let totalBookings: Int
    let totalSpent: Double
    let classesAttended: Int
    let favoriteCategory: ClassCategory?
    let memberSince: Date
    let lastActiveDate: Date
    let upcomingClasses: Int
    let completedClasses: Int
    let cancelledClasses: Int
    let averageRating: Double?
    let totalReviews: Int
}

struct UserPreferences: Codable {
    var preferredCategories: [ClassCategory] = []
    var preferredDifficulty: DifficultyLevel?
    var maxPrice: Double = 500
    var preferredDays: [WeekDay] = []
    var preferredTimeSlots: [TimeSlot] = []
    var notificationRadius: Double = 10 // miles
    var language: String = "en"
    var currency: String = "USD"
    
    enum WeekDay: String, CaseIterable, Codable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    }
    
    enum TimeSlot: String, CaseIterable, Codable {
        case morning = "Morning (6am-12pm)"
        case afternoon = "Afternoon (12pm-6pm)"
        case evening = "Evening (6pm-10pm)"
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date?
    let progress: Double // 0.0 to 1.0
    let requirement: Int
    let current: Int
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

struct NotificationSettings: Codable {
    var pushEnabled: Bool = true
    var emailEnabled: Bool = true
    var smsEnabled: Bool = false
    var bookingReminders: Bool = true
    var classUpdates: Bool = true
    var promotionalOffers: Bool = false
    var newClassAlerts: Bool = true
    var instructorUpdates: Bool = true
    var reminderTiming: ReminderTiming = .oneDay
    
    enum ReminderTiming: String, CaseIterable, Codable {
        case oneHour = "1 hour before"
        case twoHours = "2 hours before"
        case oneDay = "1 day before"
        case twoDays = "2 days before"
    }
}

struct ProfileUpdate: Codable {
    let fullName: String
    let bio: String?
    let phoneNumber: String?
    let profileImageUrl: String?
}