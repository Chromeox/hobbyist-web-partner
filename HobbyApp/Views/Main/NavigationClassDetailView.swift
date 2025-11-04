import SwiftUI

/// ClassDetailView for Navigation Destinations
/// This view works with classID strings and loads class data dynamically
struct NavigationClassDetailView: View {
    let classID: String
    @StateObject private var viewModel = ClassDetailViewModel()
    @State private var hobbyClass: HobbyClass?
    @State private var isLoading = true
    @State private var showBookingSheet = false
    @State private var isFavorited = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let hobbyClass = hobbyClass {
                classDetailContent(hobbyClass: hobbyClass)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadClassData()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading class details...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Class Not Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("We couldn't find the class you're looking for.")
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
    
    private func classDetailContent(hobbyClass: HobbyClass) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image
                headerImageView(hobbyClass: hobbyClass)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Class Title and Studio
                    classHeaderInfo(hobbyClass: hobbyClass)
                    
                    // Quick Info Cards
                    quickInfoCards(hobbyClass: hobbyClass)
                    
                    // Description
                    descriptionSection(hobbyClass: hobbyClass)
                    
                    // What to Expect
                    whatToExpectSection(hobbyClass: hobbyClass)
                    
                    // Requirements
                    if !hobbyClass.requirements.isEmpty {
                        requirementsSection(hobbyClass: hobbyClass)
                    }
                    
                    // Reviews Section
                    reviewsSection(hobbyClass: hobbyClass)
                    
                    // Instructor Bio
                    instructorSection(hobbyClass: hobbyClass)
                }
                .padding(.horizontal)
                
