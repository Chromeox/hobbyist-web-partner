import Foundation
import SwiftUI
import Combine
import Supabase

class GamificationService: GamificationServiceProtocol {
    private let supabase = SupabaseManager.shared.client
    @Published var currentPoints: UserPoints?
    @Published var currentLevel: UserLevel?
    @Published var recentAchievements: [Achievement] = []
    
    // MARK: - Points & Levels
    
    func getUserPoints() async throws -> UserPoints {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("user_points")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .single()
            .execute()
        
        let points = try response.decoded(to: UserPoints.self)
        await MainActor.run {
            self.currentPoints = points
        }
        return points
    }
    
    func awardPoints(_ transaction: PointsTransaction) async throws -> UserPoints {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        // Record the transaction
        _ = try await supabase.database
            .from("points_transactions")
            .insert(transaction)
            .execute()
        
        // Update user points
        let response = try await supabase.database
            .rpc("award_points", params: [
                "p_user_id": transaction.userId,
                "p_points": transaction.points,
                "p_type": transaction.type.rawValue
            ])
            .execute()
        
        let updatedPoints = try response.decoded(to: UserPoints.self)
        
        // Check for level up
        await checkLevelUp(updatedPoints)
        
        // Show celebration if significant points
        if transaction.points >= 50 {
            await showPointsCelebration(transaction.points)
        }
        
        return updatedPoints
    }
    
    func getUserLevel() async throws -> UserLevel {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("user_levels")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .single()
            .execute()
        
        let level = try response.decoded(to: UserLevel.self)
        await MainActor.run {
            self.currentLevel = level
        }
        return level
    }
    
    func getLeaderboard(type: LeaderboardType) async throws -> [LeaderboardEntry] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("leaderboard_\(type.rawValue)")
            .select("*")
            .order("rank", ascending: true)
            .limit(100)
            .execute()
        
