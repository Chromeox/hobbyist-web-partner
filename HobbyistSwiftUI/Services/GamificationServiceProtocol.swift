import Foundation
import SwiftUI

protocol GamificationServiceProtocol {
    // Points & Levels
    func getUserPoints() async throws -> UserPoints
    func awardPoints(_ points: PointsTransaction) async throws -> UserPoints
    func getUserLevel() async throws -> UserLevel
    func getLeaderboard(type: LeaderboardType) async throws -> [LeaderboardEntry]
    
    // Achievements & Badges
    func getUserAchievements() async throws -> [Achievement]
    func unlockAchievement(id: String) async throws -> Achievement
    func getAvailableAchievements() async throws -> [Achievement]
    func getUserBadges() async throws -> [Badge]
    
    // Streaks & Challenges
    func getUserStreaks() async throws -> UserStreaks
    func updateStreak(type: StreakType) async throws -> UserStreaks
    func getActiveChallenges() async throws -> [Challenge]
    func joinChallenge(id: String) async throws -> ChallengeParticipation
    func getChallengeProgress(id: String) async throws -> ChallengeProgress
    
    // Rewards
    func getAvailableRewards() async throws -> [Reward]
    func redeemReward(id: String) async throws -> RewardRedemption
    func getRedemptionHistory() async throws -> [RewardRedemption]
}

// MARK: - Gamification Models

struct UserPoints: Codable {
    let userId: String
    let totalPoints: Int
    let availablePoints: Int
    let lifetimePoints: Int
    let currentLevelPoints: Int
    let nextLevelPoints: Int
    let weeklyPoints: Int
    let monthlyPoints: Int
    
    var progressToNextLevel: Double {
        guard nextLevelPoints > 0 else { return 0 }
        return Double(currentLevelPoints) / Double(nextLevelPoints)
    }
}

struct PointsTransaction: Codable {
    let userId: String
    let points: Int
    let type: PointsType
    let reason: String
    let metadata: [String: Any]?
    
    enum PointsType: String, Codable {
        case classAttended = "class_attended"
        case classBooked = "class_booked"
        case reviewWritten = "review_written"
        case referralMade = "referral_made"
        case achievementUnlocked = "achievement_unlocked"
        case challengeCompleted = "challenge_completed"
        case streakMaintained = "streak_maintained"
        case bonusAwarded = "bonus_awarded"
    }
}

struct UserLevel: Codable {
    let userId: String
    let currentLevel: Int
    let levelName: String
    let levelIcon: String
    let totalXP: Int
    let currentLevelXP: Int
    let nextLevelXP: Int
    let perks: [LevelPerk]
    let nextLevelRewards: [String]
    
    var progressPercentage: Int {
        guard nextLevelXP > 0 else { return 100 }
        return Int((Double(currentLevelXP) / Double(nextLevelXP)) * 100)
    }
    
    struct LevelPerk: Codable {
        let id: String
        let name: String
        let description: String
        let icon: String
    }
}

// Level System
struct LevelSystem {
    static let levels: [Level] = [
        Level(number: 1, name: "Beginner", minXP: 0, icon: "🌱", color: .green),
        Level(number: 2, name: "Explorer", minXP: 100, icon: "🧭", color: .blue),
        Level(number: 3, name: "Enthusiast", minXP: 300, icon: "⭐", color: .yellow),
        Level(number: 4, name: "Adventurer", minXP: 600, icon: "🏃", color: .orange),
        Level(number: 5, name: "Expert", minXP: 1000, icon: "💪", color: .red),
        Level(number: 6, name: "Master", minXP: 1500, icon: "🏆", color: .purple),
        Level(number: 7, name: "Champion", minXP: 2500, icon: "👑", color: .indigo),
        Level(number: 8, name: "Legend", minXP: 4000, icon: "🌟", color: .pink)
    ]
    
    struct Level {
        let number: Int
        let name: String
        let minXP: Int
        let icon: String
        let color: Color
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let points: Int
    let requirement: AchievementRequirement
    let unlockedAt: Date?
    let progress: Double
    let isSecret: Bool
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    enum AchievementCategory: String, Codable {
        case fitness = "fitness"
        case social = "social"
        case exploration = "exploration"
        case dedication = "dedication"
        case special = "special"
    }
    
    struct AchievementRequirement: Codable {
        let type: String
        let target: Int
        let current: Int
    }
}

struct Badge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let rarity: BadgeRarity
    let earnedAt: Date
    let displayOrder: Int
    
    enum BadgeRarity: String, Codable {
        case common = "common"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .yellow
            }
        }
    }
}

