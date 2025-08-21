import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredClasses: [ClassItem] = []
    @Published var nearbyClasses: [ClassItem] = []
    @Published var upcomingClasses: [ClassItem] = []
    @Published var recommendedClasses: [ClassItem] = []
    @Published var popularInstructors: [Instructor] = []
    @Published var categories: [ClassItem.Category] = []
    @Published var hasNotifications = false
    @Published var showMapView = false
    
    // Filter properties
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 200
    @Published var selectedDistance = 5
    @Published var selectedTimes: Set<String> = []
    @Published var selectedDifficulty = "All Levels"
    
    init() {
        loadCategories()
        loadInitialData()
    }
    
    private func loadCategories() {
        categories = [
            ClassItem.Category(name: "Yoga", icon: "figure.yoga"),
            ClassItem.Category(name: "Pilates", icon: "figure.pilates"),
            ClassItem.Category(name: "Cycling", icon: "figure.outdoor.cycle"),
            ClassItem.Category(name: "Swimming", icon: "figure.pool.swim"),
            ClassItem.Category(name: "Dance", icon: "figure.dance"),
            ClassItem.Category(name: "Boxing", icon: "figure.boxing"),
            ClassItem.Category(name: "CrossFit", icon: "figure.strengthtraining.functional"),
            ClassItem.Category(name: "Running", icon: "figure.run")
        ]
    }
    
    private func loadInitialData() {
        // Load sample data
        featuredClasses = [ClassItem.sample]
        nearbyClasses = [ClassItem.sample]
        upcomingClasses = [ClassItem.sample]
        recommendedClasses = [ClassItem.sample]
        popularInstructors = [
            Instructor(
                id: "1",
                name: "Sarah Johnson",
                initials: "SJ",
                rating: "4.9",
                specialties: ["Yoga", "Meditation"],
                bio: "Certified yoga instructor with 10 years experience"
            )
        ]
    }
    
    func searchClasses(query: String) {
        // Implement search logic
    }
    
    func filterByCategory(_ category: String?) {
        // Implement category filter
    }
    
    func refreshContent() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadInitialData()
    }
    
    func resetFilters() {
        minPrice = 0
        maxPrice = 200
        selectedDistance = 5
        selectedTimes = []
        selectedDifficulty = "All Levels"
    }
    
    func applyFilters() {
        // Apply filters to classes
    }
}