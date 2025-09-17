import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            HomeView()
        } else {
            LoginView(onLoginSuccess: {
                isLoggedIn = true
            })
        }
    }
}

#Preview {
    ContentView()
}