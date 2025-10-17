import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @StateObject private var viewModel = HomeViewModel()
    @State private var isShowingSearch = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LoadingStateView()
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(
                        message: error,
                        retryAction: {
                            Task { await viewModel.load() }
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            WelcomeSection(
                                userName: supabaseService.currentUser?.name ?? "Hobbyist",
                                bookingsCount: viewModel.totalUpcomingBookings
                            )

                            SearchShortcutButton {
                                isShowingSearch = true
                            }

                            TimeFilterPicker(selectedFilter: $viewModel.timeFilter)

                            if !viewModel.featuredClasses.isEmpty {
                                FeaturedClassesSection(classes: viewModel.featuredClasses)
                            }

                            if !viewModel.categories.isEmpty {
                                CategoriesSection(categories: viewModel.categories)
                            }

                            if !viewModel.recommendedClasses.isEmpty {
                                RecommendedClassesSection(classes: viewModel.recommendedClasses)
                            }

                            if viewModel.featuredClasses.isEmpty && viewModel.recommendedClasses.isEmpty {
                                EmptyHomeState(selectedFilter: viewModel.timeFilter)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Discover")
            .sheet(isPresented: $isShowingSearch) {
                NavigationStack {
                    SearchView()
                        .environmentObject(supabaseService)
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

// MARK: - View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var featuredClasses: [SimpleClass] = []
    @Published var recommendedClasses: [SimpleClass] = []
    @Published var categories: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var totalUpcomingBookings: Int = 0
    @Published var timeFilter: TimeFilter = .today {
        didSet { updateSections() }
    }

    private let supabaseService = SimpleSupabaseService.shared
    private var allClasses: [SimpleClass] = []

    enum TimeFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        case allUpcoming = "All Upcoming"

        var id: TimeFilter { self }
        var title: String { rawValue }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let classes = await supabaseService.fetchClasses()
        let bookings = await supabaseService.fetchUserBookings()

        if !classes.isEmpty {
            allClasses = classes.sorted { lhs, rhs in
                let leftDate = lhs.startDate ?? Date.distantFuture
                let rightDate = rhs.startDate ?? Date.distantFuture
                return leftDate < rightDate
            }
            updateSections()
        } else if let error = supabaseService.errorMessage {
            errorMessage = error
        } else {
            errorMessage = "No classes available right now. Check back soon!"
        }

        totalUpcomingBookings = bookings.filter { $0.bookingDate >= Date() }.count

        isLoading = false
    }

    func refresh() async {
        supabaseService.errorMessage = nil
        await load()
    }

    private func updateSections() {
        let filtered = filteredClasses(allClasses, for: timeFilter)

        let featuredSlice = filtered.prefix(6)
        featuredClasses = Array(featuredSlice)

        let recommendedSlice = filtered.dropFirst(featuredSlice.count).prefix(10)
        recommendedClasses = Array(recommendedSlice)

        categories = Array(Set(filtered.map(\.category))).sorted()
    }

    private func filteredClasses(_ classes: [SimpleClass], for filter: TimeFilter) -> [SimpleClass] {
        guard !classes.isEmpty else { return [] }

        switch filter {
        case .today:
            return classes.filter { simpleClass in
                guard let startDate = simpleClass.startDate else { return false }
                return Calendar.current.isDateInToday(startDate)
            }
        case .thisWeek:
            return classes.filter { simpleClass in
                guard let startDate = simpleClass.startDate else { return false }
                return Calendar.current.isDate(startDate, equalTo: Date(), toGranularity: .weekOfYear)
            }
        case .allUpcoming:
            return classes.filter { simpleClass in
                guard let startDate = simpleClass.startDate else { return true }
                return startDate >= Calendar.current.startOfDay(for: Date())
            }
        }
    }
}

// MARK: - Sections

private struct WelcomeSection: View {
    let userName: String
    let bookingsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hi \(userName.split(separator: " ").first ?? "there") 👋")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(bookingsCount > 0 ?
                 "You have \(bookingsCount) upcoming \(bookingsCount == 1 ? "class" : "classes") this week." :
                    "Find a new class to keep your creativity flowing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

private struct SearchShortcutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.blue)
                Text("Search classes, studios, or instructors")
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

private struct FeaturedClassesSection: View {
    let classes: [SimpleClass]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Featured Classes",
                actionTitle: nil,
                action: nil
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(classes) { classItem in
                        HomeClassCard(classItem: classItem, style: .featured)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct CategoriesSection: View {
    let categories: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Categories")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct RecommendedClassesSection: View {
    let classes: [SimpleClass]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Recommended For You",
                actionTitle: nil,
                action: nil
            )

            LazyVStack(spacing: 16) {
                ForEach(classes) { classItem in
                    HomeClassCard(classItem: classItem, style: .standard)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Reusable UI

private struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }
}

private struct TimeFilterPicker: View {
    @Binding var selectedFilter: HomeViewModel.TimeFilter

    var body: some View {
        Picker("Time Filter", selection: $selectedFilter) {
            ForEach(HomeViewModel.TimeFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

struct HomeClassCard: View {
    enum Style {
        case featured
        case standard
    }

    let classItem: SimpleClass
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let imageURL = classItem.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            PlaceholderImage()
                        @unknown default:
                            PlaceholderImage()
                        }
                    }
                    .frame(width: style == .featured ? 120 : 80, height: style == .featured ? 120 : 80)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    PlaceholderImage()
                        .frame(width: style == .featured ? 120 : 80, height: style == .featured ? 120 : 80)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(classItem.title)
                        .font(style == .featured ? .title3 : .headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text("with \(classItem.instructor)")
                        .font(.subheadline)
                        .foregroundStyle(.blue)

                    HStack(alignment: .center, spacing: 8) {
                        Text(classItem.category)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.12))
                            )
                            .foregroundStyle(Color.blue)

                        Spacer()

                        Text(classItem.priceFormatted)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }

                    Label("\(classItem.duration) min", systemImage: "stopwatch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if let startDate = classItem.startDate {
                    Label(
                        HomeClassCard.dayFormatter.string(from: startDate),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let endDate = classItem.endDate {
                        let timeRange = "\(HomeClassCard.timeFormatter.string(from: startDate)) – \(HomeClassCard.timeFormatter.string(from: endDate))"
                        Label(timeRange, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label(HomeClassCard.timeFormatter.string(from: startDate), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Label(
                    classItem.displayLocation,
                    systemImage: classItem.isOnline ? "wifi" : "mappin.and.ellipse"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if let spots = classItem.spotsRemaining, spots > 0 {
                    Label(
                        "\(spots) spot\(spots == 1 ? "" : "s") left",
                        systemImage: "person.3.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(spots <= 3 ? Color.red : Color.secondary)
                } else if let maxCapacity = classItem.maxParticipants, maxCapacity > 0 {
                    Label(
                        "Fully booked",
                        systemImage: "checkmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        )
        .frame(width: style == .featured ? 260 : nil)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private struct PlaceholderImage: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.08))
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(Color.blue)
        }
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView("Loading classes...")
            Text("Fetching the latest schedules from Supabase.")
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
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("We had trouble loading classes.")
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

private struct EmptyHomeState: View {
    let selectedFilter: HomeViewModel.TimeFilter

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondary)

            Text("No classes match your filter.")
                .font(.headline)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal)
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .today:
            return "No classes are starting today. Try expanding your timeframe."
        case .thisWeek:
            return "We don’t have classes scheduled this week yet. Check back soon or view all upcoming classes."
        case .allUpcoming:
            return "No upcoming classes are available at the moment. Please check again later."
        }
    }
}
