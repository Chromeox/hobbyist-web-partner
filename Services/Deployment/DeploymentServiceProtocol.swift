import Foundation
import Combine

// MARK: - Deployment Models
public struct AppStoreSubmission {
    public let buildNumber: String
    public let versionString: String
    public let releaseNotes: String
    public let screenshots: [Screenshot]
    public let metadata: AppMetadata
    public let stagingStrategy: StagingStrategy
    
    public init(
        buildNumber: String,
        versionString: String,
        releaseNotes: String,
        screenshots: [Screenshot],
        metadata: AppMetadata,
        stagingStrategy: StagingStrategy
    ) {
        self.buildNumber = buildNumber
        self.versionString = versionString
        self.releaseNotes = releaseNotes
        self.screenshots = screenshots
        self.metadata = metadata
        self.stagingStrategy = stagingStrategy
    }
}

public struct Screenshot {
    public let deviceType: DeviceType
    public let imagePath: String
    public let order: Int
    public let locale: String
    
    public init(deviceType: DeviceType, imagePath: String, order: Int, locale: String) {
        self.deviceType = deviceType
        self.imagePath = imagePath
        self.order = order
        self.locale = locale
    }
}

public enum DeviceType: String, CaseIterable {
    case iPhone6_7 = "iPhone 6.7"
    case iPhone6_5 = "iPhone 6.5"
    case iPhone5_5 = "iPhone 5.5"
    case iPadPro12_9 = "iPad Pro 12.9"
    case iPadPro11 = "iPad Pro 11"
    case appleWatch = "Apple Watch"
}

public struct AppMetadata {
    public let title: String
    public let subtitle: String?
    public let description: String
    public let keywords: [String]
    public let supportURL: String
    public let marketingURL: String?
    public let privacyPolicyURL: String
    public let category: AppCategory
    public let contentRating: ContentRating
    
    public init(
        title: String,
        subtitle: String? = nil,
        description: String,
        keywords: [String],
        supportURL: String,
        marketingURL: String? = nil,
        privacyPolicyURL: String,
        category: AppCategory,
        contentRating: ContentRating
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.keywords = keywords
        self.supportURL = supportURL
        self.marketingURL = marketingURL
        self.privacyPolicyURL = privacyPolicyURL
        self.category = category
        self.contentRating = contentRating
    }
}

public enum AppCategory: String, CaseIterable {
    case health = "Health & Fitness"
    case lifestyle = "Lifestyle"
    case sports = "Sports"
    case utilities = "Utilities"
}

public enum ContentRating: String, CaseIterable {
    case fourPlus = "4+"
    case ninePlus = "9+"
    case twelvePlus = "12+"
    case seventeenPlus = "17+"
}

public struct StagingStrategy {
    public let type: StagingType
    public let percentages: [Int]
    public let durationBetweenStages: TimeInterval
    public let rollbackThreshold: Double
    
    public init(
        type: StagingType,
        percentages: [Int],
        durationBetweenStages: TimeInterval,
        rollbackThreshold: Double
    ) {
        self.type = type
        self.percentages = percentages
        self.durationBetweenStages = durationBetweenStages
        self.rollbackThreshold = rollbackThreshold
    }
}

public enum StagingType: String, CaseIterable {
    case immediate = "immediate"
    case staged = "staged"
    case beta = "beta"
    case phased = "phased"
}

public struct ReleaseStatus {
    public let buildNumber: String
    public let status: ReleaseState
    public let currentStagePercentage: Int
    public let crashRate: Double
    public let userRating: Double
    public let downloadCount: Int
    public let lastUpdated: Date
    
    public init(
        buildNumber: String,
        status: ReleaseState,
        currentStagePercentage: Int,
        crashRate: Double,
        userRating: Double,
        downloadCount: Int,
        lastUpdated: Date
    ) {
        self.buildNumber = buildNumber
        self.status = status
        self.currentStagePercentage = currentStagePercentage
        self.crashRate = crashRate
        self.userRating = userRating
        self.downloadCount = downloadCount
        self.lastUpdated = lastUpdated
    }
}

