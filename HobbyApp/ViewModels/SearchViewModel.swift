import Foundation
import Combine
import CoreLocation
import Speech
import AVFoundation

// MARK: - Backward Compatibility Enums

enum DateFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case thisWeekend = "This Weekend"
    case nextWeek = "Next Week"
    
    var dateRange: DateRange {
        switch self {
        case .all: return .any
        case .today: return .today
        case .tomorrow: return .tomorrow
        case .thisWeek: return .thisWeek
        case .thisWeekend: return .thisWeek // Will be filtered further
        case .nextWeek: return .nextWeek
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Search State
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var filteredResults: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var hasSearched: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = false
    
    // MARK: - Backward Compatibility Properties
    @Published var searchText: String = ""
    @Published var filteredClasses: [ClassItem] = []
    @Published var categories: [ClassCategory] = ClassCategory.allCases
    @Published var selectedCategory: ClassCategory? = nil
    @Published var dateFilter: DateFilter = .all
    @Published var isLoading: Bool = false
    @Published var allResults: [SearchResult] = []
    
    // Supabase service for compatibility
    var supabaseService: SimpleSupabaseService?
    
    // MARK: - Filters and Scope
    @Published var searchScope: SearchScope = .all
    @Published var currentFilters: SearchFilters = SearchFilters()
    @Published var activeFilterCount: Int = 0
    @Published var selectedSortOption: SearchSortOption = .relevance
    
    // MARK: - Suggestions and History
    @Published var autocompleteSuggestions: [String] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var recentSearches: [String] = []
    @Published var popularSearches: [String] = []
    @Published var savedSearches: [SavedSearch] = []
    
    // MARK: - Discovery Content
    @Published var suggestedClasses: [HobbyClass] = []
    @Published var nearbyClasses: [HobbyClass] = []
    @Published var trendingCategories: [TrendingCategory] = []
    @Published var quickFilterPresets: [QuickFilterPreset] = QuickFilterPreset.presets
    
    // MARK: - Location
    @Published var currentLocation: CLLocation?
    @Published var searchRadius: Double = 10 // km
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: - Voice Search
    @Published var isListeningForVoice: Bool = false
    @Published var voiceSearchText: String = ""
    @Published var voiceSearchError: String?
    
    // MARK: - UI State
    @Published var showingFilters: Bool = false
    @Published var showingLocationPermission: Bool = false
    @Published var showingSaveSearch: Bool = false
    @Published var suggestedQueries: [String] = []
    // Removed duplicate allResults declaration - already defined at line 47

    // MARK: - Services
    private let searchService = SearchService.shared
    private let locationService = LocationService.shared
    private let analyticsService = AnalyticsService.shared
    
    // MARK: - Voice Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-CA"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Private State
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let searchDebounceTime: TimeInterval = 0.3
    private var currentSearchParameters: SearchParameters?
    
    // SearchScope is now defined in SearchModels.swift
    
    init() {
        setupBindings()
        setupVoiceRecognition()
        loadInitialData()
        requestLocationPermissionIfNeeded()
        syncSearchProperties()
    }
    
    private func setupBindings() {
        // Debounced search on query change
        $searchQuery
            .debounce(for: .seconds(searchDebounceTime), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { @MainActor in
                    if !query.isEmpty {
                        await self?.performSearch()
                        await self?.fetchAutocompleteSuggestions(for: query)
                    } else {
                        self?.clearSearch()
                    }
                }
            }
            .store(in: &cancellables)
        
        // React to search scope changes
        $searchScope
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    if !(self?.searchQuery.isEmpty ?? true) {
                        await self?.performSearch()
                    }
                }
            }
            .store(in: &cancellables)
        
        // React to filter changes
        $currentFilters
            .dropFirst()
            .sink { [weak self] filters in
                Task { @MainActor in
                    self?.activeFilterCount = filters.activeFilterCount
                    self?.applyCurrentFilters()
                    if !(self?.searchQuery.isEmpty ?? true) {
                        await self?.performSearch()
                    }
                }
            }
            .store(in: &cancellables)
        
        // React to sort option changes
        $selectedSortOption
            .dropFirst()
            .sink { [weak self] _ in
                self?.applySorting()
            }
            .store(in: &cancellables)
        
        // Listen for location updates
        locationService.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
                if location != nil {
                    Task {
                        await self?.loadNearbyClasses()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for location permission changes
        locationService.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.locationPermissionStatus = status
                Task {
                    await self?.analyticsService.trackLocationPermissionGranted()
                }
            }
            .store(in: &cancellables)
        
        // Bind search service published data
        searchService.$recentSearches
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searches in
                self?.recentSearches = searches.map { $0.query }
            }
            .store(in: &cancellables)
        
        searchService.$savedSearches
            .receive(on: DispatchQueue.main)
            .assign(to: &$savedSearches)
        
        searchService.$popularSearches
            .receive(on: DispatchQueue.main)
            .assign(to: &$popularSearches)
    }
    
    private func loadInitialData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadRecentSearches() }
                group.addTask { await self.loadPopularSearches() }
                group.addTask { await self.loadSuggestedClasses() }
                group.addTask { await self.loadTrendingCategories() }
                group.addTask { await self.loadSavedSearches() }
            }
        }
        
        // Track initial screen view
        Task {
            await analyticsService.trackSearchScreenViewed()
        }
    }
    
    private func setupVoiceRecognition() {
        guard speechRecognizer?.isAvailable == true else { return }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self?.voiceSearchError = "Voice search not available"
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func requestLocationPermissionIfNeeded() {
        guard locationPermissionStatus == .notDetermined else { return }
        
        Task {
            await locationService.requestLocationPermission()
            await analyticsService.trackLocationPermissionRequested()
        }
    }
    
    func performSearch() async {
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
        hasSearched = true
        
        do {
            // Build search parameters
            let parameters = SearchParameters(
                query: searchQuery,
                scope: searchScope,
                location: currentLocation,
                radius: searchRadius,
                offset: 0,
                limit: 20,
                filters: currentFilters.hasActiveFilters ? currentFilters : nil,
                sortBy: selectedSortOption
            )
            
            currentSearchParameters = parameters
            
            // Perform search
            let results = try await searchService.search(with: parameters)
            
            // Update results
            allResults = results
            searchResults = results
            filteredResults = results
            hasMoreResults = results.count == 20
            
            // Generate suggestions based on results
            updateSuggestedQueries()
            
            // Add to recent searches
            searchService.addToSearchHistory(searchQuery, resultCount: results.count)
            
            // Track search analytics
            await trackSearch(query: searchQuery, resultCount: results.count)
            
        } catch {
            if error is CancellationError {
                // Search was cancelled, ignore
            } else {
                errorMessage = "Search failed: \(error.localizedDescription)"
                searchResults = []
                allResults = []
                filteredResults = []
                await analyticsService.trackError(error: error, context: "search_execution")
            }
        }
        
        isSearching = false
    }
    
    func loadMoreResults() async {
        guard hasMoreResults && !isSearching, let parameters = currentSearchParameters else { return }
        
        isSearching = true
        
        do {
            let nextPageParameters = SearchParameters(
                query: parameters.query,
                scope: parameters.scope,
                location: parameters.location,
                radius: parameters.radius,
                offset: searchResults.count,
                limit: 20,
                filters: parameters.filters,
                sortBy: parameters.sortBy
            )
            
            let moreResults = try await searchService.search(with: nextPageParameters)
            
            allResults.append(contentsOf: moreResults)
            searchResults.append(contentsOf: moreResults)
            filteredResults.append(contentsOf: moreResults)
            hasMoreResults = moreResults.count == 20
            
        } catch {
            errorMessage = "Failed to load more results: \(error.localizedDescription)"
            await analyticsService.trackError(error: error, context: "load_more_results")
        }
        
        isSearching = false
    }
    
    private func fetchAutocompleteSuggestions(for query: String) async {
        guard query.count >= 2 else {
            autocompleteSuggestions = []
            searchSuggestions = []
            return
        }
        
        do {
            autocompleteSuggestions = try await searchService.getAutocompleteSuggestions(query: query)
            searchSuggestions = await searchService.getSearchSuggestions(for: query)
        } catch {
            // Silently fail for autocomplete
            autocompleteSuggestions = []
            searchSuggestions = []
        }
    }
    
    func selectAutocompleteSuggestion(_ suggestion: String) {
        searchQuery = suggestion
        autocompleteSuggestions = []
        
        Task {
            await performSearch()
            await analyticsService.trackButtonTap("autocomplete_suggestion", context: suggestion)
        }
    }
    
    func selectSearchSuggestion(_ suggestion: SearchSuggestion) {
        searchQuery = suggestion.text
        
        // Set appropriate scope based on suggestion type
        switch suggestion.type {
        case .category:
            searchScope = .classes
        case .instructor:
            searchScope = .instructors
        case .venue:
            searchScope = .venues
        case .location:
            searchScope = .all
        case .query:
            break
        }
        
        Task {
            await performSearch()
            await analyticsService.trackButtonTap("search_suggestion", context: suggestion.text)
        }
    }
    
    private func loadRecentSearches() async {
        // Recent searches are now automatically updated via binding
    }
    
    private func loadPopularSearches() async {
        // Popular searches are now automatically updated via binding
    }
    
    private func loadSuggestedClasses() async {
        do {
            suggestedClasses = try await searchService.fetchSuggestedClasses()
        } catch {
            print("Failed to load suggested classes: \(error)")
        }
    }
    
    private func loadSavedSearches() async {
        // Saved searches are automatically updated via binding
    }
    
    private func loadNearbyClasses() async {
        guard let location = currentLocation else { return }
        
        do {
            nearbyClasses = try await searchService.fetchNearbyClasses(
                location: location,
                radius: searchRadius
            )
        } catch {
            print("Failed to load nearby classes: \(error)")
        }
    }
    
    private func loadTrendingCategories() async {
        do {
            let categoryNames = try await searchService.fetchTrendingCategories()
            trendingCategories = categoryNames.map { name in
                TrendingCategory(
                    name: name,
                    classCount: Int.random(in: 5...25),
                    trendingScore: Double.random(in: 0.7...1.0)
                )
            }
        } catch {
            print("Failed to load trending categories: \(error)")
        }
    }
    
    // Location permission is now handled in init()
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        allResults = []
        filteredResults = []
        autocompleteSuggestions = []
        searchSuggestions = []
        suggestedQueries = []
        errorMessage = nil
        hasMoreResults = false
        hasSearched = false
        currentSearchParameters = nil
        
        Task {
            await analyticsService.trackSearchCleared()
        }
    }
    
    func performQuickSearch(query: String) {
        searchQuery = query
        Task {
            await performSearch()
        }
    }
    
    func searchByCategory(_ category: ClassCategory) {
        searchQuery = category.rawValue
        searchScope = .classes
        Task {
            await performSearch()
            await analyticsService.trackCategoryBrowsed(category.rawValue)
        }
    }
    
    func searchByInstructor(_ instructorName: String) {
        searchQuery = instructorName
        searchScope = .instructors
        Task {
            await performSearch()
        }
    }
    
    func searchByVenue(_ venueName: String) {
        searchQuery = venueName
        searchScope = .venues
        Task {
            await performSearch()
        }
    }
    
    // Recent searches are now handled by SearchService
    
    func removeFromRecentSearches(_ query: String) {
        searchService.removeFromSearchHistory(query)
    }
    
    func clearRecentSearches() {
        searchService.clearSearchHistory()
    }
    
    // Location is now passed directly from currentLocation
    
    private func trackSearch(query: String, resultCount: Int) async {
        let filterStrings = currentFilters.hasActiveFilters ? ["filters_applied"] : []
        
        await analyticsService.trackSearch(
            query: query,
            scope: searchScope.rawValue,
            resultCount: resultCount,
            appliedFilters: filterStrings,
            executionTime: 0.0 // Could measure actual execution time
        )
    }
    
    // MARK: - Filter Management
    
    func applyFilters(_ filters: SearchFilters) {
        currentFilters = filters
        applyCurrentFilters()
        
        Task {
            if hasSearched {
                await performSearch()
            }
        }
    }
    
    private func applyCurrentFilters() {
        guard hasSearched else { return }
        
        filteredResults = allResults.filter { result in
            switch result {
            case .class(let hobbyClass):
                let parameters = SearchParameters(
                    query: searchQuery,
                    filters: currentFilters
                )
                return parameters.applyFilters(to: hobbyClass, userLocation: currentLocation)
            default:
                return true // For now, only filter classes
            }
        }
        
        applySorting()
    }
    
    private func applySorting() {
        filteredResults = filteredResults.sorted(by: selectedSortOption, userLocation: currentLocation)
    }
    
    func resetFilters() {
        currentFilters = SearchFilters()
        activeFilterCount = 0
        applyCurrentFilters()
        
        Task {
            await analyticsService.trackButtonTap("reset_filters")
        }
    }
    
    func applyQuickFilter(_ preset: QuickFilterPreset) {
        currentFilters = preset.filters
        applyCurrentFilters()
        
        Task {
            await analyticsService.trackQuickFilterUsed(preset.name)
            if hasSearched {
                await performSearch()
            }
        }
    }
    
    // MARK: - Search Results Management
    
    func resultsForFilter(_ filter: SearchFilter) -> [SearchResult] {
        switch filter {
        case .all:
            return filteredResults
        case .classes:
            return filteredResults.filter {
                if case .class = $0 { return true }
                return false
            }
        case .instructors:
            return filteredResults.filter {
                if case .instructor = $0 { return true }
                return false
            }
        case .venues:
            return filteredResults.filter {
                if case .venue = $0 { return true }
                return false
            }
        }
    }
    
    func resultCount(for filter: SearchFilter) -> Int {
        return resultsForFilter(filter).count
    }
    
    private func updateSuggestedQueries() {
        // Generate query suggestions based on current results
        var suggestions: Set<String> = []
        
        // Add category suggestions from results
        for result in allResults {
            if case .class(let hobbyClass) = result {
                suggestions.insert(hobbyClass.category.rawValue)
            }
        }
        
        // Add neighborhood suggestions
        if let location = currentLocation {
            if let neighborhood = locationService.getVancouverNeighborhood(for: location) {
                suggestions.insert("\(neighborhood) classes")
            }
        }
        
        suggestedQueries = Array(suggestions.prefix(5))
    }
    
    // MARK: - Voice Search
    
    func startVoiceSearch() {
        guard speechRecognizer?.isAvailable == true else {
            voiceSearchError = "Voice search not available"
            return
        }
        
        Task {
            await requestMicrophonePermission()
            if isListeningForVoice {
                await stopVoiceSearch()
            } else {
                await beginVoiceRecognition()
            }
        }
    }
    
    private func requestMicrophonePermission() async {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            voiceSearchError = "Microphone access denied"
        }
    }
    
    private func beginVoiceRecognition() async {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            voiceSearchError = "Speech recognition unavailable"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            voiceSearchError = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        isListeningForVoice = true
        voiceSearchError = nil
        voiceSearchText = ""
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.voiceSearchText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        await self?.processVoiceSearchResult(result.bestTranscription.formattedString)
                    }
                }
                
                if error != nil {
                    await self?.stopVoiceSearch()
                }
            }
        }
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            voiceSearchError = "Audio engine failed to start"
            await stopVoiceSearch()
        }
    }
    
    private func stopVoiceSearch() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListeningForVoice = false
    }
    
    private func processVoiceSearchResult(_ text: String) async {
        let processedQuery = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !processedQuery.isEmpty else { return }
        
        searchQuery = processedQuery
        
        await stopVoiceSearch()
        await performSearch()
        
        await analyticsService.trackVoiceSearch(
            originalText: text,
            processedQuery: processedQuery,
            resultCount: searchResults.count
        )
    }
    
    // MARK: - Saved Searches
    
    func saveCurrentSearch(name: String) {
        searchService.saveSearch(
            name: name,
            query: searchQuery,
            filters: currentFilters
        )
        
        Task {
            await analyticsService.trackButtonTap("save_search", context: name)
        }
    }
    
    func applySavedSearch(_ savedSearch: SavedSearch) {
        searchQuery = savedSearch.query
        currentFilters = savedSearch.filters
        applyCurrentFilters()
        
        Task {
            await performSearch()
            await analyticsService.trackSavedSearchUsed(savedSearch.name)
        }
    }
    
    func removeSavedSearch(_ savedSearch: SavedSearch) {
        searchService.removeSavedSearch(savedSearch)
    }
    
    // MARK: - Quick Actions
    
    func searchNearby() {
        guard let location = currentLocation else {
            showingLocationPermission = true
            return
        }
        
        var filters = SearchFilters()
        filters.distance = .nearby
        currentFilters = filters
        searchQuery = ""
        
        Task {
            await performSearch()
            await analyticsService.trackNearbySearchUsed(distance: 5.0)
        }
    }
    
    func searchFreeClasses() {
        var filters = SearchFilters()
        filters.setFreeOnly()
        currentFilters = filters
        searchQuery = "free"
        
        Task {
            await performSearch()
            await analyticsService.trackQuickFilterUsed("free_classes")
        }
    }
    
    func searchThisWeekend() {
        var filters = SearchFilters()
        filters.setThisWeekend()
        currentFilters = filters
        searchQuery = ""
        
        Task {
            await performSearch()
            await analyticsService.trackQuickFilterUsed("this_weekend")
        }
    }
    
    func useRecentSearch(_ query: String) {
        searchQuery = query
        
        Task {
            await performSearch()
            await analyticsService.trackRecentSearchUsed(query)
        }
    }
    
    func usePopularSearch(_ query: String) {
        searchQuery = query
        
        Task {
            await performSearch()
            await analyticsService.trackPopularSearchUsed(query)
        }
    }
    
    // MARK: - Backward Compatibility Methods
    
    func loadClasses() async {
        isLoading = true
        guard let supabaseService = supabaseService else {
            isLoading = false
            return
        }
        
        let classes = await supabaseService.fetchClasses()
        let classItems = classes.map { simpleClass in
            HobbyClass(simpleClass: simpleClass).toClassItem
        }
        
        filteredClasses = classItems
        isLoading = false
    }
    
    func applyFilters() {
        // Convert current state to SearchFilters
        var filters = SearchFilters()
        
        if let category = selectedCategory {
            filters.categories.insert(category)
        }
        
        filters.dateRange = dateFilter.dateRange
        
        // Special handling for weekend filter
        if dateFilter == .thisWeekend {
            filters.daysOfWeek = [.saturday, .sunday]
        }
        
        // Update currentFilters and trigger search
        currentFilters = filters
        
        // Sync searchText with searchQuery
        searchQuery = searchText
        
        Task {
            if !searchText.isEmpty || filters.hasActiveFilters {
                await performSearch()
            } else {
                await loadClasses()
            }
        }
    }
    
    // Sync between old and new search properties
    private func syncSearchProperties() {
        // Bind searchText to searchQuery
        $searchText
            .assign(to: &$searchQuery)
        
        // Convert search results to class items for backward compatibility
        $filteredResults
            .map { results in
                results.compactMap { result in
                    if case .class(let hobbyClass) = result {
                        return hobbyClass.toClassItem
                    }
                    return nil
                }
            }
            .assign(to: &$filteredClasses)
        
        // Keep allResults in sync
        $searchResults
            .assign(to: &$allResults)
        
        // Sync loading state
        $isSearching
            .assign(to: &$isLoading)
    }
    
    // MARK: - Cleanup
    
    deinit {
        Task {
            await stopVoiceSearch()
        }
    }
}

// MARK: - Supporting Models
// SearchResult, SearchParameters, and TrendingCategory are now defined in SearchModels.swift
