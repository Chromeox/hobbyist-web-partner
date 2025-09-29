import SwiftUI

// MARK: - Welcome Step View

struct WelcomeStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()

                // Enhanced App Logo with Vancouver elements
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 140)

                    Image(systemName: "figure.yoga")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }

                VStack(spacing: 16) {
                    Text("Welcome to HobbyApp!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))

                    Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 12) {
                    FeatureHighlight(
                        icon: "magnifyingglass.circle.fill",
                        title: "Discover Vancouver Classes",
                        description: "Find pottery at Claymates, cooking classes in Gastown, and more"
                    )

                    FeatureHighlight(
                        icon: "calendar.circle.fill",
                        title: "Easy Booking",
                        description: "Reserve your spot in just a few taps"
                    )

                    FeatureHighlight(
                        icon: "person.2.circle.fill",
                        title: "Creative Community",
                        description: "Connect with fellow hobbyists and discover new passions"
                    )
                }

                Spacer()
            }
        }
        .padding()
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Profile Setup Step View

struct ProfileSetupStepView: View {
    @Binding var preferences: [String: Any]
    @State private var fullName = ""
    @State private var selectedNeighborhood = "Select Neighborhood"

    private let vancouverNeighborhoods = [
        "Select Neighborhood", "Downtown", "Gastown", "Yaletown", "West End",
        "Kitsilano", "Commercial Drive", "Mount Pleasant", "Fairview", "Kerrisdale"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Tell us about yourself")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Help us personalize your Vancouver creative class experience")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter your full name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.name)
                            .onChange(of: fullName) { oldValue, newValue in
                                preferences["fullName"] = newValue
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Neighborhood")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Menu {
                            ForEach(vancouverNeighborhoods, id: \.self) { neighborhood in
                                Button(neighborhood) {
                                    selectedNeighborhood = neighborhood
                                    if neighborhood != "Select Neighborhood" {
                                        preferences["neighborhood"] = neighborhood
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedNeighborhood)
                                    .foregroundColor(selectedNeighborhood == "Select Neighborhood" ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Preferences Step View

struct PreferencesStepView: View {
    @Binding var preferences: [String: Any]
    @State private var selectedTimes: Set<String> = []
    @State private var selectedBudget = "$50-75"
    @State private var selectedGroupSize = "Small groups (4-8 people)"

    private let timeOptions = ["Morning", "Afternoon", "Evening", "Weekend"]
    private let budgetOptions = ["$25-50", "$50-75", "$75-100", "$100+"]
    private let groupSizeOptions = ["Small groups (4-8 people)", "Medium groups (8-15 people)", "Large classes (15+ people)", "One-on-one sessions"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Your Class Preferences")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Help us find the perfect classes for your schedule and budget")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 24) {
                    // Preferred Times
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred Times")
                            .font(.headline)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(timeOptions, id: \.self) { time in
                                Button(action: {
                                    if selectedTimes.contains(time) {
                                        selectedTimes.remove(time)
                                    } else {
                                        selectedTimes.insert(time)
                                    }
                                    preferences["preferredTimes"] = Array(selectedTimes)
                                }) {
                                    Text(time)
                                        .font(.body)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(selectedTimes.contains(time) ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(selectedTimes.contains(time) ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Budget Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget per Class")
                            .font(.headline)

                        VStack(spacing: 8) {
                            ForEach(budgetOptions, id: \.self) { budget in
                                Button(action: {
                                    selectedBudget = budget
                                    preferences["budgetRange"] = budget
                                }) {
                                    HStack {
                                        Text(budget)
                                            .font(.body)
                                        Spacer()
                                        if selectedBudget == budget {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }

                    // Group Size Preference
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Group Size Preference")
                            .font(.headline)

                        VStack(spacing: 8) {
                            ForEach(groupSizeOptions, id: \.self) { size in
                                Button(action: {
                                    selectedGroupSize = size
                                    preferences["groupSize"] = size
                                }) {
                                    HStack {
                                        Text(size)
                                            .font(.body)
                                        Spacer()
                                        if selectedGroupSize == size {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Interests Step View

struct InterestsStepView: View {
    @Binding var preferences: [String: Any]
    @State private var selectedInterests: Set<String> = []

    private let interestCategories = [
        InterestCategory(name: "Pottery & Ceramics", icon: "paintpalette.fill", color: .orange, description: "Hand-building, wheel throwing at Claymates"),
        InterestCategory(name: "Cooking & Culinary", icon: "chef.hat.fill", color: .red, description: "From basics to advanced cuisine"),
        InterestCategory(name: "Arts & Crafts", icon: "paintbrush.fill", color: .purple, description: "Painting, drawing, mixed media"),
        InterestCategory(name: "Photography", icon: "camera.fill", color: .blue, description: "Digital, film, and street photography"),
        InterestCategory(name: "Music & Performance", icon: "music.note", color: .green, description: "Instruments, singing, performance"),
        InterestCategory(name: "Dance & Movement", icon: "figure.dance", color: .pink, description: "Various dance styles and movement arts")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("What interests you?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Select the creative activities that spark your curiosity")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(interestCategories, id: \.name) { category in
                        InterestCategoryCard(
                            category: category,
                            isSelected: selectedInterests.contains(category.name)
                        ) {
                            if selectedInterests.contains(category.name) {
                                selectedInterests.remove(category.name)
                            } else {
                                selectedInterests.insert(category.name)
                            }
                            preferences["interests"] = Array(selectedInterests)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .padding()
    }
}

struct InterestCategory {
    let name: String
    let icon: String
    let color: Color
    let description: String
}

struct InterestCategoryCard: View {
    let category: InterestCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                }

                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? category.color.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Notifications Step View

struct NotificationsStepView: View {
    @Binding var preferences: [String: Any]
    @State private var enableNotifications = true
    @State private var classReminders = true
    @State private var newClasses = true
    @State private var specialOffers = false
    @State private var communityUpdates = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "bell.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Stay in the Loop")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Get notifications about your classes and discover new opportunities")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                VStack(spacing: 16) {
                    NotificationToggle(
                        title: "Class Reminders",
                        description: "Get reminded about your upcoming classes",
                        isOn: $classReminders
                    )

                    NotificationToggle(
                        title: "New Classes",
                        description: "Discover new classes in your areas of interest",
                        isOn: $newClasses
                    )

                    NotificationToggle(
                        title: "Special Offers",
                        description: "Be the first to know about discounts and promotions",
                        isOn: $specialOffers
                    )

                    NotificationToggle(
                        title: "Community Updates",
                        description: "Stay connected with the Vancouver creative community",
                        isOn: $communityUpdates
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .padding()
        .onAppear {
            saveNotificationPreferences()
        }
        .onChange(of: classReminders) { _, _ in saveNotificationPreferences() }
        .onChange(of: newClasses) { _, _ in saveNotificationPreferences() }
        .onChange(of: specialOffers) { _, _ in saveNotificationPreferences() }
        .onChange(of: communityUpdates) { _, _ in saveNotificationPreferences() }
    }

    private func saveNotificationPreferences() {
        preferences["notifications"] = [
            "classReminders": classReminders,
            "newClasses": newClasses,
            "specialOffers": specialOffers,
            "communityUpdates": communityUpdates
        ]
    }
}

struct NotificationToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Completion Step View

struct CompletionStepView: View {
    let preferences: [String: Any]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()

                // Success Animation
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }

                VStack(spacing: 16) {
                    Text("Welcome to Vancouver's Creative Community!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))

                    Text("You're all set! We've personalized your experience based on your preferences.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Preference Summary
                PreferenceSummaryView(preferences: preferences)

                VStack(spacing: 16) {
                    Text("Ready to discover amazing classes?")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("Your personalized class recommendations are waiting for you!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
        }
        .padding()
    }
}

struct PreferenceSummaryView: View {
    let preferences: [String: Any]

    var body: some View {
        VStack(spacing: 12) {
            if let interests = preferences["interests"] as? [String], !interests.isEmpty {
                SummaryCard(
                    icon: "heart.fill",
                    title: "Interests",
                    value: interests.joined(separator: ", "),
                    color: .red
                )
            }

            if let neighborhood = preferences["neighborhood"] as? String {
                SummaryCard(
                    icon: "location.fill",
                    title: "Preferred Area",
                    value: neighborhood,
                    color: .blue
                )
            }

            if let budget = preferences["budgetRange"] as? String {
                SummaryCard(
                    icon: "dollarsign.circle.fill",
                    title: "Budget Range",
                    value: budget,
                    color: .green
                )
            }
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}