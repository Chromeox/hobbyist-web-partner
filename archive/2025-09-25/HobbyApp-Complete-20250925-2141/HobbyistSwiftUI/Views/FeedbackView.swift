import SwiftUI
import PhotosUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var viewModel = FeedbackViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Feedback Type Selector
                    FeedbackTypeSelector(selectedType: $viewModel.feedbackType)
                        .padding(.horizontal)
                    
                    // Dynamic content based on type
                    Group {
                        switch viewModel.feedbackType {
                        case .bug:
                            BugReportForm(viewModel: viewModel)
                        case .feature:
                            FeatureRequestForm(viewModel: viewModel)
                        case .rating:
                            ExperienceRatingForm(viewModel: viewModel)
                        case .general:
                            GeneralFeedbackForm(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Attachments section
                    if viewModel.feedbackType == .bug {
                        AttachmentsSection(
                            screenshots: $viewModel.screenshots,
                            showingPhotoPicker: $showingPhotoPicker
                        )
                        .padding(.horizontal)
                    }
                    
                    // Submit button
                    SubmitButton(viewModel: viewModel) {
                        showingSuccessAlert = true
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.screenshots.append(data)
                    }
                }
            }
            .alert("Thank You!", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been submitted successfully. We appreciate your input!")
            }
            .overlay {
                if viewModel.isSubmitting {
                    LoadingOverlay()
                }
            }
        }
    }
}

// MARK: - Feedback Type Selector

struct FeedbackTypeSelector: View {
    @Binding var selectedType: FeedbackType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to share?")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FeedbackTypeButton(
                        type: .bug,
                        icon: "ladybug",
                        title: "Report Bug",
                        isSelected: selectedType == .bug
                    ) {
                        selectedType = .bug
                    }
                    
                    FeedbackTypeButton(
                        type: .feature,
                        icon: "lightbulb",
                        title: "Suggest Feature",
                        isSelected: selectedType == .feature
                    ) {
                        selectedType = .feature
                    }
                    
                    FeedbackTypeButton(
                        type: .rating,
                        icon: "star",
                        title: "Rate Experience",
                        isSelected: selectedType == .rating
                    ) {
                        selectedType = .rating
                    }
                    
                    FeedbackTypeButton(
                        type: .general,
                        icon: "bubble.left",
                        title: "General",
                        isSelected: selectedType == .general
                    ) {
                        selectedType = .general
                    }
                }
            }
        }
    }
}

// MARK: - Feedback Type Button

struct FeedbackTypeButton: View {
    let type: FeedbackType
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bug Report Form

struct BugReportForm: View {
    @ObservedObject var viewModel: FeedbackViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Label("Bug Title", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Brief description of the issue", text: $viewModel.bugTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.bugDescription)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Severity
            VStack(alignment: .leading, spacing: 8) {
                Label("Severity", systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Severity", selection: $viewModel.bugSeverity) {
                    ForEach(BugReport.BugSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Reproducible
            Toggle(isOn: $viewModel.isReproducible) {
                Label("Can you reproduce this bug?", systemImage: "arrow.clockwise")
                    .font(.subheadline)
            }
            .tint(.accentColor)
            
            // Steps to reproduce
            if viewModel.isReproducible {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Steps to Reproduce", systemImage: "list.number")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(viewModel.reproductionSteps.indices, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            
                            TextField("Step \(index + 1)", text: $viewModel.reproductionSteps[index])
                                .textFieldStyle(.roundedBorder)
                            
                            Button(action: {
                                viewModel.reproductionSteps.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.reproductionSteps.append("")
                    }) {
                        Label("Add Step", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

// MARK: - Feature Request Form

struct FeatureRequestForm: View {
    @ObservedObject var viewModel: FeedbackViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Label("Feature Title", systemImage: "lightbulb")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("What feature would you like?", text: $viewModel.featureTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.featureDescription)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Use Case
            VStack(alignment: .leading, spacing: 8) {
                Label("Use Case", systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.featureUseCase)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Label("Priority", systemImage: "flag")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Priority", selection: $viewModel.featurePriority) {
                    ForEach(FeatureRequest.Priority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - Experience Rating Form

struct ExperienceRatingForm: View {
    @ObservedObject var viewModel: FeedbackViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Overall Rating
            VStack(alignment: .leading, spacing: 12) {
                Label("Overall Experience", systemImage: "star")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            viewModel.overallRating = rating
                        }) {
                            Image(systemName: rating <= viewModel.overallRating ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(rating <= viewModel.overallRating ? .yellow : .gray)
                        }
                    }
                }
            }
            
            // Category Ratings
            VStack(alignment: .leading, spacing: 12) {
                Label("Rate Categories", systemImage: "list.star")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(["Ease of Use", "Performance", "Design", "Features"], id: \.self) { category in
                    HStack {
                        Text(category)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { rating in
                                Button(action: {
                                    viewModel.categoryRatings[category] = rating
                                }) {
                                    Image(systemName: rating <= (viewModel.categoryRatings[category] ?? 0) ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundColor(rating <= (viewModel.categoryRatings[category] ?? 0) ? .yellow : .gray)
                                }
                            }
                        }
                    }
                }
            }
            
            // Would Recommend
            Toggle(isOn: $viewModel.wouldRecommend) {
                Label("Would you recommend this app?", systemImage: "hand.thumbsup")
                    .font(.subheadline)
            }
            .tint(.accentColor)
            
            // Additional Comments
            VStack(alignment: .leading, spacing: 8) {
                Label("Additional Comments", systemImage: "bubble.left")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.additionalComments)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - General Feedback Form

struct GeneralFeedbackForm: View {
    @ObservedObject var viewModel: FeedbackViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Label("Subject", systemImage: "envelope")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("What's on your mind?", text: $viewModel.generalTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Message
            VStack(alignment: .leading, spacing: 8) {
                Label("Message", systemImage: "text.bubble")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.generalMessage)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Attachments Section

struct AttachmentsSection: View {
    @Binding var screenshots: [Data]
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Screenshots", systemImage: "photo.on.rectangle")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add button
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    
                    // Screenshots
                    ForEach(screenshots.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: screenshots[index]) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    screenshots.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Submit Button

struct SubmitButton: View {
    @ObservedObject var viewModel: FeedbackViewModel
    let onSuccess: () -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.submitFeedback()
                onSuccess()
            }
        }) {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Submit Feedback")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.canSubmit ? Color.accentColor : Color.gray)
            )
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Submitting...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
            )
        }
    }
}

// MARK: - Preview

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
            .environmentObject(AuthViewModel())
    }
}