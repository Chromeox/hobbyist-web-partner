import Foundation
import CoreLocation
import Combine

@MainActor
class SearchService: ObservableObject {
    static let shared = SearchService()
    
    private let supabaseService: SimpleSupabaseService
    private let locationService: LocationService
    private let userDefaults = UserDefaults.standard
    
    // Search history and suggestions
    @Published var recentSearches: [SearchHistoryItem] = []
    @Published var savedSearches: [SavedSearch] = []
    @Published var popularSearches: [String] = []
    
    // Caching
    private var searchCache: [String: [SearchResult]] = [:]
    private let cacheExpiryInterval: TimeInterval = 300 // 5 minutes
    
    init() {
        self.supabaseService = SimpleSupabaseService.shared
        self.locationService = LocationService.shared
        loadPersistedData()
    }
    
    // MARK: - Main Search Function
    
    func search(with parameters: SearchParameters) async throws -> [SearchResult] {
        let cacheKey = generateCacheKey(for: parameters)
        
        // Check cache first
        if let cachedResults = searchCache[cacheKey] {
            return cachedResults
        }
        
        var allResults: [SearchResult] = []
        
        // Perform concurrent searches for better performance
        await withTaskGroup(of: [SearchResult].self) { group in
            switch parameters.scope {
            case .all:
                group.addTask { await self.searchClasses(with: parameters) }
                group.addTask { await self.searchInstructors(with: parameters) }
                group.addTask { await self.searchVenues(with: parameters) }
                
                for await results in group {
                    allResults.append(contentsOf: results)
                }
            case .classes:
                allResults = await searchClasses(with: parameters)
            case .instructors:
                allResults = await searchInstructors(with: parameters)
            case .venues:
                allResults = await searchVenues(with: parameters)
            }
        }
        
        // Apply filters
        if let filters = parameters.filters {
            allResults = applyFilters(to: allResults, with: filters, userLocation: parameters.location)
        }
        
        // Sort results
        allResults = allResults.sorted(by: parameters.sortBy, userLocation: parameters.location)
        
        // Apply pagination
        let startIndex = parameters.offset
        let endIndex = min(startIndex + parameters.limit, allResults.count)
        let paginatedResults = Array(allResults[startIndex..<endIndex])
        
        // Cache results with expiry
        cacheSearchResults(key: cacheKey, results: paginatedResults)
        
        return paginatedResults
    }
    
    // MARK: - Individual Search Functions
    
    private func searchClasses(with parameters: SearchParameters) async -> [SearchResult] {
        // Fetch classes from Supabase
        let classes = await supabaseService.fetchClasses()
        
        guard !classes.isEmpty else {
            return []
        }
        
        // Convert SimpleClass to HobbyClass to SearchResult
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        var results: [SearchResult] = []
        
        for hobbyClass in hobbyClasses {
            if matchesQuery(hobbyClass, query: parameters.query) {
                results.append(.class(hobbyClass))
            }
        }
        
        return results
    }
    
    private func searchInstructors(with parameters: SearchParameters) async -> [SearchResult] {
        // For now, we'll extract instructors from classes
        // In a real app, you'd have a separate instructors table
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        // Group by instructor to avoid duplicates
        var instructorMap: [String: Instructor] = [:]
        
        for hobbyClass in hobbyClasses {
            let instructorInfo = hobbyClass.instructor
            if matchesInstructorQuery(instructorInfo, query: parameters.query) {
                let instructor = Instructor(
                    id: UUID(),
                    userId: UUID(),
                    firstName: instructorInfo.name.components(separatedBy: " ").first ?? "",
                    lastName: instructorInfo.name.components(separatedBy: " ").dropFirst().joined(separator: " "),
                    email: "",
                    phone: nil,
                    bio: instructorInfo.bio,
                    specialties: instructorInfo.specialties,
                    certificationInfo: nil,
                    rating: Decimal(instructorInfo.rating),
                    totalReviews: 0,
                    profileImageUrl: instructorInfo.profileImageUrl,
                    yearsOfExperience: instructorInfo.yearsOfExperience,
                    socialLinks: instructorInfo.socialLinks,
                    availability: nil,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: nil
                )
                instructorMap[instructorInfo.id] = instructor
            }
        }
        
        return instructorMap.values.map { .instructor($0) }
    }
    
