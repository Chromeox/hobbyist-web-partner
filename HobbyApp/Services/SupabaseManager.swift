import Foundation
import Supabase

// MARK: - Supabase Manager

/// Centralized Supabase client manager
/// Provides a single source of truth for the Supabase client across the app
@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    private(set) var client: SupabaseClient
    
    private init() {
        // Use Configuration.shared for centralized configuration
        let supabaseURL = Configuration.shared.supabaseURL
        let supabaseAnonKey = Configuration.shared.supabaseAnonKey
        
        guard !supabaseURL.isEmpty,
              let url = URL(string: supabaseURL) else {
            fatalError("""
            Invalid Supabase URL in configuration.
            Configure Config-Dev.plist or environment variables before running the app.
            """)
        }
        
        guard !supabaseAnonKey.isEmpty else {
            fatalError("Supabase anon key is missing in configuration.")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
        
        print("✅ SupabaseManager initialized")
    }
    
    /// Reinitialize the client (useful for testing or configuration changes)
    func reinitialize() {
        let supabaseURL = Configuration.shared.supabaseURL
        let supabaseAnonKey = Configuration.shared.supabaseAnonKey
        
        guard !supabaseURL.isEmpty,
              let url = URL(string: supabaseURL) else {
            print("❌ Failed to reinitialize: Invalid Supabase URL")
            return
        }
        
        guard !supabaseAnonKey.isEmpty else {
            print("❌ Failed to reinitialize: Missing Supabase anon key")
            return
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
        
        print("✅ SupabaseManager reinitialized")
    }
}
