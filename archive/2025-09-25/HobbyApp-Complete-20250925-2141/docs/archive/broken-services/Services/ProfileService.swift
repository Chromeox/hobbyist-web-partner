import Foundation
import SwiftUI

// MARK: - Core Profile Service Implementation

@MainActor
final class ProfileService: BaseModuleService, ProfileModuleProtocol {

    // MARK: - Published State

    @Published private(set) var currentProfile: UserProfile?
    @Published private(set) var isLoadingProfile: Bool = false

    // MARK: - Dependencies

    private let dataService: ProfileDataServiceProtocol
    private let dataStore: ModuleDataStore<UserProfile>

    // MARK: - Initialization

    init(dataService: ProfileDataServiceProtocol? = nil) {
        self.currentProfile = nil
        self.dataService = dataService ?? ProfileDataService()
        self.dataStore = ModuleDataStore<UserProfile>(moduleId: "profile")

        super.init(
            moduleId: "profile",
            moduleName: "Profile Module",
            dependencies: []
        )

        print("👤 ProfileService initialized")
    }

    // MARK: - Module Lifecycle

    override func initializeModule() async throws {
        // Load existing profile if user is authenticated
        if let userId = supabaseService.currentUser?.id {
            if let savedProfile = try await dataService.loadProfile(for: userId) {
                currentProfile = savedProfile
                print("👤 Loaded existing profile for user: \(userId)")
            }
        }
    }

    override func startModule() async throws {
        // Check if profile feature is enabled
        guard featureFlagManager.isEnabled(.profileModule) else {
            throw ModuleError.initializationFailed("Profile module is disabled")
        }

        print("▶️ Profile module started")
    }

    override func performHealthCheck() async throws {
        // Call parent health check first
        try await super.performHealthCheck()

        // Additional profile-specific health checks
        if let profile = currentProfile {
            // Ensure we can save/load profile data
            try await dataStore.store(profile, key: "health_check")
            try await dataStore.delete(key: "health_check")
        }
    }

    // MARK: - ProfileModuleProtocol Implementation

    var profileCompletionPercentage: Double {
        return currentProfile?.completionPercentage ?? 0.0
    }

    func saveProfile(_ profile: UserProfile) async throws {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        isLoadingProfile = true
        defer { isLoadingProfile = false }

        // Ensure the profile belongs to the current user
        let updatedProfile = UserProfile(
            id: profile.id,
            userId: user.id,
            fullName: profile.fullName,
            email: profile.email,
            profileImageUrl: profile.profileImageUrl,
            bio: profile.bio,
            experienceLevel: profile.experienceLevel,
            interests: profile.interests,
            preferredTimes: profile.preferredTimes,
            budgetRange: profile.budgetRange,
            location: profile.location,
            socialLinks: profile.socialLinks,
            preferences: profile.preferences,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )

        // Save to local storage first
        try await dataStore.store(updatedProfile, key: "current_profile")

        // Save to backend
        try await dataService.saveProfile(updatedProfile)

        // Update current state
        currentProfile = updatedProfile

        // Publish profile updated event
        let event = ModuleEvent.profileUpdated(from: moduleId, profileData: [
            "userId": user.id,
            "completionPercentage": updatedProfile.completionPercentage
        ])
        ModuleEventBus.shared.publish(event)

        print("👤 Profile saved for user: \(user.id)")
    }

    func loadProfile() async throws -> UserProfile? {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        isLoadingProfile = true
        defer { isLoadingProfile = false }

        let profile = try await dataService.loadProfile(for: user.id)
        currentProfile = profile

        if let profile = profile {
            // Cache locally
            try await dataStore.store(profile, key: "current_profile")
            print("👤 Profile loaded for user: \(user.id)")
        }

        return profile
    }

