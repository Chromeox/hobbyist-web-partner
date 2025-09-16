import Foundation
import Combine
import Supabase

// MARK: - Supabase Service
class SupabaseService {
    static let shared = SupabaseService()

    private var supabaseClient: SupabaseClient? {
        return SupabaseManager.shared.client
    }
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Configuration is now handled by SupabaseManager
    }
    
    // MARK: - Generic Request Methods
    
    func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws -> T {
        guard let client = supabaseClient else {
            throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized"]))
        }

        // For now, delegate to proper implementation or throw error for unimplemented methods
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Method should use official Supabase client"]))
    }
    
    func requestVoid(_ endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws {
        guard let client = supabaseClient else {
            throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase client not initialized"]))
        }

        // For now, delegate to proper implementation or throw error for unimplemented methods
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Method should use official Supabase client"]))
    }
    
    // MARK: - Auth Methods
    // Note: Auth methods should use AuthenticationManager which uses the official Supabase client

    func signUp(email: String, password: String, metadata: [String: Any]? = nil) async throws -> AuthResponse {
        // Delegate to AuthenticationManager instead
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Use AuthenticationManager for auth operations"]))
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        // Delegate to AuthenticationManager instead
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Use AuthenticationManager for auth operations"]))
    }
    
    func signOut() async throws {
        // Delegate to AuthenticationManager instead
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Use AuthenticationManager for auth operations"]))
    }

    func getCurrentUser() async throws -> SupabaseUser? {
        // Delegate to AuthenticationManager instead
        throw SupabaseError.networkError(NSError(domain: "SupabaseService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Use AuthenticationManager for auth operations"]))
    }
    
    // MARK: - Token Management
    
    private func saveAuthToken(_ token: String) {
        // Use secure Keychain storage instead of UserDefaults
        do {
            try KeychainService.shared.save(token, for: .authToken)
        } catch {
            print("Failed to save auth token to Keychain: \(error)")
        }
    }
    
    private func getAuthToken() -> String? {
        // Retrieve from secure Keychain storage
        do {
            return try KeychainService.shared.getString(for: .authToken)
        } catch {
            return nil
        }
    }
    
    private func clearAuthToken() {
        // Clear from secure Keychain storage
        do {
            try KeychainService.shared.delete(key: .authToken)
        } catch {
            print("Failed to clear auth token from Keychain: \(error)")
        }
    }
    
    // MARK: - Realtime Subscription
    
    func subscribeToTable(_ table: String, event: RealtimeEvent = .all) -> AnyPublisher<RealtimeMessage, Never> {
        // This is a simplified version - in production, you'd implement WebSocket connection
        // For now, returning an empty publisher
        return Empty<RealtimeMessage, Never>().eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case httpError(statusCode: Int, data: Data?)
    case authError(message: String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .authError(let message):
            return "Authentication error: \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: SupabaseUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String
    let createdAt: Date
    let updatedAt: Date
    let userMetadata: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userMetadata = "user_metadata"
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Cannot encode value"))
        }
    }
}

enum RealtimeEvent {
    case all
    case insert
    case update
    case delete
}

struct RealtimeMessage {
    let event: RealtimeEvent
    let table: String
    let data: [String: Any]
}