import SwiftUI

struct ClassDetailView: View {
    let hobbyClass: MockHobbyClass
    @State private var showBookingSheet = false
    @State private var isFavorited = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HobbyistSpacing.lg) {
                // Header Image
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: hobbyClass.iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )

                    // Favorite Button
                    Button(action: { isFavorited.toggle() }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isFavorited ? .red : .white)
                            .background(Circle().fill(Color.black.opacity(0.3)).frame(width: 40, height: 40))
                    }
                    .padding(HobbyistSpacing.md)
                }

                VStack(alignment: .leading, spacing: HobbyistSpacing.md) {
                    // Class Title and Studio
                    VStack(alignment: .leading, spacing: HobbyistSpacing.sm) {
                        Text(hobbyClass.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                            Text(hobbyClass.studioName)
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }

                    // Quick Info Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HobbyistSpacing.sm) {
                        InfoCardView(icon: "person", title: "Instructor", value: hobbyClass.instructor)
                        InfoCardView(icon: "clock", title: "Duration", value: hobbyClass.duration)
                        InfoCardView(icon: "calendar", title: "Next Class", value: hobbyClass.nextClassDate)
                        InfoCardView(icon: "dollarsign.circle", title: "Price", value: hobbyClass.price)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Class")
                            .font(.headline)

                        Text(hobbyClass.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }

                    // What to Expect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What to Expect")
                            .font(.headline)

                        ForEach(hobbyClass.whatToExpect, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                    .padding(.top, 2)

                                Text(item)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Requirements
                    if !hobbyClass.requirements.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Requirements")
                                .font(.headline)

                            ForEach(hobbyClass.requirements, id: \.self) { requirement in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16))
                                        .padding(.top, 2)

                                    Text(requirement)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Reviews Section (Mock)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reviews")
                                .font(.headline)

                            Spacer()

                            HStack(spacing: 4) {
                                ForEach(0..<5) { star in
                                    Image(systemName: star < hobbyClass.rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                }
                                Text("(\(hobbyClass.reviewCount) reviews)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                            .font(.headline)

                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(hobbyClass.instructor)
                                    .font(.headline)

                                Text(hobbyClass.instructorBio)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
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
                        Text(hobbyClass.price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("per class")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Book Now") {
                        showBookingSheet = true
                    }
                    .frame(width: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemBackground))
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
        VStack(spacing: HobbyistSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)

            VStack(spacing: HobbyistSpacing.xs) {
                Text(title)
                    .font(.hobbyistCaption())
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.hobbyistCallout())
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(HobbyistSpacing.md)
        .background(Color(.systemGray6))
        .cornerRadius(HobbyistRadius.md)
        .hobbyistShadow(.small)
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
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }

                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(comment)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: hobbyClass.iconName)
                                    .foregroundColor(.blue)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(hobbyClass.title)
                                .font(.headline)

                            Text(hobbyClass.studioName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(hobbyClass.price)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Date Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Date")
                            .font(.headline)

                        DatePicker("Class Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }

                    // Time Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Time")
                            .font(.headline)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(availableTimes, id: \.self) { time in
                                Button(time) {
                                    selectedTime = time
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedTime == time ? Color.blue : Color(.systemGray6))
                                .foregroundColor(selectedTime == time ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }

                    // Booking Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(hobbyClass.price)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }

                        Button("Confirm Booking") {
                            // Handle booking confirmation
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
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
        price: "$45",
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