    private func searchVenues(with parameters: SearchParameters) async -> [SearchResult] {
        // For now, we'll extract venues from classes
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        // Group by venue to avoid duplicates
        var venueMap: [String: Venue] = [:]
        
        for hobbyClass in hobbyClasses {
            let venueInfo = hobbyClass.venue
            if matchesVenueQuery(venueInfo, query: parameters.query) {
                let venue = Venue(
                    id: UUID(),
                    name: venueInfo.name,
                    description: "Creative space for hobby classes",
                    address: venueInfo.address,
                    city: venueInfo.city,
                    state: venueInfo.state,
                    zipCode: venueInfo.zipCode,
                    latitude: venueInfo.latitude,
                    longitude: venueInfo.longitude,
                    phone: nil,
                    email: nil,
                    website: nil,
                    amenities: venueInfo.amenities,
                    capacity: 20,
                    hourlyRate: nil,
                    isActive: true,
                    imageUrls: venueInfo.imageUrls ?? [],
                    operatingHours: [:],
                    parkingInfo: venueInfo.parkingInfo,
                    publicTransit: venueInfo.publicTransit,
                    accessibilityInfo: venueInfo.accessibilityInfo,
                    averageRating: 4.5,
                    totalReviews: 0,
                    createdAt: Date(),
                    updatedAt: nil
                )
                venueMap[venueInfo.id] = venue
            }
        }
        
        return venueMap.values.map { .venue($0) }
    }
    
    // MARK: - Query Matching
    