        let entries = try response.decoded(to: [LeaderboardEntry].self)
        return entries
    }
    
    // MARK: - Achievements & Badges
    
    func getUserAchievements() async throws -> [Achievement] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("user_achievements")
            .select("""
                *,
                achievements!inner(*)
            """)
            .eq("user_id", value: try await getCurrentUserId())
            .execute()
        
        let achievements = try response.decoded(to: [Achievement].self)
        return achievements
    }
    
    func unlockAchievement(id: String) async throws -> Achievement {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .rpc("unlock_achievement", params: [
                "p_user_id": try await getCurrentUserId(),
                "p_achievement_id": id
            ])
            .execute()
        
        let achievement = try response.decoded(to: Achievement.self)
        
        // Show achievement notification
        await showAchievementUnlocked(achievement)
        
        // Award points for achievement
        let pointsTransaction = PointsTransaction(
            userId: try await getCurrentUserId(),
            points: achievement.points,
            type: .achievementUnlocked,
            reason: "Unlocked \(achievement.name)",
            metadata: ["achievement_id": id]
        )
        _ = try await awardPoints(pointsTransaction)
        
        return achievement
    }
    
    func getAvailableAchievements() async throws -> [Achievement] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("achievements")
            .select("*")
            .eq("is_active", value: true)
            .order("category", ascending: true)
            .execute()
        
        let achievements = try response.decoded(to: [Achievement].self)
        return achievements
    }
    
    func getUserBadges() async throws -> [Badge] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("user_badges")
            .select("""
                *,
                badges!inner(*)
            """)
            .eq("user_id", value: try await getCurrentUserId())
            .order("earned_at", ascending: false)
            .execute()
        
        let badges = try response.decoded(to: [Badge].self)
        return badges
    }
    
    // MARK: - Streaks & Challenges
    
    func getUserStreaks() async throws -> UserStreaks {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("user_streaks")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .single()
            .execute()
        
        let streaks = try response.decoded(to: UserStreaks.self)
        return streaks
    }
    
    func updateStreak(type: StreakType) async throws -> UserStreaks {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .rpc("update_streak", params: [
                "p_user_id": try await getCurrentUserId(),
                "p_type": type.rawValue
            ])
            .execute()
        
        let updatedStreaks = try response.decoded(to: UserStreaks.self)
        
        // Award streak bonus points
        if type == .daily && updatedStreaks.currentDailyStreak > 0 {
            let streakPoints = GamificationEvent.streakMaintained(days: updatedStreaks.currentDailyStreak)
            _ = try await awardPoints(streakPoints)
        }
        
        return updatedStreaks
    }
    
    func getActiveChallenges() async throws -> [Challenge] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let now = Date()
        let response = try await supabase.database
            .from("challenges")
            .select("*")
            .lte("start_date", value: now.iso8601String)
            .gte("end_date", value: now.iso8601String)
            .execute()
        
        let challenges = try response.decoded(to: [Challenge].self)
        return challenges
    }
    
    func joinChallenge(id: String) async throws -> ChallengeParticipation {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let participation = [
            "challenge_id": id,
            "user_id": try await getCurrentUserId(),
            "joined_at": Date().iso8601String,
            "progress": 0,
            "is_completed": false
        ] as [String : Any]
        
        let response = try await supabase.database
            .from("challenge_participations")
            .insert(participation)
            .select()
            .single()
            .execute()
        
        let result = try response.decoded(to: ChallengeParticipation.self)
        return result
    }
    
    func getChallengeProgress(id: String) async throws -> ChallengeProgress {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("challenge_progress")
            .select("*")
            .eq("challenge_id", value: id)
            .eq("user_id", value: try await getCurrentUserId())
            .single()
            .execute()
        
        let progress = try response.decoded(to: ChallengeProgress.self)
        return progress
    }
    
    // MARK: - Rewards
    
    func getAvailableRewards() async throws -> [Reward] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("rewards")
            .select("*")
            .gt("availability->>remaining", value: 0)
            .execute()
        
        let rewards = try response.decoded(to: [Reward].self)
        return rewards
    }
    
    func redeemReward(id: String) async throws -> RewardRedemption {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        // Check user has enough points
        let userPoints = try await getUserPoints()
        let reward = try await getReward(id: id)
        
        guard userPoints.availablePoints >= reward.pointsCost else {
            throw GamificationError.insufficientPoints
        }
        
        // Process redemption
        let response = try await supabase.database
            .rpc("redeem_reward", params: [
                "p_user_id": try await getCurrentUserId(),
                "p_reward_id": id
            ])
            .execute()
        
        let redemption = try response.decoded(to: RewardRedemption.self)
        
        // Deduct points
        _ = try await supabase.database
            .rpc("deduct_points", params: [
                "p_user_id": try await getCurrentUserId(),
                "p_points": reward.pointsCost
            ])
            .execute()
        
        return redemption
    }
    
    func getRedemptionHistory() async throws -> [RewardRedemption] {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("reward_redemptions")
            .select("*")
            .eq("user_id", value: try await getCurrentUserId())
            .order("redeemed_at", ascending: false)
            .execute()
        
        let redemptions = try response.decoded(to: [RewardRedemption].self)
        return redemptions
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() async throws -> String {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let session = try await supabase.auth.session
        guard let userId = session?.user.id.uuidString else {
            throw GamificationError.userNotAuthenticated
        }
        
        return userId
    }
    
    private func getReward(id: String) async throws -> Reward {
        guard let supabase = supabase else { throw GamificationError.notInitialized }
        
        let response = try await supabase.database
            .from("rewards")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
        
        return try response.decoded(to: Reward.self)
    }
    
    private func checkLevelUp(_ points: UserPoints) async {
        let currentLevel = LevelSystem.levels.last { $0.minXP <= points.lifetimePoints } ?? LevelSystem.levels[0]
        let nextLevel = LevelSystem.levels.first { $0.minXP > points.lifetimePoints }
        
        if let previousLevel = self.currentLevel,
           currentLevel.number > previousLevel.currentLevel {
            await showLevelUpCelebration(currentLevel)
        }
    }
    
    @MainActor
    private func showPointsCelebration(_ points: Int) {
        // Show points animation
        NotificationBanner.show(InAppNotification(
            title: "+\(points) Points! 🎉",
            message: "Keep going!",
            type: .success,
            action: nil,
            imageURL: nil
        ))
    }
    
    @MainActor
    private func showAchievementUnlocked(_ achievement: Achievement) {
        NotificationBanner.show(InAppNotification(
            title: "Achievement Unlocked! 🏆",
            message: achievement.name,
            type: .success,
            action: InAppNotification.NotificationAction(
                title: "View",
                handler: {
                    // Navigate to achievements
                }
            ),
            imageURL: nil
        ))
    }
    
    @MainActor
    private func showLevelUpCelebration(_ level: LevelSystem.Level) {
        NotificationBanner.show(InAppNotification(
            title: "Level Up! \(level.icon)",
            message: "You're now a \(level.name)!",
            type: .success,
            action: nil,
            imageURL: nil
        ))
    }
}

// MARK: - Error Types

enum GamificationError: LocalizedError {
    case notInitialized
    case userNotAuthenticated
    case insufficientPoints
    case rewardUnavailable
    case challengeEnded
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Gamification service not initialized"
        case .userNotAuthenticated:
            return "User must be authenticated"
        case .insufficientPoints:
            return "Not enough points to redeem this reward"
        case .rewardUnavailable:
            return "This reward is no longer available"
        case .challengeEnded:
            return "This challenge has ended"
        }
    }
}