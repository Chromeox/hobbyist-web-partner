import Foundation
import Combine
import CoreLocation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var recentSearches: [String] = []
    @Published var popularSearches: [String] = []
    @Published var suggestedClasses: [HobbyClass] = []
    @Published var nearbyClasses: [HobbyClass] = []
    @Published var trendingCategories: [TrendingCategory] = []
    @Published var isSearching: Bool = false
    @Published var searchScope: SearchScope = .all
    @Published var locationFilter: LocationFilter = .anywhere
    @Published var currentLocation: CLLocation?
    @Published var searchRadius: Double = 10 // miles
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = false
    @Published var autocompleteSuggestions: [String] = []
    
    private var searchService: SearchService { SearchService.shared }
    private var locationService: LocationService { LocationService.shared }
    private var analyticsService: AnalyticsService { AnalyticsService.shared }
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let searchDebounceTime: TimeInterval = 0.3
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case classes = "Classes"
        case instructors = "Instructors"
        case venues = "Venues"
    }
    
    enum LocationFilter: String, CaseIterable {
        case anywhere = "Anywhere"
        case nearby = "Nearby"
        case withinCity = "Within City"
        case custom = "Custom Range"
    }
    
    init() {
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // Debounced search on query change
        $searchQuery
            .debounce(for: .seconds(searchDebounceTime), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.performSearch()
                    self?.fetchAutocompleteSuggestions(for: query)
                } else {
                    self?.clearSearch()
                }
            }
            .store(in: &cancellables)
        
        // React to search scope changes
        $searchScope
            .dropFirst()
            .sink { [weak self] _ in
                if !(self?.searchQuery.isEmpty ?? true) {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
        
        // React to location filter changes
        Publishers.CombineLatest($locationFilter, $searchRadius)
            .dropFirst()
            .sink { [weak self] _ in
                if !(self?.searchQuery.isEmpty ?? true) {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
        
        // Listen for location updates
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (location: CLLocation?) in
                self?.currentLocation = location
                if self?.locationFilter == .nearby {
                    self?.loadNearbyClasses()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadRecentSearches() }
                group.addTask { await self.loadPopularSearches() }
                group.addTask { await self.loadSuggestedClasses() }
                group.addTask { await self.loadTrendingCategories() }
                group.addTask { await self.requestLocationPermission() }
            }
        }
    }
    
    func performSearch() {
        // Cancel previous search task
        searchTask?.cancel()
        
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clearSearch()
            return
        }
        
        searchTask = Task {
            await executeSearch()
        }
    }
    
    private func executeSearch() async {
        isSearching = true
        errorMessage = nil
        
        do {
            // Build search parameters
            let parameters = SearchParameters(
                query: searchQuery,
                scope: searchScope,
                location: getLocationForFilter(),
                radius: locationFilter == .custom ? searchRadius : nil,
                offset: 0,
                limit: 20
            )
            
            // Perform search
            let results = try await searchService.search(with: parameters)
            
            // Update results
            await MainActor.run {
                self.searchResults = results
                self.hasMoreResults = results.count == 20
                
                // Add to recent searches
                self.addToRecentSearches(searchQuery)
                
                // Track search analytics
                self.trackSearch(query: searchQuery, resultCount: results.count)
            }
            
        } catch {
            await MainActor.run {
                if error is CancellationError {
                    // Search was cancelled, ignore
                } else {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.searchResults = []
                }
            }
        }
        
        await MainActor.run {
            self.isSearching = false
        }
    }
    
    func loadMoreResults() async {
        guard hasMoreResults && !isSearching else { return }
        
        isSearching = true
        
        do {
            let parameters = SearchParameters(
                query: searchQuery,
                scope: searchScope,
                location: getLocationForFilter(),
                radius: locationFilter == .custom ? searchRadius : nil,
                offset: searchResults.count,
                limit: 20
            )
            
            let moreResults = try await searchService.search(with: parameters)
            
            searchResults.append(contentsOf: moreResults)
            hasMoreResults = moreResults.count == 20
            
        } catch {
            errorMessage = "Failed to load more results: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
    
    private func fetchAutocompleteSuggestions(for query: String) {
        Task {
            do {
                autocompleteSuggestions = try await searchService.fetchAutocompleteSuggestions(for: query)
            } catch {
                // Silently fail for autocomplete
                autocompleteSuggestions = []
            }
        }
    }
    
    func selectAutocompleteSuggestion(_ suggestion: String) {
        searchQuery = suggestion
        autocompleteSuggestions = []
    }
    
    private func loadRecentSearches() async {
        do {
            recentSearches = try await searchService.fetchRecentSearches()
        } catch {
            print("Failed to load recent searches: \(error)")
        }
    }
    
    private func loadPopularSearches() async {
        do {
            popularSearches = try await searchService.fetchPopularSearches()
        } catch {
            print("Failed to load popular searches: \(error)")
        }
    }
    
    private func loadSuggestedClasses() async {
        do {
            suggestedClasses = try await searchService.fetchSuggestedClasses()
        } catch {
            print("Failed to load suggested classes: \(error)")
        }
    }
    
    private func loadNearbyClasses() {
        guard let location = currentLocation else { return }
        
        Task {
            do {
                nearbyClasses = try await searchService.fetchNearbyClasses(
                    location: location,
                    radius: searchRadius
                )
            } catch {
                print("Failed to load nearby classes: \(error)")
            }
        }
    }
    
    private func loadTrendingCategories() async {
        do {
            trendingCategories = try await searchService.fetchTrendingCategories()
        } catch {
            print("Failed to load trending categories: \(error)")
        }
    }
    
    private func requestLocationPermission() async {
        await locationService.requestLocationPermission()
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        autocompleteSuggestions = []
        errorMessage = nil
        hasMoreResults = false
    }
    
    func performQuickSearch(query: String) {
        searchQuery = query
    }
    
    func searchByCategory(_ category: ClassCategory) {
        searchQuery = category.rawValue
        searchScope = .classes
    }
    
    func searchByInstructor(_ instructorName: String) {
        searchQuery = instructorName
        searchScope = .instructors
    }
    
    func searchByVenue(_ venueName: String) {
        searchQuery = venueName
        searchScope = .venues
    }
    
    private func addToRecentSearches(_ query: String) {
        // Remove if already exists
        recentSearches.removeAll { $0 == query }
        
        // Add to beginning
        recentSearches.insert(query, at: 0)
        
        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        // Save to persistent storage
        Task {
            try? await searchService.saveRecentSearches(recentSearches)
        }
    }
    
    func removeFromRecentSearches(_ query: String) {
        recentSearches.removeAll { $0 == query }
        
        Task {
            try? await searchService.saveRecentSearches(recentSearches)
        }
    }
    
    func clearRecentSearches() {
        recentSearches = []
        
        Task {
            try? await searchService.clearRecentSearches()
        }
    }
    
    private func getLocationForFilter() -> CLLocation? {
        switch locationFilter {
        case .anywhere:
            return nil
        case .nearby, .withinCity, .custom:
            return currentLocation
        }
    }
    
    private func trackSearch(query: String, resultCount: Int) {
        Task {
            await analyticsService.trackSearch(
                query: query,
                scope: searchScope.rawValue,
                resultCount: resultCount,
                locationFilter: locationFilter.rawValue
            )
        }
    }
}

// MARK: - Supporting Models
enum SearchResult: Identifiable {
    case hobbyClass(HobbyClass)
    case instructor(Instructor)
    case venue(Venue)
    
    var id: String {
        switch self {
        case .hobbyClass(let hobbyClass):
            return "class_\(hobbyClass.id)"
        case .instructor(let instructor):
            return "instructor_\(instructor.id)"
        case .venue(let venue):
            return "venue_\(venue.id)"
        }
    }
}

struct SearchParameters {
    let query: String
    let scope: SearchViewModel.SearchScope
    let location: CLLocation?
    let radius: Double?
    let offset: Int
    let limit: Int
}

struct TrendingCategory: Identifiable {
    let id: String
    let category: ClassCategory
    let trendScore: Int
    let weeklyGrowth: Double
    let popularClasses: [HobbyClass]
}