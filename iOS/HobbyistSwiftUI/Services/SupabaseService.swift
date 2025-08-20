import Foundation
import Combine

// MARK: - Supabase Service
class SupabaseService {
    static let shared = SupabaseService()
    
    private var baseURL: String {
        guard let url = AppConfiguration.shared.supabaseURL else {
            fatalError("Supabase URL not configured. Please check AppConfiguration.")
        }
        return url
    }
    
    private var apiKey: String {
        guard let key = AppConfiguration.shared.supabaseAnonKey else {
            fatalError("Supabase API key not configured. Please check AppConfiguration.")
        }
        return key
    }
    
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Configuration is now handled by AppConfiguration
        validateConfiguration()
    }
    
    private func validateConfiguration() {
        guard AppConfiguration.shared.validateConfiguration() else {
            print("⚠️ Warning: Invalid Supabase configuration detected")
        }
    }
    
    // MARK: - Generic Request Methods
    
    func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(getAuthToken() ?? apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } else {
                throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
        } catch {
            if error is SupabaseError {
                throw error
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    func requestVoid(_ endpoint: String, method: HTTPMethod = .get, body: Data? = nil) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(endpoint)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(getAuthToken() ?? apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: nil)
            }
        } catch {
            if error is SupabaseError {
                throw error
            }
            throw SupabaseError.networkError(error)
        }
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String, metadata: [String: Any]? = nil) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/v1/signup") else {
            throw SupabaseError.invalidURL
        }
        
        var body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        if let metadata = metadata {
            body["data"] = metadata
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            saveAuthToken(authResponse.accessToken)
            return authResponse
        } else {
            throw SupabaseError.authError(message: String(data: data, encoding: .utf8) ?? "Authentication failed")
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password") else {
            throw SupabaseError.invalidURL
        }
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            saveAuthToken(authResponse.accessToken)
            return authResponse
        } else {
            throw SupabaseError.authError(message: "Invalid credentials")
        }
    }
    
    func signOut() async throws {
        guard let url = URL(string: "\(baseURL)/auth/v1/logout") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(getAuthToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            clearAuthToken()
        } else {
            throw SupabaseError.authError(message: "Failed to sign out")
        }
    }
    
    func getCurrentUser() async throws -> SupabaseUser? {
        guard getAuthToken() != nil else { return nil }
        
        guard let url = URL(string: "\(baseURL)/auth/v1/user") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(getAuthToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(SupabaseUser.self, from: data)
        } else if httpResponse.statusCode == 401 {
            clearAuthToken()
            return nil
        } else {
            throw SupabaseError.authError(message: "Failed to get user")
        }
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