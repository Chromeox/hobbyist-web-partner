import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.load() }
                    }
                } else if let profile = viewModel.profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            ProfileHeader(
                                profile: profile,
                                avatarURL: viewModel.avatarURL,
                                onEditPhoto: { showingEditProfile = true }
                            )

                            StatsSection(stats: viewModel.stats)

                            ProfileMenuSection(
                                onEditProfile: { showingEditProfile = true },
                                onOpenSettings: { showingSettings = true }
                            )

                            LogoutButton {
                                Task { await supabaseService.signOut() }
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if let profile = viewModel.profile {
                    EditProfileView(
                        profile: profile,
                        currentAvatarURL: viewModel.avatarURL
                    ) {
                        Task { await viewModel.load() }
                    }
                    .environmentObject(supabaseService)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                viewModel.supabaseService = supabaseService
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: SimpleUserProfile?
    @Published var avatarURL: String?
    @Published var stats = ProfileStats()
    @Published var isLoading = false
    @Published var errorMessage: String?

    var supabaseService: SimpleSupabaseService?

    func load() async {
        guard let supabaseService else { return }

        isLoading = true
        errorMessage = nil

        let fetchedProfile = await supabaseService.fetchUserProfile()
        let fetchedAvatar = await supabaseService.fetchUserProfileAvatarURL()
        let bookings = await supabaseService.fetchUserBookings()

        if fetchedProfile == nil,
           supabaseService.errorMessage != nil,
           profile == nil {
            errorMessage = supabaseService.errorMessage
        }

        if let fetchedProfile {
            profile = fetchedProfile
        } else if let currentUser = supabaseService.currentUser {
            profile = SimpleUserProfile(
                id: currentUser.id,
                firstName: "",
                lastName: "",
                fullName: currentUser.name,
                email: currentUser.email,
                avatarURL: fetchedAvatar,
                bio: nil,
                createdAt: nil,
                updatedAt: nil
            )
        }

        avatarURL = fetchedAvatar ?? profile?.avatarURL
        stats = ProfileStats(bookings: bookings)

        isLoading = false
    }
}

struct ProfileStats {
    let upcomingClasses: Int
    let completedClasses: Int
    let totalBookings: Int

    init(bookings: [SimpleBooking] = []) {
        let now = Date()
        upcomingClasses = bookings.filter { $0.bookingDate >= now }.count
        completedClasses = bookings.filter { $0.bookingDate < now }.count
        totalBookings = bookings.count
    }
}

// MARK: - Sections

private struct ProfileHeader: View {
    let profile: SimpleUserProfile
    let avatarURL: String?
    let onEditPhoto: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarURL: avatarURL)

                Button(action: onEditPhoto) {
                    Image(systemName: "camera.fill")
                        .font(BrandConstants.Typography.footnote)
                        .foregroundStyle(Color.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue))
                }
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 6) {
                Text(profile.fullName)
                    .font(BrandConstants.Typography.title2)
                    .fontWeight(.bold)

                Text(profile.email)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundStyle(.secondary)

                Text(profile.memberSinceText)
                    .font(BrandConstants.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal)
    }
}

private struct StatsSection: View {
    let stats: ProfileStats

    var body: some View {
        HStack(spacing: 16) {
            StatItemView(value: "\(stats.upcomingClasses)", label: "Upcoming")
            StatItemView(value: "\(stats.completedClasses)", label: "Completed")
            StatItemView(value: "\(stats.totalBookings)", label: "Total")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal)
    }
}

private struct ProfileMenuSection: View {
    let onEditProfile: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProfileMenuItemView(
                icon: "person.crop.circle",
                title: "Edit Profile",
                subtitle: "Update your personal information",
                action: onEditProfile
            )

            ProfileMenuItemView(
                icon: "calendar",
                title: "My Bookings",
                subtitle: "View upcoming and past classes",
                action: {}
            )

            ProfileMenuItemView(
                icon: "creditcard",
                title: "Credits & Billing",
                subtitle: "Manage your class credits",
                action: {}
            )

