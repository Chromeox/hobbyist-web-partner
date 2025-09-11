import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
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
                Section(NSLocalizedString("account", comment: "")) {
                    NavigationLink(destination: EditProfileView()) {
                        Label(NSLocalizedString("edit_profile", comment: ""), systemImage: "person.fill")
                    }
                    
                    NavigationLink(destination: PaymentMethodsView()) {
                        Label(NSLocalizedString("payment_methods", comment: ""), systemImage: "creditcard.fill")
                    }
                    
                    NavigationLink(destination: CreditsView()) {
                        Label(NSLocalizedString("my_credits", comment: ""), systemImage: "dollarsign.circle.fill")
                    }
                }
                
                // Preferences
                Section(NSLocalizedString("preferences", comment: "")) {
                    NavigationLink(destination: NotificationsView()) {
                        Label(NSLocalizedString("notifications", comment: ""), systemImage: "bell.fill")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label(NSLocalizedString("settings", comment: ""), systemImage: "gear")
                    }
                    
                    NavigationLink(destination: PrivacyView()) {
                        Label(NSLocalizedString("privacy", comment: ""), systemImage: "lock.fill")
                    }
                }
                
                // Support
                Section(NSLocalizedString("support", comment: "")) {
                    NavigationLink(destination: HelpCenterView()) {
                        Label(NSLocalizedString("help_center", comment: ""), systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: ContactUsView()) {
                        Label(NSLocalizedString("contact_us", comment: ""), systemImage: "envelope.fill")
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: signOut) {
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("sign_out", comment: ""))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("profile", comment: ""))
        }
    }
    
    private func signOut() {
        Task {
            await authManager.signOut()
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedPhotoData: Data?

    var body: some View {
        Form {
            Section(header: Text("Profile Picture")) {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack {
                            if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            Text("Change Photo")
                        }
                    }
                    Spacer()
                }
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                            selectedPhotoData = data
                        }
                    }
                }
            }

            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $fullName)
                TextField("Phone Number", text: $phoneNumber)
            }

            Section(header: Text("About Me")) {
                TextEditor(text: $bio)
                    .frame(height: 100)
            }
        }
        .onAppear {
            if let user = authManager.currentUser {
                fullName = user.fullName ?? ""
                // These will need to be adjusted based on your User model
                // bio = user.profile?.bio ?? ""
                // phoneNumber = user.profile?.phoneNumber ?? ""
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarItems(trailing: Button("Save") {
            // Save action
        })
    }
}

struct PaymentMethodsView: View {
    var body: some View {
        Text("Payment Methods View")
    }
}

struct CreditsView: View {
    var body: some View {
        Text("Credits View")
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notifications View")
    }
}

struct PrivacyView: View {
    var body: some View {
        Text("Privacy View")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Help Center View")
    }
}

struct ContactUsView: View {
    var body: some View {
        Text("Contact Us View")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager.shared)
    }
}
