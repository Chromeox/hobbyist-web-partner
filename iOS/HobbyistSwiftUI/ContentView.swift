import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        VStack {
            Text("HobbyistSwiftUI")
                .font(.largeTitle)
                .padding()

            Text("Build Status: ✅ File paths fixed!")
                .foregroundColor(.green)
                .padding()

            if authManager.isAuthenticated {
                Text("User is authenticated")
                    .foregroundColor(.blue)
            } else {
                Text("User not authenticated")
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(NavigationManager.shared)
}