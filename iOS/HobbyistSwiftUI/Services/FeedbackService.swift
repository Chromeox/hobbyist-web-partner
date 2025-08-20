import Foundation
import UIKit
import Combine
import os.log

// MARK: - Feedback Service

final class FeedbackService: FeedbackServiceProtocol {
    @Published var currentFeedbackType: FeedbackType = .general
    
    private let networkService: NetworkServiceProtocol
    private let logger = Logger(subsystem: "com.hobbyist.app", category: "Feedback")
    private var cancellables = Set<AnyCancellable>()
    private let feedbackQueue = DispatchQueue(label: "com.hobbyist.feedback", qos: .userInitiated)
    
    init(networkService: NetworkServiceProtocol? = nil) {
        self.networkService = networkService ?? ServiceContainer.shared.networkService
    }
    
    func submitFeedback(_ feedback: FeedbackModel) async throws {
        logger.info("Submitting feedback: \(feedback.title)")
        
        // Record breadcrumb for tracking
        ServiceContainer.shared.crashReportingService?.recordBreadcrumb(
            "Feedback submitted",
            metadata: [
                "type": feedback.type,
                "title": feedback.title,
                "has_attachments": !feedback.attachments.isEmpty
            ]
        )
        
        // Track analytics event
        ServiceContainer.shared.analyticsService?.trackEvent(
            AnalyticsEvent(
                name: "feedback_submitted",
                category: "feedback",
                action: "submit",
                label: String(describing: feedback.type),
                value: nil
            ),
            parameters: [
                "feedback_id": feedback.id,
                "type": String(describing: feedback.type),
                "has_rating": feedback.rating != nil,
                "attachments_count": feedback.attachments.count
            ]
        )
        
        // Submit to backend
        let endpoint = Endpoint(
            path: "/api/feedback",
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: try? JSONEncoder().encode(feedback),
            queryItems: nil
        )
        
        let _: FeedbackModel = try await networkService.request(endpoint)
        
        logger.info("Feedback submitted successfully: \(feedback.id)")
    }
    
    func reportBug(_ bug: BugReport) async throws {
        logger.info("Reporting bug: \(bug.title)")
        
        // Create feedback model from bug report
        let feedback = FeedbackModel(
            id: UUID().uuidString,
            userId: ServiceContainer.shared.authService?.currentUser.value?.id ?? "anonymous",
            type: .bug,
            title: bug.title,
            description: formatBugDescription(bug),
            rating: nil,
            category: bug.severity.rawValue,
            attachments: [],
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            response: nil,
            respondedAt: nil
        )
        
        // Submit feedback
        try await submitFeedback(feedback)
        
        // Upload screenshots if available
        for (index, screenshot) in bug.screenshots.enumerated() {
            try await attachScreenshot(screenshot, to: feedback.id)
        }
        
        // Log to crash reporting for tracking
        ServiceContainer.shared.crashReportingService?.recordBreadcrumb(
            "Bug reported: \(bug.title)",
            metadata: [
                "severity": bug.severity.rawValue,
                "reproducible": bug.reproducible,
                "steps_count": bug.steps.count
            ]
        )
    }
    
    func suggestFeature(_ feature: FeatureRequest) async throws {
        logger.info("Suggesting feature: \(feature.title)")
        
        let feedback = FeedbackModel(
            id: UUID().uuidString,
            userId: ServiceContainer.shared.authService?.currentUser.value?.id ?? "anonymous",
            type: .feature,
            title: feature.title,
            description: formatFeatureDescription(feature),
            rating: nil,
            category: feature.category,
            attachments: [],
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            response: nil,
            respondedAt: nil
        )
        
        try await submitFeedback(feedback)
    }
    
