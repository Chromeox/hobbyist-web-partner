import Combine
import Foundation

public class MockDeploymentService: DeploymentServiceProtocol {
    // MARK: - Mock Configuration

    public var shouldSimulateFailure = false
    public var simulatedDelay: TimeInterval = 0.5
    public var simulatedBuildNumbers: [String] = []

    // MARK: - Mock Data Storage

    private var mockReleaseStatuses: [String: ReleaseStatus] = [:]
    private var mockFeatureFlags: [FeatureFlag] = []
    private var mockABTests: [String: ABTestResult] = [:]
    private var mockValidationResults: [String: BuildValidationResult] = [:]

    public init() {
        setupMockData()
    }

    // MARK: - App Store Submission

    public func submitToAppStore(_: AppStoreSubmission) -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.submissionFailed))
                } else {
                    let submissionID = "submission_\(UUID().uuidString.prefix(8))"
                    promise(.success(submissionID))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func updateMetadata(_: AppMetadata) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.metadataUpdateFailed))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func uploadScreenshots(_: [Screenshot]) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.screenshotUploadFailed))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Release Management

    public func getReleaseStatus(for buildNumber: String) -> AnyPublisher<ReleaseStatus, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.releaseStatusFailed))
                } else {
                    let status = self.mockReleaseStatuses[buildNumber] ?? self.generateMockReleaseStatus(buildNumber: buildNumber)
                    promise(.success(status))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func startPhasedRelease(buildNumber: String, strategy: StagingStrategy) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.phasedReleaseFailed))
                } else {
                    // Update mock status to staging
                    var status = self.mockReleaseStatuses[buildNumber] ?? self.generateMockReleaseStatus(buildNumber: buildNumber)
                    status = ReleaseStatus(
                        buildNumber: buildNumber,
                        status: .stagingInProgress,
                        currentStagePercentage: strategy.percentages.first ?? 1,
                        crashRate: status.crashRate,
                        userRating: status.userRating,
                        downloadCount: status.downloadCount,
                        lastUpdated: Date()
                    )
                    self.mockReleaseStatuses[buildNumber] = status
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func pausePhasedRelease(buildNumber _: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.phasedReleaseFailed))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func resumePhasedRelease(buildNumber _: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.phasedReleaseFailed))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func rollbackRelease(buildNumber: String, reason _: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.rollbackFailed))
                } else {
                    // Update mock status to rolled back
                    if var status = self.mockReleaseStatuses[buildNumber] {
                        status = ReleaseStatus(
                            buildNumber: buildNumber,
                            status: .rollbackInProgress,
                            currentStagePercentage: 0,
                            crashRate: status.crashRate,
                            userRating: status.userRating,
                            downloadCount: status.downloadCount,
                            lastUpdated: Date()
                        )
                        self.mockReleaseStatuses[buildNumber] = status
                    }
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Compliance Validation

    public func validateCompliance() -> AnyPublisher<ComplianceResult, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.complianceValidationFailed))
                } else {
                    let result = ComplianceResult(
                        isCompliant: true,
                        violations: [],
                        warnings: ["Minor accessibility improvements recommended"],
                        checkedAt: Date()
                    )
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func validateAccessibility() -> AnyPublisher<ComplianceResult, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.accessibilityValidationFailed))
                } else {
                    let result = ComplianceResult(
                        isCompliant: true,
                        violations: [],
                        warnings: ["Consider adding more accessibility labels"],
                        checkedAt: Date()
                    )
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func validatePrivacyCompliance() -> AnyPublisher<ComplianceResult, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.privacyValidationFailed))
                } else {
                    let result = ComplianceResult(
                        isCompliant: true,
                        violations: [],
                        warnings: [],
                        checkedAt: Date()
                    )
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Analytics and Monitoring

    public func getAppStoreMetrics(for _: DateInterval) -> AnyPublisher<AppStoreMetrics, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.analyticsDataFailed))
                } else {
                    let metrics = AppStoreMetrics(
                        impressions: Int.random(in: 10000 ... 100_000),
                        pageViews: Int.random(in: 5000 ... 20000),
                        downloads: Int.random(in: 500 ... 5000),
                        conversionRate: Double.random(in: 0.05 ... 0.25),
                        averageRating: Double.random(in: 3.5 ... 5.0),
                        totalRatings: Int.random(in: 50 ... 1000),
                        crashRate: Double.random(in: 0.001 ... 0.05),
                        retentionRate: Double.random(in: 0.4 ... 0.8)
                    )
                    promise(.success(metrics))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getReviewAnalytics() -> AnyPublisher<ReviewAnalytics, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.analyticsDataFailed))
                } else {
                    let analytics = ReviewAnalytics(
                        averageRating: Double.random(in: 3.5 ... 5.0),
                        totalReviews: Int.random(in: 50 ... 500),
                        sentimentScore: Double.random(in: 0.3 ... 0.9),
                        keyTopics: ["Great app", "Easy to use", "Could improve notifications"],
                        responseRate: Double.random(in: 0.7 ... 1.0)
                    )
                    promise(.success(analytics))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getCrashReports(for buildNumber: String) -> AnyPublisher<[CrashReport], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.crashReportsFailed))
                } else {
                    let crashes = self.generateMockCrashReports(buildNumber: buildNumber)
                    promise(.success(crashes))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Feature Flag Management

    public func getFeatureFlags() -> AnyPublisher<[FeatureFlag], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.featureFlagsFailed))
                } else {
                    promise(.success(self.mockFeatureFlags))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func updateFeatureFlag(_ flag: FeatureFlag) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.featureFlagUpdateFailed))
                } else {
                    // Update or add the flag
                    if let index = self.mockFeatureFlags.firstIndex(where: { $0.name == flag.name }) {
                        self.mockFeatureFlags[index] = flag
                    } else {
                        self.mockFeatureFlags.append(flag)
                    }
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func emergencyDisableFeature(flagName: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.emergencyDisableFailed))
                } else {
                    // Disable the feature flag
                    if let index = self.mockFeatureFlags.firstIndex(where: { $0.name == flagName }) {
                        let disabledFlag = FeatureFlag(
                            name: flagName,
                            isEnabled: false,
                            rolloutPercentage: 0,
                            targetAudience: self.mockFeatureFlags[index].targetAudience,
                            description: self.mockFeatureFlags[index].description + " - EMERGENCY DISABLED",
                            lastModified: Date()
                        )
                        self.mockFeatureFlags[index] = disabledFlag
                    }
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Build Management

    public func promoteBuildToProduction(buildNumber: String) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.buildPromotionFailed))
                } else {
                    // Update release status to released
                    if var status = self.mockReleaseStatuses[buildNumber] {
                        status = ReleaseStatus(
                            buildNumber: buildNumber,
                            status: .released,
                            currentStagePercentage: 100,
                            crashRate: status.crashRate,
                            userRating: status.userRating,
                            downloadCount: status.downloadCount,
                            lastUpdated: Date()
                        )
                        self.mockReleaseStatuses[buildNumber] = status
                    }
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func createHotfixBuild(baseVersion: String, fixes _: [String]) -> AnyPublisher<String, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.hotfixCreationFailed))
                } else {
                    let hotfixBuildNumber = "hotfix_\(baseVersion)_\(Date().timeIntervalSince1970)"
                    self.simulatedBuildNumbers.append(hotfixBuildNumber)
                    promise(.success(hotfixBuildNumber))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func validateBuild(buildNumber: String) -> AnyPublisher<BuildValidationResult, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(MockDeploymentError.serviceUnavailable))
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.simulatedDelay) {
                if self.shouldSimulateFailure {
                    promise(.failure(MockDeploymentError.buildValidationFailed))
                } else {
                    let result = self.mockValidationResults[buildNumber] ?? self.generateMockBuildValidation(buildNumber: buildNumber)
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Mock Configuration Methods

    public func configureForSuccess() {
        shouldSimulateFailure = false
        simulatedDelay = 0.1
    }

    public func configureForFailure() {
        shouldSimulateFailure = true
        simulatedDelay = 0.1
    }

    public func configureForSlowResponse() {
        shouldSimulateFailure = false
        simulatedDelay = 3.0
    }

    public func addMockBuild(buildNumber: String, status: ReleaseState = .readyForSale) {
        let releaseStatus = ReleaseStatus(
            buildNumber: buildNumber,
            status: status,
            currentStagePercentage: status == .released ? 100 : 50,
            crashRate: Double.random(in: 0.001 ... 0.03),
            userRating: Double.random(in: 3.5 ... 5.0),
            downloadCount: Int.random(in: 100 ... 10000),
            lastUpdated: Date()
        )
        mockReleaseStatuses[buildNumber] = releaseStatus
    }

    public func addMockFeatureFlag(name: String, enabled: Bool = true, rollout: Int = 100) {
        let flag = FeatureFlag(
            name: name,
            isEnabled: enabled,
            rolloutPercentage: rollout,
            targetAudience: ["ios_users"],
            description: "Mock feature flag for testing",
            lastModified: Date()
        )
        mockFeatureFlags.append(flag)
    }

    // MARK: - Private Helper Methods

    private func setupMockData() {
        // Add default mock feature flags
        addMockFeatureFlag(name: "enhanced_search", enabled: true, rollout: 100)
        addMockFeatureFlag(name: "premium_features", enabled: false, rollout: 0)
        addMockFeatureFlag(name: "new_ui_design", enabled: true, rollout: 50)

        // Add default mock builds
        addMockBuild(buildNumber: "1.0.0-alpha.1", status: .released)
        addMockBuild(buildNumber: "1.0.0-alpha.2", status: .stagingInProgress)
        addMockBuild(buildNumber: "1.0.0-beta.1", status: .inReview)
    }

    private func generateMockReleaseStatus(buildNumber: String) -> ReleaseStatus {
        return ReleaseStatus(
            buildNumber: buildNumber,
            status: .readyForSale,
            currentStagePercentage: Int.random(in: 50 ... 100),
            crashRate: Double.random(in: 0.001 ... 0.03),
            userRating: Double.random(in: 3.5 ... 5.0),
            downloadCount: Int.random(in: 100 ... 10000),
            lastUpdated: Date()
        )
    }

    private func generateMockCrashReports(buildNumber: String) -> [CrashReport] {
        let crashCount = Int.random(in: 0 ... 3)
        return (0 ..< crashCount).map { index in
            CrashReport(
                crashID: "crash_\(buildNumber)_\(index)",
                buildNumber: buildNumber,
                deviceModel: ["iPhone14,2", "iPhone13,1", "iPad13,1"].randomElement()!,
                osVersion: ["16.0", "16.1", "17.0"].randomElement()!,
                stackTrace: "Mock stack trace for crash \(index)",
                occurrenceCount: Int.random(in: 1 ... 10),
                affectedUsers: Int.random(in: 1 ... 50),
                firstOccurrence: Date().addingTimeInterval(-Double.random(in: 3600 ... 86400)),
                lastOccurrence: Date().addingTimeInterval(-Double.random(in: 60 ... 3600))
            )
        }
    }

    private func generateMockBuildValidation(buildNumber: String) -> BuildValidationResult {
        let testResults = [
            TestResult(testSuite: "UnitTests", passed: 145, failed: 0, skipped: 5, duration: 35.2),
            TestResult(testSuite: "UITests", passed: 48, failed: 0, skipped: 2, duration: 125.8),
            TestResult(testSuite: "IntegrationTests", passed: 25, failed: 0, skipped: 1, duration: 65.1),
        ]

        let performanceMetrics = PerformanceMetrics(
            launchTime: Double.random(in: 0.5 ... 1.5),
            memoryUsage: Int.random(in: 30_000_000 ... 80_000_000),
            cpuUsage: Double.random(in: 5.0 ... 25.0),
            batteryImpact: BatteryImpact.allCases.randomElement()!
        )

        let securityScan = SecurityScanResult(
            vulnerabilities: [],
            overallScore: Double.random(in: 90.0 ... 100.0),
            recommendations: ["Keep dependencies updated", "Regular security audits"]
        )

        return BuildValidationResult(
            isValid: true,
            buildNumber: buildNumber,
            testResults: testResults,
            performanceMetrics: performanceMetrics,
            securityScan: securityScan
        )
    }
}

// MARK: - Mock Error Types

public enum MockDeploymentError: Error, LocalizedError {
    case serviceUnavailable
    case submissionFailed
    case metadataUpdateFailed
    case screenshotUploadFailed
    case releaseStatusFailed
    case phasedReleaseFailed
    case rollbackFailed
    case complianceValidationFailed
    case accessibilityValidationFailed
    case privacyValidationFailed
    case analyticsDataFailed
    case crashReportsFailed
    case featureFlagsFailed
    case featureFlagUpdateFailed
    case emergencyDisableFailed
    case buildPromotionFailed
    case hotfixCreationFailed
    case buildValidationFailed

    public var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "[MOCK] Deployment service is unavailable"
        case .submissionFailed:
            return "[MOCK] App Store submission failed"
        case .metadataUpdateFailed:
            return "[MOCK] Metadata update failed"
        case .screenshotUploadFailed:
            return "[MOCK] Screenshot upload failed"
        case .releaseStatusFailed:
            return "[MOCK] Failed to get release status"
        case .phasedReleaseFailed:
            return "[MOCK] Phased release operation failed"
        case .rollbackFailed:
            return "[MOCK] Release rollback failed"
        case .complianceValidationFailed:
            return "[MOCK] Compliance validation failed"
        case .accessibilityValidationFailed:
            return "[MOCK] Accessibility validation failed"
        case .privacyValidationFailed:
            return "[MOCK] Privacy validation failed"
        case .analyticsDataFailed:
            return "[MOCK] Failed to retrieve analytics data"
        case .crashReportsFailed:
            return "[MOCK] Failed to retrieve crash reports"
        case .featureFlagsFailed:
            return "[MOCK] Failed to retrieve feature flags"
        case .featureFlagUpdateFailed:
            return "[MOCK] Failed to update feature flag"
        case .emergencyDisableFailed:
            return "[MOCK] Emergency disable failed"
        case .buildPromotionFailed:
            return "[MOCK] Build promotion failed"
        case .hotfixCreationFailed:
            return "[MOCK] Hotfix creation failed"
        case .buildValidationFailed:
            return "[MOCK] Build validation failed"
        }
    }
}
