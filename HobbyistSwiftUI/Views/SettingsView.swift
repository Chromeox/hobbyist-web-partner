import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var emailNotifications = true
    @State private var pushNotifications = true
    @State private var marketingEmails = false
    @State private var selectedLanguage = "English"
    @State private var darkModeEnabled = false
    @State private var showingDeleteAccount = false
    
    let languages = ["English", "Spanish", "French", "German", "Italian"]
    
    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $pushNotifications)
                    Toggle("Email Notifications", isOn: $emailNotifications)
                    Toggle("Marketing Emails", isOn: $marketingEmails)
                }
                
                // Privacy Section
                Section("Privacy") {
                    Toggle("Location Services", isOn: $locationEnabled)
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "lock.doc")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Label("Language", systemImage: "globe")
                        Spacer()
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Toggle(isOn: $darkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon")
                    }
                }
                
                // Data & Storage Section
                Section("Data & Storage") {
                    NavigationLink(destination: Text("Download Data")) {
                        Label("Download My Data", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        clearCache()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                            .foregroundColor(.primary)
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    NavigationLink(destination: Text("Report Bug")) {
                        Label("Report a Bug", systemImage: "ladybug")
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: Text("Licenses")) {
                        Label("Third-Party Licenses", systemImage: "doc.badge.gearshape")
                    }
                    
                    NavigationLink(destination: Text("Acknowledgments")) {
                        Label("Acknowledgments", systemImage: "heart")
                    }
                }
                
                // Account Actions Section
                Section("Account Actions") {
                    Button {
                        showingDeleteAccount = true
                    } label: {
                        Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
    
    private func clearCache() {
        // Implement cache clearing logic
        print("Cache cleared")
    }
    
    private func deleteAccount() {
        Task {
            // Implement account deletion logic
            print("Account deletion requested")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AuthenticationManager.shared)
        }
    }
}