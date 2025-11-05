import SwiftUI

struct InstructorProfileView: View {
    let instructorID: String
    @StateObject private var viewModel = InstructorProfileViewModel()
    @State private var selectedTab = 0
    @State private var showingContact = false
    @State private var showingFollowSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    private let tabs = ["About", "Classes", "Reviews"]
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.instructor == nil {
                loadingView
            } else if let instructor = viewModel.instructor {
                instructorProfileContent(instructor: instructor)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInstructor(id: instructorID)
        }
        .sheet(isPresented: $showingContact) {
            if let instructor = viewModel.instructor {
                ContactInstructorSheet(instructor: instructor)
            }
        }
        .alert("Following", isPresented: $showingFollowSuccess) {
            Button("OK") { }
        } message: {
            Text("You're now following \(viewModel.instructor?.fullName ?? "this instructor")")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading instructor profile...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Instructor Not Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("We couldn't find the instructor you're looking for.")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                dismiss()
            }
            .padding()
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
    }
    
    private func instructorProfileContent(instructor: Instructor) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                instructorHeader(instructor: instructor)
                
                // Stats Section
                instructorStats(instructor: instructor)
                
                // Action Buttons
                actionButtons(instructor: instructor)
                
                // Tab Section
                tabPicker
                
                // Tab Content
                tabContent(instructor: instructor)
            }
            .padding(.bottom, 100)
        }
        .background(BrandConstants.Colors.background)
    }
    
    private func instructorHeader(instructor: Instructor) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Profile Image
                AsyncImage(url: URL(string: instructor.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(BrandConstants.Colors.primary.opacity(0.3))
                        .overlay(
                            Text(String(instructor.firstName.prefix(1)))
                                .font(BrandConstants.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(BrandConstants.Colors.primary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Name
                    Text(instructor.fullName)
                        .font(BrandConstants.Typography.title2)
                        .fontWeight(.bold)
                    
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(NSDecimalNumber(decimal: instructor.rating).doubleValue) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(BrandConstants.Typography.subheadline)
                        }
                        Text(instructor.formattedRating)
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(.medium)
                        Text("(\(instructor.totalReviews) reviews)")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Experience
                    if let experience = instructor.yearsOfExperience {
                        Text("\(experience) years of experience")
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Specialties
                    if !instructor.specialties.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(instructor.specialties.prefix(3), id: \.self) { specialty in
                                    Text(specialty)
                                        .font(BrandConstants.Typography.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(BrandConstants.Colors.primary.opacity(0.1))
                                        .foregroundColor(BrandConstants.Colors.primary)
                                        .cornerRadius(BrandConstants.CornerRadius.sm)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Bio
            if let bio = instructor.bio {
                Text(bio)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal)
    }
    
    private func instructorStats(instructor: Instructor) -> some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "graduationcap.fill",
                value: "\(viewModel.totalClasses)",
                label: "Classes Taught",
                color: .blue
            )
            
            StatCard(
                icon: "person.2.fill",
                value: "\(viewModel.totalStudents)",
                label: "Students Taught",
                color: .green
            )
            
            StatCard(
                icon: "calendar.circle.fill",
                value: "\(viewModel.upcomingClasses)",
                label: "Upcoming",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    private func actionButtons(instructor: Instructor) -> some View {
        HStack(spacing: 12) {
            // Follow Button
            Button(action: {
                Task {
                    await viewModel.toggleFollow()
                    if viewModel.isFollowing {
                        showingFollowSuccess = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isFollowing ? "heart.fill" : "heart")
                    Text(viewModel.isFollowing ? "Following" : "Follow")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isFollowing ? Color.gray.opacity(0.2) : BrandConstants.Colors.primary)
                .foregroundColor(viewModel.isFollowing ? .primary : .white)
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
            
            // Contact Button
            Button(action: {
                showingContact = true
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Contact")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(BrandConstants.Colors.teal)
                .foregroundColor(.white)
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
        }
        .padding(.horizontal)
    }
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? BrandConstants.Colors.primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? BrandConstants.Colors.primary : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .background(BrandConstants.Colors.surface)
    }
    
    private func tabContent(instructor: Instructor) -> some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case 0:
                aboutTab(instructor: instructor)
            case 1:
                classesTab
            case 2:
                reviewsTab
            default:
                EmptyView()
            }
        }
    }
    
    private func aboutTab(instructor: Instructor) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Certifications
            if let certificationInfo = instructor.certificationInfo,
               !certificationInfo.certifications.isEmpty {
                certificationsSection(certifications: certificationInfo.certifications)
            }
            
            // Social Links
            if let socialLinks = instructor.socialLinks {
                socialLinksSection(socialLinks: socialLinks)
            }
            
            // Availability (if available)
            if let availability = instructor.availability, !availability.isEmpty {
                availabilitySection(availability: availability)
            }
        }
        .padding()
    }
    
    private func certificationsSection(certifications: [Certification]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certifications")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            ForEach(certifications, id: \.name) { certification in
                CertificationCard(certification: certification)
            }
        }
    }
    
    private func socialLinksSection(socialLinks: SocialLinks) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                if let website = socialLinks.website {
                    SocialLinkButton(icon: "globe", url: website, color: .blue)
                }
                if let instagram = socialLinks.instagram {
                    SocialLinkButton(icon: "camera.fill", url: instagram, color: .pink)
                }
                if let facebook = socialLinks.facebook {
                    SocialLinkButton(icon: "f.square.fill", url: facebook, color: .blue)
                }
                if let linkedin = socialLinks.linkedin {
                    SocialLinkButton(icon: "briefcase.fill", url: linkedin, color: .blue)
                }
            }
        }
    }
    
    private func availabilitySection(availability: [AvailabilitySlot]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Availability")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(availability, id: \.dayOfWeek) { slot in
                    AvailabilityRow(slot: slot)
                }
            }
        }
    }
    
    private var classesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.instructorClasses.isEmpty {
                EmptyStateView(
                    message: "No Classes Available",
                    description: "This instructor doesn't have any classes scheduled at the moment.",
                    iconName: "calendar"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.instructorClasses) { classItem in
                        InstructorClassCard(classItem: classItem)
                    }
                }
                .padding()
            }
        }
    }
    
    private var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.reviews.isEmpty {
                EmptyStateView(
                    message: "No Reviews Yet",
                    description: "This instructor hasn't received any reviews yet.",
                    iconName: "star"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.reviews) { review in
                        ReviewCard(review: review)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(BrandConstants.Typography.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

struct CertificationCard: View {
    let certification: Certification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(certification.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if certification.isExpired {
                    Text("Expired")
                        .font(BrandConstants.Typography.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(certification.issuingOrganization)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
            
            Text("Issued: \(DateFormatter.shortDate.string(from: certification.issueDate))")
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.sm)
    }
}

struct SocialLinkButton: View {
    let icon: String
    let url: String
    let color: Color
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .cornerRadius(BrandConstants.CornerRadius.sm)
        }
    }
}

struct AvailabilityRow: View {
    let slot: AvailabilitySlot
    
    private var dayName: String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[slot.dayOfWeek % 7]
    }
    
    var body: some View {
        HStack {
            Text(dayName)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)
            
            Text("\(slot.startTime) - \(slot.endTime)")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if slot.isRecurring {
                Text("Weekly")
                    .font(BrandConstants.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(BrandConstants.Colors.primary.opacity(0.1))
                    .foregroundColor(BrandConstants.Colors.primary)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InstructorClassCard: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Class image placeholder
            Rectangle()
                .fill(BrandConstants.Colors.primary.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(BrandConstants.CornerRadius.sm)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .foregroundColor(BrandConstants.Colors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Text(classItem.venue)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(DateFormatter.shortDateTime.string(from: classItem.startDate))
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(Int(classItem.price))")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandConstants.Colors.primary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.userName)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(BrandConstants.Typography.caption)
                    }
                }
                
                Text(DateFormatter.relative.string(from: review.date))
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(review.comment)
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
}

struct ContactInstructorSheet: View {
    let instructor: Instructor
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedReason = ContactReason.general
    
    enum ContactReason: String, CaseIterable {
        case general = "General Inquiry"
        case booking = "Class Booking"
        case collaboration = "Collaboration"
        case feedback = "Feedback"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact \(instructor.firstName)")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("Send a message to this instructor")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for Contact")
                            .font(BrandConstants.Typography.headline)
                        
                        Picker("Reason", selection: $selectedReason) {
                            ForEach(ContactReason.allCases, id: \.self) { reason in
                                Text(reason.rawValue).tag(reason)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(BrandConstants.Typography.headline)
                        
                        TextField("Enter subject", text: $subject)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(BrandConstants.Typography.headline)
                        
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
                    
                    // Send Button
                    Button("Send Message") {
                        // Handle sending message
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? BrandConstants.Colors.primary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(BrandConstants.CornerRadius.md)
                    .disabled(!isFormValid)
                }
                .padding()
            }
            .navigationTitle("Contact Instructor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationStack {
        InstructorProfileView(instructorID: "sample-instructor-123")
    }
}