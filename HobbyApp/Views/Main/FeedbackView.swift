import SwiftUI

struct FeedbackView: View {
    @State private var feedbackType: FeedbackType = .general
    @State private var subject = ""
    @State private var message = ""
    @State private var contactEmail = ""
    @State private var includeSystemInfo = true
    @State private var rating: Int = 5
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We Value Your Feedback")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("Help us improve your experience by sharing your thoughts, suggestions, or reporting any issues.")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Feedback Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What would you like to share?")
                            .font(BrandConstants.Typography.headline)
                        
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            FeedbackTypeRow(
                                type: type,
                                isSelected: feedbackType == type
                            ) {
                                feedbackType = type
                            }
                        }
                    }
                    
                    // Rating (for app feedback)
                    if feedbackType == .appFeedback {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How would you rate the app?")
                                .font(BrandConstants.Typography.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: { rating = star }) {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.title2)
                                            .foregroundColor(star <= rating ? .yellow : .gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(ratingDescription)
                                    .font(BrandConstants.Typography.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    
                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(BrandConstants.Typography.headline)
                        
                        TextField("Brief description of your feedback", text: $subject)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(BrandConstants.Typography.headline)
                        
                        Text("Please provide as much detail as possible")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(BrandConstants.Colors.background)
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Contact Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Email (Optional)")
                            .font(BrandConstants.Typography.headline)
                        
                        Text("We'll use this to follow up if needed")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("your.email@example.com", text: $contactEmail)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // System Info Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $includeSystemInfo) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include System Information")
                                    .font(BrandConstants.Typography.subheadline)
                                
                                Text("Helps us diagnose technical issues")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if includeSystemInfo {
                            systemInfoView
                        }
                    }
                    .padding()
                    .background(BrandConstants.Colors.background)
                    .cornerRadius(BrandConstants.CornerRadius.md)
                    
                    // Submit Button
                    Button(action: submitFeedback) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            
                            Text(isSubmitting ? "Sending..." : "Send Feedback")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? BrandConstants.Colors.primary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been sent successfully. We appreciate your input!")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var systemInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Information:")
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                SystemInfoRow(label: "App Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                SystemInfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                SystemInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                SystemInfoRow(label: "Device", value: UIDevice.current.model)
                SystemInfoRow(label: "Device Name", value: UIDevice.current.name)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(BrandConstants.CornerRadius.sm)
    }
    
    private var ratingDescription: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitFeedback() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        // Simulate sending feedback
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
            
            await MainActor.run {
                isSubmitting = false
                
                // Randomly succeed or fail for demo purposes
                if Bool.random() {
                    showingSuccess = true
                } else {
                    errorMessage = "Failed to send feedback. Please check your internet connection and try again."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Types and Views

enum FeedbackType: String, CaseIterable {
    case general = "General Feedback"
    case bugReport = "Bug Report"
    case featureRequest = "Feature Request"
    case appFeedback = "App Rating & Review"
    case classIssue = "Class or Booking Issue"
    case instructorFeedback = "Instructor Feedback"
    
    var icon: String {
        switch self {
        case .general:
            return "bubble.left.and.bubble.right"
        case .bugReport:
            return "ant"
        case .featureRequest:
            return "lightbulb"
        case .appFeedback:
            return "star"
        case .classIssue:
            return "calendar.badge.exclamationmark"
        case .instructorFeedback:
            return "person.circle"
        }
    }
    
    var description: String {
        switch self {
        case .general:
            return "Share general thoughts or suggestions"
        case .bugReport:
            return "Report a problem or bug you encountered"
        case .featureRequest:
            return "Suggest a new feature or improvement"
        case .appFeedback:
            return "Rate and review the app"
        case .classIssue:
            return "Report issues with classes or bookings"
        case .instructorFeedback:
            return "Share feedback about an instructor"
        }
    }
}

struct FeedbackTypeRow: View {
    let type: FeedbackType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(isSelected ? BrandConstants.Colors.primary : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? BrandConstants.Colors.primary : .secondary)
            }
            .padding()
            .background(isSelected ? BrandConstants.Colors.primary.opacity(0.1) : BrandConstants.Colors.background)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(BrandConstants.Colors.background)
            .cornerRadius(BrandConstants.CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        FeedbackView()
    }
}