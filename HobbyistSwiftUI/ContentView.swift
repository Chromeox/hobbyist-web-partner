import SwiftUI

struct ContentView: View {
    @StateObject private var supabaseService = SimpleSupabaseService.shared
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn || supabaseService.isAuthenticated {
                HomeView()
            } else {
                LoginView(onLoginSuccess: {
                    isLoggedIn = true
                })
                .environmentObject(supabaseService)
            }
        }
        .onAppear {
            isLoggedIn = supabaseService.isAuthenticated
        }
    }
}

#Preview {
    ContentView()
}