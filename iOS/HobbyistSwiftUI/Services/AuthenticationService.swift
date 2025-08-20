import Foundation
import Combine

class AuthenticationService {
    static let shared = AuthenticationService()
    
    @Published private(set) var currentUser: User?
    var currentUserPublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check for existing session on init
        Task {
            await checkCurrentSession()
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        let metadata = ["full_name": fullName]
        let authResponse = try await supabaseService.signUp(
            email: email,
            password: password,
            metadata: metadata
        )
        
        // Convert Supabase user to our User model
        currentUser = User(
            id: authResponse.user.id,
            email: authResponse.user.email,
            fullName: fullName,
            createdAt: authResponse.user.createdAt
        )
        
        // Store user profile in database
        try await createUserProfile(userId: authResponse.user.id, fullName: fullName, email: email)
    }
    
    func signIn(email: String, password: String) async throws {
        let authResponse = try await supabaseService.signIn(email: email, password: password)
        
        // Fetch full user profile
        currentUser = try await fetchUserProfile(userId: authResponse.user.id)
    }
    
    func signOut() async throws {
        try await supabaseService.signOut()
        currentUser = nil
    }
    
    func resetPassword(email: String) async throws {
        // This would typically send a password reset email
        let endpoint = "auth/v1/recover"
        let body = ["email": email]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        try await supabaseService.requestVoid(endpoint, method: .post, body: jsonData)
    }
    
    func checkCurrentSession() async {
        do {
            if let supabaseUser = try await supabaseService.getCurrentUser() {
                currentUser = try await fetchUserProfile(userId: supabaseUser.id)
            }
        } catch {
            print("No active session: \(error)")
            currentUser = nil
        }
    }
    
    private func createUserProfile(userId: String, fullName: String, email: String) async throws {
        let profile = [
            "id": userId,
            "full_name": fullName,
            "email": email,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: profile)
        try await supabaseService.requestVoid("profiles", method: .post, body: jsonData)
    }
    
    private func fetchUserProfile(userId: String) async throws -> User {
        let endpoint = "profiles?id=eq.\(userId)"
        let profiles: [UserProfile] = try await supabaseService.request(endpoint)
        
        guard let profile = profiles.first else {
            throw AuthenticationError.userNotFound
        }
        
        return User(
            id: profile.id,
            email: profile.email,
            fullName: profile.fullName,
            createdAt: profile.createdAt,
            profileImageUrl: profile.profileImageUrl,
            phoneNumber: profile.phoneNumber,
            bio: profile.bio
        )
    }
}

// MARK: - Supporting Types
private struct UserProfile: Codable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    let profileImageUrl: String?
    let phoneNumber: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case createdAt = "created_at"
        case profileImageUrl = "profile_image_url"
        case phoneNumber = "phone_number"
        case bio
    }
}