    func rateExperience(_ rating: ExperienceRating) async throws {
        logger.info("Rating experience: \(rating.overallRating)/5")
        
        let feedback = FeedbackModel(
            id: UUID().uuidString,
            userId: ServiceContainer.shared.authService?.currentUser.value?.id ?? "anonymous",
            type: .rating,
            title: "App Experience Rating",
            description: formatRatingDescription(rating),
            rating: rating.overallRating,
            category: "experience",
            attachments: [],
            status: .pending,
            createdAt: Date(),
            updatedAt: Date(),
            response: nil,
            respondedAt: nil
        )
        
        try await submitFeedback(feedback)
        
        // Track rating in analytics
        ServiceContainer.shared.analyticsService?.trackEvent(
            AnalyticsEvent(
                name: "experience_rated",
                category: "feedback",
                action: "rate",
                label: nil,
                value: Double(rating.overallRating)
            ),
            parameters: [
                "overall_rating": rating.overallRating,
                "would_recommend": rating.wouldRecommend,
                "categories_rated": rating.categoryRatings.count
            ]
        )
    }
    
    func reportError(_ error: AppError?) {
        guard let error = error else { return }
        
        Task {
            do {
                let bug = BugReport(
                    title: "Automatic Error Report",
                    description: error.localizedDescription,
                    severity: .major,
                    reproducible: false,
                    steps: ["Error occurred during app usage"],
                    expectedBehavior: "No error should occur",
                    actualBehavior: error.errorDescription ?? "Unknown error",
                    deviceInfo: getDeviceInfo(),
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                    screenshots: []
                )
                
                try await reportBug(bug)
            } catch {
                logger.error("Failed to report error: \(error.localizedDescription)")
            }
        }
    }
    
    func attachScreenshot(_ imageData: Data, to feedbackId: String) async throws {
        logger.info("Attaching screenshot to feedback: \(feedbackId)")
        
        let endpoint = Endpoint(
            path: "/api/feedback/\(feedbackId)/attachments",
            method: .post,
            headers: ["Content-Type": "image/png"],
            body: imageData,
            queryItems: nil
        )
        
        let attachmentURL: URL = try await networkService.upload(imageData, to: endpoint)
        
        logger.info("Screenshot attached successfully: \(attachmentURL)")
    }
    
    func getFeedbackHistory() async throws -> [FeedbackModel] {
        logger.info("Fetching feedback history")
        
        guard let userId = ServiceContainer.shared.authService?.currentUser.value?.id else {
            throw AppError.authenticationError("User not authenticated")
        }
        
        let endpoint = Endpoint(
            path: "/api/feedback",
            method: .get,
            headers: nil,
            body: nil,
            queryItems: [URLQueryItem(name: "userId", value: userId)]
        )
        
        let feedbackList: [FeedbackModel] = try await networkService.request(endpoint)
        
        logger.info("Fetched \(feedbackList.count) feedback items")
        return feedbackList
    }
    
    // MARK: - Helper Methods
    
    private func formatBugDescription(_ bug: BugReport) -> String {
        var description = bug.description + "\n\n"
        description += "**Severity:** \(bug.severity.rawValue)\n"
        description += "**Reproducible:** \(bug.reproducible ? "Yes" : "No")\n\n"
        
        if !bug.steps.isEmpty {
            description += "**Steps to Reproduce:**\n"
            for (index, step) in bug.steps.enumerated() {
                description += "\(index + 1). \(step)\n"
            }
            description += "\n"
        }
        
        description += "**Expected Behavior:**\n\(bug.expectedBehavior)\n\n"
        description += "**Actual Behavior:**\n\(bug.actualBehavior)\n\n"
        
        description += "**Device Info:**\n"
        description += "- Model: \(bug.deviceInfo.model)\n"
        description += "- OS: \(bug.deviceInfo.osVersion)\n"
        description += "- App Version: \(bug.deviceInfo.appVersion)\n"
        
        return description
    }
    
    private func formatFeatureDescription(_ feature: FeatureRequest) -> String {
        var description = feature.description + "\n\n"
        description += "**Priority:** \(feature.priority.rawValue)\n"
        description += "**Category:** \(feature.category)\n\n"
        description += "**Use Case:**\n\(feature.useCase)\n"
        
        if let workaround = feature.currentWorkaround {
            description += "\n**Current Workaround:**\n\(workaround)"
        }
        
        return description
    }
    
