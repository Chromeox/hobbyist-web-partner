import XCTest
import Combine
@testable import HobbyistSwiftUI

final class ComplianceValidationTests: XCTestCase {
    
    var complianceService: ComplianceValidationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        complianceService = ComplianceValidationService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        complianceService = nil
        super.tearDown()
    }
    
    // MARK: - Comprehensive Compliance Tests
    
    func testValidateFullComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Full compliance validation succeeds")
        
        // When
        complianceService.validateFullCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertNotNil(result.appStoreCompliance)
                    XCTAssertNotNil(result.accessibilityCompliance)
                    XCTAssertNotNil(result.privacyCompliance)
                    XCTAssertNotNil(result.performanceCompliance)
                    XCTAssertNotNil(result.securityCompliance)
                    
                    XCTAssertGreaterThanOrEqual(result.overallScore, 0)
                    XCTAssertLessThanOrEqual(result.overallScore, 100)
                    XCTAssertGreaterThanOrEqual(result.totalViolations, 0)
                    XCTAssertGreaterThanOrEqual(result.criticalViolations, 0)
                    XCTAssertLessThanOrEqual(result.criticalViolations, result.totalViolations)
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGenerateComplianceReportSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Generate compliance report succeeds")
        
        // When
        complianceService.generateComplianceReport()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { report in
                    // Then
                    XCTAssertGreaterThanOrEqual(report.overallScore, 0)
                    XCTAssertLessThanOrEqual(report.overallScore, 100)
                    XCTAssertFalse(report.summary.isEmpty)
                    XCTAssertNotNil(report.detailedResults)
                    XCTAssertTrue(report.generatedAt <= Date())
                    XCTAssertNotNil(report.nextReviewDate)
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - App Store Guidelines Tests
    
    func testValidateAppStoreGuidelinesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "App Store guidelines validation succeeds")
        
        // When
        complianceService.validateAppStoreGuidelines()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.checkedAt <= Date())
                    // isCompliant can be true or false depending on validation results
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidateMetadataComplianceSuccess() {
        // Given
        let metadata = createValidAppMetadata()
        let expectation = XCTestExpectation(description: "Metadata compliance validation succeeds")
        
        // When
        complianceService.validateMetadataCompliance(metadata: metadata)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.metadata.title, metadata.title)
                    XCTAssertTrue(result.validatedAt <= Date())
                    // isCompliant depends on metadata validation
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateMetadataComplianceInvalidTitle() {
        // Given - Title too long (over 30 characters)
        let invalidMetadata = AppMetadata(
            title: "This Title Is Way Too Long For App Store Requirements And Will Fail Validation",
            description: "Valid description",
            keywords: ["test"],
            supportURL: "https://example.com/support",
            privacyPolicyURL: "https://example.com/privacy",
            category: .health,
            contentRating: .fourPlus
        )
        
        let expectation = XCTestExpectation(description: "Invalid metadata detected")
        
        // When
        complianceService.validateMetadataCompliance(metadata: invalidMetadata)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success with violations, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertFalse(result.isCompliant)
                    XCTAssertTrue(result.violations.contains { $0.field == "title" })
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateContentRatingSuccess() {
        // Given
        let contentRating = ContentRating.fourPlus
        let appContent = AppContent(
            hasViolence: false,
            hasAdultContent: false,
            hasGambling: false,
            hasAlcoholTobacco: false,
            hasSimulatedGambling: false,
            hasProfanity: false
        )
        
        let expectation = XCTestExpectation(description: "Content rating validation succeeds")
        
        // When
        complianceService.validateContentRating(for: contentRating, appContent: appContent)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.requestedRating, contentRating)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Accessibility Compliance Tests
    
    func testValidateAccessibilityComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Accessibility compliance validation succeeds")
        
        // When
        complianceService.validateAccessibilityCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.checkedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidateWCAG_AA_ComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "WCAG AA compliance validation succeeds")
        
        // When
        complianceService.validateWCAG_AA_Compliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertFalse(result.checks.isEmpty)
                    XCTAssertGreaterThanOrEqual(result.overallCompliance, 0.0)
                    XCTAssertLessThanOrEqual(result.overallCompliance, 1.0)
                    XCTAssertTrue(result.validatedAt <= Date())
                    
                    // Check that we have expected WCAG checks
                    let principleNames = Set(result.checks.map { $0.check.principle })
                    XCTAssertTrue(principleNames.contains("Perceivable"))
                    XCTAssertTrue(principleNames.contains("Operable"))
                    XCTAssertTrue(principleNames.contains("Understandable"))
                    XCTAssertTrue(principleNames.contains("Robust"))
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidateiOSAccessibilityFeaturesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "iOS accessibility features validation succeeds")
        
        // When
        complianceService.validateiOSAccessibilityFeatures()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertFalse(result.features.isEmpty)
                    XCTAssertGreaterThanOrEqual(result.implementationPercentage, 0.0)
                    XCTAssertLessThanOrEqual(result.implementationPercentage, 1.0)
                    XCTAssertGreaterThanOrEqual(result.overallScore, 0.0)
                    XCTAssertLessThanOrEqual(result.overallScore, 1.0)
                    XCTAssertTrue(result.validatedAt <= Date())
                    
                    // Check for expected accessibility features
                    let featureNames = Set(result.features.map { $0.name })
                    XCTAssertTrue(featureNames.contains("VoiceOver"))
                    XCTAssertTrue(featureNames.contains("Dynamic Type"))
                    XCTAssertTrue(featureNames.contains("Reduce Motion"))
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Privacy Compliance Tests
    
    func testValidatePrivacyComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Privacy compliance validation succeeds")
        
        // When
        complianceService.validatePrivacyCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.checkedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidatePrivacyPolicySuccess() {
        // Given
        let validPolicyURL = "https://hobbyist.app/privacy"
        let expectation = XCTestExpectation(description: "Privacy policy validation succeeds")
        
        // When
        complianceService.validatePrivacyPolicy(policyURL: validPolicyURL)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.url, validPolicyURL)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateDataCollectionSuccess() {
        // Given
        let dataTypes: [DataType] = [.personalInfo, .usageData, .locationData]
        let purposes: [DataCollectionPurpose] = [.appFunctionality, .analytics]
        
        let expectation = XCTestExpectation(description: "Data collection validation succeeds")
        
        // When
        complianceService.validateDataCollection(dataTypes: dataTypes, purposes: purposes)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.dataTypes, dataTypes)
                    XCTAssertEqual(result.purposes, purposes)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Performance Compliance Tests
    
    func testValidatePerformanceComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Performance compliance validation succeeds")
        
        // When
        complianceService.validatePerformanceCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.checkedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidateAppLaunchTimeSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "App launch time validation succeeds")
        
        // When
        complianceService.validateAppLaunchTime()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertGreaterThan(result.averageLaunchTime, 0)
                    XCTAssertGreaterThan(result.maxAcceptableTime, 0)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateMemoryUsageSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Memory usage validation succeeds")
        
        // When
        complianceService.validateMemoryUsage()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertGreaterThan(result.averageMemoryUsage, 0)
                    XCTAssertGreaterThan(result.peakMemoryUsage, 0)
                    XCTAssertGreaterThan(result.maxAcceptableUsage, 0)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateBatteryImpactSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Battery impact validation succeeds")
        
        // When
        complianceService.validateBatteryImpact()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(BatteryImpact.allCases.contains(result.batteryImpact))
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Security Compliance Tests
    
    func testValidateSecurityComplianceSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Security compliance validation succeeds")
        
        // When
        complianceService.validateSecurityCompliance()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertTrue(result.checkedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testValidateDataEncryptionSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Data encryption validation succeeds")
        
        // When
        complianceService.validateDataEncryption()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertFalse(result.encryptionStandard.isEmpty)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testValidateNetworkSecuritySuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Network security validation succeeds")
        
        // When
        complianceService.validateNetworkSecurity()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertGreaterThanOrEqual(result.securityScore, 0)
                    XCTAssertLessThanOrEqual(result.securityScore, 100)
                    XCTAssertTrue(result.validatedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Third-Party SDK Tests
    
    func testValidateThirdPartySDKsSuccess() {
        // Given
        let sdks = [
            ThirdPartySDK(name: "Supabase", version: "2.5.1", collectsData: true, hasPrivacyPolicy: true, purpose: "Backend services"),
            ThirdPartySDK(name: "Stripe", version: "23.27.4", collectsData: true, hasPrivacyPolicy: true, purpose: "Payment processing"),
            ThirdPartySDK(name: "Firebase", version: "10.19.0", collectsData: true, hasPrivacyPolicy: true, purpose: "Analytics and crash reporting")
        ]
        
        let expectation = XCTestExpectation(description: "Third-party SDK validation succeeds")
        
        // When
        complianceService.validateThirdPartySDKs(sdks: sdks)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.sdkResults.count, sdks.count)
                    XCTAssertGreaterThanOrEqual(result.overallCompliance, 0.0)
                    XCTAssertLessThanOrEqual(result.overallCompliance, 1.0)
                    XCTAssertTrue(result.validatedAt <= Date())
                    
                    // Check individual SDK results
                    for sdkResult in result.sdkResults {
                        XCTAssertTrue(sdks.contains { $0.name == sdkResult.sdk.name })
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Compliance Monitoring Tests
    
    func testMonitorComplianceChangesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Compliance monitoring produces notifications")
        expectation.expectedFulfillmentCount = 1
        
        // When
        complianceService.monitorComplianceChanges()
            .prefix(1) // Only take the first notification
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { notification in
                    // Then
                    XCTAssertTrue(ComplianceChangeType.allCases.contains(notification.changeType))
                    XCTAssertFalse(notification.description.isEmpty)
                    XCTAssertTrue(ComplianceImpact.allCases.contains(notification.impact))
                    XCTAssertTrue(notification.detectedAt <= Date())
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testComplianceValidationWithNetworkError() {
        // This test would simulate network errors in a real implementation
        // For now, we test that the service handles errors gracefully
        
        let expectation = XCTestExpectation(description: "Network error handled gracefully")
        
        // When - testing with invalid data that might cause errors
        let invalidSDKs = [ThirdPartySDK(name: "", version: "", collectsData: false, hasPrivacyPolicy: false, purpose: "")]
        
        complianceService.validateThirdPartySDKs(sdks: invalidSDKs)
            .sink(
                receiveCompletion: { completion in
                    // Should complete successfully even with invalid data
                    expectation.fulfill()
                },
                receiveValue: { result in
                    // Then - should handle invalid data gracefully
                    XCTAssertEqual(result.sdkResults.count, 1)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndComplianceWorkflow() {
        // Given
        let expectation = XCTestExpectation(description: "End-to-end compliance workflow completes")
        
        // When - Simulate a complete compliance check workflow
        let metadata = createValidAppMetadata()
        
        Publishers.CombineLatest4(
            complianceService.validateMetadataCompliance(metadata: metadata),
            complianceService.validateAccessibilityCompliance(),
            complianceService.validatePrivacyCompliance(),
            complianceService.validateSecurityCompliance()
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { metadataResult, accessibilityResult, privacyResult, securityResult in
                // Then
                XCTAssertNotNil(metadataResult.metadata)
                XCTAssertTrue(accessibilityResult.checkedAt <= Date())
                XCTAssertTrue(privacyResult.checkedAt <= Date())
                XCTAssertTrue(securityResult.checkedAt <= Date())
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Performance Tests
    
    func testComplianceValidationPerformance() {
        // Measure the performance of compliance validation
        measure {
            let expectation = XCTestExpectation(description: "Performance measurement")
            
            complianceService.validateFullCompliance()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 20.0)
            cancellables.removeAll()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createValidAppMetadata() -> AppMetadata {
        return AppMetadata(
            title: "HobbyistSwiftUI",
            subtitle: "Book Your Perfect Class",
            description: "Discover and book amazing classes in your area. From fitness to crafts, find your next hobby adventure with our easy-to-use booking platform.",
            keywords: ["fitness", "classes", "booking", "hobby", "activities"],
            supportURL: "https://hobbyist.app/support",
            marketingURL: "https://hobbyist.app",
            privacyPolicyURL: "https://hobbyist.app/privacy",
            category: .health,
            contentRating: .fourPlus
        )
    }
}

// MARK: - Compliance Validator Unit Tests

final class ComplianceValidatorTests: XCTestCase {
    
    // MARK: - App Store Guideline Validator Tests
    
    func testAppStoreGuidelineValidatorCreation() {
        // Given & When
        let validator = AppStoreGuidelineValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
    
    // MARK: - Accessibility Validator Tests
    
    func testAccessibilityValidatorCreation() {
        // Given & When
        let validator = AccessibilityValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
    
    // MARK: - Privacy Validator Tests
    
    func testPrivacyValidatorCreation() {
        // Given & When
        let validator = PrivacyValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
    
    // MARK: - Performance Validator Tests
    
    func testPerformanceValidatorCreation() {
        // Given & When
        let validator = PerformanceValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
    
    // MARK: - Security Validator Tests
    
    func testSecurityValidatorCreation() {
        // Given & When
        let validator = SecurityValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
    
    // MARK: - Content Rating Validator Tests
    
    func testContentRatingValidatorCreation() {
        // Given & When
        let validator = ContentRatingValidator()
        
        // Then
        XCTAssertNotNil(validator)
    }
}