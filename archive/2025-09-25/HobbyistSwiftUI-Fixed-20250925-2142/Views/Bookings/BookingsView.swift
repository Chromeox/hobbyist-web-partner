import SwiftUI

struct BookingsView: View {
    @State private var selectedTab = 0
    @State private var upcomingBookings = MockBooking.upcomingBookings
    @State private var pastBookings = MockBooking.pastBookings

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Picker
                HStack(spacing: 0) {
                    TabButton(title: "Upcoming", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    TabButton(title: "Past", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Content
                TabView(selection: $selectedTab) {
                    // Upcoming Bookings
                    UpcomingBookingsView(bookings: upcomingBookings)
                        .tag(0)

                    // Past Bookings
                    PastBookingsView(bookings: pastBookings)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct UpcomingBookingsView: View {
    let bookings: [MockBooking]
    @State private var showCancelAlert = false
    @State private var bookingToCancel: MockBooking?

    var body: some View {
        if bookings.isEmpty {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)

                Text("No Upcoming Bookings")
                    .font(.headline)

                Text("Book your first class to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Browse Classes") {
                    // Navigate to search/browse
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(bookings, id: \.id) { booking in
                        UpcomingBookingCard(booking: booking) {
                            bookingToCancel = booking
                            showCancelAlert = true
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct PastBookingsView: View {
    let bookings: [MockBooking]

    var body: some View {
        if bookings.isEmpty {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "clock")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)

                Text("No Past Bookings")
                    .font(.headline)

                Text("Your completed classes will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(bookings, id: \.id) { booking in
                        PastBookingCard(booking: booking)
                    }
                }
                .padding()
            }
        }
    }
}

struct UpcomingBookingCard: View {
    let booking: MockBooking
    let onCancel: () -> Void
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with class info
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: booking.iconName)
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.className)
                        .font(.headline)
                        .lineLimit(1)

                    Text("with \(booking.instructor)")
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    Text(booking.studio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: booking.status)

                    Text(booking.price)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            // Date and Time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(booking.date)
                    .font(.subheadline)

                Spacer()

                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(booking.time)
                    .font(.subheadline)
            }

            // Location
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.blue)
                Text(booking.location)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("View Details") {
                    showDetails = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(8)

                if booking.canCancel {
                    Button("Cancel") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }

                Button("Reschedule") {
                    // Handle reschedule
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
        .sheet(isPresented: $showDetails) {
            BookingDetailView(booking: booking)
        }
    }
}

struct PastBookingCard: View {
    let booking: MockBooking
    @State private var showReview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: booking.iconName)
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.className)
                        .font(.headline)
                        .lineLimit(1)

                    Text(booking.instructor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(booking.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: booking.status)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("Book Again") {
                    // Handle re-booking
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                if booking.status == .completed && !booking.hasReview {
                    Button("Write Review") {
                        showReview = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
        .sheet(isPresented: $showReview) {
            ReviewView(booking: booking)
        }
    }
}

struct StatusBadge: View {
    let status: BookingStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .confirmed: return Color.green.opacity(0.2)
        case .pending: return Color.orange.opacity(0.2)
        case .cancelled: return Color.red.opacity(0.2)
        case .completed: return Color.blue.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch status {
        case .confirmed: return .green
        case .pending: return .orange
        case .cancelled: return .red
        case .completed: return .blue
        }
    }
}

struct BookingDetailView: View {
    let booking: MockBooking
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Class Image/Icon
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: booking.iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        )

                    // Booking Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(booking.className)
                            .font(.title)
                            .fontWeight(.bold)

                        DetailRow(icon: "person", title: "Instructor", value: booking.instructor)
                        DetailRow(icon: "building.2", title: "Studio", value: booking.studio)
                        DetailRow(icon: "calendar", title: "Date", value: booking.date)
                        DetailRow(icon: "clock", title: "Time", value: booking.time)
                        DetailRow(icon: "location", title: "Location", value: booking.location)
                        DetailRow(icon: "dollarsign.circle", title: "Price", value: booking.price)

                        HStack {
                            Text("Status")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            StatusBadge(status: booking.status)
                        }
                    }

                    // Booking ID
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Booking Information")
                            .font(.headline)

                        Text("Booking ID: \(booking.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Booked on: \(booking.bookingDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Booking Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ReviewView: View {
    let booking: MockBooking
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var reviewText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Class Info
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(booking.className)
                            .font(.headline)
                        Text("with \(booking.instructor)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                // Rating
                VStack(alignment: .leading, spacing: 12) {
                    Text("How was your experience?")
                        .font(.headline)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                }

                // Review Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Write a review")
                        .font(.headline)

                    TextField("Tell others about your experience...", text: $reviewText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5, reservesSpace: true)
                }

                Spacer()

                // Submit Button
                Button("Submit Review") {
                    // Handle review submission
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(rating > 0 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(rating == 0)
            }
            .padding()
            .navigationTitle("Write Review")
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

enum BookingStatus: String, CaseIterable {
    case confirmed = "Confirmed"
    case pending = "Pending"
    case cancelled = "Cancelled"
    case completed = "Completed"
}

struct MockBooking {
    let id = UUID().uuidString.prefix(8).uppercased()
    let className: String
    let instructor: String
    let studio: String
    let date: String
    let time: String
    let location: String
    let price: String
    let status: BookingStatus
    let bookingDate: String
    let canCancel: Bool
    let hasReview: Bool
    let iconName: String

    static let upcomingBookings = [
        MockBooking(className: "Pottery Basics", instructor: "Sarah Chen", studio: "Clay Studio Vancouver", date: "Tomorrow, Mar 16", time: "10:00 AM - 12:00 PM", location: "1234 Art Street, Vancouver", price: "$45", status: .confirmed, bookingDate: "Mar 10, 2024", canCancel: true, hasReview: false, iconName: "paintbrush.fill"),
        MockBooking(className: "Yoga Flow", instructor: "Emma Wilson", studio: "Zen Yoga Studio", date: "Friday, Mar 18", time: "6:00 PM - 7:00 PM", location: "567 Wellness Ave, Vancouver", price: "$25", status: .confirmed, bookingDate: "Mar 12, 2024", canCancel: true, hasReview: false, iconName: "figure.yoga"),
    ]

    static let pastBookings = [
        MockBooking(className: "Italian Cooking", instructor: "Marco Rossi", studio: "Culinary Arts Center", date: "Mar 10, 2024", time: "2:00 PM - 4:00 PM", location: "890 Food Street, Vancouver", price: "$65", status: .completed, bookingDate: "Mar 5, 2024", canCancel: false, hasReview: false, iconName: "fork.knife"),
        MockBooking(className: "Watercolor Painting", instructor: "Lisa Park", studio: "Art Collective", date: "Mar 8, 2024", time: "1:00 PM - 3:00 PM", location: "234 Creative Blvd, Vancouver", price: "$35", status: .completed, bookingDate: "Mar 3, 2024", canCancel: false, hasReview: true, iconName: "paintbrush"),
    ]
}

#Preview {
    BookingsView()
}