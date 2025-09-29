import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    
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
                            Text(supabaseService.currentUser?.name ?? "User")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(supabaseService.currentUser?.email ?? "")
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
                    
                    NavigationLink(destination: Text("Settings View")) {
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
            await supabaseService.signOut()
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
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
                .onChange(of: selectedPhoto) { _ in
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
            if let user = supabaseService.currentUser {
                fullName = user.name
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
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Payment Methods")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Manage your payment methods and billing information")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Payment Methods")
        }
    }
}


struct NotificationsView: View {
    @State private var classReminders = true
    @State private var newClasses = true
    @State private var promotions = false

    var body: some View {
        NavigationStack {
            List {
                Section("Class Notifications") {
                    HStack {
                        Label("Class Reminders", systemImage: "bell.fill")
                        Spacer()
                        Toggle("", isOn: $classReminders)
                    }

                    HStack {
                        Label("New Classes", systemImage: "sparkles")
                        Spacer()
                        Toggle("", isOn: $newClasses)
                    }
                }

                Section("Marketing") {
                    HStack {
                        Label("Promotions", systemImage: "tag.fill")
                        Spacer()
                        Toggle("", isOn: $promotions)
                    }
                }
            }
            .navigationTitle("Notifications")
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Data Privacy") {
                    NavigationLink("View Privacy Policy") {
                        Text("Privacy Policy Content")
                            .navigationTitle("Privacy Policy")
                    }

                    NavigationLink("Data We Collect") {
                        Text("Data Collection Information")
                            .navigationTitle("Data Collection")
                    }
                }

                Section("Account Management") {
                    NavigationLink("Download My Data") {
                        Text("Data Export Options")
                            .navigationTitle("Download Data")
                    }

                    NavigationLink("Delete Account") {
                        Text("Account Deletion Options")
                            .navigationTitle("Delete Account")
                    }
                }
            }
            .navigationTitle("Privacy")
        }
    }
}

struct HelpCenterView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Getting Started") {
                    NavigationLink("How to Book a Class") {
                        Text("Class booking instructions")
                            .navigationTitle("Book a Class")
                    }

                    NavigationLink("Understanding Credits") {
                        Text("Credit system explanation")
                            .navigationTitle("Credits System")
                    }

                    NavigationLink("Account Setup") {
                        Text("Account setup guide")
                            .navigationTitle("Account Setup")
                    }
                }

                Section("Common Issues") {
                    NavigationLink("Cancellation Policy") {
                        Text("Cancellation policy details")
                            .navigationTitle("Cancellations")
                    }

                    NavigationLink("Technical Problems") {
                        Text("Troubleshooting steps")
                            .navigationTitle("Technical Help")
                    }
                }
            }
            .navigationTitle("Help Center")
        }
    }
}

struct ContactUsView: View {
    @State private var subject = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Contact Us")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("We'd love to hear from you! Send us a message and we'll get back to you soon.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Subject", text: $subject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextEditor(text: $message)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }

                Button("Send Message") {
                    // Handle send message
                }
                .buttonStyle(.borderedProminent)
                .disabled(subject.isEmpty || message.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Contact Us")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SimpleSupabaseService.shared)
    }
}
