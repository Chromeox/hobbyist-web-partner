import Foundation
import Combine

@MainActor
class ClassListViewModel: ObservableObject {
    @Published var classes: [HobbyClass] = []
    @Published var filteredClasses: [HobbyClass] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: ClassCategory?
    @Published var selectedDifficulty: DifficultyLevel?
    @Published var priceRange: ClosedRange<Double> = 0...500
    @Published var selectedDate: Date?
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .dateAscending
    @Published var showFavoritesOnly: Bool = false
    
    private let classService: ClassService
    private let favoritesService: FavoritesService
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption: String, CaseIterable {
        case dateAscending = "Date (Earliest)"
        case dateDescending = "Date (Latest)"
        case priceAscending = "Price (Low to High)"
        case priceDescending = "Price (High to Low)"
        case popularityDescending = "Most Popular"
        case ratingDescending = "Highest Rated"
    }
    
    init(
        classService: ClassService = ClassService.shared,
        favoritesService: FavoritesService = FavoritesService.shared
    ) {
        self.classService = classService
        self.favoritesService = favoritesService
        setupBindings()
        Task { await loadClasses() }
    }
    
    private func setupBindings() {
        // Combine search text, filters, and sort options to automatically update filtered classes
        Publishers.CombineLatest4(
            $searchText,
            $selectedCategory,
            $selectedDifficulty,
            $sortOption
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
        
        // React to price range changes
        $priceRange
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        // React to date and favorites filter changes
        Publishers.CombineLatest3($selectedDate, $showFavoritesOnly, favoritesService.favoritesPublisher)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    func loadClasses() async {
        isLoading = true
        errorMessage = nil
        
        do {
            classes = try await classService.fetchClasses()
            applyFilters()
        } catch {
            errorMessage = handleError(error)
            classes = []
            filteredClasses = []
        }
        
        isLoading = false
    }
    
    func refreshClasses() async {
        await loadClasses()
    }
    
    private func applyFilters() {
        var result = classes
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { hobbyClass in
                hobbyClass.title.localizedCaseInsensitiveContains(searchText) ||
                hobbyClass.description.localizedCaseInsensitiveContains(searchText) ||
                hobbyClass.instructor.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        
        // Apply price filter
        result = result.filter { hobbyClass in
            priceRange.contains(hobbyClass.price)
        }
        
        // Apply date filter
        if let date = selectedDate {
            let calendar = Calendar.current
            result = result.filter { hobbyClass in
                calendar.isDate(hobbyClass.startDate, inSameDayAs: date)
            }
        }
        
        // Apply favorites filter
        if showFavoritesOnly {
            let favoriteIds = favoritesService.favoriteClassIds
            result = result.filter { favoriteIds.contains($0.id) }
        }
        
        // Apply sorting
        result = sortClasses(result)
        
        filteredClasses = result
    }
    
    private func sortClasses(_ classes: [HobbyClass]) -> [HobbyClass] {
        switch sortOption {
        case .dateAscending:
            return classes.sorted { $0.startDate < $1.startDate }
        case .dateDescending:
            return classes.sorted { $0.startDate > $1.startDate }
        case .priceAscending:
            return classes.sorted { $0.price < $1.price }
        case .priceDescending:
            return classes.sorted { $0.price > $1.price }
        case .popularityDescending:
            return classes.sorted { $0.enrolledCount > $1.enrolledCount }
        case .ratingDescending:
            return classes.sorted { $0.averageRating > $1.averageRating }
        }
    }
    
    func toggleFavorite(for classId: String) async {
        do {
            try await favoritesService.toggleFavorite(classId: classId)
        } catch {
            errorMessage = handleError(error)
        }
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        priceRange = 0...500
        selectedDate = nil
        searchText = ""
        sortOption = .dateAscending
        showFavoritesOnly = false
    }
    
    func loadMoreClasses() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let moreClasses = try await classService.fetchMoreClasses(offset: classes.count)
            classes.append(contentsOf: moreClasses)
            applyFilters()
        } catch {
            errorMessage = handleError(error)
        }
        
        isLoading = false
    }

    private func handleError(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your connection and try again."
            case .timedOut:
                return "The request timed out. Please try again."
            default:
                return "An unexpected network error occurred. Please try again later."
            }
        }
        
        // For other errors, you can add more specific handling here
        
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Supporting Models
struct HobbyClass: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: ClassCategory
    let difficulty: DifficultyLevel
    let price: Double
    let startDate: Date
    let endDate: Date
    let duration: Int // in minutes
    let maxParticipants: Int
    let enrolledCount: Int
    let instructor: Instructor
    let venue: Venue
    let imageUrl: String?
    let averageRating: Double
    let totalReviews: Int
    let tags: [String]
    
    var availableSpots: Int {
        maxParticipants - enrolledCount
    }
    
    var isAvailable: Bool {
        availableSpots > 0 && startDate > Date()
    }
}

struct Instructor: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String
    let profileImageUrl: String?
    let rating: Double
    let totalClasses: Int
    let specialties: [String]
}

struct Venue: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
    let imageUrls: [String]
}


enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case allLevels = "All Levels"
}
