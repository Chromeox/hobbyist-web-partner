import SwiftUI

/// Demographics collection step for onboarding
/// Captures age, gender, and Vancouver neighborhood preferences
struct DemographicsStep: View {
    @Binding var userPreferences: [String: Any]
    @State private var selectedAgeRange: String = ""
    @State private var selectedGender: String = ""
    @State private var selectedNeighborhood: String = ""
    @State private var showingNeighborhoodPicker = false
    
    private let ageRanges = [
        "18-25", "26-35", "36-45", "46-55", "55+"
    ]
    
    private let genderOptions = [
        "Woman", "Man", "Non-binary", "Prefer not to say"
    ]
    
    private let vancouverNeighborhoods = [
        "Downtown/Yaletown", "Kitsilano", "Commercial Drive",
        "Mount Pleasant", "Gastown", "West End", "Fairview",
        "East Vancouver", "North Shore", "Richmond",
        "Burnaby", "Other"
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BrandConstants.Spacing.xl) {
                Spacer(minLength: BrandConstants.Spacing.xxl)
                
                // Welcoming header
                VStack(spacing: BrandConstants.Spacing.md) {
                    // Friendly icon
                    ZStack {
                        Circle()
                            .fill(BrandConstants.Colors.surface.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.2.circle.fill")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                    }
                    
                    Text("Let's get to know you!")
                        .font(BrandConstants.Typography.largeTitle)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .multilineTextAlignment(.center)
                    
                    Text("Help us personalize your Vancouver creative experience")
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BrandConstants.Spacing.md)
                }
                
                // Demographics form in glassmorphic card
                VStack(spacing: BrandConstants.Spacing.lg) {
                    // Age range selection
                    demographicSection(
                        title: "What's your age range?",
                        subtitle: "This helps us recommend age-appropriate classes"
                    ) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                            ForEach(ageRanges, id: \.self) { range in
                                SelectionButton(
                                    title: range,
                                    isSelected: selectedAgeRange == range
                                ) {
                                    selectedAgeRange = range
                                    userPreferences["age_range"] = range
                                }
                            }
                        }
                    }
                    
                    // Gender selection
                    demographicSection(
                        title: "How do you identify?",
                        subtitle: "Optional - helps create inclusive class recommendations"
                    ) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                            ForEach(genderOptions, id: \.self) { option in
                                SelectionButton(
                                    title: option,
                                    isSelected: selectedGender == option
                                ) {
                                    selectedGender = option
                                    userPreferences["gender"] = option
                                }
                            }
                        }
                    }
                    
                    // Neighborhood selection
                    demographicSection(
                        title: "Where in Vancouver are you?",
                        subtitle: "We'll prioritize classes near you"
                    ) {
                        Button(action: {
                            showingNeighborhoodPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                                    Text(selectedNeighborhood.isEmpty ? "Select your area" : selectedNeighborhood)
                                        .font(BrandConstants.Typography.body)
                                        .foregroundColor(selectedNeighborhood.isEmpty ? .secondary : BrandConstants.Colors.text)
                                    
                                    if !selectedNeighborhood.isEmpty {
                                        Text("Tap to change")
                                            .font(BrandConstants.Typography.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(BrandConstants.Spacing.md)
                            .background(Color(.systemBackground))
                            .cornerRadius(BrandConstants.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                                    .stroke(selectedNeighborhood.isEmpty ? Color(.systemGray4) : BrandConstants.Colors.primary, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(BrandConstants.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                        .fill(BrandConstants.Colors.surface.opacity(0.15))
                        .shadow(color: BrandConstants.Colors.text.opacity(0.1), radius: 16, y: 8)
                )
                .padding(.horizontal, BrandConstants.Spacing.md)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingNeighborhoodPicker) {
            NeighborhoodPickerView(
                selectedNeighborhood: $selectedNeighborhood,
                neighborhoods: vancouverNeighborhoods
            ) { neighborhood in
                selectedNeighborhood = neighborhood
                userPreferences["neighborhood"] = neighborhood
                showingNeighborhoodPicker = false
            }
        }
        .onAppear {
            // Load existing preferences if available
            if let ageRange = userPreferences["age_range"] as? String {
                selectedAgeRange = ageRange
            }
            if let gender = userPreferences["gender"] as? String {
                selectedGender = gender
            }
            if let neighborhood = userPreferences["neighborhood"] as? String {
                selectedNeighborhood = neighborhood
            }
        }
    }
    
    @ViewBuilder
    private func demographicSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(BrandConstants.Colors.surface)
                
                Text(subtitle)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(BrandConstants.Colors.surface.opacity(0.8))
            }
            
            content()
        }
    }
}

/// Reusable selection button for demographics
private struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? BrandConstants.Colors.surface : BrandConstants.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BrandConstants.Spacing.md)
                .padding(.horizontal, BrandConstants.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                        .fill(isSelected ? BrandConstants.Colors.primary : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                        .stroke(
                            isSelected ? BrandConstants.Colors.primary : Color(.systemGray4),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Neighborhood picker sheet
private struct NeighborhoodPickerView: View {
    @Binding var selectedNeighborhood: String
    let neighborhoods: [String]
    let onSelection: (String) -> Void
    
    var body: some View {
        NavigationStack {
            List(neighborhoods, id: \.self) { neighborhood in
                Button(action: {
                    onSelection(neighborhood)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(neighborhood)
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(BrandConstants.Colors.text)
                            
                            if neighborhood == "Downtown/Yaletown" {
                                Text("Urban core, transit accessible")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            } else if neighborhood == "Kitsilano" {
                                Text("Beach community, yoga studios")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            } else if neighborhood == "Commercial Drive" {
                                Text("Artistic community, diverse culture")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedNeighborhood == neighborhood {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Your Area")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        BrandConstants.Gradients.landing
            .ignoresSafeArea()
        
        DemographicsStep(userPreferences: .constant([:]))
    }
}