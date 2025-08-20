import Foundation
import Combine
import Supabase
import AuthenticationServices

class AuthService: AuthServiceProtocol {
    @Published var isAuthenticated = CurrentValueSubject<Bool, Never>(false)
    @Published var currentUser = CurrentValueSubject<User?, Never>(nil)
    
    private var cancellables = Set<AnyCancellable>()
    private let supabase = SupabaseManager.shared.client
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Task {
            for await state in supabase?.auth.authStateChanges ?? AsyncStream { _ in } {
                await MainActor.run {
                    switch state.event {
                    case .signedIn:
                        self.isAuthenticated.send(true)
                        if let session = state.session {
                            self.currentUser.send(self.mapSupabaseUser(session.user))
                        }
                    case .signedOut:
                        self.isAuthenticated.send(false)
                        self.currentUser.send(nil)
                    case .tokenRefreshed:
                        if let session = state.session {
                            self.currentUser.send(self.mapSupabaseUser(session.user))
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = mapSupabaseUser(response.user)
            await MainActor.run {
                self.isAuthenticated.send(true)
                self.currentUser.send(user)
            }
            
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func signUp(email: String, password: String, metadata: [String: Any]? = nil) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: metadata
            )
            
            let user = mapSupabaseUser(response.user)
            await MainActor.run {
                self.isAuthenticated.send(true)
                self.currentUser.send(user)
            }
            
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }
        
        do {
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken
                )
            )
            
            let user = mapSupabaseUser(response.user)
            await MainActor.run {
                self.isAuthenticated.send(true)
                self.currentUser.send(user)
            }
            
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.isAuthenticated.send(false)
                self.currentUser.send(nil)
            }
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func resetPassword(email: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func updateProfile(updates: ProfileUpdate) async throws -> User {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        var attributes = UserAttributes()
        
        if let fullName = updates.fullName {
            attributes.data?["full_name"] = fullName
        }
        if let avatarURL = updates.avatarURL {
            attributes.data?["avatar_url"] = avatarURL
        }
        if let phoneNumber = updates.phoneNumber {
            attributes.phone = phoneNumber
        }
        if let metadata = updates.metadata {
            attributes.data = metadata
        }
        
        do {
            let response = try await supabase.auth.update(user: attributes)
            let user = mapSupabaseUser(response.user)
            
            await MainActor.run {
                self.currentUser.send(user)
            }
            
            return user
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func refreshSession() async throws {
        guard let supabase = supabase else {
            throw AuthError.networkError
        }
        
        do {
            _ = try await supabase.auth.refreshSession()
        } catch {
            throw mapAuthError(error)
        }
    }
    
    func checkAuthStatus() async {
        guard let supabase = supabase else { return }
        
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                if session != nil {
                    self.isAuthenticated.send(true)
                    if let user = session?.user {
                        self.currentUser.send(self.mapSupabaseUser(user))
                    }
                } else {
                    self.isAuthenticated.send(false)
                    self.currentUser.send(nil)
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated.send(false)
                self.currentUser.send(nil)
            }
        }
    }
    
    private func mapSupabaseUser(_ supabaseUser: Supabase.User) -> User {
        return User(
            id: supabaseUser.id.uuidString,
            email: supabaseUser.email,
            fullName: supabaseUser.userMetadata?["full_name"] as? String,
            avatarURL: supabaseUser.userMetadata?["avatar_url"] as? String,
            phoneNumber: supabaseUser.phone,
            createdAt: supabaseUser.createdAt,
            metadata: supabaseUser.userMetadata
        )
    }
    
    private func mapAuthError(_ error: Error) -> AuthError {
        if let supabaseError = error as? Supabase.AuthError {
            switch supabaseError.statusCode {
            case 400:
                return .invalidCredentials
            case 422:
                return .weakPassword
            case 409:
                return .emailAlreadyInUse
            default:
                return .unknownError(supabaseError.localizedDescription)
            }
        }
        return .networkError
    }
}