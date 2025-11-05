import Foundation
import CoreLocation
import SwiftUI

// MARK: - Search Parameters
struct SearchParameters {
    let query: String
    let scope: SearchScope
    let location: CLLocation?
    let radius: Double?
    let offset: Int
    let limit: Int
    let filters: SearchFilters?
    let sortBy: SearchSortOption
    
    init(
        query: String,
        scope: SearchScope = .all,
        location: CLLocation? = nil,
        radius: Double? = nil,
        offset: Int = 0,
        limit: Int = 20,
        filters: SearchFilters? = nil,
        sortBy: SearchSortOption = .relevance
    ) {
        self.query = query
        self.scope = scope
        self.location = location
        self.radius = radius
        self.offset = offset
        self.limit = limit
        self.filters = filters
        self.sortBy = sortBy
    }
}

// MARK: - Search Scope
enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case classes = "Classes"
    case instructors = "Instructors"
    case venues = "Venues"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "magnifyingglass"
        case .classes: return "graduationcap"
        case .instructors: return "person.circle"
        case .venues: return "building.2"
        }
    }
}

// MARK: - Search Result
enum SearchResult: Identifiable {
    case `class`(HobbyClass)
    case instructor(Instructor)
    case venue(Venue)
    
    var id: String {
        switch self {
        case .class(let hobbyClass): return "class_\(hobbyClass.id)"
        case .instructor(let instructor): return "instructor_\(instructor.id)"
        case .venue(let venue): return "venue_\(venue.id)"
        }
    }
    
    var typeLabel: String {
        switch self {
        case .class: return "Class"
        case .instructor: return "Instructor"
        case .venue: return "Venue"
        }
    }
    
    var typeIcon: String {
        switch self {
        case .class: return "graduationcap.fill"
        case .instructor: return "person.circle.fill"
        case .venue: return "building.2.fill"
        }
    }
    
    var typeColor: Color {
        switch self {
        case .class: return BrandConstants.Colors.primary
        case .instructor: return BrandConstants.Colors.teal
        case .venue: return BrandConstants.Colors.coral
        }
    }
    
    var isExactMatch: Bool {
        // This would be calculated during search based on query matching
        return false
    }
    
    var title: String {
        switch self {
        case .class(let hobbyClass): return hobbyClass.title
        case .instructor(let instructor): return instructor.fullName
        case .venue(let venue): return venue.name
        }
    }
    
    var subtitle: String {
        switch self {
        case .class(let hobbyClass): return hobbyClass.instructor.name
        case .instructor(let instructor): return instructor.bio ?? "Instructor"
        case .venue(let venue): return venue.address
        }
    }
    
    var price: Double? {
        switch self {
        case .class(let hobbyClass): return hobbyClass.price
        case .instructor, .venue: return nil
        }
    }
    
    var rating: Double? {
        switch self {
        case .class(let hobbyClass): return hobbyClass.averageRating
        case .instructor(let instructor): return NSDecimalNumber(decimal: instructor.rating).doubleValue
        case .venue(let venue): return venue.averageRating
        }
    }
}

// MARK: - Search Filters
struct SearchFilters: Codable, Equatable {
    var categories: Set<ClassCategory> = []
    var minPrice: Double = 0
    var maxPrice: Double = 500
    var includeFree: Bool = true
    var difficultyLevels: Set<DifficultyLevel> = []
    var dateRange: DateRange = .any
    var timeOfDay: Set<TimeOfDay> = []
    var daysOfWeek: Set<DayOfWeek> = []
    var duration: DurationRange = .any
    var classSize: ClassSizeRange = .any
    var distance: DistanceRange = .anywhere
    var onlyUpcoming: Bool = true
    var onlyAvailable: Bool = false
    var minRating: Double = 0
    var hasParking: Bool = false
    var isAccessible: Bool = false
    var allowsOnline: Bool = true
    var neighborhoods: Set<String> = []
    var sortBy: SearchSortOption = .relevance
    
    init() {}
    
