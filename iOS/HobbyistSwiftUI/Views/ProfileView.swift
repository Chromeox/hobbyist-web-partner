import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.fullName ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Account Settings
                Section("Account") {
                    NavigationLink(destination: Text("Edit Profile")) {
                        Label("Edit Profile", systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: Text("Payment Methods")) {
                        Label("Payment Methods", systemImage: "creditcard.fill")
                    }
                    
                    NavigationLink(destination: Text("Credits")) {
                        Label("My Credits", systemImage: "dollarsign.circle.fill")
                    }
                }
                
                // Preferences
                Section("Preferences") {
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy", systemImage: "lock.fill")
                    }
                }
                
                // Support
                Section("Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Contact Us")) {
                        Label("Contact Us", systemImage: "envelope.fill")
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func signOut() {
        Task {
            await authManager.signOut()
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager.shared)
    }
}