struct UserStreaks: Codable {
    let userId: String
    let currentDailyStreak: Int
    let longestDailyStreak: Int
    let currentWeeklyStreak: Int
    let longestWeeklyStreak: Int
    let lastActivityDate: Date
    let streakFreezes: Int
    
    var isStreakActive: Bool {
        let calendar = Calendar.current
        let daysSinceLastActivity = calendar.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        return daysSinceLastActivity <= 1
    }
}

enum StreakType: String {
    case daily = "daily"
    case weekly = "weekly"
}

struct Challenge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let type: ChallengeType
    let startDate: Date
    let endDate: Date
    let goal: Int
    let reward: ChallengeReward
    let participants: Int
    let imageURL: String?
    let rules: [String]
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    enum ChallengeType: String, Codable {
        case individual = "individual"
        case team = "team"
        case community = "community"
    }
    
    struct ChallengeReward: Codable {
        let points: Int
        let badge: String?
        let credits: Int?
        let title: String?
    }
}

struct ChallengeParticipation: Codable {
    let challengeId: String
    let userId: String
    let joinedAt: Date
    let progress: Int
    let goal: Int
    let rank: Int?
    let isCompleted: Bool
    let completedAt: Date?
    
    var progressPercentage: Double {
        guard goal > 0 else { return 0 }
        return min(Double(progress) / Double(goal), 1.0)
    }
}

struct ChallengeProgress: Codable {
    let challengeId: String
    let userId: String
    let currentProgress: Int
    let goal: Int
    let rank: Int
    let totalParticipants: Int
    let milestones: [Milestone]
    let recentActivities: [Activity]
    
    struct Milestone: Codable {
        let name: String
        let progress: Int
        let achieved: Bool
        let achievedAt: Date?
    }
    
    struct Activity: Codable {
        let description: String
        let points: Int
        let timestamp: Date
    }
}

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let rank: Int
    let userId: String
    let userName: String
    let userAvatar: String?
    let score: Int
    let change: Int // Position change from previous period
    let level: Int
    let badges: [String]
    
    var changeIndicator: String {
        if change > 0 {
            return "↑ \(change)"
        } else if change < 0 {
            return "↓ \(abs(change))"
        } else {
            return "―"
        }
    }
    
    var changeColor: Color {
        if change > 0 {
            return .green
        } else if change < 0 {
            return .red
        } else {
            return .gray
        }
    }
}

enum LeaderboardType: String {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
    case friends = "friends"
    case local = "local"
}

struct Reward: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let pointsCost: Int
    let category: RewardCategory
    let imageURL: String?
    let availability: RewardAvailability
    let terms: String
    let expiresAt: Date?
    
    enum RewardCategory: String, Codable {
        case credits = "credits"
        case discounts = "discounts"
        case merchandise = "merchandise"
        case experiences = "experiences"
        case digital = "digital"
    }
    
    struct RewardAvailability: Codable {
        let total: Int
        let remaining: Int
        let userLimit: Int
        let userRedeemed: Int
        
        var isAvailable: Bool {
            remaining > 0 && userRedeemed < userLimit
        }
    }
}

struct RewardRedemption: Identifiable, Codable {
    let id: String
    let rewardId: String
    let rewardName: String
    let userId: String
    let pointsSpent: Int
    let redeemedAt: Date
    let status: RedemptionStatus
    let code: String?
    let expiresAt: Date?
    
    enum RedemptionStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case delivered = "delivered"
        case used = "used"
        case expired = "expired"
    }
}

// MARK: - Gamification Events

struct GamificationEvent {
    static func classCompleted(classId: String) -> PointsTransaction {
        PointsTransaction(
            userId: "",
            points: 50,
            type: .classAttended,
            reason: "Completed a class",
            metadata: ["class_id": classId]
        )
    }
    
    static func reviewWritten(classId: String, rating: Int) -> PointsTransaction {
        let bonusPoints = rating >= 4 ? 10 : 0
        return PointsTransaction(
            userId: "",
            points: 20 + bonusPoints,
            type: .reviewWritten,
            reason: "Wrote a review",
            metadata: ["class_id": classId, "rating": rating]
        )
    }
    
    static func streakMaintained(days: Int) -> PointsTransaction {
        let streakBonus = min(days * 5, 100)
        return PointsTransaction(
            userId: "",
            points: streakBonus,
            type: .streakMaintained,
            reason: "\(days) day streak!",
            metadata: ["streak_days": days]
        )
    }
    
    static func referralMade() -> PointsTransaction {
        PointsTransaction(
            userId: "",
            points: 100,
            type: .referralMade,
            reason: "Referred a friend",
            metadata: nil
        )
    }
}