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
            return AppError.booking(bookingError, context: context)
        }
        
        if let paymentError = error as? PaymentError {
            return AppError.payment(paymentError, context: context)
        }
        
        if let creditError = error as? CreditServiceError {
            return AppError.credit(creditError, context: context)
        }
        
        // Network errors
        if let urlError = error as? URLError {
            return convertURLError(urlError, context: context)
        }
        
        // Supabase errors
        if error.localizedDescription.contains("network") {
            return AppError.network(.connectionFailed, context: context)
        }
        
        // Default unknown error
        return AppError.unknown(error.localizedDescription, context: context)
    }
    
    private func convertToPaymentError(_ error: Error) -> AppError {
        if let paymentError = error as? PaymentError {
            return AppError.payment(paymentError, context: "Payment Processing")
        }
        
        // Stripe-specific error handling
        if error.localizedDescription.contains("card") {
            return AppError.payment(.paymentFailed("Your card was declined. Please try a different payment method."), context: "Card Processing")
        }
        
        if error.localizedDescription.contains("insufficient") {
            return AppError.payment(.insufficientCredits, context: "Payment Processing")
        }
        
        return AppError.payment(.unknownError(error.localizedDescription), context: "Payment Processing")
    }
    
    private func convertToBookingError(_ error: Error, context: BookingContext) -> AppError {
        if let bookingError = error as? BookingError {
            return AppError.booking(bookingError, context: context.description)
        }
        
        // Context-specific error handling
        switch context {
        case .classSelection:
            if error.localizedDescription.contains("availability") {
                return AppError.booking(.classFullyBooked, context: "Class Selection")
            }
        case .paymentProcessing:
            return convertToPaymentError(error)
        case .confirmation:
            return AppError.booking(.networkError, context: "Booking Confirmation")
        case .modification:
            return AppError.booking(.modificationNotAllowed, context: "Booking Modification")
        case .cancellation:
            return AppError.booking(.cancellationNotAllowed, context: "Booking Cancellation")
        }
        
        return AppError.booking(.unknown(error.localizedDescription), context: context.description)
    }
    
    private func convertURLError(_ error: URLError, context: String) -> AppError {
        switch error.code {
        case .notConnectedToInternet:
            return AppError.network(.noConnection, context: context)
        case .timedOut:
            return AppError.network(.timeout, context: context)
        case .cannotFindHost, .cannotConnectToHost:
            return AppError.network(.serverUnavailable, context: context)
        default:
            return AppError.network(.connectionFailed, context: context)
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
        let analyticsData = [
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
        return SimpleSupabaseService.shared.currentUser?.id.uuidString
    }
}

// MARK: - App Error Types

enum AppError: LocalizedError, Identifiable {
    case booking(BookingError, context: String)
    case payment(PaymentError, context: String)
    case credit(CreditServiceError, context: String)
    case network(NetworkError, context: String)
    case authentication(AuthError, context: String)
    case unknown(String, context: String)
    
    var id: String {
        return "\(category)_\(title)_\(UUID().uuidString)"
    }
    
    var title: String {
        switch self {
        case .booking(let error, _):
            return "Booking Error"
        case .payment(let error, _):
            return "Payment Error"
        case .credit(let error, _):
            return "Credits Error"
        case .network(let error, _):
            return "Connection Error"
        case .authentication(let error, _):
            return "Authentication Error"
        case .unknown(_, _):
            return "Unexpected Error"
        }
    }
    
    var userMessage: String {
        switch self {
        case .booking(let error, _):
            return error.localizedDescription ?? "Something went wrong with your booking"
        case .payment(let error, _):
            return error.localizedDescription ?? "Payment processing failed"
        case .credit(let error, _):
            return error.localizedDescription ?? "Credits error occurred"
        case .network(let error, _):
            return error.localizedDescription
        case .authentication(let error, _):
            return error.localizedDescription
        case .unknown(let message, _):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var technicalMessage: String {
        switch self {
        case .booking(let error, let context):
            return "Booking error in \(context): \(error)"
        case .payment(let error, let context):
            return "Payment error in \(context): \(error)"
        case .credit(let error, let context):
            return "Credit error in \(context): \(error)"
        case .network(let error, let context):
            return "Network error in \(context): \(error)"
        case .authentication(let error, let context):
            return "Auth error in \(context): \(error)"
        case .unknown(let message, let context):
            return "Unknown error in \(context): \(message)"
        }
    }
    
    var category: String {
        switch self {
        case .booking: return "booking"
        case .payment: return "payment"
        case .credit: return "credit"
        case .network: return "network"
        case .authentication: return "auth"
        case .unknown: return "unknown"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .booking(let error, _):
            switch error {
            case .classFullyBooked, .userNotAuthenticated, .bookingNotFound:
                return false
            case .invalidPayment, .networkError:
                return true
            default:
                return true
            }
        case .payment(let error, _):
            switch error {
            case .userCancelled:
                return false
            case .networkError, .paymentFailed, .stripeConfigurationError:
                return true
            case .insufficientCredits, .invalidAmount:
                return false
            default:
                return true
            }
        case .network:
            return true
        case .credit(let error, _):
            switch error {
            case .userNotAuthenticated:
                return false
            default:
                return true
            }
        case .authentication:
            return false
        case .unknown:
            return true
        }
    }
    
    var suggestedAction: String {
        switch self {
        case .booking(let error, _):
            switch error {
            case .classFullyBooked:
                return "Try joining the waitlist or select a different time slot"
            case .userNotAuthenticated:
                return "Please sign in to continue"
            case .invalidPayment:
                return "Check your payment method and try again"
            case .networkError:
                return "Check your internet connection and try again"
            default:
                return "Please try again or contact support"
            }
        case .payment(let error, _):
            switch error {
            case .userCancelled:
                return "Complete the payment to finish your booking"
            case .insufficientCredits:
                return "Purchase more credits or use a different payment method"
            case .paymentFailed:
                return "Try a different payment method"
            case .networkError:
                return "Check your connection and try again"
            default:
                return "Please try again or contact support"
            }
        case .network:
            return "Check your internet connection and try again"
        case .credit:
            return "Please try again or contact support"
        case .authentication:
            return "Please sign in again"
        case .unknown:
            return "Please try again or contact support if the problem persists"
        }
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