    private func matchesQuery(_ hobbyClass: HobbyClass, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowerQuery = query.lowercased()
        let searchableText = [
            hobbyClass.title,
            hobbyClass.description,
            hobbyClass.instructor.name,
            hobbyClass.category.rawValue,
            hobbyClass.venue.name,
            hobbyClass.venue.city,
            hobbyClass.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        return searchableText.contains(lowerQuery)
    }
    
    private func matchesInstructorQuery(_ instructor: InstructorInfo, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowerQuery = query.lowercased()
        let searchableText = [
            instructor.name,
            instructor.bio ?? "",
            instructor.specialties.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        return searchableText.contains(lowerQuery)
    }
    
    private func matchesVenueQuery(_ venue: VenueInfo, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowerQuery = query.lowercased()
        let searchableText = [
            venue.name,
            venue.address,
            venue.city,
            venue.state,
            venue.amenities.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        return searchableText.contains(lowerQuery)
    }
    
    // MARK: - Filter Application
    
    private func applyFilters(to results: [SearchResult], with filters: SearchFilters, userLocation: CLLocation?) -> [SearchResult] {
        return results.filter { result in
            switch result {
            case .class(let hobbyClass):
                let parameters = SearchParameters(query: "", filters: filters)
                return parameters.applyFilters(to: hobbyClass, userLocation: userLocation)
            case .instructor(let instructor):
                return applyInstructorFilters(instructor, with: filters)
            case .venue(let venue):
                return applyVenueFilters(venue, with: filters, userLocation: userLocation)
            }
        }
    }
    
    private func applyInstructorFilters(_ instructor: Instructor, with filters: SearchFilters) -> Bool {
        // Rating filter
        let instructorRating = NSDecimalNumber(decimal: instructor.rating).doubleValue
        if instructorRating < filters.minRating {
            return false
        }
        
        // Category filter (check if instructor teaches in these categories)
        if !filters.categories.isEmpty {
            // This would require additional data about what categories an instructor teaches
            // For now, we'll allow all instructors to pass this filter
        }
        
        return true
    }
    
    private func applyVenueFilters(_ venue: Venue, with filters: SearchFilters, userLocation: CLLocation?) -> Bool {
        // Rating filter
        if venue.averageRating < filters.minRating {
            return false
        }
        
        // Distance filter
        if let userLocation = userLocation, let distanceLimit = filters.distance.distanceKm {
            let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
            let distance = userLocation.distance(from: venueLocation) / 1000 // Convert to km
            if distance > distanceLimit {
                return false
            }
        }
        
        // Parking filter
        if filters.hasParking && venue.parkingInfo == nil {
            return false
        }
        
        // Accessibility filter
        if filters.isAccessible && venue.accessibilityInfo == nil {
            return false
        }
        
        return true
    }
    
    // MARK: - Autocomplete Suggestions
    
    func getAutocompleteSuggestions(query: String) async throws -> [String] {
        guard query.count >= 2 else { return [] }
        
        var suggestions: Set<String> = []
        
        // Add suggestions from recent searches
        for searchItem in recentSearches {
            if searchItem.query.lowercased().contains(query.lowercased()) {
                suggestions.insert(searchItem.query)
            }
        }
        
        // Add suggestions from popular searches
        for popularSearch in popularSearches {
            if popularSearch.lowercased().contains(query.lowercased()) {
                suggestions.insert(popularSearch)
            }
        }
        
        // Add category suggestions
        for category in ClassCategory.allCases {
            if category.rawValue.lowercased().contains(query.lowercased()) {
                suggestions.insert(category.rawValue)
            }
        }
        
        // Add neighborhood suggestions
        for neighborhood in VancouverNeighborhoods.all {
            if neighborhood.lowercased().contains(query.lowercased()) {
                suggestions.insert(neighborhood)
            }
        }
        
        return Array(suggestions.prefix(8)).sorted()
    }
    
    // MARK: - Search History Management
    
    func addToSearchHistory(_ query: String, resultCount: Int) {
        let historyItem = SearchHistoryItem(query: query, resultCount: resultCount)
        
        // Remove existing entry if it exists
        recentSearches.removeAll { $0.query == query }
        
        // Add to beginning
        recentSearches.insert(historyItem, at: 0)
        
        // Keep only last 20 searches
        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }
        
        saveSearchHistory()
    }
    
    func removeFromSearchHistory(_ query: String) {
        recentSearches.removeAll { $0.query == query }
        saveSearchHistory()
    }
    
    func clearSearchHistory() {
        recentSearches = []
        userDefaults.removeObject(forKey: "searchHistory")
    }
    
    // MARK: - Saved Searches
    
    func saveSearch(name: String, query: String, filters: SearchFilters) {
        let savedSearch = SavedSearch(name: name, query: query, filters: filters)
        savedSearches.append(savedSearch)
        saveSavedSearches()
    }
    
    func removeSavedSearch(_ search: SavedSearch) {
        savedSearches.removeAll { $0.id == search.id }
        saveSavedSearches()
    }
    
    // MARK: - Data Fetchers
    
    func fetchRecentSearches() async throws -> [String] {
        return recentSearches.map { $0.query }
    }
    
    func fetchPopularSearches() async throws -> [String] {
        // In a real app, this would come from analytics
        return [
            "pottery", "cooking", "photography", "painting", "dance",
            "yoga", "writing", "jewelry", "woodworking", "ceramics"
        ]
    }
    
    func fetchSuggestedClasses() async throws -> [HobbyClass] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        // Return featured or highly rated classes
        return hobbyClasses
            .filter { $0.averageRating >= 4.5 }
            .sorted { $0.averageRating > $1.averageRating }
            .prefix(6)
            .map { $0 }
    }
    
    func fetchNearbyClasses(location: CLLocation, radius: Double) async throws -> [HobbyClass] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        return hobbyClasses.filter { hobbyClass in
            let classLocation = CLLocation(
                latitude: hobbyClass.venue.latitude,
                longitude: hobbyClass.venue.longitude
            )
            let distance = location.distance(from: classLocation) / 1000 // Convert to km
            return distance <= radius
        }.sorted { lhs, rhs in
            let leftLocation = CLLocation(latitude: lhs.venue.latitude, longitude: lhs.venue.longitude)
            let rightLocation = CLLocation(latitude: rhs.venue.latitude, longitude: rhs.venue.longitude)
            return location.distance(from: leftLocation) < location.distance(from: rightLocation)
        }
    }
    
