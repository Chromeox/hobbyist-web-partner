import SwiftUI

struct MyBookingsView: View {
    @StateObject private var viewModel = MyBookingsViewModel()
    @State private var selectedTab = 0
    @State private var showingFilters = false
    @State private var selectedBooking: Booking?
    @State private var showingBookingDetail = false
    @State private var showingCancelAlert = false
    @State private var bookingToCancel: Booking?
    
    private let tabs = ["Upcoming", "Past", "Cancelled"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                tabPicker
                
                // Content
                Group {
                    if viewModel.isLoading && viewModel.allBookings.isEmpty {
                        SkeletonList(.bookingItem, count: 4)
                            .padding()
                    } else {
                        tabContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.loadBookings()
            }
            .onAppear {
                Task {
                    await viewModel.loadBookings()
                }
            }
            .sheet(isPresented: $showingFilters) {
                BookingFiltersSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBookingDetail) {
                if let booking = selectedBooking {
                    BookingDetailSheet(booking: booking) { action in
                        handleBookingAction(action, for: booking)
                    }
                }
            }
            .alert("Cancel Booking", isPresented: $showingCancelAlert) {
                Button("Cancel", role: .cancel) {
                    bookingToCancel = nil
                }
                Button("Confirm", role: .destructive) {
                    if let booking = bookingToCancel {
                        Task {
                            await viewModel.cancelBooking(booking)
                        }
                    }
                    bookingToCancel = nil
                }
            } message: {
                Text("Are you sure you want to cancel this booking? This action cannot be undone.")
            }
        }
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
                        HStack(spacing: 4) {
                            Text(tabs[index])
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? BrandConstants.Colors.primary : .secondary)
                            
                            // Show count badges
                            if let count = tabCount(for: index), count > 0 {
                                Text("\(count)")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(selectedTab == index ? BrandConstants.Colors.primary : Color.gray)
                                    .clipShape(Capsule())
                            }
                        }
                        
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
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
    
    private var loadingView: some View {
        BrandedLoadingView(message: "Loading your bookings...", showLogo: false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                upcomingBookingsView
            case 1:
                pastBookingsView
            case 2:
                cancelledBookingsView
            default:
                EmptyView()
            }
        }
    }
    
    private var upcomingBookingsView: some View {
        BookingListView(
            bookings: viewModel.upcomingBookings,
            emptyMessage: "No Upcoming Bookings",
            emptyDescription: "Book a class to see it here!",
            emptyIcon: "calendar.badge.plus",
            showCancelOption: true,
            onBookingTap: { booking in
                selectedBooking = booking
                showingBookingDetail = true
            },
            onCancelTap: { booking in
                bookingToCancel = booking
                showingCancelAlert = true
            }
        )
    }
    
    private var pastBookingsView: some View {
        BookingListView(
            bookings: viewModel.pastBookings,
            emptyMessage: "No Past Bookings",
            emptyDescription: "Completed classes will appear here",
            emptyIcon: "clock.arrow.circlepath",
            showCancelOption: false,
            onBookingTap: { booking in
                selectedBooking = booking
                showingBookingDetail = true
            }
        )
    }
    
    private var cancelledBookingsView: some View {
        BookingListView(
            bookings: viewModel.cancelledBookings,
            emptyMessage: "No Cancelled Bookings",
            emptyDescription: "Cancelled bookings will appear here",
            emptyIcon: "xmark.circle",
            showCancelOption: false,
            onBookingTap: { booking in
                selectedBooking = booking
                showingBookingDetail = true
            }
        )
    }
    
    private func tabCount(for index: Int) -> Int? {
        switch index {
        case 0: return viewModel.upcomingBookings.count
        case 1: return viewModel.pastBookings.count
        case 2: return viewModel.cancelledBookings.count
        default: return nil
        }
    }
    
    private func handleBookingAction(_ action: BookingAction, for booking: Booking) {
        Task {
            switch action {
            case .cancel:
                bookingToCancel = booking
                showingCancelAlert = true
            case .reschedule:
                await viewModel.rescheduleBooking(booking)
            case .addToCalendar:
                viewModel.addToCalendar(booking)
            case .share:
                viewModel.shareBooking(booking)
            case .contactInstructor:
                // Handle contact instructor
                break
            case .writeReview:
                await viewModel.writeReview(for: booking)
            }
        }
    }
}

// MARK: - Supporting Views

struct BookingListView: View {
    let bookings: [Booking]
    let emptyMessage: String
    let emptyDescription: String
    let emptyIcon: String
    let showCancelOption: Bool
    let onBookingTap: (Booking) -> Void
    let onCancelTap: ((Booking) -> Void)?
    
