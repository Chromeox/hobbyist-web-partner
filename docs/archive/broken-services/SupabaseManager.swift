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

        // Using the simplified initialization as the custom storage and logger
        // can be added later if needed. The default implementation handles
        // session storage automatically.
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
}

// Note: Custom storage and logger implementations can be added later
// if needed using SupabaseClientOptions. The default implementation
// handles session storage automatically and provides adequate logging.