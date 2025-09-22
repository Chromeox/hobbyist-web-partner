import Foundation

// MARK: - Profile Module Tests
// In a production app, these would be proper XCTest cases

class ProfileModuleTests {

    private var profileService: ProfileService!
    private var mockDataService: MockProfileDataService!

    init() {
        print("🧪 Initializing ProfileModuleTests")
        setup()
    }

    private func setup() {
        mockDataService = MockProfileDataService()
        profileService = ProfileService(dataService: mockDataService)
    }

    // MARK: - Test Methods

    func runAllTests() async {
        print("🧪 Running Profile Module Tests...")

        await testModuleInitialization()
        await testProfileCreation()
        await testProfileUpdates()
        await testProfileValidation()
        await testProfileCompletion()
        await testFeatureFlagIntegration()

        print("✅ All profile tests completed")
    }

    private func testModuleInitialization() async {
        print("🧪 Testing module initialization...")

        do {
            try await profileService.initialize()
            assert(profileService.moduleId == "profile", "Module ID should be 'profile'")
            assert(profileService.isHealthy, "Module should be healthy after initialization")
            print("✅ Module initialization test passed")
        } catch {
            print("❌ Module initialization test failed: \(error)")
        }
    }

    private func testProfileCreation() async {
        print("🧪 Testing profile creation...")

        do {
            // Create a test profile
            let testProfile = UserProfile(
                userId: "test_user_123",
                fullName: "Test User",
                email: "test@example.com",
                bio: "Test bio",
                experienceLevel: .intermediate,
                interests: ["Yoga", "Cooking"],
                preferredTimes: ["Morning", "Evening"],
                budgetRange: .budget50to100
            )

            try await profileService.saveProfile(testProfile)

            // Verify profile was saved
            let savedProfile = try await profileService.loadProfile()
            assert(savedProfile?.fullName == "Test User", "Profile should be saved correctly")
            assert(savedProfile?.interests.count == 2, "Interests should be saved")

            print("✅ Profile creation test passed")
        } catch {
            print("❌ Profile creation test failed: \(error)")
        }
    }

    private func testProfileUpdates() async {
        print("🧪 Testing profile updates...")

        do {
            // Update profile field
            try await profileService.updateProfileField(.bio, value: "Updated bio")

            // Verify update
            let profile = profileService.currentProfile
            assert(profile?.bio == "Updated bio", "Bio should be updated")

            // Update interests
            try await profileService.updateProfileField(.interests, value: ["Yoga", "Cooking", "Photography"])

            // Verify interests update
            let updatedProfile = profileService.currentProfile
            assert(updatedProfile?.interests.count == 3, "Interests should be updated")

            print("✅ Profile updates test passed")
        } catch {
            print("❌ Profile updates test failed: \(error)")
        }
    }

    private func testProfileValidation() async {
        print("🧪 Testing profile validation...")

        // Test with incomplete profile
        let incompleteProfile = UserProfile(
            userId: "test_user",
            fullName: "",
            email: "test@example.com"
        )

        // Temporarily set incomplete profile for testing
        try? await profileService.saveProfile(incompleteProfile)

        let validation = profileService.validateProfile()
        assert(!validation.isValid, "Incomplete profile should not be valid")

        // Test with complete profile
        let completeProfile = UserProfile(
            userId: "test_user",
            fullName: "Complete User",
            email: "test@example.com",
            interests: ["Yoga"]
        )

        try? await profileService.saveProfile(completeProfile)

        let validValidation = profileService.validateProfile()
        assert(validValidation.isValid, "Complete profile should be valid")

        print("✅ Profile validation test passed")
    }

    private func testProfileCompletion() async {
        print("🧪 Testing profile completion calculation...")

        // Test empty profile
        let emptyProfile = UserProfile(
            userId: "test_user",
            fullName: "",
            email: "test@example.com"
        )

        try? await profileService.saveProfile(emptyProfile)
        let emptyCompletion = profileService.profileCompletionPercentage
        assert(emptyCompletion == 0.2, "Empty profile should have low completion percentage")

        // Test complete profile
        let completeProfile = UserProfile(
            userId: "test_user",
            fullName: "Complete User",
            email: "test@example.com",
            profileImageUrl: "https://example.com/image.jpg",
            bio: "Complete bio",
            experienceLevel: .advanced,
            interests: ["Yoga", "Cooking"],
            preferredTimes: ["Morning"],
            budgetRange: .budget100to200,
            location: ProfileLocation(
                address: "123 Test St",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6B 1A1",
                latitude: nil,
                longitude: nil
            ),
            socialLinks: [
                SocialLink(platform: .instagram, username: "testuser", url: "https://instagram.com/testuser")
            ]
        )

        try? await profileService.saveProfile(completeProfile)
        let fullCompletion = profileService.profileCompletionPercentage
        assert(fullCompletion == 1.0, "Complete profile should have 100% completion")

        print("✅ Profile completion test passed")
    }