            ProfileMenuItemView(
                icon: "gear",
                title: "Settings",
                subtitle: "Notifications and preferences",
                action: onOpenSettings
            )
        }
        .padding(.horizontal)
    }
}

private struct LogoutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text("Log Out")
                    .font(BrandConstants.Typography.headline)
                Spacer()
            }
            .padding()
            .background(Color.red.opacity(0.12))
            .foregroundStyle(Color.red)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

private struct AvatarView: View {
    let avatarURL: String?

    var body: some View {
        Group {
            if let avatarURL,
               let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        FallbackAvatar()
                    @unknown default:
                        FallbackAvatar()
                    }
                }
            } else {
                FallbackAvatar()
            }
        }
        .clipShape(Circle())
        .background(
            Circle()
                .fill(Color.blue.opacity(0.1))
        )
    }

    private struct FallbackAvatar: View {
        var body: some View {
            Image(systemName: "person.fill")
                .font(BrandConstants.Typography.heroTitle)
                .foregroundStyle(Color.blue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct StatItemView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            Text(label)
                .font(BrandConstants.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileMenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(BrandConstants.Typography.title2)
                    .foregroundStyle(Color.blue)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BrandConstants.Typography.headline)
                    Text(subtitle)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView("Loading profile...")
            Text("Fetching your information from Supabase.")
                .font(BrandConstants.Typography.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

private struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(BrandConstants.Typography.heroTitle)
                .foregroundStyle(.red)

            Text("We couldn't load your profile.")
                .font(BrandConstants.Typography.headline)
            Text(message)
                .font(BrandConstants.Typography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(BrandConstants.Typography.heroTitle)
                .foregroundStyle(.secondary)

            Text("Profile unavailable")
                .font(BrandConstants.Typography.headline)
            Text("Sign in to view your profile details.")
                .font(BrandConstants.Typography.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Edit Profile

private struct EditProfileView: View {
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String
    @State private var bio: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var uploadedAvatarURL: String?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    let initialProfile: SimpleUserProfile
    let currentAvatarURL: String?
    let onSave: () -> Void

    init(profile: SimpleUserProfile, currentAvatarURL: String?, onSave: @escaping () -> Void) {
        self.initialProfile = profile
        self.currentAvatarURL = currentAvatarURL
        self.onSave = onSave
        _fullName = State(initialValue: profile.fullName)
        _bio = State(initialValue: profile.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $fullName)
                    Text(initialProfile.email)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Bio") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                }

                Section("Profile Photo") {
                    HStack(spacing: 16) {
                        AvatarPreview(
                            imageData: selectedPhotoData,
                            existingURL: uploadedAvatarURL ?? currentAvatarURL
                        )
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                }
                                Text(isProcessing ? "Uploading..." : "Change Photo")
                            }
                        }
                        .disabled(isProcessing)
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task { await loadPhoto(from: newItem) }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(Color.red)
                            .font(BrandConstants.Typography.footnote)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let compressed = compressImage(data) {
                    selectedPhotoData = compressed
                    try await uploadPhoto(compressed)
                } else {
                    errorMessage = "Unable to process image."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func compressImage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 800
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.jpegData(compressionQuality: 0.85)
    }

    private func uploadPhoto(_ data: Data) async throws {
        guard supabaseService.currentUser != nil else {
            throw NSError(domain: "Profile", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to upload a photo."])
        }

        do {
            let url = try await supabaseService.uploadProfilePicture(data)
            uploadedAvatarURL = url
            errorMessage = nil
        } catch {
            uploadedAvatarURL = nil
            throw error
        }
    }

    private func saveChanges() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await supabaseService.updateUserProfile(
                avatarURL: uploadedAvatarURL,
                fullName: fullName.isEmpty ? nil : fullName,
                bio: bio.isEmpty ? nil : bio
            )
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AvatarPreview: View {
    let imageData: Data?
    let existingURL: String?

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let existingURL, let url = URL(string: existingURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Placeholder()
                    @unknown default:
                        Placeholder()
                    }
                }
            } else {
                Placeholder()
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
    }

    private struct Placeholder: View {
        var body: some View {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .foregroundStyle(Color.blue.opacity(0.3))
        }
    }
}