public enum ReleaseState: String, CaseIterable {
    case preparing = "preparing"
    case inReview = "in_review"
    case rejected = "rejected"
    case readyForSale = "ready_for_sale"
    case processingForAppStore = "processing_for_app_store"
    case pendingDeveloperRelease = "pending_developer_release"
    case stagingInProgress = "staging_in_progress"
    case released = "released"
    case rollbackInProgress = "rollback_in_progress"
}

public struct ComplianceResult {
    public let isCompliant: Bool
    public let violations: [ComplianceViolation]
    public let warnings: [String]
    public let checkedAt: Date
    
    public init(isCompliant: Bool, violations: [ComplianceViolation], warnings: [String], checkedAt: Date) {
        self.isCompliant = isCompliant
        self.violations = violations
        self.warnings = warnings
        self.checkedAt = checkedAt
    }
}

public struct ComplianceViolation {
    public let category: ComplianceCategory
    public let severity: ViolationSeverity
    public let message: String
    public let recommendation: String
    
    public init(category: ComplianceCategory, severity: ViolationSeverity, message: String, recommendation: String) {
        self.category = category
        self.severity = severity
        self.message = message
        self.recommendation = recommendation
    }
}

public enum ComplianceCategory: String, CaseIterable {
    case appStoreGuidelines = "app_store_guidelines"
    case accessibility = "accessibility"
    case privacy = "privacy"
    case performance = "performance"
    case security = "security"
}

public enum ViolationSeverity: String, CaseIterable {
    case critical = "critical"
    case warning = "warning"
    case info = "info"
}

// MARK: - Deployment Service Protocol
public protocol DeploymentServiceProtocol {
    
    // MARK: - App Store Submission
    func submitToAppStore(_ submission: AppStoreSubmission) -> AnyPublisher<String, Error>
    func updateMetadata(_ metadata: AppMetadata) -> AnyPublisher<Void, Error>
    func uploadScreenshots(_ screenshots: [Screenshot]) -> AnyPublisher<Void, Error>
    
    // MARK: - Release Management
    func getReleaseStatus(for buildNumber: String) -> AnyPublisher<ReleaseStatus, Error>
    func startPhasedRelease(buildNumber: String, strategy: StagingStrategy) -> AnyPublisher<Void, Error>
    func pausePhasedRelease(buildNumber: String) -> AnyPublisher<Void, Error>
    func resumePhasedRelease(buildNumber: String) -> AnyPublisher<Void, Error>
    func rollbackRelease(buildNumber: String, reason: String) -> AnyPublisher<Void, Error>
    
    // MARK: - Compliance Validation
    func validateCompliance() -> AnyPublisher<ComplianceResult, Error>
    func validateAccessibility() -> AnyPublisher<ComplianceResult, Error>
    func validatePrivacyCompliance() -> AnyPublisher<ComplianceResult, Error>
    
    // MARK: - Analytics and Monitoring
    func getAppStoreMetrics(for dateRange: DateInterval) -> AnyPublisher<AppStoreMetrics, Error>
    func getReviewAnalytics() -> AnyPublisher<ReviewAnalytics, Error>
    func getCrashReports(for buildNumber: String) -> AnyPublisher<[CrashReport], Error>
    
    // MARK: - Feature Flag Management
    func getFeatureFlags() -> AnyPublisher<[FeatureFlag], Error>
    func updateFeatureFlag(_ flag: FeatureFlag) -> AnyPublisher<Void, Error>
    func emergencyDisableFeature(flagName: String) -> AnyPublisher<Void, Error>
    
    // MARK: - Build Management
    func promoteBuildToProduction(buildNumber: String) -> AnyPublisher<Void, Error>
    func createHotfixBuild(baseVersion: String, fixes: [String]) -> AnyPublisher<String, Error>
    func validateBuild(buildNumber: String) -> AnyPublisher<BuildValidationResult, Error>
}

// MARK: - Supporting Models
public struct AppStoreMetrics {
    public let impressions: Int
    public let pageViews: Int
    public let downloads: Int
    public let conversionRate: Double
    public let averageRating: Double
    public let totalRatings: Int
    public let crashRate: Double
    public let retentionRate: Double
    
    public init(
        impressions: Int,
        pageViews: Int,
        downloads: Int,
        conversionRate: Double,
        averageRating: Double,
        totalRatings: Int,
        crashRate: Double,
        retentionRate: Double
    ) {
        self.impressions = impressions
        self.pageViews = pageViews
        self.downloads = downloads
        self.conversionRate = conversionRate
        self.averageRating = averageRating
        self.totalRatings = totalRatings
        self.crashRate = crashRate
        self.retentionRate = retentionRate
    }
}

