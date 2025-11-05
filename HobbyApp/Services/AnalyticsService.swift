import Foundation

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Search Analytics
    
    func trackSearch(
        query: String,
        scope: String,
        resultCount: Int,
        appliedFilters: [String],
        executionTime: TimeInterval
    ) async {
        let event = SearchAnalyticsEvent(
            query: query,
            scope: scope,
            resultCount: resultCount,
            appliedFilters: appliedFilters,
            executionTime: executionTime,
            timestamp: Date()
        )
        
        await logEvent("search_performed", parameters: event.toDictionary())
    }
    
    func trackSearchResultTap(
        query: String,
        resultType: String,
        resultId: String,
        position: Int
    ) async {
        let parameters: [String: Any] = [
            "query": query,
            "result_type": resultType,
            "result_id": resultId,
            "position": position,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("search_result_tap", parameters: parameters)
    }
    
    func trackFilterUsage(
        filterType: String,
        filterValue: String,
        query: String
    ) async {
        let parameters: [String: Any] = [
            "filter_type": filterType,
            "filter_value": filterValue,
            "query": query,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("search_filter_applied", parameters: parameters)
    }
    
    func trackVoiceSearch(
        originalText: String,
        processedQuery: String,
        resultCount: Int
    ) async {
        let parameters: [String: Any] = [
            "original_text": originalText,
            "processed_query": processedQuery,
            "result_count": resultCount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("voice_search_performed", parameters: parameters)
    }
    
    // MARK: - User Behavior Analytics
    
    func trackScreenView(_ screenName: String) async {
        let parameters: [String: Any] = [
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("screen_view", parameters: parameters)
    }
    
    func trackButtonTap(_ buttonName: String, context: String? = nil) async {
        var parameters: [String: Any] = [
            "button_name": buttonName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let context = context {
            parameters["context"] = context
        }
        
        await logEvent("button_tap", parameters: parameters)
    }
    
    func trackClassBooking(
        classId: String,
        className: String,
        price: Double,
        paymentMethod: String,
        discoveryMethod: String
    ) async {
        let parameters: [String: Any] = [
            "class_id": classId,
            "class_name": className,
            "price": price,
            "payment_method": paymentMethod,
            "discovery_method": discoveryMethod,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("class_booked", parameters: parameters)
    }
    
    // MARK: - Performance Analytics
    
    func trackAPICall(
        endpoint: String,
        duration: TimeInterval,
        success: Bool,
        errorCode: String? = nil
    ) async {
        var parameters: [String: Any] = [
            "endpoint": endpoint,
            "duration": duration,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let errorCode = errorCode {
            parameters["error_code"] = errorCode
        }
        
        await logEvent("api_call", parameters: parameters)
    }
    
    func trackAppLaunch(
        isFirstLaunch: Bool,
        appVersion: String,
        osVersion: String
    ) async {
        let parameters: [String: Any] = [
            "is_first_launch": isFirstLaunch,
            "app_version": appVersion,
            "os_version": osVersion,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        await logEvent("app_launch", parameters: parameters)
    }
    
    // MARK: - Error Analytics
    
    func trackError(
        error: Error,
        context: String,
        additionalInfo: [String: Any] = [:]
    ) async {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        parameters.merge(additionalInfo) { _, new in new }
        
        await logEvent("error_occurred", parameters: parameters)
    }
    
    // MARK: - Private Implementation
    
    private func logEvent(_ eventName: String, parameters: [String: Any]) async {
        // In a real implementation, this would send to your analytics service
        // For now, we'll just log to console in debug builds
        #if DEBUG
        print("📊 Analytics Event: \(eventName)")
        print("📊 Parameters: \(parameters)")
        #endif
        
        // Here you would integrate with your analytics service:
        // - Firebase Analytics
        // - Mixpanel
        // - Amplitude
        // - Custom analytics backend
        
        // Example Firebase implementation:
        // Analytics.logEvent(eventName, parameters: parameters)
        
        // Example custom backend implementation:
        // try? await AnalyticsAPI.shared.logEvent(eventName, parameters: parameters)
    }
}

// MARK: - Analytics Models

struct SearchAnalyticsEvent {
    let query: String
    let scope: String
    let resultCount: Int
    let appliedFilters: [String]
    let executionTime: TimeInterval
    let timestamp: Date
    
    func toDictionary() -> [String: Any] {
        return [
            "query": query,
            "scope": scope,
            "result_count": resultCount,
            "applied_filters": appliedFilters,
            "execution_time": executionTime,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// MARK: - Analytics Extensions

extension AnalyticsService {
    
    // MARK: - Convenience Methods
    
    func trackSearchScreenViewed() async {
        await trackScreenView("search")
    }
    
    func trackSearchFiltersOpened() async {
        await trackButtonTap("search_filters", context: "search_screen")
    }
    
    func trackSearchCleared() async {
        await trackButtonTap("clear_search", context: "search_screen")
    }
    
    func trackQuickFilterUsed(_ filterName: String) async {
        await trackFilterUsage(
            filterType: "quick_filter",
            filterValue: filterName,
            query: ""
        )
    }
    
    func trackSavedSearchUsed(_ searchName: String) async {
        await trackButtonTap("saved_search", context: searchName)
    }
    
    func trackRecentSearchUsed(_ query: String) async {
        await trackButtonTap("recent_search", context: query)
    }
    
    // MARK: - Category Analytics
    
    func trackCategoryBrowsed(_ categoryName: String) async {
        await trackButtonTap("category_browse", context: categoryName)
    }
    
    func trackPopularSearchUsed(_ query: String) async {
        await trackButtonTap("popular_search", context: query)
    }
    
    // MARK: - Location Analytics
    
    func trackLocationPermissionRequested() async {
        await trackButtonTap("location_permission_request")
    }
    
    func trackLocationPermissionGranted() async {
        await trackButtonTap("location_permission_granted")
    }
    
    func trackLocationPermissionDenied() async {
        await trackButtonTap("location_permission_denied")
    }
    
    func trackNearbySearchUsed(distance: Double) async {
        await trackFilterUsage(
            filterType: "location",
            filterValue: "nearby_\(distance)km",
            query: ""
        )
    }
}