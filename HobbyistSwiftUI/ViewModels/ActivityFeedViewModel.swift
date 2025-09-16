import Foundation
import Combine

// MARK: - ServiceContainer placeholder
struct ServiceContainer {
    static let shared = ServiceContainer()
    let crashReportingService = CrashReportingService()
}

struct CrashReportingService {
    func recordError(_ error: Error, context: [String: String]) {
        print("Error recorded: \(error) with context: \(context)")
    }
}

class ActivityFeedViewModel: ObservableObject {
    @Published var activities: [ActivityFeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let activityService = ActivityService()
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadActivities(filter: ActivityFeedView.ActivityFilter) {
        guard let userId = authManager.currentUser?.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedActivities = try await activityService.fetchActivities(
                    for: userId,
                    filter: filter.rawValue.lowercased()
                )
                
                await MainActor.run {
                    self.activities = fetchedActivities
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshActivities(filter: ActivityFeedView.ActivityFilter) async {
        guard let userId = authManager.currentUser?.id else { return }
        
        do {
            let fetchedActivities = try await activityService.fetchActivities(
                for: userId,
                filter: filter.rawValue.lowercased()
            )
            
            await MainActor.run {
                self.activities = fetchedActivities
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func markActivityAsRead(_ activity: ActivityFeedItem) {
        Task {
            do {
                try await activityService.markAsRead(activityId: activity.id)
            } catch {
                ServiceContainer.shared.crashReportingService.recordError(error, context: ["activityId": activity.id.uuidString])
            }
        }
    }
}

// MARK: - Activity Service
class ActivityService {
    private let supabaseService = SupabaseService.shared
    
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
                createdAt: calendar.date(byAdding: .hour, value: -1, to: now)!
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
                createdAt: calendar.date(byAdding: .hour, value: -3, to: now)!
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
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!
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
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!
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
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!
            )
        ]
    }
}