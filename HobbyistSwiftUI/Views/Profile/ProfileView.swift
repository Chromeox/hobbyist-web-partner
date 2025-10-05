import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var user = MockUser()
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var avatarURL: String?
    @State private var isLoadingAvatar = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        ZStack(alignment: .bottomTrailing) {
                            if let avatarURL = avatarURL, !avatarURL.isEmpty {
                                AsyncImage(url: URL(string: avatarURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 80, height: 80)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.blue)
                                    @unknown default:
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(.blue)
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)
                            }

                            Button(action: { showEditProfile = true }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Circle().fill(Color.blue))
                            }
                            .offset(x: -5, y: -5)
                        }
                        .frame(width: 80, height: 80)

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
                EditProfileView(user: $user, onPhotoUploaded: {
                    // Reload avatar when user uploads new photo
                    Task {
                        await loadAvatar()
                    }
                })
                .environmentObject(supabaseService)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .task {
                // Load avatar when view appears
                await loadAvatar()
            }
            .refreshable {
                // Reload avatar on pull-to-refresh
                await loadAvatar()
            }
        }
    }

    private func loadAvatar() async {
        isLoadingAvatar = true
        avatarURL = await supabaseService.fetchUserProfileAvatarURL()
        isLoadingAvatar = false
        print("🖼️ Avatar loaded: \(avatarURL ?? "nil")")
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
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String
    @State private var editedEmail: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var uploadedAvatarURL: String?
    @State private var isUploadingPhoto = false
    @State private var showUploadError = false
    @State private var uploadErrorMessage = ""
    @State private var showSuccessMessage = false
    @State private var showUploadSuccess = false
    let onPhotoUploaded: () -> Void

    init(user: Binding<MockUser>, onPhotoUploaded: @escaping () -> Void = {}) {
        self._user = user
        self._editedName = State(initialValue: user.wrappedValue.name)
        self._editedEmail = State(initialValue: user.wrappedValue.email)
        self.onPhotoUploaded = onPhotoUploaded
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
                        // Display photo preview or placeholder
                        if let photoData = selectedPhotoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    if isUploadingPhoto {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(isUploadingPhoto ? "Uploading..." : "Change Photo")
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isUploadingPhoto)
                            .onChange(of: selectedPhotoItem) { newItem in
                                Task {
                                    await loadPhoto(from: newItem)
                                }
                            }

                            Text("Upload a new profile photo")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            // Debug status indicator
                            if let _ = uploadedAvatarURL {
                                Text("✅ Photo uploaded successfully")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Debug Section
                Section("Debug Info") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Authenticated: \(supabaseService.currentUser != nil ? "✅" : "❌")")
                            .font(.caption)
                        if let user = supabaseService.currentUser {
                            Text("User ID: \(user.id)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("Photo uploaded: \(uploadedAvatarURL != nil ? "✅" : "❌")")
                            .font(.caption)
                        if let url = uploadedAvatarURL {
                            Text("URL: \(url)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
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
                        Task {
                            await saveProfile()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isUploadingPhoto)
                }
            }
            .alert("Upload Error", isPresented: $showUploadError) {
                Button("OK") { }
            } message: {
                Text(uploadErrorMessage)
            }
            .alert("Photo Uploaded", isPresented: $showUploadSuccess) {
                Button("OK") { }
            } message: {
                Text("Photo uploaded successfully! Tap Save to update your profile.")
            }
            .alert("Success", isPresented: $showSuccessMessage) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Profile updated successfully!")
            }
        }
    }

    // MARK: - Photo Handling

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else {
            print("⚠️ loadPhoto called with nil item")
            return
        }

        print("📸 [1/5] Photo selected, starting load process...")
        isUploadingPhoto = true

        do {
            print("📸 [2/5] Loading image data from PhotosPickerItem...")
            // Load the image data
            if let data = try await item.loadTransferable(type: Data.self) {
                print("✅ Image data loaded: \(data.count) bytes")

                print("📸 [3/5] Compressing image (max 800x800, 0.8 quality)...")
                // Compress and resize the image
                if let compressedData = compressImage(data) {
                    print("✅ Image compressed: \(compressedData.count) bytes (reduced by \(data.count - compressedData.count) bytes)")
                    selectedPhotoData = compressedData

                    print("📸 [4/5] Uploading to Supabase Storage...")
                    // Upload to Supabase
                    await uploadPhotoToSupabase(compressedData)
                } else {
                    print("❌ Image compression failed")
                    uploadErrorMessage = "Failed to process image. Please try another photo."
                    showUploadError = true
                }
            } else {
                print("❌ Failed to extract Data from PhotosPickerItem")
                uploadErrorMessage = "Failed to load image data"
                showUploadError = true
            }
        } catch {
            print("❌ PhotosPickerItem load error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            uploadErrorMessage = "Failed to load image: \(error.localizedDescription)"
            showUploadError = true
        }

        isUploadingPhoto = false
        print("📸 Upload process complete. isUploadingPhoto = false")
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        // Resize to max 800x800 while maintaining aspect ratio
        let maxDimension: CGFloat = 800
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Compress to JPEG with 0.8 quality
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }

    private func uploadPhotoToSupabase(_ imageData: Data) async {
        print("📸 [4/5] Starting Supabase upload...")
        print("📸 User authenticated: \(supabaseService.currentUser != nil)")
        if let user = supabaseService.currentUser {
            print("📸 User ID: \(user.id)")
        } else {
            print("❌ NO USER AUTHENTICATED - Upload will fail!")
            uploadErrorMessage = "You must be logged in to upload photos"
            showUploadError = true
            return
        }

        do {
            // Upload to Supabase Storage
            print("📸 Calling supabaseService.uploadProfilePicture...")
            let avatarURL = try await supabaseService.uploadProfilePicture(imageData)

            // Store the URL for later use
            uploadedAvatarURL = avatarURL

            print("✅ [5/5] Photo uploaded successfully!")
            print("✅ Avatar URL: \(avatarURL)")
            print("✅ URL stored in uploadedAvatarURL")

            // Show immediate success feedback
            showUploadSuccess = true

            // Trigger parent view to reload avatar
            onPhotoUploaded()

        } catch {
            // Clear any previous upload URL on failure
            uploadedAvatarURL = nil

            print("❌ [UPLOAD FAILED]")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error: \(error)")
            print("❌ Localized description: \(error.localizedDescription)")

            uploadErrorMessage = "Upload failed: \(error.localizedDescription)"
            showUploadError = true
        }
    }

    private func saveProfile() async {
        print("\n💾 [SAVE PROFILE] Button tapped")
        print("💾 Current state:")
        print("   - uploadedAvatarURL: \(uploadedAvatarURL ?? "nil")")
        print("   - isUploadingPhoto: \(isUploadingPhoto)")
        print("   - editedName: \(editedName)")
        print("   - editedEmail: \(editedEmail)")

        // Update local model
        user.name = editedName
        user.email = editedEmail

        do {
            // Save profile data to Supabase
            if let avatarURL = uploadedAvatarURL {
                print("💾 Saving profile WITH avatar URL...")
                try await supabaseService.updateUserProfile(avatarURL: avatarURL)
                print("✅ Profile saved successfully with avatar: \(avatarURL)")

                // Show success message
                if !isUploadingPhoto {
                    print("✅ Showing success alert")
                    showSuccessMessage = true
                } else {
                    print("⚠️ Still uploading, not showing success alert")
                }
            } else {
                // No avatar to save - just update local fields
                print("ℹ️ No avatar URL to save (photo may not have been uploaded)")
                print("ℹ️ Dismissing Edit Profile sheet")

                // Still dismiss if nothing is uploading
                if !isUploadingPhoto {
                    dismiss()
                } else {
                    print("⚠️ Still uploading, not dismissing")
                }
            }

            // TODO: Also save name and other profile fields when schema is ready

        } catch {
            print("❌ [SAVE FAILED]")
            print("❌ Error: \(error)")
            print("❌ Localized description: \(error.localizedDescription)")

            uploadErrorMessage = "Failed to save profile: \(error.localizedDescription)"
            showUploadError = true
        }

        print("💾 [SAVE PROFILE] Complete\n")
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