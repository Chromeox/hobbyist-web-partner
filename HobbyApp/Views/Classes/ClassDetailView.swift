import SwiftUI

struct ClassDetailView: View {
    let hobbyClass: MockHobbyClass
    @State private var showBookingSheet = false
    @State private var isFavorited = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [BrandConstants.Colors.primary.opacity(0.8), BrandConstants.Colors.coral.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: hobbyClass.iconName)
                                .font(BrandConstants.Typography.largeTitle)
                                .foregroundColor(BrandConstants.Colors.surface)
                        )

                    // Favorite Button
                    Button(action: { isFavorited.toggle() }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(BrandConstants.Typography.title3)
                            .foregroundColor(isFavorited ? BrandConstants.Colors.error : BrandConstants.Colors.surface)
                            .background(Circle().fill(BrandConstants.Colors.text.opacity(0.3)).frame(width: 40, height: 40))
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Class Title and Studio
                    VStack(alignment: .leading, spacing: 8) {
                        Text(hobbyClass.title)
                            .font(BrandConstants.Typography.largeTitle)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(BrandConstants.Colors.primary)
                            Text(hobbyClass.studioName)
                                .font(BrandConstants.Typography.headline)
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                    }

                    // Quick Info Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        InfoCardView(icon: "person", title: "Instructor", value: hobbyClass.instructor)
                        InfoCardView(icon: "clock", title: "Duration", value: hobbyClass.duration)
                        InfoCardView(icon: "calendar", title: "Next Class", value: hobbyClass.nextClassDate)
                        InfoCardView(icon: "dollarsign.circle", title: "Price", value: hobbyClass.price)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Class")
                            .font(BrandConstants.Typography.headline)

                        Text(hobbyClass.description)
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                            .lineLimit(nil)
                    }

                    // What to Expect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to Expect")
                            .font(BrandConstants.Typography.headline)

                        ForEach(hobbyClass.whatToExpect, id: \.self) { item in
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

                    // Requirements
                    if !hobbyClass.requirements.isEmpty {
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

                    // Reviews Section (Mock)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reviews")
                                .font(BrandConstants.Typography.headline)

                            Spacer()

                            HStack(spacing: 4) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < hobbyClass.rating ? "star.fill" : "star")
                                        .foregroundColor(BrandConstants.Colors.warning)
                                        .font(BrandConstants.Typography.subheadline)
                                }
                                Text("(\(hobbyClass.reviewCount) reviews)")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                            }
                        }

                        // Sample Review
                        ReviewCardView(
                            name: "Sarah M.",
                            rating: 5,
                            comment: "Amazing class! The instructor was so patient and helpful. Perfect for beginners.",
                            date: "2 days ago"
                        )
                    }

                    // Instructor Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About \(hobbyClass.instructor)")
                            .font(BrandConstants.Typography.headline)

                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(BrandConstants.Typography.largeTitle)
                                .foregroundColor(BrandConstants.Colors.primary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(hobbyClass.instructor)
                                    .font(BrandConstants.Typography.headline)

                                Text(hobbyClass.instructorBio)
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                                    .lineLimit(3)
                            }
                        }
                        .padding()
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                }
                .padding(.horizontal)

                // Bottom spacing for fixed button
                Spacer(minLength: 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            // Fixed Book Now Button
            VStack(spacing: 0) {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(hobbyClass.creditsRequired) Credits")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("per class")
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
        .sheet(isPresented: $showBookingSheet) {
            BookingSheetView(hobbyClass: hobbyClass)
        }
    }
}

struct InfoCardView: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title2)
                .foregroundColor(.blue)

            VStack(spacing: 4) {
                Text(title)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
}

struct ReviewCardView: View {
    let name: String
    let rating: Int
    let comment: String
    let date: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < rating ? "star.fill" : "star")
                            .foregroundColor(BrandConstants.Colors.warning)
                            .font(BrandConstants.Typography.caption)
                    }
                }

                Text(date)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Text(comment)
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

struct BookingSheetView: View {
    let hobbyClass: MockHobbyClass
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
                                Image(systemName: hobbyClass.iconName)
                                    .foregroundColor(BrandConstants.Colors.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(hobbyClass.title)
                                .font(BrandConstants.Typography.headline)

                            Text(hobbyClass.studioName)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(BrandConstants.Colors.secondaryText)

                            Text("\(hobbyClass.creditsRequired) Credits")
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
                            Text("\(hobbyClass.creditsRequired) Credits")
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

struct MockHobbyClass {
    let title: String
    let instructor: String
    let price: String
    let duration: String
    let studioName: String
    let nextClassDate: String
    let description: String
    let whatToExpect: [String]
    let requirements: [String]
    let rating: Int
    let reviewCount: Int
    let instructorBio: String
    let iconName: String

    static let pottery = MockHobbyClass(
        title: "Pottery Basics",
        instructor: "Sarah Chen",
        duration: "2 hours",
        studioName: "Clay Studio Vancouver",
        nextClassDate: "Tomorrow 10:00 AM",
        description: "Learn the fundamentals of pottery in this beginner-friendly class. You'll explore hand-building techniques, work with clay, and create your first ceramic piece to take home.",
        whatToExpect: [
            "Introduction to different types of clay",
            "Basic hand-building techniques",
            "Creating your first pottery piece",
            "Glazing and finishing techniques",
            "All materials and tools provided"
        ],
        requirements: [
            "No experience necessary",
            "Wear clothes you don't mind getting dirty",
            "Closed-toe shoes required"
        ],
        rating: 5,
        reviewCount: 24,
        instructorBio: "Sarah has been teaching pottery for over 8 years and specializes in beginner-friendly classes.",
        iconName: "paintbrush.fill"
    )
}

#Preview {
    NavigationStack {
        ClassDetailView(hobbyClass: MockHobbyClass.pottery)
    }
}