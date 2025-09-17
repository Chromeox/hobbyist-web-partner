import Foundation
import Combine
import Supabase
import Realtime

class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    private let supabaseClient = SupabaseManager.shared.client
    private var channels: [String: RealtimeChannel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // Published events
    @Published var latestBooking: Booking?
    @Published var latestReview: Review?
    @Published var latestActivity: ActivityFeedItem?
    @Published var classUpdate: ClassItem?
    @Published var followUpdate: Following?
    
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Setup Subscriptions
    
    private func setupSubscriptions() {
        // Subscribe to auth changes to manage subscriptions
        AuthenticationManager.shared.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    self?.startSubscriptions()
                } else {
                    self?.stopSubscriptions()
                }
            }
            .store(in: &cancellables)
    }
    
    func startSubscriptions() {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        // Subscribe to different channels
        subscribeToBookings(userId: userId)
        subscribeToReviews()
        subscribeToActivities(userId: userId)
        subscribeToClasses()
        subscribeToFollowing(userId: userId)
    }
    
    func stopSubscriptions() {
        // Remove all channels
        for (_, channel) in channels {
            Task {
                await channel.unsubscribe()
            }
        }
        channels.removeAll()
    }
    
    // MARK: - Booking Subscriptions
    
    private func subscribeToBookings(userId: UUID) {
        let channel = supabaseClient.channel("bookings:\(userId)")
        
        channel
            .onPostgresChange(
                event: .all,
                schema: "public",
                table: "bookings",
                filter: "user_id=eq.\(userId.uuidString)"
            ) { [weak self] payload in
                self?.handleBookingChange(payload)
            }
            .subscribe()
        
        channels["bookings"] = channel
    }
    
    private func handleBookingChange(_ payload: PostgresChangePayload) {
        Task { @MainActor in
            switch payload.eventType {
            case .insert:
                if let booking = try? JSONDecoder().decode(Booking.self, from: payload.newRecord) {
                    self.latestBooking = booking
                    NotificationCenter.default.post(name: .newBookingCreated, object: booking)
                }
            case .update:
                if let booking = try? JSONDecoder().decode(Booking.self, from: payload.newRecord) {
                    self.latestBooking = booking
                    NotificationCenter.default.post(name: .bookingUpdated, object: booking)
                }
            case .delete:
                if let bookingData = payload.oldRecord,
                   let booking = try? JSONDecoder().decode(Booking.self, from: bookingData) {
                    NotificationCenter.default.post(name: .bookingCancelled, object: booking)
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Review Subscriptions
    
    private func subscribeToReviews() {
        let channel = supabaseClient.channel("reviews")
        
        channel
            .onPostgresChange(
                event: .insert,
                schema: "public",
                table: "reviews"
            ) { [weak self] payload in
                self?.handleReviewInsert(payload)
            }
            .subscribe()
        
        channels["reviews"] = channel
    }
    
    private func handleReviewInsert(_ payload: PostgresChangePayload) {
        Task { @MainActor in
            if let review = try? JSONDecoder().decode(Review.self, from: payload.newRecord) {
                self.latestReview = review
                NotificationCenter.default.post(name: .newReviewPosted, object: review)
            }
        }
    }
    
    // MARK: - Activity Feed Subscriptions
    
    private func subscribeToActivities(userId: UUID) {
        let channel = supabaseClient.channel("activities:\(userId)")
        
        // Subscribe to activities from people the user follows
        channel
            .onPostgresChange(
                event: .insert,
                schema: "public",
                table: "activity_feed"
            ) { [weak self] payload in
                self?.handleActivityInsert(payload, userId: userId)
            }
            .subscribe()
        
        channels["activities"] = channel
    }
    
    private func handleActivityInsert(_ payload: PostgresChangePayload, userId: UUID) {
        Task { @MainActor in
            if let activity = try? JSONDecoder().decode(ActivityFeedItem.self, from: payload.newRecord) {
                // Check if this activity is relevant to the user
                let isRelevant = await self.isActivityRelevant(activity, for: userId)
                if isRelevant {
                    self.latestActivity = activity
                    NotificationCenter.default.post(name: .newActivity, object: activity)
                }
            }
        }
    }
    
    private func isActivityRelevant(_ activity: ActivityFeedItem, for userId: UUID) async -> Bool {
        // Check if the user follows the actor
        do {
            return try await FollowingService.shared.isFollowing(
                userId: userId,
                targetId: activity.actorId,
                targetType: .user
            )
        } catch {
            return false
        }
    }
    
    // MARK: - Class Subscriptions
    
    private func subscribeToClasses() {
        let channel = supabaseClient.channel("classes")
        
        channel
            .onPostgresChange(
                event: .update,
                schema: "public",
                table: "classes"
            ) { [weak self] payload in
                self?.handleClassUpdate(payload)
            }
            .subscribe()
        
        channels["classes"] = channel
    }
    
    private func handleClassUpdate(_ payload: PostgresChangePayload) {
        Task { @MainActor in
            if let classItem = try? JSONDecoder().decode(ClassItem.self, from: payload.newRecord) {
                self.classUpdate = classItem
                NotificationCenter.default.post(name: .classUpdated, object: classItem)
            }
        }
    }
    
    // MARK: - Following Subscriptions
    
    private func subscribeToFollowing(userId: UUID) {
        let channel = supabaseClient.channel("following:\(userId)")
        
        // Subscribe to new followers
        channel
            .onPostgresChange(
                event: .insert,
                schema: "public",
                table: "following",
                filter: "following_id=eq.\(userId.uuidString)"
            ) { [weak self] payload in
                self?.handleNewFollower(payload)
            }
            .subscribe()
        
        channels["following"] = channel
    }
    
    private func handleNewFollower(_ payload: PostgresChangePayload) {
        Task { @MainActor in
            if let following = try? JSONDecoder().decode(Following.self, from: payload.newRecord) {
                self.followUpdate = following
                NotificationCenter.default.post(name: .newFollower, object: following)
            }
        }
    }
    
    // MARK: - Presence (Online Status)
    
    func trackPresence(userId: UUID) {
        let channel = supabaseClient.channel("presence")
        
        Task {
            try await channel
                .track(["user_id": userId.uuidString, "online_at": Date().timeIntervalSince1970])
            
            channel
                .onPresenceChange { [weak self] presenceState in
                    self?.handlePresenceChange(presenceState)
                }
                .subscribe()
            
            channels["presence"] = channel
        }
    }
    
    private func handlePresenceChange(_ state: PresenceState) {
        // Handle online/offline status of users
        let onlineUsers = state.joins.compactMap { presence in
            presence.payload["user_id"] as? String
        }
        
        NotificationCenter.default.post(
            name: .presenceUpdated,
            object: onlineUsers
        )
    }
    
    // MARK: - Broadcast (Live Class Updates)
    
    func joinClassLiveUpdates(classId: UUID) {
        let channel = supabaseClient.channel("class:\(classId)")
        
        channel
            .onBroadcast(event: "participant_joined") { [weak self] message in
                self?.handleParticipantJoined(message, classId: classId)
            }
            .onBroadcast(event: "class_started") { [weak self] message in
                self?.handleClassStarted(message, classId: classId)
            }
            .subscribe()
        
        channels["class:\(classId)"] = channel
    }
    
    private func handleParticipantJoined(_ message: BroadcastMessage, classId: UUID) {
        NotificationCenter.default.post(
            name: .participantJoined,
            object: ["classId": classId, "payload": message.payload]
        )
    }
    
    private func handleClassStarted(_ message: BroadcastMessage, classId: UUID) {
        NotificationCenter.default.post(
            name: .classStarted,
            object: ["classId": classId, "payload": message.payload]
        )
    }
    
    // MARK: - Send Broadcast Messages
    
    func broadcastJoinedClass(classId: UUID, userId: UUID, userName: String) async {
        guard let channel = channels["class:\(classId)"] else { return }
        
        try? await channel.broadcast(
            event: "participant_joined",
            payload: [
                "user_id": userId.uuidString,
                "user_name": userName,
                "joined_at": Date().timeIntervalSince1970
            ]
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let newBookingCreated = Notification.Name("newBookingCreated")
    static let bookingUpdated = Notification.Name("bookingUpdated")
    static let bookingCancelled = Notification.Name("bookingCancelled")
    static let newReviewPosted = Notification.Name("newReviewPosted")
    static let newActivity = Notification.Name("newActivity")
    static let classUpdated = Notification.Name("classUpdated")
    static let newFollower = Notification.Name("newFollower")
    static let presenceUpdated = Notification.Name("presenceUpdated")
    static let participantJoined = Notification.Name("participantJoined")
    static let classStarted = Notification.Name("classStarted")
}

// MARK: - Helper Types for Realtime
struct PresenceState {
    let joins: [PresenceAction]
    let leaves: [PresenceAction]
}

struct PresenceAction {
    let payload: [String: Any]
}

struct BroadcastMessage {
    let event: String
    let payload: [String: Any]
}

struct PostgresChangePayload {
    let eventType: ChangeEventType
    let newRecord: Data
    let oldRecord: Data?
    let columns: [String]?
    let commitTimestamp: String?
}

enum ChangeEventType {
    case insert
    case update
    case delete
    case all
}