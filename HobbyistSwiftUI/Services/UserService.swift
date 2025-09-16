import Foundation
import Supabase
import Combine

// MARK: - User Service
class UserService: ObservableObject {
    private let supabaseClient: SupabaseClient

    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var error: Error?

    init(supabase: SupabaseClient) {
        self.supabaseClient = supabase
    }

    // MARK: - User Profile Management

    func getCurrentUser() async throws -> AppUser? {
        let session = try await supabaseClient.auth.session
        let user = session.user

        return AppUser(
            id: user.id.uuidString,
            email: user.email ?? "",
            name: user.userMetadata["full_name"]?.description ?? "",
            createdAt: user.createdAt
        )
    }

    func updateUserProfile(_ profile: UserProfileUpdate) async throws {
        let updates: [String: AnyJSON] = [
            "full_name": AnyJSON.string(profile.fullName),
            "bio": AnyJSON.string(profile.bio ?? ""),
            "phone": AnyJSON.string(profile.phone ?? "")
        ]

        try await supabaseClient.auth.update(user: UserAttributes(data: updates))
    }

    func uploadUserAvatar(_ imageData: Data) async throws -> String {
        // TODO: Implement avatar upload to Supabase Storage
        // For now, return a placeholder URL
        return "https://placeholder.com/avatar.jpg"
    }

    func deleteUser() async throws {
        // TODO: Implement user deletion
        // This would involve cleanup of user data and account deletion
        throw UserServiceError.notImplemented
    }
}

// MARK: - Supporting Types

struct UserProfileUpdate {
    let fullName: String
    let bio: String?
    let phone: String?
}

enum UserServiceError: LocalizedError {
    case notImplemented
    case userNotFound
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Feature not implemented yet"
        case .userNotFound:
            return "User not found"
        case .updateFailed:
            return "Failed to update user profile"
        }
    }
}