import Foundation
import SwiftUI

@MainActor
final class AccountSettingsViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var profileImageUrl: String?
    @Published var memberSince = ""
    @Published var classesAttended = 0
    @Published var totalSpent = ""
    @Published var favoriteCategory = ""
    @Published var twoFactorEnabled = false
    @Published var connectedDevicesCount = 0
    @Published var analyticsEnabled = true
    @Published var googleConnected = false
    @Published var appleConnected = false
    @Published var facebookConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var initials: String {
        let names = fullName.components(separatedBy: " ")
        let initials = names.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    func loadAccountInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Generate sample account data
            loadSampleAccountData()
            
        } catch {
            errorMessage = "Failed to load account information"
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        isLoading = true
        
        do {
            // Simulate account deletion delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // In a real app, this would call the API to delete the account
            // and then sign out the user
            
        } catch {
            errorMessage = "Failed to delete account"
        }
        
        isLoading = false
    }
    
    func toggleGoogleConnection() async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        googleConnected.toggle()
    }
    
    func toggleAppleConnection() async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        appleConnected.toggle()
    }
    
    func toggleFacebookConnection() async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        facebookConnected.toggle()
    }
    
    private func loadSampleAccountData() {
        let firstNames = ["Alex", "Jordan", "Taylor", "Casey", "Riley", "Avery", "Morgan", "Quinn"]
        let lastNames = ["Johnson", "Smith", "Williams", "Brown", "Davis", "Miller", "Wilson", "Garcia"]
        
        fullName = "\(firstNames.randomElement() ?? "User") \(lastNames.randomElement() ?? "Name")"
        email = "\(fullName.lowercased().replacingOccurrences(of: " ", with: "."))@example.com"
        
        // Member since (random date in the past 2 years)
        let daysAgo = Int.random(in: 30...730)
        let memberSinceDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let memberSinceFormatter = DateFormatter()
        memberSinceFormatter.dateFormat = "MMMM yyyy"
        memberSince = memberSinceFormatter.string(from: memberSinceDate)
        
        // Stats
        classesAttended = Int.random(in: 0...50)
        let spentAmount = Double.random(in: 0...2000)
        totalSpent = String(format: "$%.0f", spentAmount)
        
        let categories = ["Arts & Crafts", "Cooking", "Photography", "Music", "Fitness", "Writing"]
        favoriteCategory = categories.randomElement() ?? "Arts & Crafts"
        
        // Security settings
        twoFactorEnabled = Bool.random()
        connectedDevicesCount = Int.random(in: 1...5)
        
        // Privacy settings
        analyticsEnabled = Bool.random()
        
        // Connected accounts
        googleConnected = Bool.random()
        appleConnected = Bool.random()
        facebookConnected = Bool.random()
        
        // Profile image (optional)
        profileImageUrl = Bool.random() ? "https://example.com/profile.jpg" : nil
    }
}