    private func formatRatingDescription(_ rating: ExperienceRating) -> String {
        var description = "**Overall Rating:** \(rating.overallRating)/5\n"
        description += "**Would Recommend:** \(rating.wouldRecommend ? "Yes" : "No")\n\n"
        
        if !rating.categoryRatings.isEmpty {
            description += "**Category Ratings:**\n"
            for (category, score) in rating.categoryRatings {
                description += "- \(category): \(score)/5\n"
            }
            description += "\n"
        }
        
        if !rating.likes.isEmpty {
            description += "**What I Like:**\n"
            for like in rating.likes {
                description += "- \(like)\n"
            }
            description += "\n"
        }
        
        if !rating.improvements.isEmpty {
            description += "**Suggested Improvements:**\n"
            for improvement in rating.improvements {
                description += "- \(improvement)\n"
            }
            description += "\n"
        }
        
        if let comments = rating.additionalComments {
            description += "**Additional Comments:**\n\(comments)"
        }
        
        return description
    }
    
    private func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo
        
        return DeviceInfo(
            model: device.modelName,
            osVersion: "\(device.systemName) \(device.systemVersion)",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            screenSize: "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))",
            networkType: getNetworkType(),
            batteryLevel: device.batteryLevel,
            availableStorage: getAvailableStorage()
        )
    }
    
    private func getNetworkType() -> String {
        // This would use Reachability or similar library in production
        return "WiFi" // Placeholder
    }
    
    private func getAvailableStorage() -> Int64 {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(
                forPath: NSHomeDirectory() as String
            )
            let freeSpace = (systemAttributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            return freeSpace
        } catch {
            return 0
        }
    }
}

// MARK: - Mock Feedback Service

final class MockFeedbackService: FeedbackServiceProtocol {
    @Published var currentFeedbackType: FeedbackType = .general
    
    private var submittedFeedback: [FeedbackModel] = []
    private var reportedBugs: [BugReport] = []
    private var suggestedFeatures: [FeatureRequest] = []
    private var experienceRatings: [ExperienceRating] = []
    private var attachedScreenshots: [(feedbackId: String, data: Data)] = []
    
    func submitFeedback(_ feedback: FeedbackModel) async throws {
        submittedFeedback.append(feedback)
        print("🧪 Mock Feedback Submitted: \(feedback.title)")
    }
    
    func reportBug(_ bug: BugReport) async throws {
        reportedBugs.append(bug)
        print("🧪 Mock Bug Reported: \(bug.title) - Severity: \(bug.severity.rawValue)")
    }
    
    func suggestFeature(_ feature: FeatureRequest) async throws {
        suggestedFeatures.append(feature)
        print("🧪 Mock Feature Suggested: \(feature.title) - Priority: \(feature.priority.rawValue)")
    }
    
    func rateExperience(_ rating: ExperienceRating) async throws {
        experienceRatings.append(rating)
        print("🧪 Mock Experience Rated: \(rating.overallRating)/5")
    }
    
    func reportError(_ error: AppError?) {
        if let error = error {
            print("🧪 Mock Error Reported: \(error.localizedDescription)")
        }
    }
    
    func attachScreenshot(_ imageData: Data, to feedbackId: String) async throws {
        attachedScreenshots.append((feedbackId, imageData))
        print("🧪 Mock Screenshot Attached to feedback: \(feedbackId) - Size: \(imageData.count) bytes")
    }
    
    func getFeedbackHistory() async throws -> [FeedbackModel] {
        print("🧪 Mock Feedback History Requested - Returning \(submittedFeedback.count) items")
        return submittedFeedback
    }
    
    // Test helper methods
    func reset() {
        submittedFeedback.removeAll()
        reportedBugs.removeAll()
        suggestedFeatures.removeAll()
        experienceRatings.removeAll()
        attachedScreenshots.removeAll()
    }
    
    func getSubmittedFeedback() -> [FeedbackModel] {
        return submittedFeedback
    }
    
    func getReportedBugs() -> [BugReport] {
        return reportedBugs
    }
}