import SwiftUI

struct BookingsView: View {
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @StateObject private var viewModel = BookingsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Booking Status", selection: $viewModel.selectedSegment) {
                    Text("Upcoming").tag(BookingsViewModel.Segment.upcoming)
                    Text("Past").tag(BookingsViewModel.Segment.past)
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    if viewModel.isLoading {
                        LoadingStateView()
                    } else if let error = viewModel.errorMessage {
                        ErrorStateView(message: error) {
                            Task { await viewModel.loadBookings() }
                        }
                    } else if viewModel.currentBookings.isEmpty {
                        EmptyStateView(segment: viewModel.selectedSegment)
                    } else {
                        List {
                            ForEach(viewModel.currentBookings, id: \.id) { booking in
                                BookingCard(booking: booking)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("My Bookings")
            .background(Color(.systemGroupedBackground))
            .task {
                viewModel.supabaseService = supabaseService
                await viewModel.loadBookings()
            }
            .refreshable {
                await viewModel.loadBookings()
            }
        }
    }
}

@MainActor
final class BookingsViewModel: ObservableObject {
    enum Segment: Hashable {
        case upcoming
        case past
    }

    @Published var upcomingBookings: [SimpleBooking] = []
    @Published var pastBookings: [SimpleBooking] = []
    @Published var selectedSegment: Segment = .upcoming
    @Published var isLoading = false
    @Published var errorMessage: String?

    var supabaseService: SimpleSupabaseService?

    var currentBookings: [SimpleBooking] {
        switch selectedSegment {
        case .upcoming:
            return upcomingBookings
        case .past:
            return pastBookings
        }
    }

    func loadBookings() async {
        guard let supabaseService else { return }

        isLoading = true
        errorMessage = nil

        let bookings = await supabaseService.fetchUserBookings()

        if !bookings.isEmpty {
            let now = Date()
            upcomingBookings = bookings.filter { $0.bookingDate >= now }
                .sorted { $0.bookingDate < $1.bookingDate }
            pastBookings = bookings.filter { $0.bookingDate < now }
                .sorted { $0.bookingDate > $1.bookingDate }
        } else if let error = supabaseService.errorMessage {
            errorMessage = error
            upcomingBookings = []
            pastBookings = []
        } else {
            upcomingBookings = []
            pastBookings = []
        }

        isLoading = false
    }
}

private struct BookingCard: View {
    let booking: SimpleBooking

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                BookingThumbnail()
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.className)
                        .font(BrandConstants.Typography.headline)
                        .lineLimit(2)

                    Text("with \(booking.instructor)")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundStyle(.blue)

                    if let venue = booking.venue, !venue.isEmpty {
                        Label(
                            venue,
                            systemImage: venue.lowercased() == "online" ? "wifi" : "mappin.and.ellipse"
                        )
                        .font(BrandConstants.Typography.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                StatusBadge(status: booking.status)
            }

            Divider()

            HStack {
                Label(booking.bookingDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(booking.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

private struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "confirmed":
            return .green
        case "pending":
            return .orange
        case "cancelled":
            return .red
        default:
            return .blue
        }
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView("Loading bookings...")
            Text("Syncing with your Supabase account.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

private struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("We couldn't load your bookings.")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

private struct EmptyStateView: View {
    let segment: BookingsViewModel.Segment

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: segment == .upcoming ? "calendar.badge.plus" : "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(segment == .upcoming ? "No upcoming bookings yet." : "No past bookings.")
                .font(.headline)

            Text(segment == .upcoming ?
                 "Find a class you love and book it in seconds." :
                    "Your completed classes will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

private struct BookingThumbnail: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(Color.blue)
        }
    }
}
