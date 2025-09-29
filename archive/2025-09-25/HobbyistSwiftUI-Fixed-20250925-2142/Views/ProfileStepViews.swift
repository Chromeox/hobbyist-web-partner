import SwiftUI
import PhotosUI

// MARK: - Profile Basic Info View

struct ProfileBasicInfoView: View {
    @Binding var profile: UserProfile
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Let's start with the basics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Tell us a bit about yourself so we can personalize your experience")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Profile Image Section
                VStack(spacing: 12) {
                    if let imageData = profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.gray)
                    }

                    PhotosPicker("Add Photo", selection: $selectedPhoto, matching: .images)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                // Form Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name *")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter your full name", text: Binding(
                            get: { profile.fullName },
                            set: { newValue in
                                profile = UserProfile(
                                    id: profile.id,
                                    userId: profile.userId,
                                    fullName: newValue,
                                    email: profile.email,
                                    profileImageUrl: profile.profileImageUrl,
                                    bio: profile.bio,
                                    experienceLevel: profile.experienceLevel,
                                    interests: profile.interests,
                                    preferredTimes: profile.preferredTimes,
                                    budgetRange: profile.budgetRange,
                                    location: profile.location,
                                    socialLinks: profile.socialLinks,
                                    preferences: profile.preferences,
                                    createdAt: profile.createdAt,
                                    updatedAt: Date()
                                )
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Tell us about yourself (optional)", text: Binding(
                            get: { profile.bio ?? "" },
                            set: { newValue in
                                profile = UserProfile(
                                    id: profile.id,
                                    userId: profile.userId,
                                    fullName: profile.fullName,
                                    email: profile.email,
                                    profileImageUrl: profile.profileImageUrl,
                                    bio: newValue.isEmpty ? nil : newValue,
                                    experienceLevel: profile.experienceLevel,
                                    interests: profile.interests,
                                    preferredTimes: profile.preferredTimes,
                                    budgetRange: profile.budgetRange,
                                    location: profile.location,
                                    socialLinks: profile.socialLinks,
                                    preferences: profile.preferences,
                                    createdAt: profile.createdAt,
                                    updatedAt: Date()
                                )
                            }
                        ), axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                if let newPhoto = newPhoto,
                   let data = try? await newPhoto.loadTransferable(type: Data.self) {
                    profileImageData = data
                }
            }
        }
    }
}

// MARK: - Profile Experience View

