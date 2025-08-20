import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            ClassesView()
                .tabItem {
                    Label("Classes", systemImage: "calendar")
                }
                .tag(1)
            
            BookingsView()
                .tabItem {
                    Label("Bookings", systemImage: "ticket")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
    }
}

struct AuthenticationView: View {
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationStack {
            LoginView()
                .navigationDestination(isPresented: $isShowingSignUp) {
                    SignUpView()
                }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome to HobbyistSwiftUI")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Discover and book hobby classes")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}

struct ClassesView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Classes will appear here")
            }
            .navigationTitle("Classes")
        }
    }
}

struct BookingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Your bookings will appear here")
            }
            .navigationTitle("My Bookings")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Profile settings")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Sign In") {
                // Handle login
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Create Account") {
                // Handle signup
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Sign Up")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(NavigationManager())
}