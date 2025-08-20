import Foundation
import Combine
import AuthenticationServices

protocol AuthServiceProtocol {
    var isAuthenticated: CurrentValueSubject<Bool, Never> { get }
    var currentUser: CurrentValueSubject<User?, Never> { get }
    
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, metadata: [String: Any]?) async throws -> User
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User
    func signOut() async throws
    func resetPassword(email: String) async throws
    func updateProfile(updates: ProfileUpdate) async throws -> User
    func refreshSession() async throws
    func checkAuthStatus() async
}

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarURL: String?
    let phoneNumber: String?
    let createdAt: Date
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
        case metadata
    }
}

struct ProfileUpdate {
    var fullName: String?
    var avatarURL: String?
    var phoneNumber: String?
    var metadata: [String: Any]?
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .networkError:
            return "Network connection error"
        case .unknownError(let message):
            return message
        }
    }
}