    func updateProfileField(_ field: ProfileField, value: Any) async throws {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        guard var profile = currentProfile else {
            throw ModuleError.initializationFailed("No current profile to update")
        }

        // Update the specific field
        switch field {
        case .fullName:
            guard let fullName = value as? String else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .bio:
            guard let bio = value as? String else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .experienceLevel:
            guard let level = value as? ExperienceLevel else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: level,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .interests:
            guard let interests = value as? [String] else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .preferredTimes:
            guard let times = value as? [String] else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: times,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .budgetRange:
            guard let budget = value as? BudgetRange else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: budget,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .location:
            guard let location = value as? ProfileLocation else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .socialLinks:
            guard let links = value as? [SocialLink] else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: links,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .preferences:
            guard let prefs = value as? ProfilePreferences else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: profile.profileImageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: prefs,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )

        case .profileImage:
            guard let imageUrl = value as? String else { return }
            profile = UserProfile(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                email: profile.email,
                profileImageUrl: imageUrl,
                bio: profile.bio,
                experienceLevel: profile.experienceLevel,
                interests: profile.interests,
                preferredTimes: profile.preferredTimes,
                budgetRange: profile.budgetRange,
                location: profile.location,
                socialLinks: profile.socialLinks,
                preferences: profile.preferences,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )
        }

        // Save the updated profile
        try await saveProfile(profile)

        print("👤 Updated profile field: \(field.displayName)")
    }

    func updateProfileImage(_ imageData: Data) async throws -> String {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        isLoadingProfile = true
        defer { isLoadingProfile = false }

        // Upload image to storage
        let imageUrl = try await dataService.uploadProfileImage(imageData, for: user.id)

        // Update profile with new image URL
        try await updateProfileField(.profileImage, value: imageUrl)

        print("👤 Profile image updated for user: \(user.id)")
        return imageUrl
    }

    func getProfileRequirements() -> [ProfileRequirement] {
        return [
            ProfileRequirement(
                field: .fullName,
                description: "Full name is required for bookings",
                isRequired: true
            ) { !$0.fullName.isEmpty },

            ProfileRequirement(
                field: .interests,
                description: "At least one interest helps with recommendations",
                isRequired: true
            ) { !$0.interests.isEmpty },

            ProfileRequirement(
                field: .profileImage,
                description: "Profile image helps instructors recognize you"
            ) { $0.profileImageUrl != nil },

            ProfileRequirement(
                field: .bio,
                description: "Bio helps connect with other hobbyists"
            ) { $0.bio != nil && !$0.bio!.isEmpty },

            ProfileRequirement(
                field: .location,
                description: "Location helps find nearby classes"
            ) { $0.location != nil },

            ProfileRequirement(
                field: .experienceLevel,
                description: "Experience level helps match appropriate classes"
            ) { $0.experienceLevel != .beginner },

            ProfileRequirement(
                field: .preferredTimes,
                description: "Preferred times help with class recommendations"
            ) { !$0.preferredTimes.isEmpty }
        ]
    }

    func validateProfile() -> ProfileValidationResult {
        guard let profile = currentProfile else {
            return .invalid(errors: ["No profile exists"])
        }

        let requirements = getProfileRequirements()
        let missingRequired = requirements.filter { requirement in
            requirement.isRequired && !requirement.validationRule(profile)
        }.map { $0.field }

        if !missingRequired.isEmpty {
            return .incomplete(missingFields: missingRequired)
        }

        return .valid
    }

    func deleteProfile() async throws {
        guard let user = supabaseService.currentUser else {
            throw ModuleError.authenticationRequired
        }

        isLoadingProfile = true
        defer { isLoadingProfile = false }

        // Delete from backend
        try await dataService.deleteProfile(for: user.id)

        // Clear local storage
        try await dataStore.delete(key: "current_profile")

        // Clear current state
        currentProfile = nil

        // Publish profile deleted event
        let event = ModuleEvent.profileDeleted(from: moduleId, userData: ["userId": user.id])
        ModuleEventBus.shared.publish(event)

        print("👤 Profile deleted for user: \(user.id)")
    }
}

// MARK: - Profile Data Service Implementation

private class ProfileDataService: ProfileDataServiceProtocol {

    private let supabaseService = SimpleSupabaseService.shared

