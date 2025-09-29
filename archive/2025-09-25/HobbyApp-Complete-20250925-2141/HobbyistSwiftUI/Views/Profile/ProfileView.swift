import SwiftUI

struct ProfileView: View {
    @State private var user = MockUser()
    @State private var showEditProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .overlay(
                                Button(action: { showEditProfile = true }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.blue))
                                        .frame(width: 28, height: 28)
                                }
                                .offset(x: 25, y: 25)
                            )

                        VStack(spacing: 4) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(user.memberSince)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Quick Stats
                        HStack(spacing: 32) {
                            StatItemView(value: "\(user.classesBooked)", label: "Classes")
                            StatItemView(value: "\(user.creditsRemaining)", label: "Credits")
                            StatItemView(value: "\(user.favoriteStudios)", label: "Favorites")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Menu Items
                    VStack(spacing: 16) {
                        ProfileMenuItemView(
                            icon: "person.crop.circle",
                            title: "Edit Profile",
                            subtitle: "Update your personal information"
                        ) {
                            showEditProfile = true
                        }

                        ProfileMenuItemView(
                            icon: "calendar",
                            title: "My Bookings",
                            subtitle: "View upcoming and past classes"
                        ) {
                            // Navigate to bookings
                        }

                        ProfileMenuItemView(
                            icon: "heart",
                            title: "Favorites",
                            subtitle: "Your saved classes and studios"
                        ) {
                            // Navigate to favorites
                        }

                        ProfileMenuItemView(
                            icon: "creditcard",
                            title: "Credits & Billing",
                            subtitle: "Manage your class credits"
                        ) {
                            // Navigate to credits
                        }

                        ProfileMenuItemView(
                            icon: "bell",
                            title: "Notifications",
                            subtitle: "Manage your notification preferences"
                        ) {
                            // Navigate to notifications
                        }

                        ProfileMenuItemView(
                            icon: "gear",
                            title: "Settings",
                            subtitle: "App preferences and account settings"
                        ) {
                            showSettings = true
                        }

                        ProfileMenuItemView(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            subtitle: "Get help or contact support"
                        ) {
                            // Navigate to help
                        }
                    }
                    .padding(.horizontal)

                    // Logout Button
                    Button("Log Out") {
                        // Handle logout
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(user: $user)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct StatItemView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileMenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Binding var user: MockUser
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String
    @State private var editedEmail: String

    init(user: Binding<MockUser>) {
        self._user = user
        self._editedName = State(initialValue: user.wrappedValue.name)
        self._editedEmail = State(initialValue: user.wrappedValue.email)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $editedName)
                    TextField("Email", text: $editedEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Profile Photo") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Button("Change Photo") {
                                // Handle photo change
                            }
                            .foregroundColor(.blue)

                            Text("Upload a new profile photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        user.name = editedName
                        user.email = editedEmail
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var marketingEmails = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $notificationsEnabled)
                    Toggle("Location Services", isOn: $locationEnabled)
                    Toggle("Marketing Emails", isOn: $marketingEmails)
                }

                Section("Privacy") {
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .foregroundColor(.blue)

                    Button("Terms of Service") {
                        // Open terms
                    }
                    .foregroundColor(.blue)
                }

                Section("Account") {
                    Button("Delete Account") {
                        // Handle account deletion
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MockUser {
    var name: String = "Alex Johnson"
    var email: String = "alex.johnson@email.com"
    var memberSince: String = "Member since March 2024"
    var classesBooked: Int = 12
    var creditsRemaining: Int = 8
    var favoriteStudios: Int = 3
}

#Preview {
    ProfileView()
}