    func fetchTrendingCategories() async throws -> [String] {
        // In a real app, this would come from analytics
        return ClassCategory.allCases.map { $0.rawValue }.shuffled().prefix(5).map { $0 }
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() {
        loadSearchHistory()
        loadSavedSearches()
        loadPopularSearches()
    }
    
    private func loadSearchHistory() {
        if let data = userDefaults.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            recentSearches = history
        }
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            userDefaults.set(data, forKey: "searchHistory")
        }
    }
    
    private func loadSavedSearches() {
        if let data = userDefaults.data(forKey: "savedSearches"),
           let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            savedSearches = searches
        }
    }
    
    private func saveSavedSearches() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            userDefaults.set(data, forKey: "savedSearches")
        }
    }
    
    private func loadPopularSearches() {
        popularSearches = [
            "pottery", "cooking", "photography", "painting", "dance",
            "yoga", "writing", "jewelry", "woodworking", "ceramics"
        ]
    }
    
    // MARK: - Cache Management
    
    private var cacheTimestamps: [String: Date] = [:]
    
    private func generateCacheKey(for parameters: SearchParameters) -> String {
        let filtersHash = parameters.filters?.hashValue ?? 0
        let locationHash = parameters.location?.hashValue ?? 0
        return "\(parameters.query)_\(parameters.scope.rawValue)_\(parameters.sortBy.rawValue)_\(filtersHash)_\(locationHash)"
    }
    
    private func cacheSearchResults(key: String, results: [SearchResult]) {
        searchCache[key] = results
        cacheTimestamps[key] = Date()
        
        // Clean expired cache entries
        cleanExpiredCache()
    }
    
    private func cleanExpiredCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) > cacheExpiryInterval ? key : nil
        }
        
        for key in expiredKeys {
            searchCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    func clearCache() {
        searchCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    // MARK: - Analytics Stubs
    
    func saveRecentSearches(_ searches: [String]) async throws {
        // Convert to SearchHistoryItem and save
        recentSearches = searches.map { SearchHistoryItem(query: $0, resultCount: 0) }
        saveSearchHistory()
    }
    
    func clearRecentSearches() async throws {
        clearSearchHistory()
    }
    
    // MARK: - Performance Optimized Search Methods
    
    func performFullTextSearch(query: String, limit: Int = 50) async -> [SearchResult] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        let searchTerms = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var scoredResults: [(result: SearchResult, score: Int)] = []
        
        for hobbyClass in hobbyClasses {
            let score = calculateRelevanceScore(for: hobbyClass, searchTerms: searchTerms)
            if score > 0 {
                scoredResults.append((result: .class(hobbyClass), score: score))
            }
        }
        
        // Sort by relevance score and return top results
        return scoredResults
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0.result }
    }
    
    private func calculateRelevanceScore(for hobbyClass: HobbyClass, searchTerms: [String]) -> Int {
        var score = 0
        let searchableText = [
            hobbyClass.title,
            hobbyClass.description,
            hobbyClass.instructor.name,
            hobbyClass.category.rawValue,
            hobbyClass.venue.name,
            hobbyClass.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        
        for term in searchTerms {
            // Exact title match gets highest score
            if hobbyClass.title.lowercased().contains(term) {
                score += 10
            }
            // Category match gets high score
            if hobbyClass.category.rawValue.lowercased().contains(term) {
                score += 8
            }
            // Instructor name match
            if hobbyClass.instructor.name.lowercased().contains(term) {
                score += 6
            }
            // Venue name match
            if hobbyClass.venue.name.lowercased().contains(term) {
                score += 4
            }
            // Description match
            if hobbyClass.description.lowercased().contains(term) {
                score += 2
            }
            // Tag match
            if hobbyClass.tags.joined(separator: " ").lowercased().contains(term) {
                score += 3
            }
        }
        
        return score
    }
    
    func searchWithGeofiltering(location: CLLocation, radius: Double, query: String = "") async -> [SearchResult] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        return hobbyClasses.compactMap { hobbyClass in
            let classLocation = CLLocation(latitude: hobbyClass.venue.latitude, longitude: hobbyClass.venue.longitude)
            let distance = location.distance(from: classLocation) / 1000 // Convert to km
            
            if distance <= radius {
                if query.isEmpty || matchesQuery(hobbyClass, query: query) {
                    return SearchResult.class(hobbyClass)
                }
            }
            return nil
        }.sorted { lhs, rhs in
            // Sort by distance
            let leftLocation = CLLocation(latitude: lhs.title == hobbyClass.title ? hobbyClass.venue.latitude : 0, longitude: lhs.title == hobbyClass.title ? hobbyClass.venue.longitude : 0)
            let rightLocation = CLLocation(latitude: rhs.title == hobbyClass.title ? hobbyClass.venue.latitude : 0, longitude: rhs.title == hobbyClass.title ? hobbyClass.venue.longitude : 0)
            return location.distance(from: leftLocation) < location.distance(from: rightLocation)
        }
    }
    
    // MARK: - Advanced Filtering
    
    func searchByMultipleCategories(_ categories: [ClassCategory], filters: SearchFilters? = nil) async -> [SearchResult] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        let filteredClasses = hobbyClasses.filter { hobbyClass in
            categories.contains(hobbyClass.category)
        }
        
        var results = filteredClasses.map { SearchResult.class($0) }
        
        if let filters = filters {
            results = applyFilters(to: results, with: filters, userLocation: nil)
        }
        
        return results
    }
    
    func searchByDateRange(startDate: Date, endDate: Date, categories: [ClassCategory] = []) async -> [SearchResult] {
        let classes = await supabaseService.fetchClasses()
        let hobbyClasses = classes.map { HobbyClass(simpleClass: $0) }
        
        return hobbyClasses.compactMap { hobbyClass in
            let classStartsInRange = hobbyClass.startDate >= startDate && hobbyClass.startDate <= endDate
            let categoriesMatch = categories.isEmpty || categories.contains(hobbyClass.category)
            
            if classStartsInRange && categoriesMatch {
                return SearchResult.class(hobbyClass)
            }
            return nil
        }.sorted { $0.title < $1.title }
    }
    
    func getFacetedSearchResults(query: String) async -> (classes: [SearchResult], instructors: [SearchResult], venues: [SearchResult]) {
        let parameters = SearchParameters(query: query, scope: .all)
        
        let classResults = await searchClasses(with: parameters)
        let instructorResults = await searchInstructors(with: parameters)
        let venueResults = await searchVenues(with: parameters)
        
        return (classResults, instructorResults, venueResults)
    }
}