                // Bottom spacing for fixed button
                Spacer(minLength: 100)
            }
        }
        .overlay(alignment: .bottom) {
            bookingButton(hobbyClass: hobbyClass)
        }
        .sheet(isPresented: $showBookingSheet) {
            BookingFlowSheet(classID: classID, hobbyClass: hobbyClass)
        }
    }
    
    private func headerImageView(hobbyClass: HobbyClass) -> some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: hobbyClass.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            BrandConstants.Colors.primary.opacity(0.8),
                            BrandConstants.Colors.coral.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: hobbyClass.category.iconName)
                            .font(BrandConstants.Typography.largeTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                    )
            }
            .frame(height: 250)
            .clipped()

            // Favorite Button
            Button(action: { isFavorited.toggle() }) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(isFavorited ? BrandConstants.Colors.error : BrandConstants.Colors.surface)
                    .background(
                        Circle()
                            .fill(BrandConstants.Colors.text.opacity(0.3))
                            .frame(width: 40, height: 40)
                    )
            }
            .padding(16)
        }
    }
    
    private func classHeaderInfo(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hobbyClass.title)
                .font(BrandConstants.Typography.largeTitle)
                .fontWeight(.bold)

            HStack {
                Image(systemName: "location")
                    .foregroundColor(BrandConstants.Colors.primary)
                Text(hobbyClass.venue.name)
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(BrandConstants.Colors.primary)
            }
        }
    }
    
    private func quickInfoCards(hobbyClass: HobbyClass) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            InfoCardView(
                icon: "person",
                title: "Instructor",
                value: hobbyClass.instructor.name
            )
            InfoCardView(
                icon: "clock",
                title: "Duration",
                value: "\(hobbyClass.duration) min"
            )
            InfoCardView(
                icon: "calendar",
                title: "Start Time",
                value: DateFormatter.shortTime.string(from: hobbyClass.startDate)
            )
            InfoCardView(
                icon: "dollarsign.circle",
                title: "Price",
                value: hobbyClass.price == 0 ? "Free" : String(format: "$%.0f", hobbyClass.price)
            )
        }
    }
    
    private func descriptionSection(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Class")
                .font(BrandConstants.Typography.headline)

            Text(hobbyClass.description)
                .font(BrandConstants.Typography.body)
                .foregroundColor(BrandConstants.Colors.secondaryText)
                .lineLimit(nil)
        }
    }
    
    private func whatToExpectSection(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What You'll Need to Bring")
                .font(BrandConstants.Typography.headline)

            ForEach(hobbyClass.whatToBring.isEmpty ? ["All materials provided"] : hobbyClass.whatToBring, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(BrandConstants.Colors.success)
                        .font(BrandConstants.Typography.body)
                        .padding(.top, 2)

                    Text(item)
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
            }
        }
    }
    
    private func requirementsSection(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requirements")
                .font(BrandConstants.Typography.headline)

            ForEach(hobbyClass.requirements, id: \.self) { requirement in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .font(BrandConstants.Typography.body)
                        .padding(.top, 2)

                    Text(requirement)
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
            }
        }
    }
    
    private func reviewsSection(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reviews")
                    .font(BrandConstants.Typography.headline)

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(hobbyClass.averageRating) ? "star.fill" : "star")
                            .foregroundColor(BrandConstants.Colors.warning)
                            .font(BrandConstants.Typography.subheadline)
                    }
                    Text("(\(hobbyClass.totalReviews) reviews)")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
            }

            // Display reviews from viewModel
            ForEach(viewModel.reviews.prefix(2)) { review in
                ReviewCardView(review: review)
            }
            
            if viewModel.hasMoreReviews {
                Button("View All Reviews") {
                    Task {
                        await viewModel.loadMoreReviews()
                    }
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
        }
    }
    
    private func instructorSection(hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About \(hobbyClass.instructor.name)")
                .font(BrandConstants.Typography.headline)

            HStack(spacing: 12) {
                AsyncImage(url: URL(string: hobbyClass.instructor.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(BrandConstants.Colors.primary.opacity(0.3))
                        .overlay(
                            Text(String(hobbyClass.instructor.name.prefix(1)))
                                .font(BrandConstants.Typography.title2)
                                .foregroundColor(BrandConstants.Colors.primary)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(hobbyClass.instructor.name)
                        .font(BrandConstants.Typography.headline)

                    if let bio = hobbyClass.instructor.bio {
                        Text(bio)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                            .lineLimit(3)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", hobbyClass.instructor.rating))
                            .font(BrandConstants.Typography.caption)
                        Text("• \(hobbyClass.instructor.totalClasses) classes")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(BrandConstants.Colors.background)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
    }
    
    private func bookingButton(hobbyClass: HobbyClass) -> some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if hobbyClass.price == 0 {
                        Text("Free Class")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    } else {
                        Text(String(format: "$%.0f", hobbyClass.price))
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Text("per person")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }

                Spacer()

                Button("Book Now") {
                    showBookingSheet = true
                }
                .frame(width: 120)
                .padding()
                .background(BrandConstants.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(BrandConstants.CornerRadius.md)
                .fontWeight(.semibold)
            }
            .padding()
            .background(BrandConstants.Colors.surface)
        }
    }
    
    private func loadClassData() async {
        isLoading = true
        
        // Simulate loading class data by ID
        // In a real app, this would make an API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Create a sample class based on the ID
        hobbyClass = createSampleClass(for: classID)
        await viewModel.loadClassDetails(for: hobbyClass?.toClassItem ?? ClassItem.sample)
        
        isLoading = false
    }
    
    private func createSampleClass(for id: String) -> HobbyClass {
        // Create a sample class based on the ID
        // In a real app, this would fetch from your data source
        let categories: [ClassCategory] = [.arts, .cooking, .fitness, .music, .photography]
        let category = categories.randomElement() ?? .arts
        
        let titles = [
            "Pottery Basics", "Watercolor Painting", "Digital Photography", 
            "Italian Cooking", "Yoga Flow", "Guitar Fundamentals"
        ]
        
        let instructors = [
            "Sarah Chen", "David Martinez", "Emma Thompson", 
            "Michael Park", "Lisa Rodriguez", "James Wilson"
        ]
        
        return HobbyClass(
            id: id,
            title: titles.randomElement() ?? "Creative Class",
            description: "Learn new skills in a fun and supportive environment. This class is perfect for beginners and those looking to explore their creative side.",
            category: category,
            difficulty: .beginner,
            price: Double.random(in: 25...85),
            startDate: Date().addingTimeInterval(86400), // Tomorrow
            endDate: Date().addingTimeInterval(86400 + 7200), // 2 hours later
            duration: 120,
            maxParticipants: 12,
            enrolledCount: Int.random(in: 3...8),
            instructor: InstructorInfo(
                id: UUID().uuidString,
                name: instructors.randomElement() ?? "Instructor",
                bio: "Experienced instructor with a passion for teaching and helping students discover their creative potential.",
                profileImageUrl: nil,
                rating: Double.random(in: 4.2...5.0),
                totalClasses: Int.random(in: 15...150),
                totalStudents: Int.random(in: 50...500),
                specialties: [category.rawValue],
                certifications: [],
                yearsOfExperience: Int.random(in: 2...15),
                socialLinks: nil
            ),
            venue: VenueInfo(
                id: UUID().uuidString,
                name: "Creative Studio Vancouver",
                address: "123 Main Street",
                city: "Vancouver",
                state: "BC",
                zipCode: "V6B 1A1",
                latitude: 49.2827,
                longitude: -123.1207,
                amenities: ["Parking", "WiFi", "Materials Provided"],
                parkingInfo: "Free street parking available",
                publicTransit: "Near Skytrain station",
                imageUrls: nil,
                accessibilityInfo: "Wheelchair accessible"
            ),
            imageUrl: nil,
            thumbnailUrl: nil,
            averageRating: Double.random(in: 4.0...5.0),
            totalReviews: Int.random(in: 8...45),
            tags: ["beginner-friendly", "creative"],
            requirements: ["No experience required", "Wear comfortable clothes"],
            whatToBring: ["Enthusiasm", "Water bottle"],
            cancellationPolicy: "Free cancellation up to 24 hours before class",
            isOnline: false,
            meetingUrl: nil
        )
    }
}

// MARK: - Supporting Views

struct ReviewCardView: View {
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
                            .foregroundColor(BrandConstants.Colors.warning)
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
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

struct BookingFlowSheet: View {
    let classID: String
    let hobbyClass: HobbyClass
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var selectedTime = "10:00 AM"
    
    private let availableTimes = ["9:00 AM", "10:00 AM", "11:00 AM", "2:00 PM", "3:00 PM", "4:00 PM"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Class Summary
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(BrandConstants.Colors.primary.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                            .overlay(
                                Image(systemName: hobbyClass.category.iconName)
                                    .foregroundColor(BrandConstants.Colors.primary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hobbyClass.title)
                                .font(BrandConstants.Typography.headline)
                            
                            Text(hobbyClass.venue.name)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                            
                            Text(hobbyClass.price == 0 ? "Free" : String(format: "$%.0f", hobbyClass.price))
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(BrandConstants.Colors.background)
                    .cornerRadius(BrandConstants.CornerRadius.md)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Date")
                            .font(BrandConstants.Typography.headline)
                        
                        DatePicker("Class Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                    
                    // Time Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Time")
                            .font(BrandConstants.Typography.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(availableTimes, id: \.self) { time in
                                Button(time) {
                                    selectedTime = time
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTime == time ? BrandConstants.Colors.primary : BrandConstants.Colors.background)
                                .foregroundColor(selectedTime == time ? BrandConstants.Colors.surface : BrandConstants.Colors.text)
                                .cornerRadius(BrandConstants.CornerRadius.sm)
                            }
                        }
                    }
                    
                    // Booking Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total")
                                .font(BrandConstants.Typography.headline)
                            Spacer()
                            Text(hobbyClass.price == 0 ? "Free" : String(format: "$%.0f", hobbyClass.price))
                                .font(BrandConstants.Typography.headline)
                                .fontWeight(.bold)
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                        
                        Button("Confirm Booking") {
                            // Handle booking confirmation
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                        .fontWeight(.semibold)
                    }
                    .padding()
                    .background(BrandConstants.Colors.background)
                    .cornerRadius(BrandConstants.CornerRadius.md)
                }
                .padding()
            }
            .navigationTitle("Book Class")
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
}

// MARK: - Date Formatters

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NavigationStack {
        NavigationClassDetailView(classID: "sample-class-123")
    }
}