    private func testFeatureFlagIntegration() async {
        print("🧪 Testing feature flag integration...")

        let featureFlagManager = FeatureFlagManager.shared

        // Test with feature disabled
        featureFlagManager.setFlag(.profileModule, enabled: false)

        do {
            try await profileService.start()
            print("❌ Service should not start when feature flag is disabled")
        } catch {
            print("✅ Service correctly fails when feature flag is disabled")
        }

        // Test with feature enabled
        featureFlagManager.setFlag(.profileModule, enabled: true)

        do {
            try await profileService.start()
            print("✅ Service starts correctly when feature flag is enabled")
        } catch {
            print("❌ Service should start when feature flag is enabled: \(error)")
        }
    }

    // MARK: - Profile Requirements Testing

    func testProfileRequirements() {
        print("🧪 Testing profile requirements...")

        let requirements = profileService.getProfileRequirements()
        assert(requirements.count > 0, "Should have profile requirements")

        let requiredFields = requirements.filter { $0.isRequired }
        assert(requiredFields.count >= 2, "Should have required fields (name and interests)")

        print("✅ Profile requirements test passed")
    }

    // MARK: - Integration Test with SimpleSupabaseService

    func testSupabaseIntegration() async {
        print("🧪 Testing Supabase integration...")

        let supabaseService = SimpleSupabaseService.shared

        // This test would verify that profile works with actual authentication
        if supabaseService.isAuthenticated {
            do {
                let profile = try await profileService.loadProfile()
                print("✅ Profile loading works with authenticated user")

                if let profile = profile {
                    print("✅ User profile found: \(profile.fullName)")
                } else {
                    print("ℹ️ No existing profile found - this is normal for new users")
                }
            } catch {
                print("⚠️ Supabase integration test encountered error: \(error)")
            }
        } else {
            print("ℹ️ Skipping Supabase integration test - user not authenticated")
        }
    }

    // MARK: - Profile Image Testing

    func testProfileImageUpload() async {
        print("🧪 Testing profile image upload...")

        // Create mock image data
        let mockImageData = Data("mock_image_data".utf8)

        do {
            let imageUrl = try await profileService.updateProfileImage(mockImageData)
            assert(!imageUrl.isEmpty, "Image URL should not be empty")

            // Verify profile was updated with image URL
            let profile = profileService.currentProfile
            assert(profile?.profileImageUrl == imageUrl, "Profile should be updated with image URL")

            print("✅ Profile image upload test passed")
        } catch {
            print("❌ Profile image upload test failed: \(error)")
        }
    }

    // MARK: - Profile Deletion Testing

    func testProfileDeletion() async {
        print("🧪 Testing profile deletion...")

        do {
            // Create a profile first
            let testProfile = UserProfile(
                userId: "delete_test_user",
                fullName: "Delete Test",
                email: "delete@example.com"
            )

            try await profileService.saveProfile(testProfile)
            assert(profileService.currentProfile != nil, "Profile should exist before deletion")

            // Delete the profile
            try await profileService.deleteProfile()
            assert(profileService.currentProfile == nil, "Profile should be nil after deletion")

            print("✅ Profile deletion test passed")
        } catch {
            print("❌ Profile deletion test failed: \(error)")
        }
    }
}

// MARK: - Mock Data Service for Testing

private class MockProfileDataService: ProfileDataServiceProtocol {

    private var savedProfiles: [String: UserProfile] = [:]
    private var uploadedImages: [String: Data] = [:]

    func saveProfile(_ profile: UserProfile) async throws {
        savedProfiles[profile.userId] = profile
        print("🧪 Mock: Saved profile for user: \(profile.userId)")
    }