// MARK: - Search Service Extensions

extension SearchService {
    
    // MARK: - Quick Search Methods
    
    func quickSearchByCategory(_ category: ClassCategory) async throws -> [SearchResult] {
        let parameters = SearchParameters(
            query: category.rawValue,
            scope: .classes,
            sortBy: .relevance
        )
        return try await search(with: parameters)
    }
    
    func quickSearchNearby(userLocation: CLLocation, radius: Double = 5.0) async throws -> [SearchResult] {
        var filters = SearchFilters()
        filters.distance = .nearby
        
        let parameters = SearchParameters(
            query: "",
            scope: .classes,
            location: userLocation,
            radius: radius,
            filters: filters,
            sortBy: .distance
        )
        return try await search(with: parameters)
    }
    
    func quickSearchFreeClasses() async throws -> [SearchResult] {
        var filters = SearchFilters()
        filters.setFreeOnly()
        
        let parameters = SearchParameters(
            query: "",
            scope: .classes,
            filters: filters,
            sortBy: .dateAsc
        )
        return try await search(with: parameters)
    }
    
    func quickSearchThisWeekend() async throws -> [SearchResult] {
        var filters = SearchFilters()
        filters.setThisWeekend()
        
        let parameters = SearchParameters(
            query: "",
            scope: .classes,
            filters: filters,
            sortBy: .dateAsc
        )
        return try await search(with: parameters)
    }
    
    // MARK: - Advanced Search Features
    
    func searchWithVoiceQuery(_ voiceText: String) async throws -> [SearchResult] {
        // Process voice text (could include NLP for better understanding)
        let processedQuery = processVoiceQuery(voiceText)
        
        let parameters = SearchParameters(
            query: processedQuery,
            scope: .all,
            sortBy: .relevance
        )
        return try await search(with: parameters)
    }
    
    private func processVoiceQuery(_ voiceText: String) -> String {
        // Simple processing - could be enhanced with NLP
        var processed = voiceText.lowercased()
        
        // Handle common voice patterns
        processed = processed.replacingOccurrences(of: "search for ", with: "")
        processed = processed.replacingOccurrences(of: "find ", with: "")
        processed = processed.replacingOccurrences(of: "show me ", with: "")
        processed = processed.replacingOccurrences(of: "i want to learn ", with: "")
        
        return processed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getSearchSuggestions(for query: String) async -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Category suggestions
        for category in ClassCategory.allCases {
            if category.rawValue.lowercased().contains(query.lowercased()) {
                suggestions.append(SearchSuggestion(
                    text: category.rawValue,
                    type: .category,
                    resultCount: nil
                ))
            }
        }
        
        // Location suggestions
        for neighborhood in VancouverNeighborhoods.popular {
            if neighborhood.lowercased().contains(query.lowercased()) {
                suggestions.append(SearchSuggestion(
                    text: neighborhood,
                    type: .location,
                    resultCount: nil
                ))
            }
        }
        
        return Array(suggestions.prefix(5))
    }
}