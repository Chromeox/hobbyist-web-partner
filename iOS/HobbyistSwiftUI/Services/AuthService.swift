import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authError: AppError?
    
    private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Task {
            for await state in supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    await handleSignIn(session: state.session)
                case .signedOut:
                    await handleSignOut()
                case .userUpdated:
                    await refreshUser()
                default:
                    break
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            await handleSignIn(session: response.session)
        } catch {
            authError = AppError.authenticationError(error.localizedDescription)
            throw authError!
        } finally {
            isLoading = false
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            
            if let session = response.session {
                await handleSignIn(session: session)
            }
        } catch {
            if error.localizedDescription.contains("already registered") {
                authError = AppError.emailAlreadyInUse
            } else {
                authError = AppError.authenticationError(error.localizedDescription)
            }
            throw authError!
        } finally {
            isLoading = false
        }
    }
    
    func signOut() async throws {
        isLoading = true
        authError = nil
        
        do {
            try await supabase.auth.signOut()
            await handleSignOut()
        } catch {
            authError = AppError.authenticationError(error.localizedDescription)
            throw authError!
        } finally {
            isLoading = false
        }
    }
    
    private func handleSignIn(session: Session?) async {
        guard let session = session else { return }
        
        isAuthenticated = true
        await fetchUserProfile(userId: session.user.id)
        ServiceContainer.shared.crashReportingService.setUserIdentifier(session.user.id.uuidString)
        ServiceContainer.shared.analyticsService.trackEvent("user_signed_in")
    }
    
    private func handleSignOut() async {
        isAuthenticated = false
        currentUser = nil
        ServiceContainer.shared.analyticsService.trackEvent("user_signed_out")
    }
    
    private func fetchUserProfile(userId: UUID) async {
        do {
            let user = try await ServiceContainer.shared.userService.getUser(id: userId)
            currentUser = user
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
    }
    
    private func refreshUser() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        await fetchUserProfile(userId: userId)
    }
    
    func checkAuthenticationState() {
        Task {
            if let session = try? await supabase.auth.session {
                await handleSignIn(session: session)
            }
        }
    }
}