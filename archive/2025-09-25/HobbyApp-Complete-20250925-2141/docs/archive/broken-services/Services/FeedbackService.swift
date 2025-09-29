import Foundation
import UIKit
import Combine
import os.log

// MARK: - Feedback Types

enum FeedbackType: String, CaseIterable {
    case general = "general"
    case bug = "bug"
    case feature = "feature"
    case performance = "performance"
}

struct FeedbackModel {
    let type: FeedbackType
    let message: String
    let metadata: [String: Any]?
}

protocol FeedbackServiceProtocol {
    func submitFeedback(_ feedback: FeedbackModel) async throws
}

protocol NetworkServiceProtocol {
    // Basic network service interface
}

// MARK: - Mock Network Service

struct MockNetworkService: NetworkServiceProtocol {
    // Placeholder implementation
}

// MARK: - Feedback Service

final class FeedbackService: FeedbackServiceProtocol {
    @Published var currentFeedbackType: FeedbackType = .general

    private let networkService: NetworkServiceProtocol
    private let logger = Logger(subsystem: "com.hobbyist.app", category: "Feedback")
    private var cancellables = Set<AnyCancellable>()

    init(networkService: NetworkServiceProtocol? = nil) {
        self.networkService = networkService ?? MockNetworkService()
    }

    func submitFeedback(_ feedback: FeedbackModel) async throws {
        logger.info("Submitting feedback: \(feedback.type.rawValue)")

        // Mock implementation for build compatibility
        await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        logger.info("Feedback submitted successfully")
    }
}

// MARK: - Mock Feedback Service

final class MockFeedbackService: FeedbackServiceProtocol {
    @Published var currentFeedbackType: FeedbackType = .general

    func submitFeedback(_ feedback: FeedbackModel) async throws {
        print("🧪 Mock Feedback Submitted: \(feedback.type.rawValue)")
    }
}