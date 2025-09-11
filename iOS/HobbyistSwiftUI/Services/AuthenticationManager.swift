import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: Error?
    
    private var supabase: SupabaseClient? {
        return ServiceContainer.shared.supabaseClient
    }
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        guard let supabase = supabase else { return }
        
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.isAuthenticated = session.user != nil
                if let user = session.user {
                    self.currentUser = User(
                        id: UUID(uuidString: user.id.uuidString) ?? UUID(),
                        email: user.email ?? "",
                        name: user.userMetadata["name"]?.description ?? "",
                        createdAt: user.createdAt
                    )
                }
            }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
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
            throw AuthError.configurationError
        }
        
        await MainActor.run {
            self.isLoading = true
            self.authError = nil
        }
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = User(
                    id: UUID(uuidString: response.user.id.uuidString) ?? UUID(),
                    email: response.user.email ?? email,
                    name: response.user.userMetadata["name"]?.description ?? "",
                    createdAt: response.user.createdAt
                )
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error
                self.isLoading = false
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        guard let supabase = supabase else {
            throw AuthError.configurationError
        }
        
        await MainActor.run {
            self.isLoading = true
            self.authError = nil
        }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = User(
                    id: UUID(uuidString: response.user?.id.uuidString ?? "") ?? UUID(),
                    email: response.user?.email ?? email,
                    name: name,
                    createdAt: response.user?.createdAt ?? Date()
                )
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error
                self.isLoading = false
            }
            throw error
        }
    }
    
    func signOut() async throws {
        guard let supabase = supabase else {
            throw AuthError.configurationError
        }
        
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            await MainActor.run {
                self.authError = error
            }
            throw error
        }
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case configurationError
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .configurationError:
            return "App configuration error. Please try again later."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}