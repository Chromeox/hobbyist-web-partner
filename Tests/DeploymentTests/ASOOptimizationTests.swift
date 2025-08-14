import XCTest
import Combine
@testable import HobbyistSwiftUI

final class ASOOptimizationTests: XCTestCase {
    
    var asoService: ASO_OptimizationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        asoService = ASO_OptimizationService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        asoService = nil
        super.tearDown()
    }
    
    // MARK: - Keyword Optimization Tests
    
    func testAnalyzeKeywordsForHealthCategory() {
        // Given
        let expectation = XCTestExpectation(description: "Keyword analysis completes for health category")
        
        // When
        asoService.analyzeKeywords(for: .health)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.category, .health)
                    XCTAssertFalse(result.trendingKeywords.isEmpty)
                    XCTAssertFalse(result.keywordMetrics.isEmpty)
                    XCTAssertFalse(result.longTailSuggestions.isEmpty)
                    XCTAssertTrue(result.analyzedAt <= Date())
                    
                    // Verify health-related keywords are present
                    let keywordStrings = result.trendingKeywords.map { $0.keyword }
                    XCTAssertTrue(keywordStrings.contains { $0.contains("fitness") })
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testOptimizeKeywords() {
        // Given
        let currentKeywords = ["fitness", "workout", "health"]
        let targetKeywords = ["fitness app", "workout tracker", "health monitoring", "exercise planner"]
        let expectation = XCTestExpectation(description: "Keyword optimization completes")
        
        // When
        asoService.optimizeKeywords(
            currentKeywords: currentKeywords,
            targetKeywords: targetKeywords,
            category: .health
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { result in
                // Then
                XCTAssertEqual(result.originalKeywords, currentKeywords)
                XCTAssertFalse(result.optimizedKeywords.isEmpty)
                XCTAssertFalse(result.currentPerformance.isEmpty)
                XCTAssertGreaterThan(result.projectedImprovement.trafficIncrease, 0)
                XCTAssertGreaterThan(result.confidence, 0)
                XCTAssertLessThanOrEqual(result.confidence, 1.0)
                XCTAssertTrue(result.optimizedAt <= Date())
                
                // Check that optimized keywords include target keywords
                for targetKeyword in targetKeywords {
                    XCTAssertTrue(result.optimizedKeywords.contains(targetKeyword))
                }
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTrackKeywordRankings() {
        // Given
        let keywords = ["fitness app", "workout tracker", "health monitor"]
        let expectation = XCTestExpectation(description: "Keyword ranking tracking completes")
        
        // When
        asoService.trackKeywordRankings(keywords: keywords)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { rankings in
                    // Then
                    XCTAssertEqual(rankings.count, keywords.count)
                    
                    for (index, ranking) in rankings.enumerated() {
                        XCTAssertEqual(ranking.keyword, keywords[index])
                        XCTAssertGreaterThan(ranking.currentRank, 0)
                        XCTAssertLessThanOrEqual(ranking.currentRank, 100)
                        XCTAssertGreaterThan(ranking.bestRank, 0)
                        XCTAssertTrue(ranking.trackingDate <= Date())
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Competitor Analysis Tests
    
    func testAnalyzeCompetitors() {
        // Given
        let competitorAppIDs = ["fitness-competitor-1", "health-app-2", "workout-app-3"]
        let expectation = XCTestExpectation(description: "Competitor analysis completes")
        
        // When
        asoService.analyzeCompetitors(appIDs: competitorAppIDs)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.competitorProfiles.count, competitorAppIDs.count)
                    XCTAssertNotNil(result.marketPositioning)
                    XCTAssertFalse(result.keywordGaps.isEmpty)
                    XCTAssertFalse(result.optimizationOpportunities.isEmpty)
                    XCTAssertTrue(result.analyzedAt <= Date())
                    
                    // Verify competitor profiles
                    for profile in result.competitorProfiles {
                        XCTAssertTrue(competitorAppIDs.contains(profile.appID))
                        XCTAssertGreaterThan(profile.rating, 0)
                        XCTAssertLessThanOrEqual(profile.rating, 5.0)
                        XCTAssertGreaterThanOrEqual(profile.ranking, 1)
                        XCTAssertGreaterThan(profile.estimatedDownloads, 0)
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFindCompetitorKeywords() {
        // Given
        let competitorAppID = "fitness-competitor-app"
        let expectation = XCTestExpectation(description: "Competitor keyword extraction completes")
        
        // When
        asoService.findCompetitorKeywords(competitorAppID: competitorAppID)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { keywords in
                    // Then
                    XCTAssertFalse(keywords.isEmpty)
                    
                    for keyword in keywords {
                        XCTAssertFalse(keyword.keyword.isEmpty)
                        XCTAssertGreaterThan(keyword.difficulty, 0)
                        XCTAssertLessThanOrEqual(keyword.difficulty, 1.0)
                        XCTAssertGreaterThan(keyword.rank, 0)
                        XCTAssertLessThanOrEqual(keyword.rank, 100)
                    }
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testCompareWithCompetitors() {
        // Given
        let ourAppID = "com.hobbyist.app"
        let competitorAppIDs = ["competitor-1", "competitor-2"]
        let expectation = XCTestExpectation(description: "Competitive comparison completes")
        
        // When
        asoService.compareWithCompetitors(ourAppID: ourAppID, competitorAppIDs: competitorAppIDs)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.ourApp.appID, ourAppID)
                    XCTAssertEqual(result.competitors.count, competitorAppIDs.count)
                    XCTAssertFalse(result.competitiveStrengths.isEmpty)
                    XCTAssertFalse(result.competitiveWeaknesses.isEmpty)
                    XCTAssertNotNil(result.marketShareEstimate)
                    XCTAssertTrue(result.comparedAt <= Date())
                    
                    // Verify market share estimate
                    XCTAssertGreaterThan(result.marketShareEstimate.estimatedShare, 0)
                    XCTAssertLessThanOrEqual(result.marketShareEstimate.estimatedShare, 1.0)
                    XCTAssertGreaterThan(result.marketShareEstimate.rank, 0)
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - A/B Testing Tests
    
    func testCreateABTest() {
        // Given
        let variants = [
            MetadataVariant(
                id: "control",
                name: "Control Version",
                title: "HobbyistSwiftUI - Book Classes",
                description: "Original description",
                keywords: ["fitness", "classes"],
                screenshots: nil
            ),
            MetadataVariant(
                id: "variant_a",
                name: "Variant A - Enhanced",
                title: "HobbyistSwiftUI - Find Your Hobby",
                description: "Enhanced description with better keywords",
                keywords: ["fitness", "classes", "hobby", "activities"],
                screenshots: nil
            )
        ]
        let trafficSplit = [0.5, 0.5]
        
        let expectation = XCTestExpectation(description: "A/B test creation completes")
        
        // When
        asoService.createABTest(
            testName: "Title Optimization Test",
            variants: variants,
            trafficSplit: trafficSplit
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { result in
                // Then
                XCTAssertFalse(result.testID.isEmpty)
                XCTAssertEqual(result.testName, "Title Optimization Test")
                XCTAssertEqual(result.variants.count, 2)
                XCTAssertEqual(result.trafficSplit, trafficSplit)
                XCTAssertEqual(result.status, .running)
                XCTAssertNotNil(result.startedAt)
                XCTAssertTrue(result.createdAt <= Date())
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testMonitorABTest() {
        // Given
        let testID = "test_123"
        let expectation = XCTestExpectation(description: "A/B test monitoring produces results")
        expectation.expectedFulfillmentCount = 1
        
        // When
        asoService.monitorABTest(testID: testID)
            .prefix(1) // Only take the first monitoring result
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.testID, testID)
                    XCTAssertFalse(result.variantPerformance.isEmpty)
                    XCTAssertTrue(ABTestRecommendedAction.allCases.contains(result.recommendedAction))
                    XCTAssertTrue(result.checkedAt <= Date())
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConcludeABTest() {
        // Given
        let testID = "test_conclusion_123"
        let winningVariant = "variant_a"
        let expectation = XCTestExpectation(description: "A/B test conclusion completes")
        
        // When
        asoService.concludeABTest(testID: testID, winningVariant: winningVariant)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { result in
                    // Then
                    XCTAssertEqual(result.testID, testID)
                    XCTAssertEqual(result.winningVariant, winningVariant)
                    XCTAssertFalse(result.finalResults.isEmpty)
                    XCTAssertGreaterThanOrEqual(result.improvementPercentage, 0)
                    XCTAssertTrue(result.concludedAt <= Date())
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Metadata Optimization Tests
    
    func testOptimizeAppTitle() {
        // Given
        let currentTitle = "HobbyistSwiftUI"
        let keywords = ["fitness", "classes", "booking", "workout"]
        let characterLimit = 30
        
        let expectation = XCTestExpectation(description: "Title optimization completes")
        
        // When
        asoService.optimizeAppTitle(
            currentTitle: currentTitle,
            keywords: keywords,
            characterLimit: characterLimit
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { result in
                // Then
                XCTAssertEqual(result.originalTitle, currentTitle)
                XCTAssertFalse(result.optimizedTitles.isEmpty)
                XCTAssertFalse(result.keywordsIncorporated.isEmpty)
                XCTAssertLessThanOrEqual(result.characterCount, characterLimit)
                XCTAssertGreaterThan(result.seoScore, 0)
                XCTAssertLessThanOrEqual(result.seoScore, 1.0)
                
                // Check that suggested titles incorporate keywords
                let allTitles = result.optimizedTitles.joined(separator: " ").lowercased()
                for keyword in result.keywordsIncorporated {
                    XCTAssertTrue(allTitles.contains(keyword.lowercased()))
                }
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testOptimizeDescription() {
        // Given
        let currentDescription = "A simple app for booking classes."
        let keywords = ["fitness", "workout", "health", "classes"]
        let callToActions = ["Download now", "Start your journey", "Book today"]
        
        let expectation = XCTestExpectation(description: "Description optimization completes")
        
        // When
        asoService.optimizeDescription(
            currentDescription: currentDescription,
            keywords: keywords,
            callToActions: callToActions
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { result in
                // Then
                XCTAssertEqual(result.originalDescription, currentDescription)
                XCTAssertFalse(result.optimizedDescription.isEmpty)
                XCTAssertGreaterThan(result.keywordDensity, 0)
                XCTAssertLessThanOrEqual(result.keywordDensity, 1.0)
                XCTAssertGreaterThan(result.readabilityScore, 0)
                XCTAssertLessThanOrEqual(result.readabilityScore, 1.0)
                XCTAssertGreaterThan(result.ctaStrength, 0)
                XCTAssertLessThanOrEqual(result.ctaStrength, 1.0)
                
                // Check that optimized description is longer and more informative
                XCTAssertGreaterThan(result.optimizedDescription.count, currentDescription.count)
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testOptimizeScreenshots() {
        // Given
        let currentScreenshots = [
            Screenshot(deviceType: .iPhone6_7, imagePath: "/screenshots/home.png", order: 1, locale: "en-US"),
            Screenshot(deviceType: .iPhone6_7, imagePath: "/screenshots/classes.png", order: 2, locale: "en-US")
        ]
        let targetAudience = TargetAudience(
            demographics: ["25-45", "health-conscious"],
            interests: ["fitness", "wellness", "classes"],
            behavior: ["mobile-first", "social-sharing"]
        )
        
        let expectation = XCTestExpectation(description: "Screenshot optimization completes")
        
        // When
        asoService.optimizeScreenshots(
            currentScreenshots: currentScreenshots,
            targetAudience: targetAudience
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { result in
                // Then
                XCTAssertEqual(result.originalScreenshots.count, currentScreenshots.count)
                XCTAssertEqual(result.optimizedScreenshots.count, currentScreenshots.count)
                XCTAssertFalse(result.improvements.isEmpty)
                XCTAssertGreaterThan(result.expectedImprovements.conversionIncrease, 0)
                XCTAssertGreaterThan(result.expectedImprovements.engagementIncrease, 0)
                XCTAssertGreaterThan(result.expectedImprovements.visualAppealScore, 0)
                XCTAssertLessThanOrEqual(result.expectedImprovements.visualAppealScore, 1.0)
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Performance Tracking Tests
    
    func testTrackASOPerformance() {
        // Given
        let timeRange = DateInterval(start: Date().addingTimeInterval(-86400 * 7), end: Date())
        let expectation = XCTestExpectation(description: "ASO performance tracking completes")
        
        // When
        asoService.trackASOPerformance(timeRange: timeRange)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                },
                receiveValue: { report in
                    // Then
                    XCTAssertEqual(report.timeRange, timeRange)
                    XCTAssertFalse(report.keywordPerformance.isEmpty)
                    XCTAssertNotNil(report.conversionMetrics)
                    XCTAssertNotNil(report.visibilityMetrics)
                    XCTAssertFalse(report.rankingChanges.isEmpty)
                    XCTAssertGreaterThanOrEqual(report.overallScore, 0)
                    XCTAssertLessThanOrEqual(report.overallScore, 100)
                    XCTAssertTrue(report.generatedAt <= Date())
                    
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGenerateOptimizationRecommendations() {
        // Given
        let metadata = createTestAppMetadata()
        let performanceData = createTestPerformanceData()
        
        let expectation = XCTestExpectation(description: "Optimization recommendations generated")
        
        // When
        asoService.generateOptimizationRecommendations(
            currentMetadata: metadata,
            performanceData: performanceData
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { recommendations in
                // Then
                // Recommendations can be empty if no optimizations are needed
                for recommendation in recommendations {
                    XCTAssertTrue(RecommendationType.allCases.contains(recommendation.type))
                    XCTAssertFalse(recommendation.title.isEmpty)
                    XCTAssertFalse(recommendation.description.isEmpty)
                    XCTAssertGreaterThan(recommendation.impact, 0)
                    XCTAssertLessThanOrEqual(recommendation.impact, 1.0)
                    XCTAssertGreaterThan(recommendation.effort, 0)
                    XCTAssertLessThanOrEqual(recommendation.effort, 1.0)
                    XCTAssertTrue(Priority.allCases.contains(recommendation.priority))
                }
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testABTestConfigurationError() {
        // Given - Invalid configuration with mismatched variants and traffic split
        let variants = [
            MetadataVariant(id: "control", name: "Control", title: "Test", description: nil, keywords: nil, screenshots: nil)
        ]
        let trafficSplit = [0.5, 0.5] // Two splits but only one variant
        
        let expectation = XCTestExpectation(description: "Invalid A/B test configuration handled")
        
        // When
        asoService.createABTest(
            testName: "Invalid Test",
            variants: variants,
            trafficSplit: trafficSplit
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertTrue(error.localizedDescription.contains("configuration"))
                    expectation.fulfill()
                } else {
                    XCTFail("Expected configuration error")
                }
            },
            receiveValue: { _ in
                XCTFail("Expected error, got success")
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testInvalidTrafficSplitError() {
        // Given - Traffic split doesn't sum to 1.0
        let variants = [
            MetadataVariant(id: "A", name: "Variant A", title: "Test A", description: nil, keywords: nil, screenshots: nil),
            MetadataVariant(id: "B", name: "Variant B", title: "Test B", description: nil, keywords: nil, screenshots: nil)
        ]
        let trafficSplit = [0.7, 0.7] // Sums to 1.4, not 1.0
        
        let expectation = XCTestExpectation(description: "Invalid traffic split handled")
        
        // When
        asoService.createABTest(
            testName: "Invalid Split Test",
            variants: variants,
            trafficSplit: trafficSplit
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Then
                    XCTAssertTrue(error.localizedDescription.contains("sum to 1.0"))
                    expectation.fulfill()
                } else {
                    XCTFail("Expected traffic split error")
                }
            },
            receiveValue: { _ in
                XCTFail("Expected error, got success")
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndASOWorkflow() {
        // Given
        let expectation = XCTestExpectation(description: "End-to-end ASO workflow completes")
        
        // When - Simulate a complete ASO workflow
        Publishers.CombineLatest4(
            asoService.analyzeKeywords(for: .health),
            asoService.analyzeCompetitors(appIDs: ["competitor-1", "competitor-2"]),
            asoService.optimizeAppTitle(currentTitle: "HobbyistSwiftUI", keywords: ["fitness", "classes"], characterLimit: 30),
            asoService.trackASOPerformance(timeRange: DateInterval(start: Date().addingTimeInterval(-86400), end: Date()))
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            },
            receiveValue: { keywordAnalysis, competitorAnalysis, titleOptimization, performanceReport in
                // Then
                XCTAssertNotNil(keywordAnalysis)
                XCTAssertNotNil(competitorAnalysis)
                XCTAssertNotNil(titleOptimization)
                XCTAssertNotNil(performanceReport)
                
                expectation.fulfill()
            }
        )
        .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Performance Tests
    
    func testASOServicePerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Performance measurement")
            
            asoService.analyzeKeywords(for: .health)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 10.0)
            cancellables.removeAll()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAppMetadata() -> AppMetadata {
        return AppMetadata(
            title: "HobbyistSwiftUI",
            subtitle: "Book Your Perfect Class",
            description: "Discover and book amazing classes in your area.",
            keywords: ["fitness", "classes", "booking"],
            supportURL: "https://hobbyist.app/support",
            privacyPolicyURL: "https://hobbyist.app/privacy",
            category: .health,
            contentRating: .fourPlus
        )
    }
    
    private func createTestPerformanceData() -> ASOPerformanceData {
        return ASOPerformanceData(
            conversionRate: 0.12,
            installRate: 0.08,
            keywordRankings: [
                KeywordRanking(keyword: "fitness", currentRank: 25, previousRank: 30, bestRank: 20, trackingDate: Date()),
                KeywordRanking(keyword: "classes", currentRank: 40, previousRank: 42, bestRank: 35, trackingDate: Date())
            ],
            competitorData: []
        )
    }
}

// MARK: - ASO Service Component Tests

final class ASOServiceComponentTests: XCTestCase {
    
    func testKeywordAnalyzerCreation() {
        // Given & When
        let analyzer = KeywordAnalyzer()
        
        // Then
        XCTAssertNotNil(analyzer)
    }
    
    func testCompetitorAnalyzerCreation() {
        // Given & When
        let analyzer = CompetitorAnalyzer()
        
        // Then
        XCTAssertNotNil(analyzer)
    }
    
    func testMetadataOptimizerCreation() {
        // Given & When
        let optimizer = MetadataOptimizer()
        
        // Then
        XCTAssertNotNil(optimizer)
    }
    
    func testABTestingManagerCreation() {
        // Given & When
        let manager = ABTestingManager()
        
        // Then
        XCTAssertNotNil(manager)
    }
    
    func testPerformanceTrackerCreation() {
        // Given & When
        let tracker = PerformanceTracker()
        
        // Then
        XCTAssertNotNil(tracker)
    }
}

// MARK: - Data Model Tests

final class ASODataModelTests: XCTestCase {
    
    func testTrendingKeywordInitialization() {
        // Given
        let keyword = TrendingKeyword(
            keyword: "fitness app",
            volume: 50000,
            trend: .rising,
            difficulty: 0.8
        )
        
        // Then
        XCTAssertEqual(keyword.keyword, "fitness app")
        XCTAssertEqual(keyword.volume, 50000)
        XCTAssertEqual(keyword.trend, .rising)
        XCTAssertEqual(keyword.difficulty, 0.8)
    }
    
    func testMetadataVariantInitialization() {
        // Given
        let variant = MetadataVariant(
            id: "test_variant",
            name: "Test Variant",
            title: "Test Title",
            description: "Test Description",
            keywords: ["test", "variant"],
            screenshots: nil
        )
        
        // Then
        XCTAssertEqual(variant.id, "test_variant")
        XCTAssertEqual(variant.name, "Test Variant")
        XCTAssertEqual(variant.title, "Test Title")
        XCTAssertEqual(variant.description, "Test Description")
        XCTAssertEqual(variant.keywords, ["test", "variant"])
        XCTAssertNil(variant.screenshots)
    }
    
    func testTargetAudienceInitialization() {
        // Given
        let audience = TargetAudience(
            demographics: ["25-45", "college-educated"],
            interests: ["fitness", "technology"],
            behavior: ["mobile-first", "price-conscious"]
        )
        
        // Then
        XCTAssertEqual(audience.demographics, ["25-45", "college-educated"])
        XCTAssertEqual(audience.interests, ["fitness", "technology"])
        XCTAssertEqual(audience.behavior, ["mobile-first", "price-conscious"])
    }
}