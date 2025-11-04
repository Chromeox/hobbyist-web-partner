import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var notificationSettings = NotificationSettings()
    @Published var userPreferences = UserPreferences()
    @Published var isDarkModeEnabled = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingDeleteAccountAlert = false
    @Published var showingSignOutAlert = false
    
    private let authManager: AuthenticationManager
    private let profileViewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(authManager: AuthenticationManager = AuthenticationManager.shared,
         profileViewModel: ProfileViewModel) {
        self.authManager = authManager
        self.profileViewModel = profileViewModel
        loadSettings()
        setupBindings()
    }
    
    private func setupBindings() {
        // Listen for preference changes from profile
        profileViewModel.$preferences
            .assign(to: \.userPreferences, on: self)
            .store(in: &cancellables)
        
        profileViewModel.$notificationSettings
            .assign(to: \.notificationSettings, on: self)
            .store(in: &cancellables)
        
        // Listen for dark mode changes
        $isDarkModeEnabled
            .removeDuplicates()
            .sink { [weak self] isDark in
                self?.updateAppearance(isDark: isDark)
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        // Load from UserDefaults for immediate UI updates
        isDarkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        
        // Load notification settings from UserDefaults
        notificationSettings = loadNotificationSettings()
        userPreferences = loadUserPreferences()
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        saveNotificationSettings(settings)
        
        Task {
            await profileViewModel.updateNotificationSettings(settings)
        }
    }
    
    private func loadNotificationSettings() -> NotificationSettings {
        var settings = NotificationSettings()
        settings.pushNotifications = UserDefaults.standard.object(forKey: "pushNotifications") as? Bool ?? true
        settings.emailNotifications = UserDefaults.standard.object(forKey: "emailNotifications") as? Bool ?? true
        settings.marketingEmails = UserDefaults.standard.object(forKey: "marketingEmails") as? Bool ?? false
        settings.classReminders = UserDefaults.standard.object(forKey: "classReminders") as? Bool ?? true
        return settings
    }
    
    private func saveNotificationSettings(_ settings: NotificationSettings) {
        UserDefaults.standard.set(settings.pushNotifications, forKey: "pushNotifications")
        UserDefaults.standard.set(settings.emailNotifications, forKey: "emailNotifications")
        UserDefaults.standard.set(settings.marketingEmails, forKey: "marketingEmails")
        UserDefaults.standard.set(settings.classReminders, forKey: "classReminders")
    }
    
    // MARK: - User Preferences
    
    func updateUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        saveUserPreferences(preferences)
        
        Task {
            await profileViewModel.updatePreferences(preferences)
        }
    }
    
    private func loadUserPreferences() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: "userPreferences"),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return preferences
    }
    
    private func saveUserPreferences(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
    
    // MARK: - Appearance
    
    private func updateAppearance(isDark: Bool) {
        UserDefaults.standard.set(isDark, forKey: "darkModeEnabled")
        
        // Update the app's appearance
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
    
    // MARK: - Account Actions
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.signOut()
            successMessage = "Signed out successfully"
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.deleteAccount()
            successMessage = "Account deleted successfully"
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Data Management
    
    func clearCache() {
        // Clear image cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear temporary files
        let tempDir = NSTemporaryDirectory()
        let tempURL = URL(fileURLWithPath: tempDir)
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(atPath: tempDir)
            for tempFile in tempFiles {
                let fileURL = tempURL.appendingPathComponent(tempFile)
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
        
        successMessage = "Cache cleared successfully"
    }
    
    func exportUserData() async -> URL? {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Create user data export
        let userData = UserDataExport(
            profile: authManager.currentUser,
            preferences: userPreferences,
            notificationSettings: notificationSettings,
            statistics: profileViewModel.statistics,
            exportDate: Date()
        )
        
        guard let jsonData = try? JSONEncoder().encode(userData) else {
            errorMessage = "Failed to prepare user data"
            return nil
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("user_data_export.json")
        
        do {
            try jsonData.write(to: tempURL)
            successMessage = "User data exported successfully"
            return tempURL
        } catch {
            errorMessage = "Failed to export user data: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - App Info
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var fullVersionString: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - User Data Export Model

struct UserDataExport: Codable {
    let profile: AppUser?
    let preferences: UserPreferences
    let notificationSettings: NotificationSettings
    let statistics: UserStatistics?
    let exportDate: Date
}