    func loadProfile(for userId: String) async throws -> UserProfile? {
        return savedProfiles[userId]
    }

    func updateProfileField(_ field: ProfileField, value: Any, for userId: String) async throws {
        // This is handled by ProfileService
        print("🧪 Mock: Updated field \(field.displayName) for user: \(userId)")
    }

    func uploadProfileImage(_ imageData: Data, for userId: String) async throws -> String {
        let imageId = UUID().uuidString
        uploadedImages[userId] = imageData
        let imageUrl = "https://mock-storage.com/profile_images/\(userId)/\(imageId).jpg"
        print("🧪 Mock: Uploaded profile image for user: \(userId)")
        return imageUrl
    }

    func deleteProfile(for userId: String) async throws {
        savedProfiles.removeValue(forKey: userId)
        uploadedImages.removeValue(forKey: userId)
        print("🧪 Mock: Deleted profile for user: \(userId)")
    }

    func profileExists(for userId: String) async throws -> Bool {
        return savedProfiles[userId] != nil
    }
}

// MARK: - Test Runner

extension ProfileModuleTests {

    static func runTests() async {
        let testSuite = ProfileModuleTests()
        await testSuite.runAllTests()
        testSuite.testProfileRequirements()
        await testSuite.testSupabaseIntegration()
        await testSuite.testProfileImageUpload()
        await testSuite.testProfileDeletion()
    }
}

// MARK: - Debug Helper for Manual Testing

#if DEBUG
extension ProfileModuleTests {

    func printModuleStatus() {
        print("📊 Profile Module Status:")
        print("- Module ID: \(profileService.moduleId)")
        print("- Module Name: \(profileService.moduleName)")
        print("- Is Healthy: \(profileService.isHealthy)")

        if let profile = profileService.currentProfile {
            print("- Current Profile: \(profile.fullName)")
            print("- Completion: \(Int(profile.completionPercentage * 100))%")
            print("- Interests: \(profile.interests.count)")
            print("- Experience Level: \(profile.experienceLevel.displayName)")
        } else {
            print("- Current Profile: None")
        }
    }

    func simulateCompleteProfileCreation() async {
        print("🎬 Simulating complete profile creation...")

        do {
            // Step 1: Basic Info
            var profile = UserProfile(
                userId: "simulation_user",
                fullName: "Simulation User",
                email: "simulation@example.com"
            )

            try await profileService.saveProfile(profile)
            print("✅ Step 1: Basic info saved")

            // Step 2: Experience and Budget
            try await profileService.updateProfileField(.experienceLevel, value: ExperienceLevel.intermediate)
            try await profileService.updateProfileField(.budgetRange, value: BudgetRange.budget50to100)
            print("✅ Step 2: Experience and budget updated")

            // Step 3: Interests and Times
            try await profileService.updateProfileField(.interests, value: ["Yoga", "Cooking", "Photography"])
            try await profileService.updateProfileField(.preferredTimes, value: ["Morning", "Evening"])
            print("✅ Step 3: Interests and times updated")

            // Step 4: Bio and Image
            try await profileService.updateProfileField(.bio, value: "Passionate about learning new hobbies and connecting with like-minded people.")

            let mockImageData = Data("mock_profile_image".utf8)
            _ = try await profileService.updateProfileImage(mockImageData)
            print("✅ Step 4: Bio and image updated")

            // Step 5: Location and Social
            let location = ProfileLocation(
                address: "123 Hobby St",
                city: "Vancouver",
                province: "BC",
                postalCode: "V6B 1A1",
                latitude: 49.2827,
                longitude: -123.1207
            )
            try await profileService.updateProfileField(.location, value: location)

            let socialLinks = [
                SocialLink(platform: .instagram, username: "hobbyist_sim", url: "https://instagram.com/hobbyist_sim")
            ]
            try await profileService.updateProfileField(.socialLinks, value: socialLinks)
            print("✅ Step 5: Location and social links updated")

            // Final validation
            let validation = profileService.validateProfile()
            let completion = profileService.profileCompletionPercentage

            print("🎉 Simulation completed successfully!")
            print("📊 Final Profile Status:")
            print("- Validation: \(validation.isValid ? "Valid" : "Invalid")")
            print("- Completion: \(Int(completion * 100))%")

        } catch {
            print("❌ Simulation failed: \(error)")
        }
    }
}
#endif