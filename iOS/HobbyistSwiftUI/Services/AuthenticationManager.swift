import Foundation
import SwiftUI
import Combine
import Supabase
import AuthenticationServices

// MARK: - User Model
struct AppUser: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String?
    let avatarURL: String?
    let phoneNumber: String?
    let createdAt: Date
    let metadata: [String: String]?
    
    init(id: String, email: String, name: String?, createdAt: Date) {
        self.id = id
        self.email = email
        self.fullName = name
        self.avatarURL = nil
        self.phoneNumber = nil
        self.createdAt = createdAt
        self.metadata = nil
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case userNotFound
    case unknown(String)
    
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
        case .userNotFound:
            return "No account found with this email"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var authError: AuthError?
    
    // Form state for UI binding
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    
    private var supabase: SupabaseClient? {
        return ServiceContainer.shared.supabaseClient
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Methods
    
    func checkAuthStatus() async {
        guard let supabase = supabase else { return }
        
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.isAuthenticated = session.user != nil
                if let user = session.user {
                    self.currentUser = AppUser(
                        id: user.id.uuidString,
                        email: user.email ?? "",
                        name: user.userMetadata["full_name"]?.description ?? "",
                        createdAt: user.createdAt
                    )
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.authError = .networkError
            }
        }
    }
    
    func checkAuthenticationState() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func signIn(email: String, password: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        isLoading = true
        authError = nil
        
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            
            if let user = response.user {
                currentUser = AppUser(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    name: user.userMetadata["full_name"]?.description ?? "",
                    createdAt: user.createdAt
                )
                isAuthenticated = true
            }
        } catch {
            authError = mapSupabaseError(error)
            throw authError!
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        isLoading = true
        authError = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            
            if let user = response.user {
                currentUser = AppUser(
                    id: user.id.uuidString,
                    email: user.email ?? "",
                    name: fullName,
                    createdAt: user.createdAt
                )
                isAuthenticated = true
            }
        } catch {
            authError = mapSupabaseError(error)
            throw authError!
        }
        
        isLoading = false
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        isLoading = true
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            clearForm()
        } catch {
            authError = mapSupabaseError(error)
            throw authError!
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            authError = mapSupabaseError(error)
            throw authError!
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        isLoading = true
        authError = nil
        
        do {
            guard let identityToken = credential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                throw AuthError.unknown("Failed to get identity token")
            }
            
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: identityTokenString)
            )
            
            if let user = response.user {
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                currentUser = AppUser(
                    id: user.id.uuidString,
                    email: user.email ?? credential.email ?? "",
                    name: fullName.isEmpty ? nil : fullName,
                    createdAt: user.createdAt
                )
                isAuthenticated = true
            }
        } catch {
            authError = mapSupabaseError(error)
            throw authError!
        }
        
        isLoading = false
    }
    
    // MARK: - Form Validation
    
    func validateLoginForm() -> Bool {
        if email.isEmpty || password.isEmpty {
            authError = .unknown("Please fill in all fields")
            return false
        }
        
        if !isValidEmail(email) {
            authError = .unknown("Please enter a valid email address")
            return false
        }
        
        if password.count < 6 {
            authError = .weakPassword
            return false
        }
        
        return true
    }
    
    func validateSignUpForm() -> Bool {
        if email.isEmpty || password.isEmpty || fullName.isEmpty {
            authError = .unknown("Please fill in all fields")
            return false
        }
        
        if !isValidEmail(email) {
            authError = .unknown("Please enter a valid email address")
            return false
        }
        
        if password.count < 8 {
            authError = .weakPassword
            return false
        }
        
        if password != confirmPassword {
            authError = .unknown("Passwords do not match")
            return false
        }
        
        if fullName.count < 2 {
            authError = .unknown("Please enter your full name")
            return false
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func mapSupabaseError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid login credentials") {
            return .invalidCredentials
        } else if errorMessage.contains("user already registered") {
            return .emailAlreadyInUse
        } else if errorMessage.contains("password") && errorMessage.contains("weak") {
            return .weakPassword
        } else if errorMessage.contains("network") || errorMessage.contains("connection") {
            return .networkError
        } else {
            return .unknown(error.localizedDescription)
        }
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        authError = nil
    }
}

// MARK: - Legacy User Model Support
// Temporary compatibility for existing code that references User
typealias User = AppUser