    func saveProfile(_ profile: UserProfile) async throws {
        // Convert profile to dictionary for Supabase storage
        let profileData: [String: Any] = [
            "id": profile.id,
            "user_id": profile.userId,
            "full_name": profile.fullName,
            "email": profile.email,
            "profile_image_url": profile.profileImageUrl as Any,
            "bio": profile.bio as Any,
            "experience_level": profile.experienceLevel.rawValue,
            "interests": profile.interests,
            "preferred_times": profile.preferredTimes,
            "budget_range": profile.budgetRange.rawValue,
            "location": try? JSONEncoder().encode(profile.location),
            "social_links": try? JSONEncoder().encode(profile.socialLinks),
            "preferences": try? JSONEncoder().encode(profile.preferences),
            "created_at": profile.createdAt.ISO8601Format(),
            "updated_at": profile.updatedAt.ISO8601Format()
        ]

        // For now, store in UserDefaults. In production, this would go to Supabase
        let key = "user_profile_\(profile.userId)"
        if let data = try? JSONSerialization.data(withJSONObject: profileData) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadProfile(for userId: String) async throws -> UserProfile? {
        let key = "user_profile_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Parse the saved profile
        guard let id = dict["id"] as? String,
              let fullName = dict["full_name"] as? String,
              let email = dict["email"] as? String,
              let experienceLevelRaw = dict["experience_level"] as? String,
              let experienceLevel = ExperienceLevel(rawValue: experienceLevelRaw),
              let interests = dict["interests"] as? [String],
              let preferredTimes = dict["preferred_times"] as? [String],
              let budgetRangeRaw = dict["budget_range"] as? String,
              let budgetRange = BudgetRange(rawValue: budgetRangeRaw),
              let createdAtString = dict["created_at"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }

        let profileImageUrl = dict["profile_image_url"] as? String
        let bio = dict["bio"] as? String
        let updatedAtString = dict["updated_at"] as? String
        let updatedAt = updatedAtString.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        // Parse complex objects
        var location: ProfileLocation?
        if let locationData = dict["location"] as? Data {
            location = try? JSONDecoder().decode(ProfileLocation.self, from: locationData)
        }

        var socialLinks: [SocialLink] = []
        if let socialLinksData = dict["social_links"] as? Data {
            socialLinks = (try? JSONDecoder().decode([SocialLink].self, from: socialLinksData)) ?? []
        }

        var preferences = ProfilePreferences()
        if let preferencesData = dict["preferences"] as? Data {
            preferences = (try? JSONDecoder().decode(ProfilePreferences.self, from: preferencesData)) ?? ProfilePreferences()
        }

        return UserProfile(
            id: id,
            userId: userId,
            fullName: fullName,
            email: email,
            profileImageUrl: profileImageUrl,
            bio: bio,
            experienceLevel: experienceLevel,
            interests: interests,
            preferredTimes: preferredTimes,
            budgetRange: budgetRange,
            location: location,
            socialLinks: socialLinks,
            preferences: preferences,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func updateProfileField(_ field: ProfileField, value: Any, for userId: String) async throws {
        // Load existing profile
        guard var profile = try await loadProfile(for: userId) else {
            throw ModuleError.initializationFailed("Profile not found")
        }

        // This is handled by ProfileService.updateProfileField
        // Just save the updated profile
        try await saveProfile(profile)
    }

    func uploadProfileImage(_ imageData: Data, for userId: String) async throws -> String {
        // For now, simulate image upload by creating a local reference
        // In production, this would upload to Supabase Storage
        let imageId = UUID().uuidString
        let imagePath = "profile_images/\(userId)/\(imageId).jpg"

        // Store image data locally (for demo purposes)
        let key = "profile_image_\(userId)"
        UserDefaults.standard.set(imageData, forKey: key)

        // Return the simulated URL
        return "https://example.com/storage/\(imagePath)"
    }

    func deleteProfile(for userId: String) async throws {
        let key = "user_profile_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)

        // Also remove profile image
        let imageKey = "profile_image_\(userId)"
        UserDefaults.standard.removeObject(forKey: imageKey)
    }

    func profileExists(for userId: String) async throws -> Bool {
        let key = "user_profile_\(userId)"
        return UserDefaults.standard.data(forKey: key) != nil
    }
}