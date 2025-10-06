import Foundation

class AppConfiguration {
    static let shared = AppConfiguration()

    var current: AppConfig? {
        return AppConfig()
    }

    private init() {}
}

struct AppConfig {
    let supabaseURL: String
    let supabaseAnonKey: String

    init() {
        // In a real app, these would come from a secure plist or environment
        // For now, using placeholder values that need to be configured
        self.supabaseURL = "https://mcjqvdzdhtcvbrejvrtp.supabase.co"
        self.supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjM3MzE4NzIsImV4cCI6MjAzOTMwNzg3Mn0.c5KX7QsNpLTGKWsO0LcHWMp8MqKM0E6Gq1l8zQ4H1xI"
    }
}