    var body: some View {
        Group {
            if bookings.isEmpty {
                EmptyStateView(
                    message: emptyMessage,
                    description: emptyDescription,
                    iconName: emptyIcon
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(bookings) { booking in
                            BookingCard(
                                booking: booking,
                                showCancelOption: showCancelOption,
                                onTap: { onBookingTap(booking) },
                                onCancel: showCancelOption ? { onCancelTap?(booking) } : nil
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct BookingCard: View {
    let booking: Booking
    let showCancelOption: Bool
    let onTap: () -> Void
    let onCancel: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.classTitle)
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("with \(booking.instructor.fullName)")
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    BookingStatusBadge(status: booking.status)
                }
                
                // Date and Time
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(BrandConstants.Colors.primary)
                            .font(BrandConstants.Typography.caption)
                        
                        Text(DateFormatter.bookingDate.string(from: booking.classDate))
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundColor(BrandConstants.Colors.primary)
                            .font(BrandConstants.Typography.caption)
                        
                        Text(DateFormatter.timeOnly.string(from: booking.classDate))
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Venue
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .font(BrandConstants.Typography.caption)
                    
                    Text(booking.venue.name)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Price and Actions
                HStack {
                    Text("$\(String(format: "%.0f", booking.totalAmount))")
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandConstants.Colors.primary)
                    
                    Spacer()
                    
                    if showCancelOption && booking.status == .confirmed {
                        Button("Cancel") {
                            onCancel?()
                        }
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                    }
                }
            }
            .padding()
            .background(BrandConstants.Colors.surface)
            .cornerRadius(BrandConstants.CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BookingStatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.displayName)
            .font(BrandConstants.Typography.caption)
            .fontWeight(.medium)
            .foregroundColor(status.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.backgroundColor)
            .cornerRadius(BrandConstants.CornerRadius.sm)
    }
}

struct BookingFiltersSheet: View {
    @ObservedObject var viewModel: MyBookingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: BookingFilters
    
    init(viewModel: MyBookingsViewModel) {
        self.viewModel = viewModel
        self._tempFilters = State(initialValue: viewModel.filters)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From", selection: $tempFilters.startDate, displayedComponents: .date)
                    DatePicker("To", selection: $tempFilters.endDate, displayedComponents: .date)
                }
                
                Section("Status") {
                    ForEach(BookingStatus.allCases, id: \.self) { status in
                        HStack {
                            Text(status.displayName)
                            Spacer()
                            if tempFilters.statuses.contains(status) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if tempFilters.statuses.contains(status) {
                                tempFilters.statuses.remove(status)
                            } else {
                                tempFilters.statuses.insert(status)
                            }
                        }
                    }
                }
                
                Section("Price Range") {
                    HStack {
                        Text("$\(Int(tempFilters.minPrice))")
                        Slider(value: $tempFilters.minPrice, in: 0...500, step: 10)
                        Text("$\(Int(tempFilters.maxPrice))")
                    }
                }
            }
            .navigationTitle("Filter Bookings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.applyFilters(tempFilters)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BookingDetailSheet: View {
    let booking: Booking
    let onAction: (BookingAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(booking.classTitle)
                                .font(BrandConstants.Typography.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            BookingStatusBadge(status: booking.status)
                        }
                        
                        Text("with \(booking.instructor.fullName)")
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Date")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                                Text(DateFormatter.fullDate.string(from: booking.classDate))
                                    .font(BrandConstants.Typography.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                                Text(DateFormatter.timeOnly.string(from: booking.classDate))
                                    .font(BrandConstants.Typography.subheadline)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(booking.venue.name)
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                            
                            Text(booking.venue.address)
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(.secondary)
                            
                            Text("\(booking.venue.city), \(booking.venue.state)")
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    
                    // Booking Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Booking Details")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            BookingDetailRow(label: "Booking ID", value: booking.id.uuidString.prefix(8).uppercased())
                            BookingDetailRow(label: "Booked On", value: DateFormatter.shortDateTime.string(from: booking.bookedAt))
                            BookingDetailRow(label: "Total Amount", value: "$\(String(format: "%.2f", booking.totalAmount))")
                            if booking.status == .cancelled, let cancelledAt = booking.cancelledAt {
                                BookingDetailRow(label: "Cancelled On", value: DateFormatter.shortDateTime.string(from: cancelledAt))
                            }
                        }
                        .padding()
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                    
                    // Actions
                    if booking.status == .confirmed && booking.classDate > Date() {
                        actionButtons
                    } else if booking.status == .completed {
                        completedActions
                    }
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
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Add to Calendar") {
                onAction(.addToCalendar)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
            
            HStack(spacing: 12) {
                Button("Reschedule") {
                    onAction(.reschedule)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(BrandConstants.Colors.teal)
                .foregroundColor(.white)
                .cornerRadius(BrandConstants.CornerRadius.md)
                
                Button("Cancel Booking") {
                    onAction(.cancel)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
        }
    }
    
    private var completedActions: some View {
        VStack(spacing: 12) {
            Button("Write Review") {
                onAction(.writeReview)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
            
            Button("Share Experience") {
                onAction(.share)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(BrandConstants.Colors.teal)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
    }
}

struct BookingDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions

extension BookingStatus {
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        case .noShow:
            return "No Show"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pending:
            return Color.orange.opacity(0.2)
        case .confirmed:
            return Color.green.opacity(0.2)
        case .completed:
            return Color.blue.opacity(0.2)
        case .cancelled:
            return Color.red.opacity(0.2)
        case .noShow:
            return Color.gray.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch self {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .completed:
            return .blue
        case .cancelled:
            return .red
        case .noShow:
            return .gray
        }
    }
}

extension DateFormatter {
    static let bookingDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

enum BookingAction {
    case cancel
    case reschedule
    case addToCalendar
    case share
    case contactInstructor
    case writeReview
}

#Preview {
    MyBookingsView()
}