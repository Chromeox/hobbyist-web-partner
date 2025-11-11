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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter properties
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 200
    @Published var selectedDistance = 5
    @Published var selectedTimes: Set<String> = []
    @Published var selectedDifficulty = "All Levels"
    
    // Real data services
    private let classService = ClassService.shared
    private let instructorService = InstructorService.shared
    private let searchService = SearchService.shared

    nonisolated init() {
        Task { @MainActor in
            self.loadCategories()
            await self.loadInitialData()
        }
    }
    
    private func loadCategories() {
        categories = [
            ClassItem.Category(name: "Ceramics", icon: "paintpalette"),
            ClassItem.Category(name: "Pottery", icon: "cup.and.saucer"),
            ClassItem.Category(name: "Painting", icon: "paintbrush"),
            ClassItem.Category(name: "Photography", icon: "camera"),
            ClassItem.Category(name: "Woodworking", icon: "hammer"),
            ClassItem.Category(name: "Jewelry Making", icon: "diamond"),
            ClassItem.Category(name: "Cooking", icon: "fork.knife.circle"),
            ClassItem.Category(name: "Dance", icon: "figure.dance"),
            ClassItem.Category(name: "Music", icon: "music.note"),
            ClassItem.Category(name: "Writing", icon: "pencil"),
            ClassItem.Category(name: "Rumble Boxing", icon: "figure.boxing")
        ]
    }
    
    private func loadInitialData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load real data using our services
            async let allClasses = classService.fetchClasses()
            async let popularClasses = classService.getPopularClasses()
            async let instructors = instructorService.fetchInstructors()
            
            let classes = try await allClasses
            let popular = try await popularClasses
            let allInstructors = try await instructors
            
            // Convert to ClassItems for the UI
            let classItems = classes.map { ClassItem.from(hobbyClass: $0) }
            let popularItems = popular.map { ClassItem.from(hobbyClass: $0) }
            
            featuredClasses = Array(popularItems.prefix(6))
            nearbyClasses = Array(classItems.prefix(5))
            upcomingClasses = Array(classItems.prefix(3))
            recommendedClasses = Array(classItems.shuffled().prefix(4))
            
            // Convert instructors to InstructorCards
            popularInstructors = allInstructors.map { instructor in
                InstructorCard(
                    id: instructor.id.uuidString,
                    name: instructor.name,
                    initials: createInitials(from: instructor.name),
                    rating: String(format: "%.1f", NSDecimalNumber(decimal: instructor.rating).doubleValue),
                    specialties: instructor.specialties,
                    bio: instructor.bio ?? ""
                )
            }
            
            print("✅ Loaded \(classes.count) classes and \(allInstructors.count) instructors from data services")
            
        } catch {
            print("❌ Failed to load data: \(error)")
            errorMessage = error.localizedDescription
            
            // Fall back to existing sample data if services fail
            loadFallbackData()
        }
        
        isLoading = false
    }
    
    private func loadFallbackData() {
        print("🔄 Loading fallback UI data")
        
        // Use existing sample data as last resort
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
            )
        ]
    }
    
    private func createInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1).uppercased())\(components[1].prefix(1).uppercased())"
        } else if let first = components.first {
            return "\(first.prefix(2).uppercased())"
        }
        return "??"
    }
    
    func searchClasses(query: String) async {
        guard !query.isEmpty else {
            await loadInitialData()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let searchResults = try await searchService.searchClasses(query: query)
            let classItems = searchResults.map { ClassItem.from(hobbyClass: $0) }
            
            featuredClasses = Array(classItems.prefix(6))
            nearbyClasses = Array(classItems.prefix(5))
            upcomingClasses = Array(classItems.prefix(3))
            recommendedClasses = Array(classItems.shuffled().prefix(4))
            
            print("🔍 Found \(searchResults.count) classes for query: \(query)")
            
        } catch {
            print("❌ Search failed: \(error)")
            errorMessage = "Failed to search classes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func filterByCategory(_ category: String?) async {
        guard let category = category else {
            await loadInitialData()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Convert string category to ClassCategory enum
            let hobbyCategory = ClassCategory(rawValue: category.lowercased()) ?? .other
            let filteredClasses = try await classService.getClassesByCategory(hobbyCategory)
            let classItems = filteredClasses.map { ClassItem.from(hobbyClass: $0) }
            
            featuredClasses = Array(classItems.prefix(6))
            nearbyClasses = Array(classItems.prefix(5))
            upcomingClasses = Array(classItems.prefix(3))
            recommendedClasses = Array(classItems.shuffled().prefix(4))
            
            print("🏷️ Found \(filteredClasses.count) classes in category: \(category)")
            
        } catch {
            print("❌ Category filter failed: \(error)")
            errorMessage = "Failed to filter by category: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshContent() async {
        await loadInitialData()
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