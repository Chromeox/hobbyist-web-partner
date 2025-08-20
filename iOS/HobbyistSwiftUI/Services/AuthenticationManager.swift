import Foundation
import SwiftUI
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authError: AuthError?
    
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.authService = AuthService()
        setupBindings()
    }
    
    private func setupBindings() {
        authService.isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
            }
            .store(in: &cancellables)
        
        authService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        authError = nil
        
        do {
            _ = try await authService.signIn(email: email, password: password)
        } catch let error as AuthError {
            authError = error
        } catch {
            authError = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUp(email: String, password: String, fullName: String? = nil) async {
        isLoading = true
        authError = nil
        
        var metadata: [String: Any]?
        if let fullName = fullName {
            metadata = ["full_name": fullName]
        }
        
        do {
            _ = try await authService.signUp(
                email: email,
                password: password,
                metadata: metadata
            )
        } catch let error as AuthError {
            authError = error
        } catch {
            authError = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        
        do {
            try await authService.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func resetPassword(email: String) async {
        isLoading = true
        authError = nil
        
        do {
            try await authService.resetPassword(email: email)
        } catch let error as AuthError {
            authError = error
        } catch {
            authError = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    @MainActor
    func checkAuthStatus() async {
        isLoading = true
        await authService.checkAuthStatus()
        isLoading = false
    }
}