    var hasActiveFilters: Bool {
        return !categories.isEmpty ||
               minPrice > 0 ||
               maxPrice < 500 ||
               !includeFree ||
               !difficultyLevels.isEmpty ||
               dateRange != .any ||
               !timeOfDay.isEmpty ||
               !daysOfWeek.isEmpty ||
               duration != .any ||
               classSize != .any ||
               distance != .anywhere ||
               !onlyUpcoming ||
               onlyAvailable ||
               minRating > 0 ||
               hasParking ||
               isAccessible ||
               !allowsOnline ||
               !neighborhoods.isEmpty
    }
    
    var activeFilterCount: Int {
        var count = 0
        if !categories.isEmpty { count += 1 }
        if minPrice > 0 || maxPrice < 500 { count += 1 }
        if !difficultyLevels.isEmpty { count += 1 }
        if dateRange != .any { count += 1 }
        if !timeOfDay.isEmpty { count += 1 }
        if !daysOfWeek.isEmpty { count += 1 }
        if duration != .any { count += 1 }
        if classSize != .any { count += 1 }
        if distance != .anywhere { count += 1 }
        if onlyAvailable { count += 1 }
        if minRating > 0 { count += 1 }
        if hasParking { count += 1 }
        if isAccessible { count += 1 }
        if !allowsOnline { count += 1 }
        if !neighborhoods.isEmpty { count += 1 }
        return count
    }
    
    // Clear all filters
    mutating func clear() {
        self = SearchFilters()
    }
    
    // Quick filter methods
    mutating func setFreeOnly() {
        minPrice = 0
        maxPrice = 0
        includeFree = true
    }
    
    mutating func setThisWeekend() {
        dateRange = .thisWeek
        daysOfWeek = [.saturday, .sunday]
    }
    
    mutating func setBeginnerFriendly() {
        difficultyLevels = [.beginner, .allLevels]
    }
    
    mutating func setNearby() {
        distance = .nearby
    }
    
    mutating func setHighlyRated() {
        minRating = 4.5
    }
}

// MARK: - Filter Enums
enum DateRange: String, CaseIterable, Codable {
    case any = "Any Time"
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case thisMonth = "This Month"
    case nextMonth = "Next Month"
    case custom = "Custom Range"
    
    var id: String { rawValue }
}

enum TimeOfDay: String, CaseIterable, Codable {
    case morning = "Morning (6am-12pm)"
    case afternoon = "Afternoon (12pm-6pm)"
    case evening = "Evening (6pm-10pm)"
    case lateNight = "Late Night (10pm+)"
    
    var id: String { rawValue }
    
    var timeRange: ClosedRange<Int> {
        switch self {
        case .morning: return 6...11
        case .afternoon: return 12...17
        case .evening: return 18...21
        case .lateNight: return 22...23
        }
    }
}

enum DayOfWeek: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    var id: String { rawValue }
    var weekdayIndex: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}

enum DurationRange: String, CaseIterable, Codable {
    case any = "Any Duration"
    case short = "Short (< 1 hour)"
    case medium = "Medium (1-2 hours)"
    case long = "Long (2-4 hours)"
    case halfDay = "Half Day (4-6 hours)"
    case fullDay = "Full Day (6+ hours)"
    
    var id: String { rawValue }
    
    var minuteRange: ClosedRange<Int>? {
        switch self {
        case .any: return nil
        case .short: return 1...59
        case .medium: return 60...119
        case .long: return 120...239
        case .halfDay: return 240...359
        case .fullDay: return 360...999
        }
    }
}

enum ClassSizeRange: String, CaseIterable, Codable {
    case any = "Any Size"
    case small = "Small (1-5 people)"
    case medium = "Medium (6-15 people)"
    case large = "Large (16+ people)"
    
    var id: String { rawValue }
    
    var participantRange: ClosedRange<Int>? {
        switch self {
        case .any: return nil
        case .small: return 1...5
        case .medium: return 6...15
        case .large: return 16...999
        }
    }
}

enum DistanceRange: String, CaseIterable, Codable {
    case anywhere = "Anywhere"
    case nearby = "Nearby (< 5km)"
    case walking = "Walking Distance (< 1km)"
    case cycling = "Cycling Distance (< 10km)"
    case driving = "Driving Distance (< 25km)"
    case custom = "Custom Distance"
    
    var id: String { rawValue }
    
