import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case authenticationError(String)
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case insufficientCredits
    case bookingConflict
    case classFull
    case paymentFailed(String)
    case dataCorrupted
    case unauthorized
    case serverError(Int)
    case validationError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .insufficientCredits:
            return "Insufficient credits for this booking"
        case .bookingConflict:
            return "You already have a booking at this time"
        case .classFull:
            return "This class is full"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .dataCorrupted:
            return "Data error occurred. Please try again"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .serverError(let code):
            return "Server error (\(code))"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .unknown(let message):
            return message.isEmpty ? "An unexpected error occurred" : message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .authenticationError, .invalidCredentials:
            return "Please check your credentials and try again"
        case .emailAlreadyInUse:
            return "Try logging in or use a different email"
        case .weakPassword:
            return "Use a stronger password with at least 8 characters"
        case .insufficientCredits:
            return "Purchase more credits to book this class"
        case .bookingConflict:
            return "Choose a different class time"
        case .classFull:
            return "Join the waitlist or choose another class"
        case .paymentFailed:
            return "Check your payment details and try again"
        case .unauthorized:
            return "Please log in to continue"
        case .serverError:
            return "Please try again later"
        default:
            return "Please try again"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError:
            return true
        default:
            return false
        }
    }
}