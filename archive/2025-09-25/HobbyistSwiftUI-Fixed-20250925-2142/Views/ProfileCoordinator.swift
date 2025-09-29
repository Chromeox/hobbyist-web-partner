import SwiftUI

// MARK: - Profile Coordinator

struct ProfileCoordinator: View {
    @StateObject private var profileService = ProfileService()
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    @State private var currentStep: ProfileStep = .overview
    @State private var showingImagePicker = false
    @State private var isEditing = false

    let onComplete: (() -> Void)?

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Group {
                if profileService.currentProfile == nil {
                    ProfileCreationView(
                        profileService: profileService,
                        currentStep: $currentStep,
                        onComplete: {
                            onComplete?()
                        }
                    )
                } else {
                    ProfileOverviewView(
                        profileService: profileService,
                        isEditing: $isEditing,
                        onEdit: {
                            isEditing = true
                        }
                    )
                }
            }
        }
        .task {
            do {
                try await profileService.initialize()
                try await profileService.start()
                _ = try await profileService.loadProfile()
            } catch {
                print("❌ Failed to initialize profile: \(error)")
            }
        }
    }
}

// MARK: - Profile Steps

enum ProfileStep: String, CaseIterable {
    case overview = "overview"
    case basicInfo = "basic_info"
    case experience = "experience"
    case interests = "interests"
    case preferences = "preferences"
    case social = "social"
    case completion = "completion"

    var displayName: String {
        switch self {
        case .overview:
            return "Profile Overview"
        case .basicInfo:
            return "Basic Information"
        case .experience:
            return "Experience & Budget"
        case .interests:
            return "Interests & Times"
        case .preferences:
            return "Preferences"
        case .social:
            return "Social & Location"
        case .completion:
            return "Complete Profile"
        }
    }

    var iconName: String {
        switch self {
        case .overview:
            return "person.circle"
        case .basicInfo:
            return "person.text.rectangle"
        case .experience:
            return "star.circle"
        case .interests:
            return "heart.circle"
        case .preferences:
            return "gear.circle"
        case .social:
            return "globe.circle"
        case .completion:
            return "checkmark.circle"
        }
    }
}

// MARK: - Profile Creation Flow

struct ProfileCreationView: View {
    @ObservedObject var profileService: ProfileService
    @Binding var currentStep: ProfileStep
    @EnvironmentObject var supabaseService: SimpleSupabaseService
    @State private var profile: UserProfile
    let onComplete: () -> Void