    var distanceKm: Double? {
        switch self {
        case .anywhere: return nil
        case .walking: return 1.0
        case .nearby: return 5.0
        case .cycling: return 10.0
        case .driving: return 25.0
        case .custom: return nil
        }
    }
}

// MARK: - Search Sort Options
enum SearchSortOption: String, CaseIterable, Codable {
    case relevance = "Relevance"
    case priceAsc = "Price: Low to High"
    case priceDesc = "Price: High to Low"
    case dateAsc = "Date: Soonest First"
    case dateDesc = "Date: Latest First"
    case rating = "Highest Rated"
    case popularity = "Most Popular"
    case distance = "Nearest First"
    case newest = "Newest Classes"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .relevance: return "sparkles"
        case .priceAsc, .priceDesc: return "dollarsign.circle"
        case .dateAsc, .dateDesc: return "calendar"
        case .rating: return "star.fill"
        case .popularity: return "heart.fill"
        case .distance: return "location.fill"
        case .newest: return "clock.fill"
        }
    }
}

// MARK: - Search Filter for Results Display
enum SearchFilter: String, CaseIterable {
    case all = "All"
    case classes = "Classes"
    case instructors = "Instructors"
    case venues = "Venues"
    
    var displayName: String { rawValue }
    var id: String { rawValue }
}

// MARK: - Trending Category
struct TrendingCategory: Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let classCount: Int
    let trendingScore: Double
    let color: Color
    
    init(name: String, classCount: Int, trendingScore: Double) {
        self.id = UUID()
        self.name = name
        self.iconName = ClassCategory(rawValue: name)?.iconName ?? "tag.fill"
        self.classCount = classCount
        self.trendingScore = trendingScore
        self.color = Self.colorForCategory(name)
    }
    
    private static func colorForCategory(_ name: String) -> Color {
        switch name {
        case "Arts & Crafts": return BrandConstants.Colors.Category.arts
        case "Cooking & Baking": return BrandConstants.Colors.Category.cooking
        case "Photography": return BrandConstants.Colors.Category.photography
        case "Music & Performance": return BrandConstants.Colors.Category.music
        default: return BrandConstants.Colors.primary
        }
    }
}

// MARK: - Vancouver Neighborhoods
struct VancouverNeighborhoods {
    static let all = [
        "Downtown", "West End", "Yaletown", "Gastown", "Chinatown",
        "Kitsilano", "Point Grey", "Kerrisdale", "Shaughnessy",
        "Mount Pleasant", "Commercial Drive", "Grandview-Woodland",
        "Fairview", "False Creek", "Olympic Village",
        "Main Street", "Riley Park", "Cambie Village",
        "Burnaby", "Richmond", "North Vancouver", "West Vancouver"
    ]
    
    static let popular = [
        "Downtown", "Kitsilano", "Gastown", "Mount Pleasant", 
        "Commercial Drive", "Main Street", "Yaletown"
    ]
}

// MARK: - Location Filter
enum LocationFilter: String, CaseIterable {
    case anywhere = "Anywhere"
    case nearby = "Nearby"
    case withinCity = "Within City"
    case custom = "Custom Range"
    
    var id: String { rawValue }
}

// MARK: - Helpers

extension SearchResult {
    init(hobbyClass: HobbyClass) {
        self.id = UUID()
        self.type = .hobbyClass
        self.title = hobbyClass.title
        self.subtitle = hobbyClass.instructor.name
        self.imageUrl = hobbyClass.imageUrl
        self.startDate = hobbyClass.startDate
        self.endDate = hobbyClass.endDate
        self.location = hobbyClass.isOnline ? "Online" : (hobbyClass.venue.name.isEmpty ? hobbyClass.venue.city : hobbyClass.venue.name)
        self.rating = hobbyClass.averageRating
        self.price = hobbyClass.price
        self.distance = nil
        self.relevanceScore = 1.0
    }
}

extension SearchParameters {
    func matches(_ result: SearchResult) -> Bool {
        guard !query.isEmpty else { return true }
        let lowerQuery = query.lowercased()
        if result.title.lowercased().contains(lowerQuery) { return true }
        if let subtitle = result.subtitle?.lowercased(), subtitle.contains(lowerQuery) { return true }
        if let location = result.location?.lowercased(), location.contains(lowerQuery) { return true }
        return false
    }
}
