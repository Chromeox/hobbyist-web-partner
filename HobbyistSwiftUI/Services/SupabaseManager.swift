import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    private(set) var client: SupabaseClient?
    
    private init() {}
    
    func initialize(url: String, key: String) {
        guard let url = URL(string: url) else {
            print("Invalid Supabase URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: SupabaseAuthClientOptions(
                    storage: UserDefaultsLocalStorage(),
                    detectSessionInUrl: true
                ),
                global: SupabaseGlobalOptions(
                    logger: SupabaseLogger()
                )
            )
        )
    }
}

// Custom UserDefaults storage for Supabase Auth
class UserDefaultsLocalStorage: SupabaseLocalStorage {
    private let userDefaults = UserDefaults.standard
    
    func store(key: String, value: Data) async throws {
        userDefaults.set(value, forKey: key)
    }
    
    func retrieve(key: String) async throws -> Data? {
        return userDefaults.data(forKey: key)
    }
    
    func remove(key: String) async throws {
        userDefaults.removeObject(forKey: key)
    }
}

// Custom logger for Supabase
struct SupabaseLogger: SupabaseLoggerProtocol {
    func log(message: String, level: SupabaseLogLevel) {
        #if DEBUG
        switch level {
        case .debug:
            print("🔍 [Supabase Debug]: \(message)")
        case .error:
            print("❌ [Supabase Error]: \(message)")
        case .warning:
            print("⚠️ [Supabase Warning]: \(message)")
        case .info:
            print("ℹ️ [Supabase Info]: \(message)")
        default:
            print("[Supabase]: \(message)")
        }
        #endif
    }
}