    init(profileService: ProfileService, currentStep: Binding<ProfileStep>, onComplete: @escaping () -> Void) {
        self.profileService = profileService
        self._currentStep = currentStep
        self.onComplete = onComplete

        // Initialize with basic profile data
        let user = SimpleSupabaseService.shared.currentUser
        self._profile = State(initialValue: UserProfile(
            userId: user?.id ?? "",
            fullName: user?.name ?? "",
            email: user?.email ?? ""
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProfileProgressBar(currentStep: currentStep, totalSteps: ProfileStep.allCases.count - 2)
                .padding()

            // Content
            TabView(selection: $currentStep) {
                ProfileBasicInfoView(profile: $profile)
                    .tag(ProfileStep.basicInfo)

                ProfileExperienceView(profile: $profile)
                    .tag(ProfileStep.experience)

                ProfileInterestsView(profile: $profile)
                    .tag(ProfileStep.interests)

                ProfilePreferencesView(profile: $profile)
                    .tag(ProfileStep.preferences)

                ProfileSocialView(profile: $profile)
                    .tag(ProfileStep.social)

                ProfileCompletionView(
                    profile: $profile,
                    profileService: profileService,
                    onComplete: onComplete
                )
                .tag(ProfileStep.completion)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Navigation
            ProfileNavigationView(
                currentStep: $currentStep,
                profile: profile,
                onSave: saveProfile
            )
            .padding()
        }
        .navigationTitle("Create Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    private func saveProfile() {
        Task {
            do {
                try await profileService.saveProfile(profile)
            } catch {
                print("❌ Failed to save profile: \(error)")
            }
        }
    }
}

// MARK: - Profile Overview

struct ProfileOverviewView: View {
    @ObservedObject var profileService: ProfileService
    @Binding var isEditing: Bool
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let profile = profileService.currentProfile {
                    // Profile Header
                    ProfileHeaderView(profile: profile)

                    // Profile Stats
                    ProfileStatsView(profile: profile)

                    // Profile Sections
                    VStack(spacing: 16) {
                        ProfileSectionCard(
                            title: "Personal Information",
                            icon: "person.circle",
                            content: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProfileDetailRow(label: "Name", value: profile.fullName)
                                    ProfileDetailRow(label: "Email", value: profile.email)
                                    if let bio = profile.bio {
                                        ProfileDetailRow(label: "Bio", value: bio)
                                    }
                                }
                            }
                        )

                        ProfileSectionCard(
                            title: "Experience & Preferences",
                            icon: "star.circle",
                            content: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProfileDetailRow(label: "Experience", value: profile.experienceLevel.displayName)
                                    ProfileDetailRow(label: "Budget Range", value: profile.budgetRange.displayName)
                                    if !profile.preferredTimes.isEmpty {
                                        ProfileDetailRow(label: "Preferred Times", value: profile.preferredTimes.joined(separator: ", "))
                                    }
                                }
                            }
                        )

                        if !profile.interests.isEmpty {
                            ProfileSectionCard(
                                title: "Interests",
                                icon: "heart.circle",
                                content: {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(profile.interests, id: \.self) { interest in
                                            Text(interest)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            )
                        }

                        if let location = profile.location {
                            ProfileSectionCard(
                                title: "Location",
                                icon: "location.circle",
                                content: {
                                    ProfileDetailRow(label: "Location", value: location.displayName)
                                }
                            )
                        }

                        if !profile.socialLinks.isEmpty {
                            ProfileSectionCard(
                                title: "Social Links",
                                icon: "globe.circle",
                                content: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(profile.socialLinks, id: \.platform) { link in
                                            ProfileSocialLinkRow(socialLink: link)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // No profile state
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)

                        Text("No Profile Created")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create your profile to get personalized class recommendations")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Create Profile") {
                            onEdit()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if profileService.currentProfile != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        onEdit()
                    }
                }
            }
        }
    }
}

// MARK: - Profile Progress Bar

struct ProfileProgressBar: View {
    let currentStep: ProfileStep
    let totalSteps: Int

    private var currentStepIndex: Int {
        ProfileStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Profile Setup")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(currentStepIndex + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            if let imageUrl = profile.profileImageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                Text(profile.fullName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(profile.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let bio = profile.bio {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
    }
}

// MARK: - Profile Stats

struct ProfileStatsView: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 20) {
            ProfileStatCard(
                title: "Profile",
                value: "\(Int(profile.completionPercentage * 100))%",
                subtitle: "Complete",
                color: profile.completionPercentage > 0.8 ? .green : .orange
            )

            ProfileStatCard(
                title: "Interests",
                value: "\(profile.interests.count)",
                subtitle: "Selected",
                color: .blue
            )

            ProfileStatCard(
                title: "Experience",
                value: profile.experienceLevel.displayName,
                subtitle: "Level",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Profile Section Card

struct ProfileSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title2)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

// MARK: - Profile Detail Row

struct ProfileDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)

            Spacer()
        }
    }
}

// MARK: - Profile Social Link Row

struct ProfileSocialLinkRow: View {
    let socialLink: SocialLink

    var body: some View {
        HStack {
            Image(systemName: socialLink.platform.iconName)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(socialLink.platform.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("@\(socialLink.username)")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Profile Navigation

struct ProfileNavigationView: View {
    @Binding var currentStep: ProfileStep
    let profile: UserProfile
    let onSave: () -> Void

    private let steps = ProfileStep.allCases.filter { $0 != .overview }

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    private var canContinue: Bool {
        switch currentStep {
        case .basicInfo:
            return !profile.fullName.isEmpty
        case .interests:
            return !profile.interests.isEmpty
        default:
            return true
        }
    }

    var body: some View {
        HStack {
            if currentIndex > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep = steps[currentIndex - 1]
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            if currentIndex < steps.count - 1 {
                Button("Next") {
                    onSave()
                    withAnimation {
                        currentStep = steps[currentIndex + 1]
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(canContinue ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(!canContinue)
            }
        }
    }
}

#Preview("Profile Coordinator") {
    ProfileCoordinator()
        .environmentObject(SimpleSupabaseService.shared)
}