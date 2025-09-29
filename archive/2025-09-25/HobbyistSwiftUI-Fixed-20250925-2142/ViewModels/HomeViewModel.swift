import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredClasses: [ClassItem] = []
    @Published var nearbyClasses: [ClassItem] = []
    @Published var upcomingClasses: [ClassItem] = []
    @Published var recommendedClasses: [ClassItem] = []
    @Published var popularInstructors: [InstructorCard] = []
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
            ClassItem.Category(name: "Ceramics", icon: "paintpalette"),
            ClassItem.Category(name: "Pottery", icon: "cup.and.saucer"),
            ClassItem.Category(name: "Painting", icon: "paintbrush"),
            ClassItem.Category(name: "Photography", icon: "camera"),
            ClassItem.Category(name: "Woodworking", icon: "hammer"),
            ClassItem.Category(name: "Jewelry Making", icon: "diamond"),
            ClassItem.Category(name: "Cooking", icon: "chef.hat"),
            ClassItem.Category(name: "Dance", icon: "figure.dance"),
            ClassItem.Category(name: "Music", icon: "music.note"),
            ClassItem.Category(name: "Writing", icon: "pencil"),
            ClassItem.Category(name: "Rumble Boxing", icon: "figure.boxing")
        ]
    }
    
    private func loadInitialData() {
        // Load hobby-focused sample data
        let allClasses = ClassItem.hobbyClassSamples

        featuredClasses = allClasses.filter { $0.isFeatured }
        nearbyClasses = Array(allClasses.prefix(5))
        upcomingClasses = Array(allClasses.prefix(3))
        recommendedClasses = allClasses.shuffled().prefix(4).map { $0 }

        popularInstructors = [
            InstructorCard(
                id: "1",
                name: "Maria Chen",
                initials: "MC",
                rating: "4.9",
                specialties: ["Ceramics", "Pottery"],
                bio: "Master ceramicist with 15 years teaching experience"
            ),
            InstructorCard(
                id: "2",
                name: "David Park",
                initials: "DP",
                rating: "4.8",
                specialties: ["Woodworking", "Furniture"],
                bio: "Sustainable woodworking artist and craftsman"
            ),
            InstructorCard(
                id: "3",
                name: "Sofia Rodriguez",
                initials: "SR",
                rating: "4.7",
                specialties: ["Painting", "Watercolor"],
                bio: "Fine arts painter specializing in botanical watercolors"
            ),
            InstructorCard(
                id: "4",
                name: "Alex Thompson",
                initials: "AT",
                rating: "4.9",
                specialties: ["Rumble Boxing"],
                bio: "Former competitive boxer, certified Rumble instructor"
            ),
            InstructorCard(
                id: "5",
                name: "Elena Kovač",
                initials: "EK",
                rating: "4.7",
                specialties: ["Jewelry Making", "Wire Work"],
                bio: "Traditional European jewelry artisan and silversmith"
            ),
            InstructorCard(
                id: "6",
                name: "Carlos Mendoza",
                initials: "CM",
                rating: "4.8",
                specialties: ["Dance", "Salsa"],
                bio: "International salsa champion and dance instructor"
            ),
            InstructorCard(
                id: "7",
                name: "Maya Thompson",
                initials: "MT",
                rating: "4.9",
                specialties: ["Music", "Guitar"],
                bio: "Professional musician and certified music educator"
            ),
            InstructorCard(
                id: "8",
                name: "Rachel Bennett",
                initials: "RB",
                rating: "4.6",
                specialties: ["Writing", "Creative Writing"],
                bio: "Published author and creative writing workshop leader"
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