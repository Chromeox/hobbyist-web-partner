import Foundation
import Combine


@MainActor
class ActivityFeedViewModel: ObservableObject {
    @Published var activities: [ActivityFeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let activityService = ActivityService()
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadActivities(filter: String) { // ActivityFeedView.ActivityFilter) {
        isLoading = true
        errorMessage = nil

        Task {
            guard let userId = await authManager.getCurrentUserId() else {
                self.isLoading = false
                return
            }

            do {
                let fetchedActivities = try await activityService.fetchActivities(
                    for: userId,
                    filter: filter.lowercased() // filter.rawValue.lowercased()
                )

                self.activities = fetchedActivities
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func refreshActivities(filter: String) async { // ActivityFeedView.ActivityFilter) async {
        guard let userId = await authManager.getCurrentUserId() else { return }

        do {
            let fetchedActivities = try await activityService.fetchActivities(
                for: userId,
                filter: filter.lowercased() // filter.rawValue.lowercased()
            )

            self.activities = fetchedActivities
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func markActivityAsRead(_ activity: ActivityFeedItem) {
        Task {
            do {
                try await activityService.markAsRead(activityId: activity.id)
            } catch {
                // Error handling - could add logging here
                print("Error marking activity as read: \(error)")
            }
        }
    }
}

// MARK: - Activity Service
class ActivityService {
    private let supabaseService = SimpleSupabaseService.shared

    func fetchActivities(for userId: UUID, filter: String) async throws -> [ActivityFeedItem] {
        // In a real app, this would query the Supabase database
        // For now, return mock data
        return ActivityFeedItem.mockData()
    }

    func markAsRead(activityId: UUID) async throws {
        // Mark activity as read in database
    }
}

// MARK: - Mock Data Extension
extension ActivityFeedItem {
    static func mockData() -> [ActivityFeedItem] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            ActivityFeedItem(
                id: UUID(),
                actorId: UUID(),
                actorName: "Sarah Chen",
                actorImageUrl: nil,
                actionType: .booked,
                targetType: "class",
                targetId: UUID(),
                targetName: "Morning Yoga Flow",
                metadata: nil,
                createdAt: calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            ),
            ActivityFeedItem(
                id: UUID(),
                actorId: UUID(),
                actorName: "Mike Johnson",
                actorImageUrl: nil,
                actionType: .reviewed,
                targetType: "instructor",
                targetId: UUID(),
                targetName: "Emma Watson",
                metadata: ["rating": "5"],
                createdAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now
            ),
            ActivityFeedItem(
                id: UUID(),
                actorId: UUID(),
                actorName: "Lisa Park",
                actorImageUrl: nil,
                actionType: .followed,
                targetType: "venue",
                targetId: UUID(),
                targetName: "Downtown Fitness Studio",
                metadata: nil,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            ActivityFeedItem(
                id: UUID(),
                actorId: UUID(),
                actorName: "James Wilson",
                actorImageUrl: nil,
                actionType: .achieved,
                targetType: "achievement",
                targetId: UUID(),
                targetName: "10 Classes Milestone",
                metadata: ["badge": "bronze"],
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            ),
            ActivityFeedItem(
                id: UUID(),
                actorId: UUID(),
                actorName: "Emily Davis",
                actorImageUrl: nil,
                actionType: .joined,
                targetType: nil,
                targetId: nil,
                targetName: nil,
                metadata: nil,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now
            )
        ]
    }
}