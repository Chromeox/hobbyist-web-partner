import Foundation
import SwiftUI

// MARK: - Centralized Error Handling Service

@MainActor
final class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Handle any error with appropriate user feedback
    func handleError(_ error: Error, context: String = "") {
        let appError = convertToAppError(error, context: context)
        
        // Log error
        logError(appError, context: context)
        
        // Show user feedback
        currentError = appError
        showErrorAlert = true
        
        // Trigger haptic feedback
        HapticFeedbackService.shared.playError()
        
        // Analytics logging (in production)
        logErrorToAnalytics(appError, context: context)
    }
    
    /// Handle payment-specific errors with retry logic
    func handlePaymentError(_ error: Error, onRetry: @escaping () -> Void) {
        let paymentError = convertToPaymentError(error)
        
        // Log payment error
        logError(paymentError, context: "Payment Processing")
        
        // Show payment-specific error handling
        currentError = paymentError
        showErrorAlert = true
        
        // Store retry action
        self.retryAction = onRetry
    }
    
    /// Handle booking errors with context-aware messaging
    func handleBookingError(_ error: Error, bookingContext: BookingContext) {
        let bookingError = convertToBookingError(error, context: bookingContext)
        
        logError(bookingError, context: "Booking: \(bookingContext.description)")
        
        currentError = bookingError
        showErrorAlert = true
    }
    
    /// Clear current error
    func clearError() {
        currentError = nil
        showErrorAlert = false
        retryAction = nil
    }
    
    /// Get user-friendly error message
    func getUserFriendlyMessage(for error: Error) -> String {
        let appError = convertToAppError(error)
        return appError.userMessage
    }
    
    /// Check if error is recoverable
    func isRecoverable(_ error: Error) -> Bool {
        let appError = convertToAppError(error)
        return appError.isRecoverable
    }
    
    // MARK: - Private Properties
    
    private var retryAction: (() -> Void)?
    
    // MARK: - Error Conversion Methods
    
    private func convertToAppError(_ error: Error, context: String = "") -> AppError {
        // Convert various error types to AppError
        if let appError = error as? AppError {
            return appError
        }

        if let bookingError = error as? BookingError {
            // Convert standalone BookingError to AppError.BookingError
            switch bookingError {
            case .classFullyBooked:
                return AppError.booking(.classFullyBooked)
            case .cancellationNotAllowed:
                return AppError.booking(.cancellationNotAllowed)
            case .modificationNotAllowed:
                return AppError.booking(.modificationNotAllowed)
            case .invalidBookingRequest, .bookingNotFound:
                return AppError.booking(.invalidBooking)
            case .userNotAuthenticated:
                return AppError.authentication(.unauthorized)
            case .insufficientCredits:
                return AppError.credit(.insufficientCredits)
            case .invalidPayment, .paymentProcessingFailed:
                return AppError.payment(.paymentFailed(bookingError.localizedDescription))
            case .networkError(let message):
                return AppError.network(.networkError(message))
            }
        }

        if let paymentError = error as? PaymentError {
            // Convert standalone PaymentError to AppError.PaymentError
            switch paymentError {
            case .failed(let message):
                return AppError.payment(.paymentFailed(message))
            case .invalidAmount:
                return AppError.payment(.invalidPaymentMethod)
            case .networkError:
                return AppError.network(.networkError("Network error during payment"))
            case .cancelled, .configurationError:
                return AppError.payment(.paymentFailed(paymentError.localizedDescription))
            }
        }

        if let creditError = error as? CreditServiceError {
            // Convert CreditServiceError to appropriate AppError
            switch creditError {
            case .userNotAuthenticated:
                return AppError.authentication(.unauthorized)
            case .paymentSetupFailed(let message), .purchaseFailed(let message):
                return AppError.payment(.paymentFailed(message))
            }
        }

        // Network errors
        if let urlError = error as? URLError {
            return convertURLError(urlError, context: context)
        }

        // Supabase errors
        if error.localizedDescription.contains("network") {
            return AppError.network(.connectionFailed("Network connection issue in \(context)"))
        }

        // Default unknown error
        return AppError.unknown("Error in \(context): \(error.localizedDescription)")
    }
    
    private func convertToPaymentError(_ error: Error) -> AppError {
        if let paymentError = error as? PaymentError {
            // Convert standalone PaymentError to AppError.PaymentError
            switch paymentError {
            case .failed(let message):
                return AppError.payment(.paymentFailed(message))
            case .invalidAmount:
                return AppError.payment(.invalidPaymentMethod)
            case .networkError:
                return AppError.network(.networkError("Network error during payment"))
            case .cancelled, .configurationError:
                return AppError.payment(.paymentFailed(paymentError.localizedDescription))
            }
        }

        // Stripe-specific error handling
        if error.localizedDescription.contains("card") {
            return AppError.payment(.paymentFailed("Your card was declined. Please try a different payment method."))
        }

        if error.localizedDescription.contains("insufficient") {
            return AppError.credit(.insufficientCredits)
        }

        return AppError.payment(.paymentFailed(error.localizedDescription))
    }
    
    private func convertToBookingError(_ error: Error, context: BookingContext) -> AppError {
        if let bookingError = error as? BookingError {
            // Convert standalone BookingError to AppError.BookingError
            switch bookingError {
            case .classFullyBooked:
                return AppError.booking(.classFullyBooked)
            case .cancellationNotAllowed:
                return AppError.booking(.cancellationNotAllowed)
            case .modificationNotAllowed:
                return AppError.booking(.modificationNotAllowed)
            case .invalidBookingRequest, .bookingNotFound:
                return AppError.booking(.invalidBooking)
            case .userNotAuthenticated:
                return AppError.authentication(.unauthorized)
            case .insufficientCredits:
                return AppError.credit(.insufficientCredits)
            case .invalidPayment, .paymentProcessingFailed:
                return AppError.payment(.paymentFailed(bookingError.localizedDescription))
            case .networkError(let message):
                return AppError.network(.networkError(message))
            }
        }

        // Context-specific error handling
        switch context {
        case .classSelection:
            if error.localizedDescription.contains("availability") {
                return AppError.booking(.classFullyBooked)
            }
        case .paymentProcessing:
            return convertToPaymentError(error)
        case .confirmation:
            return AppError.network(.connectionFailed("Booking confirmation failed"))
        case .modification:
            return AppError.booking(.modificationNotAllowed)
        case .cancellation:
            return AppError.booking(.cancellationNotAllowed)
        }

        return AppError.booking(.invalidBooking)
    }
    
    private func convertURLError(_ error: URLError, context: String) -> AppError {
        switch error.code {
        case .notConnectedToInternet:
            return AppError.network(.noConnection)
        case .timedOut:
            return AppError.network(.timeout)
        case .cannotFindHost, .cannotConnectToHost:
            return AppError.network(.serverUnavailable)
        default:
            return AppError.network(.connectionFailed("Connection failed in \(context)"))
        }
    }
    
    // MARK: - Logging Methods
    
    private func logError(_ error: AppError, context: String) {
        let logEntry = ErrorLogEntry(
            error: error,
            context: context,
            timestamp: Date(),
            userId: getCurrentUserId()
        )
        
        errorHistory.insert(logEntry, at: 0)
        
        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory = Array(errorHistory.prefix(50))
        }
        
        // Print to console in debug mode
        #if DEBUG
        print("🔥 Error: \(error.title) - \(error.userMessage)")
        print("   Context: \(context)")
        print("   Technical: \(error.technicalMessage)")
        #endif
    }
    
    private func logErrorToAnalytics(_ error: AppError, context: String) {
        // In production, send to analytics service
        let analyticsData: [String: Any] = [
            "error_type": error.category,
            "error_title": error.title,
            "context": context,
            "is_recoverable": error.isRecoverable,
            "user_id": getCurrentUserId() ?? "anonymous"
        ]
        
        // TODO: Send to analytics service (Firebase, Mixpanel, etc.)
        print("📊 Analytics: \(analyticsData)")
    }
    
    private func getCurrentUserId() -> String? {
        return SimpleSupabaseService.shared.currentUser?.id
    }
}