struct ProfileExperienceView: View {
    @Binding var profile: UserProfile

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Experience & Budget")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Help us match you with the right classes and activities")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 24) {
                    // Experience Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Experience Level")
                            .font(.headline)
                            .foregroundColor(.primary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                ExperienceLevelCard(
                                    level: level,
                                    isSelected: profile.experienceLevel == level
                                ) {
                                    profile = UserProfile(
                                        id: profile.id,
                                        userId: profile.userId,
                                        fullName: profile.fullName,
                                        email: profile.email,
                                        profileImageUrl: profile.profileImageUrl,
                                        bio: profile.bio,
                                        experienceLevel: level,
                                        interests: profile.interests,
                                        preferredTimes: profile.preferredTimes,
                                        budgetRange: profile.budgetRange,
                                        location: profile.location,
                                        socialLinks: profile.socialLinks,
                                        preferences: profile.preferences,
                                        createdAt: profile.createdAt,
                                        updatedAt: Date()
                                    )
                                }
                            }
                        }
                    }

                    // Budget Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget Range")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("What's your typical budget per class?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(BudgetRange.allCases, id: \.self) { budget in
                                BudgetRangeCard(
                                    budget: budget,
                                    isSelected: profile.budgetRange == budget
                                ) {
                                    profile = UserProfile(
                                        id: profile.id,
                                        userId: profile.userId,
                                        fullName: profile.fullName,
                                        email: profile.email,
                                        profileImageUrl: profile.profileImageUrl,
                                        bio: profile.bio,
                                        experienceLevel: profile.experienceLevel,
                                        interests: profile.interests,
                                        preferredTimes: profile.preferredTimes,
                                        budgetRange: budget,
                                        location: profile.location,
                                        socialLinks: profile.socialLinks,
                                        preferences: profile.preferences,
                                        createdAt: profile.createdAt,
                                        updatedAt: Date()
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

// MARK: - Profile Interests View

struct ProfileInterestsView: View {
    @Binding var profile: UserProfile
    @State private var selectedInterests: Set<String> = []
    @State private var selectedTimes: Set<String> = []

    private let availableInterests = [
        "Yoga", "Cooking", "Pottery", "Painting", "Dance", "Photography",
        "Fitness", "Martial Arts", "Music", "Writing", "Gardening", "Crafts",
        "Languages", "Meditation", "Wine Tasting", "Baking", "Woodworking",
        "Knitting", "Calligraphy", "Jewelry Making"
    ]

    private let availableTimes = [
        "Early Morning (6-9 AM)", "Morning (9-12 PM)", "Afternoon (12-5 PM)",
        "Evening (5-8 PM)", "Night (8-10 PM)", "Weekends Only"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Interests & Schedule")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Choose activities you'd like to explore and your preferred times")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 24) {
                    // Interests
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests *")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Select at least one interest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(availableInterests, id: \.self) { interest in
                                InterestTag(
                                    text: interest,
                                    isSelected: selectedInterests.contains(interest)
                                ) {
                                    if selectedInterests.contains(interest) {
                                        selectedInterests.remove(interest)
                                    } else {
                                        selectedInterests.insert(interest)
                                    }
                                    updateProfile()
                                }
                            }
                        }
                    }

                    // Preferred Times
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred Times")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("When do you prefer to take classes?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            ForEach(availableTimes, id: \.self) { time in
                                TimeSlotCard(
                                    time: time,
                                    isSelected: selectedTimes.contains(time)
                                ) {
                                    if selectedTimes.contains(time) {
                                        selectedTimes.remove(time)
                                    } else {
                                        selectedTimes.insert(time)
                                    }
                                    updateProfile()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            selectedInterests = Set(profile.interests)
            selectedTimes = Set(profile.preferredTimes)
        }
    }

    private func updateProfile() {
        profile = UserProfile(
            id: profile.id,
            userId: profile.userId,
            fullName: profile.fullName,
            email: profile.email,
            profileImageUrl: profile.profileImageUrl,
            bio: profile.bio,
            experienceLevel: profile.experienceLevel,
            interests: Array(selectedInterests),
            preferredTimes: Array(selectedTimes),
            budgetRange: profile.budgetRange,
            location: profile.location,
            socialLinks: profile.socialLinks,
            preferences: profile.preferences,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Profile Preferences View

struct ProfilePreferencesView: View {
    @Binding var profile: UserProfile
    @State private var preferences: ProfilePreferences

    init(profile: Binding<UserProfile>) {
        self._profile = profile
        self._preferences = State(initialValue: profile.wrappedValue.preferences)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Notification Preferences")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Choose how you'd like to stay updated")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 16) {
                    PreferenceToggleCard(
                        title: "Class Reminders",
                        description: "Get notified before your classes start",
                        icon: "bell.circle",
                        isOn: Binding(
                            get: { preferences.classReminders },
                            set: { newValue in
                                preferences = ProfilePreferences(
                                    classReminders: newValue,
                                    newClassAlerts: preferences.newClassAlerts,
                                    weeklyDigest: preferences.weeklyDigest,
                                    marketingEmails: preferences.marketingEmails,
                                    locationEnabled: preferences.locationEnabled,
                                    profileVisibility: preferences.profileVisibility
                                )
                                updateProfile()
                            }
                        )
                    )

                    PreferenceToggleCard(
                        title: "New Class Alerts",
                        description: "Be the first to know about new classes",
                        icon: "sparkles",
                        isOn: Binding(
                            get: { preferences.newClassAlerts },
                            set: { newValue in
                                preferences = ProfilePreferences(
                                    classReminders: preferences.classReminders,
                                    newClassAlerts: newValue,
                                    weeklyDigest: preferences.weeklyDigest,
                                    marketingEmails: preferences.marketingEmails,
                                    locationEnabled: preferences.locationEnabled,
                                    profileVisibility: preferences.profileVisibility
                                )
                                updateProfile()
                            }
                        )
                    )

                    PreferenceToggleCard(
                        title: "Weekly Digest",
                        description: "Weekly summary of classes and activities",
                        icon: "newspaper",
                        isOn: Binding(
                            get: { preferences.weeklyDigest },
                            set: { newValue in
                                preferences = ProfilePreferences(
                                    classReminders: preferences.classReminders,
                                    newClassAlerts: preferences.newClassAlerts,
                                    weeklyDigest: newValue,
                                    marketingEmails: preferences.marketingEmails,
                                    locationEnabled: preferences.locationEnabled,
                                    profileVisibility: preferences.profileVisibility
                                )
                                updateProfile()
                            }
                        )
                    )

                    PreferenceToggleCard(
                        title: "Location Services",
                        description: "Find classes and activities near you",
                        icon: "location.circle",
                        isOn: Binding(
                            get: { preferences.locationEnabled },
                            set: { newValue in
                                preferences = ProfilePreferences(
                                    classReminders: preferences.classReminders,
                                    newClassAlerts: preferences.newClassAlerts,
                                    weeklyDigest: preferences.weeklyDigest,
                                    marketingEmails: preferences.marketingEmails,
                                    locationEnabled: newValue,
                                    profileVisibility: preferences.profileVisibility
                                )
                                updateProfile()
                            }
                        )
                    )

                    // Profile Visibility
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "eye.circle")
                                .foregroundColor(.blue)
                                .font(.title2)

                            Text("Profile Visibility")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Picker("Profile Visibility", selection: Binding(
                            get: { preferences.profileVisibility },
                            set: { newValue in
                                preferences = ProfilePreferences(
                                    classReminders: preferences.classReminders,
                                    newClassAlerts: preferences.newClassAlerts,
                                    weeklyDigest: preferences.weeklyDigest,
                                    marketingEmails: preferences.marketingEmails,
                                    locationEnabled: preferences.locationEnabled,
                                    profileVisibility: newValue
                                )
                                updateProfile()
                            }
                        )) {
                            ForEach(ProfilePreferences.ProfileVisibility.allCases, id: \.self) { visibility in
                                Text(visibility.displayName).tag(visibility)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private func updateProfile() {
        profile = UserProfile(
            id: profile.id,
            userId: profile.userId,
            fullName: profile.fullName,
            email: profile.email,
            profileImageUrl: profile.profileImageUrl,
            bio: profile.bio,
            experienceLevel: profile.experienceLevel,
            interests: profile.interests,
            preferredTimes: profile.preferredTimes,
            budgetRange: profile.budgetRange,
            location: profile.location,
            socialLinks: profile.socialLinks,
            preferences: preferences,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Profile Social View

struct ProfileSocialView: View {
    @Binding var profile: UserProfile
    @State private var socialLinks: [SocialLink] = []
    @State private var location: ProfileLocation?

    // Location fields
    @State private var address = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postalCode = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Location & Social")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Help others connect with you and find local classes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 24) {
                    // Location Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location (Optional)")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(spacing: 12) {
                            TextField("Address", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            HStack(spacing: 12) {
                                TextField("City", text: $city)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                TextField("Province", text: $province)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            TextField("Postal Code", text: $postalCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }

                    // Social Links Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Social Links (Optional)")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(spacing: 12) {
                            ForEach(socialLinks.indices, id: \.self) { index in
                                SocialLinkInputRow(
                                    socialLink: $socialLinks[index]
                                ) {
                                    socialLinks.remove(at: index)
                                    updateProfile()
                                }
                            }

                            Button("Add Social Link") {
                                socialLinks.append(SocialLink(
                                    platform: .instagram,
                                    username: "",
                                    url: ""
                                ))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            socialLinks = profile.socialLinks
            if let loc = profile.location {
                location = loc
                address = loc.address
                city = loc.city
                province = loc.province
                postalCode = loc.postalCode
            }
        }
        .onChange(of: address) { _, _ in updateLocation() }
        .onChange(of: city) { _, _ in updateLocation() }
        .onChange(of: province) { _, _ in updateLocation() }
        .onChange(of: postalCode) { _, _ in updateLocation() }
    }

    private func updateLocation() {
        if !city.isEmpty && !province.isEmpty {
            location = ProfileLocation(
                address: address,
                city: city,
                province: province,
                postalCode: postalCode,
                latitude: nil,
                longitude: nil
            )
        } else {
            location = nil
        }
        updateProfile()
    }

    private func updateProfile() {
        profile = UserProfile(
            id: profile.id,
            userId: profile.userId,
            fullName: profile.fullName,
            email: profile.email,
            profileImageUrl: profile.profileImageUrl,
            bio: profile.bio,
            experienceLevel: profile.experienceLevel,
            interests: profile.interests,
            preferredTimes: profile.preferredTimes,
            budgetRange: profile.budgetRange,
            location: location,
            socialLinks: socialLinks,
            preferences: profile.preferences,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Profile Completion View

struct ProfileCompletionView: View {
    @Binding var profile: UserProfile
    @ObservedObject var profileService: ProfileService
    @State private var isCreating = false
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("Profile Complete!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("You're all set to discover and book amazing classes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Profile Summary
                ProfileCompletionSummaryView(profile: profile)

                Button(action: createProfile) {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create My Profile")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isCreating)
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private func createProfile() {
        isCreating = true

        Task {
            do {
                try await profileService.saveProfile(profile)
                await MainActor.run {
                    isCreating = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                }
                print("❌ Failed to create profile: \(error)")
            }
        }
    }
}

struct ProfileCompletionSummaryView: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 12) {
            Text("Profile Summary")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                HStack {
                    Text("Completion:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(profile.completionPercentage * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Interests:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(profile.interests.count) selected")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Experience:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(profile.experienceLevel.displayName)
                        .fontWeight(.semibold)
                }

                if let location = profile.location {
                    HStack {
                        Text("Location:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(location.displayName)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Views

struct ExperienceLevelCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(level.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(level.description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct BudgetRangeCard: View {
    let budget: BudgetRange
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(budget.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
}

struct InterestTag: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct TimeSlotCard: View {
    let time: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(time)
                    .font(.subheadline)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct PreferenceToggleCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct SocialLinkInputRow: View {
    @Binding var socialLink: SocialLink
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Picker("Platform", selection: Binding(
                get: { socialLink.platform },
                set: { newPlatform in
                    socialLink = SocialLink(
                        platform: newPlatform,
                        username: socialLink.username,
                        url: socialLink.url
                    )
                }
            )) {
                ForEach(SocialLink.SocialPlatform.allCases, id: \.self) { platform in
                    Text(platform.displayName).tag(platform)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(width: 120)

            TextField("Username", text: Binding(
                get: { socialLink.username },
                set: { newUsername in
                    socialLink = SocialLink(
                        platform: socialLink.platform,
                        username: newUsername,
                        url: newUsername.isEmpty ? "" : generateURL(platform: socialLink.platform, username: newUsername)
                    )
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    private func generateURL(platform: SocialLink.SocialPlatform, username: String) -> String {
        switch platform {
        case .instagram:
            return "https://instagram.com/\(username)"
        case .facebook:
            return "https://facebook.com/\(username)"
        case .twitter:
            return "https://twitter.com/\(username)"
        case .linkedin:
            return "https://linkedin.com/in/\(username)"
        case .website:
            return username.hasPrefix("http") ? username : "https://\(username)"
        }
    }
}

#Preview("Profile Basic Info") {
    ProfileBasicInfoView(profile: .constant(UserProfile(
        userId: "test",
        fullName: "Test User",
        email: "test@example.com"
    )))
}