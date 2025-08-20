import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var fullName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isSignUpMode: Bool = false
    
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthenticationService = AuthenticationService.shared) {
        self.authService = authService
        setupBindings()
    }
    
    private func setupBindings() {
        authService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
    }
    
    func login() async {
        guard validateLoginInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard validateSignUpInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                fullName: fullName
            )
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await authService.signOut()
            clearForm()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    private func validateLoginInput() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        return true
    }
    
    private func validateSignUpInput() -> Bool {
        if email.isEmpty || password.isEmpty || fullName.isEmpty {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return false
        }
        
        if fullName.count < 2 {
            errorMessage = "Please enter your full name"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthenticationError {
            switch authError {
            case .invalidCredentials:
                return "Invalid email or password"
            case .userNotFound:
                return "No account found with this email"
            case .emailAlreadyInUse:
                return "An account with this email already exists"
            case .weakPassword:
                return "Password is too weak. Please choose a stronger password"
            case .networkError:
                return "Network error. Please check your connection"
            case .unknown(let message):
                return message
            }
        }
        return error.localizedDescription
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        errorMessage = nil
        isSignUpMode = false
    }
    
    func toggleAuthMode() {
        isSignUpMode.toggle()
        errorMessage = nil
    }
}

// MARK: - Supporting Models
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    var profileImageUrl: String?
    var phoneNumber: String?
    var bio: String?
}

enum AuthenticationError: Error {
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown(String)
}