public struct ReviewAnalytics {
    public let averageRating: Double
    public let totalReviews: Int
    public let sentimentScore: Double
    public let keyTopics: [String]
    public let responseRate: Double
    
    public init(averageRating: Double, totalReviews: Int, sentimentScore: Double, keyTopics: [String], responseRate: Double) {
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.sentimentScore = sentimentScore
        self.keyTopics = keyTopics
        self.responseRate = responseRate
    }
}

public struct CrashReport {
    public let crashID: String
    public let buildNumber: String
    public let deviceModel: String
    public let osVersion: String
    public let stackTrace: String
    public let occurrenceCount: Int
    public let affectedUsers: Int
    public let firstOccurrence: Date
    public let lastOccurrence: Date
    
    public init(
        crashID: String,
        buildNumber: String,
        deviceModel: String,
        osVersion: String,
        stackTrace: String,
        occurrenceCount: Int,
        affectedUsers: Int,
        firstOccurrence: Date,
        lastOccurrence: Date
    ) {
        self.crashID = crashID
        self.buildNumber = buildNumber
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.stackTrace = stackTrace
        self.occurrenceCount = occurrenceCount
        self.affectedUsers = affectedUsers
        self.firstOccurrence = firstOccurrence
        self.lastOccurrence = lastOccurrence
    }
}

public struct FeatureFlag {
    public let name: String
    public let isEnabled: Bool
    public let rolloutPercentage: Int
    public let targetAudience: [String]
    public let description: String
    public let lastModified: Date
    
    public init(name: String, isEnabled: Bool, rolloutPercentage: Int, targetAudience: [String], description: String, lastModified: Date) {
        self.name = name
        self.isEnabled = isEnabled
        self.rolloutPercentage = rolloutPercentage
        self.targetAudience = targetAudience
        self.description = description
        self.lastModified = lastModified
    }
}

public struct BuildValidationResult {
    public let isValid: Bool
    public let buildNumber: String
    public let testResults: [TestResult]
    public let performanceMetrics: PerformanceMetrics
    public let securityScan: SecurityScanResult
    
    public init(
        isValid: Bool,
        buildNumber: String,
        testResults: [TestResult],
        performanceMetrics: PerformanceMetrics,
        securityScan: SecurityScanResult
    ) {
        self.isValid = isValid
        self.buildNumber = buildNumber
        self.testResults = testResults
        self.performanceMetrics = performanceMetrics
        self.securityScan = securityScan
    }
}

public struct TestResult {
    public let testSuite: String
    public let passed: Int
    public let failed: Int
    public let skipped: Int
    public let duration: TimeInterval
    
    public init(testSuite: String, passed: Int, failed: Int, skipped: Int, duration: TimeInterval) {
        self.testSuite = testSuite
        self.passed = passed
        self.failed = failed
        self.skipped = skipped
        self.duration = duration
    }
}

public struct PerformanceMetrics {
    public let launchTime: TimeInterval
    public let memoryUsage: Int
    public let cpuUsage: Double
    public let batteryImpact: BatteryImpact
    
    public init(launchTime: TimeInterval, memoryUsage: Int, cpuUsage: Double, batteryImpact: BatteryImpact) {
        self.launchTime = launchTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.batteryImpact = batteryImpact
    }
}

public enum BatteryImpact: String, CaseIterable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

public struct SecurityScanResult {
    public let vulnerabilities: [SecurityVulnerability]
    public let overallScore: Double
    public let recommendations: [String]
    
    public init(vulnerabilities: [SecurityVulnerability], overallScore: Double, recommendations: [String]) {
        self.vulnerabilities = vulnerabilities
        self.overallScore = overallScore
        self.recommendations = recommendations
    }
}

public struct SecurityVulnerability {
    public let id: String
    public let severity: SecuritySeverity
    public let description: String
    public let recommendation: String
    
    public init(id: String, severity: SecuritySeverity, description: String, recommendation: String) {
        self.id = id
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }
}

public enum SecuritySeverity: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case info = "info"
}