// MARK: - Supporting Error Types

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverUnavailable
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .timeout:
            return "Request timed out. Please try again"
        case .serverUnavailable:
            return "Server is temporarily unavailable"
        case .connectionFailed:
            return "Connection failed. Please check your internet"
        }
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case sessionExpired
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}

enum BookingContext {
    case classSelection
    case paymentProcessing
    case confirmation
    case modification
    case cancellation
    
    var description: String {
        switch self {
        case .classSelection: return "Class Selection"
        case .paymentProcessing: return "Payment Processing"
        case .confirmation: return "Booking Confirmation"
        case .modification: return "Booking Modification"
        case .cancellation: return "Booking Cancellation"
        }
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String
    let timestamp: Date
    let userId: String?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorService = ErrorHandlingService.shared
    
    var body: some View {
        EmptyView()
            .alert(
                errorService.currentError?.title ?? "Error",
                isPresented: $errorService.showErrorAlert,
                presenting: errorService.currentError
            ) { error in
                if error.isRecoverable {
                    Button("Try Again") {
                        errorService.clearError()
                        // Retry action would be called here
                    }
                    
                    Button("Cancel", role: .cancel) {
                        errorService.clearError()
                    }
                } else {
                    Button("OK") {
                        errorService.clearError()
                    }
                }
            } message: { error in
                Text(error.userMessage)
            }
    }
}

// MARK: - View Extension for Error Handling

extension View {
    func handleErrors() -> some View {
        self.overlay(ErrorAlertView())
    }
}