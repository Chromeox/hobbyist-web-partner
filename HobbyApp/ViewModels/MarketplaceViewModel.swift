import Foundation
import Combine
import CoreLocation

@MainActor
class MarketplaceViewModel: ObservableObject {
    @Published var classes: [ClassItem] = []
    @Published var featuredClasses: [ClassItem] = []
    @Published var nearbyInstructors: [Instructor] = []
    @Published var popularVenues: [Venue] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filters
    @Published var priceRange: ClosedRange<Double> = 0...500
    @Published var selectedDistance: Double = 10.0 // miles
    @Published var selectedDuration: Int? = nil
    @Published var selectedDifficulty: String? = nil
    
    private let classService = ClassService.shared
    private let instructorService = InstructorService.shared
    private let venueService = VenueService.shared
    private let locationManager = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationUpdates()
    }
    
    private func setupLocationUpdates() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.loadNearbyData()
            }
            .store(in: &cancellables)
    }
    
    func loadMarketplaceData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Load all data in parallel
                async let classesResult = classService.fetchUpcomingClasses()
                async let instructorsResult = instructorService.fetchAllInstructors()
                async let venuesResult = venueService.fetchStudios()
                
                let (fetchedClasses, fetchedInstructors, fetchedVenues) = await (
                    try classesResult,
                    try instructorsResult,
                    try venuesResult
                )
                
                self.classes = fetchedClasses
                self.featuredClasses = Array(fetchedClasses.prefix(5))
                self.nearbyInstructors = self.filterNearbyInstructors(fetchedInstructors)
                self.popularVenues = self.sortVenuesByPopularity(fetchedVenues)
                self.extractCategories(from: fetchedClasses)
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadNearbyData() {
        guard let userLocation = locationManager.currentLocation else { return }
        
        Task {
            do {
                let instructors = try await instructorService.fetchNearbyInstructors(
                    location: userLocation,
                    radius: selectedDistance
                )
                
                self.nearbyInstructors = instructors
            } catch {
                print("Error loading nearby instructors: \(error)")
            }
        }
    }
    
    private func filterNearbyInstructors(_ instructors: [Instructor]) -> [Instructor] {
        // For now, return top rated instructors
        // In a real app, this would filter by location
        return instructors
            .filter { $0.isActive }
            .sorted { $0.rating > $1.rating }
            .prefix(10)
            .map { $0 }
    }
    
    private func sortVenuesByPopularity(_ venues: [Venue]) -> [Venue] {
        // For now, return active venues
        // In a real app, this would sort by popularity metrics
        return venues
            .filter { $0.isActive }
            .prefix(5)
            .map { $0 }
    }
    
    private func extractCategories(from classes: [ClassItem]) {
        let uniqueCategories = Set(classes.compactMap { $0.category })
        categories = Array(uniqueCategories).sorted()
    }
    
    func applyFilters() {
        // Filter logic would go here
        // This would filter the classes array based on selected filters
    }
    
    func searchClasses(query: String) {
        guard !query.isEmpty else {
            loadMarketplaceData()
            return
        }
        
        Task {
            do {
                let results = try await classService.searchClasses(query: query)
                // Convert HobbyClass to ClassItem
                self.classes = results.map { hobbyClass in
                    ClassItem(from: hobbyClass)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Filter View
import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Price Range")) {
                    VStack {
                        HStack {
                            Text("$\(Int(viewModel.priceRange.lowerBound))")
                            Spacer()
                            Text("$\(Int(viewModel.priceRange.upperBound))")
                        }
                        .font(.caption)
                        
                        // Note: In a real app, you'd use a RangeSlider here
                        Slider(value: .constant(250), in: 0...500)
                            .disabled(true) // Placeholder
                    }
                }
                
                Section(header: Text("Distance")) {
                    Picker("Maximum Distance", selection: $viewModel.selectedDistance) {
                        Text("1 mile").tag(1.0)
                        Text("5 miles").tag(5.0)
                        Text("10 miles").tag(10.0)
                        Text("25 miles").tag(25.0)
                        Text("50+ miles").tag(50.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Class Duration")) {
                    Picker("Duration", selection: $viewModel.selectedDuration) {
                        Text("Any").tag(nil as Int?)
                        Text("30 min").tag(30 as Int?)
                        Text("45 min").tag(45 as Int?)
                        Text("60 min").tag(60 as Int?)
                        Text("90+ min").tag(90 as Int?)
                    }
                }
                
                Section(header: Text("Difficulty Level")) {
                    Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                        Text("All Levels").tag(nil as String?)
                        Text("Beginner").tag("beginner" as String?)
                        Text("Intermediate").tag("intermediate" as String?)
                        Text("Advanced").tag("advanced" as String?)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Reset") {
                    viewModel.priceRange = 0...500
                    viewModel.selectedDistance = 10.0
                    viewModel.selectedDuration = nil
                    viewModel.selectedDifficulty = nil
                },
                trailing: Button("Apply") {
                    viewModel.applyFilters()
                    dismiss()
                }
            )
        }
    }
}