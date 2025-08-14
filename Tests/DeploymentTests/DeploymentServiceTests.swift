import XCTest
import Combine
@testable import HobbyistSwiftUI

final class DeploymentServiceTests: XCTestCase {
    
    var mockDeploymentService: MockDeploymentService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockDeploymentService = MockDeploymentService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        mockDeploymentService = nil
        super.tearDown()
    }
    
    // MARK: - App Store Submission Tests
    
    func testSubmitToAppStoreSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let submission = createMockAppStoreSubmission()
        let expectation = XCTestExpectation(description: "App Store submission succeeds")
        
        // When
        mockDeploymentService.submitToAppStore(submission)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { submissionID in
                    // Then
                    XCTAssertFalse(submissionID.isEmpty)
                    XCTAssertTrue(submissionID.starts(with: "submission_"))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSubmitToAppStoreFailure() {
        // Given
        mockDeploymentService.configureForFailure()
        
        let submission = createMockAppStoreSubmission()
        let expectation = XCTestExpectation(description: "App Store submission fails")
        
        // When
        mockDeploymentService.submitToAppStore(submission)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error.localizedDescription.contains("[MOCK]"))
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure, got success")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUpdateMetadataSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let metadata = createMockAppMetadata()
        let expectation = XCTestExpectation(description: "Metadata update succeeds")
        
        // When
        mockDeploymentService.updateMetadata(metadata)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUploadScreenshotsSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let screenshots = createMockScreenshots()
        let expectation = XCTestExpectation(description: "Screenshot upload succeeds")
        
        // When
        mockDeploymentService.uploadScreenshots(screenshots)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Release Management Tests
    
    func testGetReleaseStatusSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        mockDeploymentService.addMockBuild(buildNumber: "1.0.0-test", status: .readyForSale)
        
        let expectation = XCTestExpectation(description: "Get release status succeeds")
        
        // When
        mockDeploymentService.getReleaseStatus(for: "1.0.0-test")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { status in
                    // Then
                    XCTAssertEqual(status.buildNumber, "1.0.0-test")
                    XCTAssertEqual(status.status, .readyForSale)
                    XCTAssertGreaterThan(status.userRating, 0)
                    XCTAssertGreaterThanOrEqual(status.downloadCount, 0)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testStartPhasedReleaseSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        mockDeploymentService.addMockBuild(buildNumber: "1.0.0-staged")
        
        let strategy = StagingStrategy(
            type: .staged,
            percentages: [1, 5, 25, 100],
            durationBetweenStages: 86400, // 24 hours
            rollbackThreshold: 0.05
        )
        
        let expectation = XCTestExpectation(description: "Start phased release succeeds")
        
        // When
        mockDeploymentService.startPhasedRelease(buildNumber: "1.0.0-staged", strategy: strategy)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRollbackReleaseSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        mockDeploymentService.addMockBuild(buildNumber: "1.0.0-rollback", status: .released)
        
        let expectation = XCTestExpectation(description: "Rollback release succeeds")
        
        // When
        mockDeploymentService.rollbackRelease(buildNumber: "1.0.0-rollback", reason: "Critical bug found")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Compliance Validation Tests
    
    func testValidateComplianceSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Compliance validation succeeds")
        
        // When
        mockDeploymentService.validateCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isCompliant)
                    XCTAssertTrue(result.violations.isEmpty)
                    XCTAssertFalse(result.checkedAt > Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testValidateAccessibilitySuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Accessibility validation succeeds")
        
        // When
        mockDeploymentService.validateAccessibility()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isCompliant)
                    XCTAssertTrue(result.violations.isEmpty)
                    XCTAssertFalse(result.warnings.isEmpty) // Should have some warnings
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testValidatePrivacyComplianceSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Privacy compliance validation succeeds")
        
        // When
        mockDeploymentService.validatePrivacyCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isCompliant)
                    XCTAssertTrue(result.violations.isEmpty)
                    XCTAssertTrue(result.warnings.isEmpty)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Analytics and Monitoring Tests
    
    func testGetAppStoreMetricsSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let dateRange = DateInterval(start: Date().addingTimeInterval(-86400), end: Date())
        let expectation = XCTestExpectation(description: "Get App Store metrics succeeds")
        
        // When
        mockDeploymentService.getAppStoreMetrics(for: dateRange)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { metrics in
                    // Then
                    XCTAssertGreaterThan(metrics.impressions, 0)
                    XCTAssertGreaterThan(metrics.pageViews, 0)
                    XCTAssertGreaterThan(metrics.downloads, 0)
                    XCTAssertGreaterThan(metrics.conversionRate, 0)
                    XCTAssertGreaterThan(metrics.averageRating, 0)
                    XCTAssertLessThanOrEqual(metrics.averageRating, 5.0)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testGetReviewAnalyticsSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Get review analytics succeeds")
        
        // When
        mockDeploymentService.getReviewAnalytics()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { analytics in
                    // Then
                    XCTAssertGreaterThan(analytics.averageRating, 0)
                    XCTAssertGreaterThan(analytics.totalReviews, 0)
                    XCTAssertGreaterThan(analytics.sentimentScore, 0)
                    XCTAssertFalse(analytics.keyTopics.isEmpty)
                    XCTAssertGreaterThan(analytics.responseRate, 0)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testGetCrashReportsSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Get crash reports succeeds")
        
        // When
        mockDeploymentService.getCrashReports(for: "1.0.0-test")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { reports in
                    // Then - can be empty or contain mock crashes
                    for report in reports {
                        XCTAssertFalse(report.crashID.isEmpty)
                        XCTAssertEqual(report.buildNumber, "1.0.0-test")
                        XCTAssertGreaterThan(report.occurrenceCount, 0)
                        XCTAssertGreaterThan(report.affectedUsers, 0)
                    }
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Feature Flag Management Tests
    
    func testGetFeatureFlagsSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Get feature flags succeeds")
        
        // When
        mockDeploymentService.getFeatureFlags()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { flags in
                    // Then
                    XCTAssertFalse(flags.isEmpty) // Mock service adds default flags
                    
                    for flag in flags {
                        XCTAssertFalse(flag.name.isEmpty)
                        XCTAssertGreaterThanOrEqual(flag.rolloutPercentage, 0)
                        XCTAssertLessThanOrEqual(flag.rolloutPercentage, 100)
                        XCTAssertFalse(flag.description.isEmpty)
                    }
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUpdateFeatureFlagSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let flag = FeatureFlag(
            name: "test_feature",
            isEnabled: true,
            rolloutPercentage: 50,
            targetAudience: ["ios_users"],
            description: "Test feature flag",
            lastModified: Date()
        )
        
        let expectation = XCTestExpectation(description: "Update feature flag succeeds")
        
        // When
        mockDeploymentService.updateFeatureFlag(flag)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testEmergencyDisableFeatureSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        mockDeploymentService.addMockFeatureFlag(name: "emergency_test", enabled: true)
        
        let expectation = XCTestExpectation(description: "Emergency disable feature succeeds")
        
        // When
        mockDeploymentService.emergencyDisableFeature(flagName: "emergency_test")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Build Management Tests
    
    func testPromoteBuildToProductionSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        mockDeploymentService.addMockBuild(buildNumber: "1.0.0-promote", status: .readyForSale)
        
        let expectation = XCTestExpectation(description: "Promote build to production succeeds")
        
        // When
        mockDeploymentService.promoteBuildToProduction(buildNumber: "1.0.0-promote")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCreateHotfixBuildSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let fixes = ["Fix critical crash in login flow", "Resolve payment processing issue"]
        let expectation = XCTestExpectation(description: "Create hotfix build succeeds")
        
        // When
        mockDeploymentService.createHotfixBuild(baseVersion: "1.0.0", fixes: fixes)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { hotfixBuildNumber in
                    // Then
                    XCTAssertTrue(hotfixBuildNumber.starts(with: "hotfix_"))
                    XCTAssertTrue(hotfixBuildNumber.contains("1.0.0"))
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testValidateBuildSuccess() {
        // Given
        mockDeploymentService.configureForSuccess()
        
        let expectation = XCTestExpectation(description: "Validate build succeeds")
        
        // When
        mockDeploymentService.validateBuild(buildNumber: "1.0.0-validate")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.isValid)
                    XCTAssertEqual(result.buildNumber, "1.0.0-validate")
                    XCTAssertFalse(result.testResults.isEmpty)
                    XCTAssertGreaterThan(result.performanceMetrics.launchTime, 0)
                    XCTAssertGreaterThan(result.securityScan.overallScore, 0)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceUnavailableError() {
        // Given
        mockDeploymentService = nil
        let service: DeploymentServiceProtocol = MockDeploymentService()
        
        let expectation = XCTestExpectation(description: "Service unavailable error")
        
        // When
        service.getReleaseStatus(for: "test")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertTrue(error.localizedDescription.contains("unavailable"))
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected error, got success")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSlowResponseHandling() {
        // Given
        mockDeploymentService.configureForSlowResponse()
        
        let start = Date()
        let expectation = XCTestExpectation(description: "Slow response handled")
        
        // When
        mockDeploymentService.getReleaseStatus(for: "slow-test")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    // Then
                    let elapsed = Date().timeIntervalSince(start)
                    XCTAssertGreaterThan(elapsed, 2.5) // Should take at least 3 seconds
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Mock Configuration Tests
    
    func testMockConfigurationMethods() {
        // Test success configuration
        mockDeploymentService.configureForSuccess()
        XCTAssertFalse(mockDeploymentService.shouldSimulateFailure)
        XCTAssertEqual(mockDeploymentService.simulatedDelay, 0.1)
        
        // Test failure configuration
        mockDeploymentService.configureForFailure()
        XCTAssertTrue(mockDeploymentService.shouldSimulateFailure)
        
        // Test slow response configuration
        mockDeploymentService.configureForSlowResponse()
        XCTAssertFalse(mockDeploymentService.shouldSimulateFailure)
        XCTAssertEqual(mockDeploymentService.simulatedDelay, 3.0)
    }
    
    func testMockBuildManagement() {
        // Test adding mock build
        mockDeploymentService.addMockBuild(buildNumber: "test-build", status: .released)
        
        let expectation = XCTestExpectation(description: "Mock build retrieval")
        mockDeploymentService.configureForSuccess()
        
        mockDeploymentService.getReleaseStatus(for: "test-build")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { status in
                    XCTAssertEqual(status.buildNumber, "test-build")
                    XCTAssertEqual(status.status, .released)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testMockFeatureFlagManagement() {
        // Test adding mock feature flag
        mockDeploymentService.addMockFeatureFlag(name: "test-flag", enabled: true, rollout: 75)
        
        let expectation = XCTestExpectation(description: "Mock feature flag retrieval")
        mockDeploymentService.configureForSuccess()
        
        mockDeploymentService.getFeatureFlags()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { flags in
                    let testFlag = flags.first { $0.name == "test-flag" }
                    XCTAssertNotNil(testFlag)
                    XCTAssertTrue(testFlag!.isEnabled)
                    XCTAssertEqual(testFlag!.rolloutPercentage, 75)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockAppStoreSubmission() -> AppStoreSubmission {
        return AppStoreSubmission(
            buildNumber: "1.0.0-test",
            versionString: "1.0.0",
            releaseNotes: "Test release with new features and bug fixes",
            screenshots: createMockScreenshots(),
            metadata: createMockAppMetadata(),
            stagingStrategy: StagingStrategy(
                type: .staged,
                percentages: [1, 5, 25, 100],
                durationBetweenStages: 86400,
                rollbackThreshold: 0.05
            )
        )
    }
    
    private func createMockAppMetadata() -> AppMetadata {
        return AppMetadata(
            title: "HobbyistSwiftUI",
            subtitle: "Book Your Perfect Class",
            description: "Discover and book amazing classes in your area. From fitness to crafts, find your next hobby adventure.",
            keywords: ["fitness", "classes", "booking", "hobby", "activities"],
            supportURL: "https://hobbyist.app/support",
            marketingURL: "https://hobbyist.app",
            privacyPolicyURL: "https://hobbyist.app/privacy",
            category: .health,
            contentRating: .fourPlus
        )
    }
    
    private func createMockScreenshots() -> [Screenshot] {
        return [
            Screenshot(deviceType: .iPhone6_7, imagePath: "/screenshots/iphone_6_7_1.png", order: 1, locale: "en-US"),
            Screenshot(deviceType: .iPhone6_7, imagePath: "/screenshots/iphone_6_7_2.png", order: 2, locale: "en-US"),
            Screenshot(deviceType: .iPadPro12_9, imagePath: "/screenshots/ipad_pro_12_9_1.png", order: 1, locale: "en-US")
        ]
    }
}

// MARK: - Service Container Integration Tests

final class DeploymentServiceContainerTests: XCTestCase {
    
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceContainer(
            supabaseClient: MockSupabaseClient(), 
            environment: .test
        )
    }
    
    override func tearDown() {
        serviceContainer = nil
        super.tearDown()
    }
    
    func testDeploymentServiceRegistration() {
        // When
        let deploymentService = serviceContainer.deploymentService()
        
        // Then
        XCTAssertTrue(deploymentService is MockDeploymentService)
    }
    
    func testDeploymentServiceSingleton() {
        // When
        let service1 = serviceContainer.deploymentService()
        let service2 = serviceContainer.deploymentService()
        
        // Then
        XCTAssertTrue(service1 === service2, "DeploymentService should be singleton")
    }
    
    func testProductionServiceCreation() {
        // Given
        let productionContainer = ServiceContainer()
        productionContainer.configure(for: .production)
        
        // When
        let deploymentService = productionContainer.deploymentService()
        
        // Then
        XCTAssertTrue(deploymentService is AppStoreAutomationService)
    }
}

// MARK: - Mock Supabase Client

private class MockSupabaseClient {
    // Minimal mock for testing purposes
}

// MARK: - Performance Tests

final class DeploymentServicePerformanceTests: XCTestCase {
    
    var mockService: MockDeploymentService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockDeploymentService()
        mockService.configureForSuccess()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        mockService = nil
        super.tearDown()
    }
    
    func testConcurrentDeploymentOperations() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 5
        
        let buildNumbers = ["build1", "build2", "build3", "build4", "build5"]
        
        // When - Execute multiple operations concurrently
        for buildNumber in buildNumbers {
            mockService.getReleaseStatus(for: buildNumber)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { status in
                        XCTAssertEqual(status.buildNumber, buildNumber)
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLargeDataHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Large dataset handled efficiently")
        
        // Add many mock builds
        for i in 1...100 {
            mockService.addMockBuild(buildNumber: "build-\(i)")
        }
        
        // Add many feature flags
        for i in 1...50 {
            mockService.addMockFeatureFlag(name: "flag-\(i)")
        }
        
        let startTime = Date()
        
        // When
        Publishers.CombineLatest(
            mockService.getReleaseStatus(for: "build-50"),
            mockService.getFeatureFlags()
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { status, flags in
                // Then
                let elapsedTime = Date().timeIntervalSince(startTime)
                XCTAssertLessThan(elapsedTime, 1.0, "Should handle large datasets efficiently")
                XCTAssertEqual(status.buildNumber, "build-50")
                XCTAssertGreaterThanOrEqual(flags.count, 50)
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testMemoryUsageUnderLoad() {
        // This test would measure memory usage under load
        // In a real implementation, you could use XCTMemoryMetric
        measure {
            let expectation = XCTestExpectation(description: "Memory test operations")
            expectation.expectedFulfillmentCount = 100
            
            // Perform many operations
            for i in 1...100 {
                mockService.getReleaseStatus(for: "memory-test-\(i)")
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in
                            expectation.fulfill()
                        }
                    )
                    .store(in: &cancellables)
            }
            
            wait(for: [expectation], timeout: 10.0)
            cancellables.removeAll()
        }
    }
}