import SwiftUI

// MARK: - Refactored Class Sessions Component

struct ClassSessionsComponent: View, DataDisplayComponent {
    typealias Configuration = ClassSessionsConfiguration
    typealias DataType = SessionsData

    // MARK: - Properties

    let configuration: ClassSessionsConfiguration
    let data: SessionsData
    let isLoading: Bool
    let errorState: String?
    let onSessionSelect: ((SessionData) -> Void)?
    let onFilterChange: ((SessionFilter) -> Void)?

    // MARK: - State

    @State private var selectedFilter: SessionFilter = .all
    @State private var selectedDateRange: DateRange = .thisWeek

    // MARK: - Initializer

    init(
        sessionsData: SessionsData,
        isLoading: Bool = false,
        errorState: String? = nil,
        onSessionSelect: ((SessionData) -> Void)? = nil,
        onFilterChange: ((SessionFilter) -> Void)? = nil,
        configuration: ClassSessionsConfiguration = ClassSessionsConfiguration()
    ) {
        data = sessionsData
        self.isLoading = isLoading
        self.errorState = errorState
        self.onSessionSelect = onSessionSelect
        self.onFilterChange = onFilterChange
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SessionsHeader(
                sessionsData: data,
                selectedFilter: $selectedFilter,
                selectedDateRange: $selectedDateRange,
                onFilterChange: { filter in
                    onFilterChange?(filter)
                },
                configuration: configuration
            )

            if isLoading {
                SessionsLoadingView()
            } else if let errorState = errorState {
                SessionsErrorView(message: errorState)
            } else {
                SessionsContent(
                    sessionsData: data,
                    selectedFilter: selectedFilter,
                    selectedDateRange: selectedDateRange,
                    onSessionSelect: onSessionSelect,
                    configuration: configuration
                )
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Sessions Header Sub-Component

struct SessionsHeader: View {
    let sessionsData: SessionsData
    @Binding var selectedFilter: SessionFilter
    @Binding var selectedDateRange: DateRange
    let onFilterChange: ((SessionFilter) -> Void)?
    let configuration: ClassSessionsConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ModularHeader(
                title: "Available Sessions",
                subtitle: "\(filteredSessionsCount) sessions found",
                headerStyle: .medium
            )

            SessionsFilters(
                selectedFilter: $selectedFilter,
                selectedDateRange: $selectedDateRange,
                onFilterChange: onFilterChange
            )
        }
    }

    private var filteredSessionsCount: Int {
        // Calculate based on current filters
        sessionsData.sessions.filter { session in
            selectedFilter.matches(session: session) &&
                selectedDateRange.contains(date: session.date)
        }.count
    }
}

// MARK: - Sessions Filters Sub-Component

struct SessionsFilters: View {
    @Binding var selectedFilter: SessionFilter
    @Binding var selectedDateRange: DateRange
    let onFilterChange: ((SessionFilter) -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            // Session Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SessionFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            onTap: {
                                selectedFilter = filter
                                onFilterChange?(filter)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Date Range Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        FilterChip(
                            title: range.displayName,
                            isSelected: selectedDateRange == range,
                            onTap: { selectedDateRange = range }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Filter Chip Sub-Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? .accentColor : .gray.opacity(0.2)
                )
                .foregroundColor(
                    isSelected ? .white : .primary
                )
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Sessions Content Sub-Component

struct SessionsContent: View {
    let sessionsData: SessionsData
    let selectedFilter: SessionFilter
    let selectedDateRange: DateRange
    let onSessionSelect: ((SessionData) -> Void)?
    let configuration: ClassSessionsConfiguration

    private var filteredSessions: [SessionData] {
        sessionsData.sessions.filter { session in
            selectedFilter.matches(session: session) &&
                selectedDateRange.contains(date: session.date)
        }.sorted { $0.date < $1.date }
    }

    private var groupedSessions: [(String, [SessionData])] {
        Dictionary(grouping: filteredSessions) { session in
            session.date.formatted(.dateTime.weekday(.wide).month().day())
        }
        .sorted { $0.key < $1.key }
    }

    var body: some View {
        if configuration.displayStyle == .list {
            SessionsList(
                sessions: filteredSessions,
                onSessionSelect: onSessionSelect
            )
        } else {
            SessionsGrid(
                groupedSessions: groupedSessions,
                onSessionSelect: onSessionSelect,
                configuration: configuration
            )
        }
    }
}

// MARK: - Sessions List Sub-Component

struct SessionsList: View {
    let sessions: [SessionData]
    let onSessionSelect: ((SessionData) -> Void)?

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(sessions, id: \.id) { session in
                EnhancedSessionCard(
                    session: session,
                    displayStyle: .list,
                    onSelect: { onSessionSelect?(session) }
                )
            }
        }
    }
}

// MARK: - Sessions Grid Sub-Component

struct SessionsGrid: View {
    let groupedSessions: [(String, [SessionData])]
    let onSessionSelect: ((SessionData) -> Void)?
    let configuration: ClassSessionsConfiguration

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(groupedSessions, id: \.0) { dayTitle, sessions in
                SessionsDay(
                    dayTitle: dayTitle,
                    sessions: sessions,
                    onSessionSelect: onSessionSelect,
                    configuration: configuration
                )
            }
        }
    }
}

// MARK: - Sessions Day Sub-Component

struct SessionsDay: View {
    let dayTitle: String
    let sessions: [SessionData]
    let onSessionSelect: ((SessionData) -> Void)?
    let configuration: ClassSessionsConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dayTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sessions, id: \.id) { session in
                        EnhancedSessionCard(
                            session: session,
                            displayStyle: .grid,
                            onSelect: { onSessionSelect?(session) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Enhanced Session Card Sub-Component

struct EnhancedSessionCard: View, InteractiveComponent {
    typealias Configuration = SessionCardConfiguration
    typealias Action = SessionAction

    let configuration: SessionCardConfiguration
    let session: SessionData
    let displayStyle: SessionDisplayStyle
    let onAction: ((SessionAction) -> Void)?

    @State private var isFavorited = false

    init(
        session: SessionData,
        displayStyle: SessionDisplayStyle = .list,
        onSelect: (() -> Void)? = nil,
        configuration: SessionCardConfiguration = SessionCardConfiguration()
    ) {
        self.session = session
        self.displayStyle = displayStyle
        self.configuration = configuration
        onAction = { action in
            switch action {
            case .select:
                onSelect?()
            case .favorite:
                // Handle favorite action
                break
            case .share:
                // Handle share action
                break
            }
        }
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        Button(action: { onAction?(.select) }) {
            if displayStyle == .list {
                ListSessionCard()
            } else {
                GridSessionCard()
            }
        }
        .buttonStyle(.plain)
        .componentStyle(configuration)
    }

    @ViewBuilder
    private func ListSessionCard() -> some View {
        HStack(spacing: 16) {
            SessionDateBadge(date: session.date)

            VStack(alignment: .leading, spacing: 6) {
                SessionTitle(session: session)
                SessionDetails(session: session)
                SessionStatus(session: session)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SessionPrice(price: session.price)
                SessionActions(
                    session: session,
                    isFavorited: $isFavorited,
                    compact: true
                )
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sessionBorderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func GridSessionCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SessionDateBadge(date: session.date, style: .compact)

            VStack(alignment: .leading, spacing: 8) {
                SessionTitle(session: session)
                SessionDetails(session: session)

                HStack {
                    SessionStatus(session: session, compact: true)
                    Spacer()
                    SessionPrice(price: session.price)
                }

                SessionActions(
                    session: session,
                    isFavorited: $isFavorited,
                    compact: false
                )
            }
        }
        .frame(width: 200)
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sessionBorderColor, lineWidth: 1)
        )
    }

    private var sessionBorderColor: Color {
        switch session.availability {
        case .available: return .gray.opacity(0.3)
        case .almostFull: return .orange.opacity(0.5)
        case .waitlist: return .red.opacity(0.5)
        case .full: return .gray.opacity(0.5)
        }
    }

    enum SessionAction {
        case select
        case favorite
        case share
    }
}

// MARK: - Session Sub-Components

struct SessionDateBadge: View {
    let date: Date
    let style: BadgeStyle

    init(date: Date, style: BadgeStyle = .normal) {
        self.date = date
        self.style = style
    }

    var body: some View {
        VStack(alignment: .center, spacing: style == .compact ? 2 : 4) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(style == .compact ? .caption2 : .caption)
                .foregroundColor(.secondary)

            Text(date.formatted(.dateTime.day()))
                .font(style == .compact ? .headline : .title2)
                .fontWeight(.bold)

            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(style == .compact ? .caption2 : .caption)
                .foregroundColor(.secondary)
        }
        .frame(width: style == .compact ? 40 : 50)
    }

    enum BadgeStyle {
        case normal
        case compact
    }
}

struct SessionTitle: View {
    let session: SessionData

    var body: some View {
        Text(session.time)
            .font(.headline)
            .fontWeight(.medium)
    }
}

struct SessionDetails: View {
    let session: SessionData

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "person.2")
                Text("\(session.spotsLeft) spots")
            }

            if let instructor = session.instructor {
                HStack(spacing: 4) {
                    Image(systemName: "person")
                    Text(instructor)
                }
            }

            if let duration = session.duration {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(duration)min")
                }
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

struct SessionStatus: View {
    let session: SessionData
    let compact: Bool

    init(session: SessionData, compact: Bool = false) {
        self.session = session
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(session.availability.color)
                .frame(width: 6, height: 6)

            if !compact {
                Text(session.availability.displayName)
                    .font(.caption)
                    .foregroundColor(session.availability.color)
            }
        }
    }
}

struct SessionPrice: View {
    let price: Double

    var body: some View {
        Text("$\(price, specifier: "%.0f")")
            .font(.subheadline)
            .fontWeight(.semibold)
    }
}

struct SessionActions: View {
    let session: SessionData
    @Binding var isFavorited: Bool
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            Button(action: { isFavorited.toggle() }) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .foregroundColor(isFavorited ? .red : .secondary)
            }

            if !compact {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }

                if session.availability == .waitlist {
                    Button("Join Waitlist") {}
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
            }
        }
        .font(.caption)
    }
}

// MARK: - Loading and Error Views

struct SessionsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 4, id: \.self) { _ in
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 50, height: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 12)
                            .frame(width: 120)
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .background(.background)
        .cornerRadius(12)
        .shimmering()
    }
}

struct SessionsErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to Load Sessions")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct SessionsData {
    let sessions: [SessionData]
    let totalCount: Int
    let availableCount: Int
    let waitlistCount: Int
}

struct SessionData: Identifiable {
    let id = UUID()
    let date: Date
    let time: String
    let spotsLeft: Int
    let price: Double
    let isWaitlisted: Bool
    let availability: SessionAvailability
    let instructor: String?
    let duration: Int?

    init(
        date: Date,
        time: String,
        spotsLeft: Int,
        price: Double,
        isWaitlisted: Bool = false,
        instructor: String? = nil,
        duration: Int? = nil
    ) {
        self.date = date
        self.time = time
        self.spotsLeft = spotsLeft
        self.price = price
        self.isWaitlisted = isWaitlisted
        self.instructor = instructor
        self.duration = duration

        // Determine availability based on spots and waitlist status
        if isWaitlisted {
            availability = .waitlist
        } else if spotsLeft == 0 {
            availability = .full
        } else if spotsLeft <= 2 {
            availability = .almostFull
        } else {
            availability = .available
        }
    }
}

enum SessionAvailability {
    case available
    case almostFull
    case waitlist
    case full

    var color: Color {
        switch self {
        case .available: return .green
        case .almostFull: return .orange
        case .waitlist: return .red
        case .full: return .gray
        }
    }

    var displayName: String {
        switch self {
        case .available: return "Available"
        case .almostFull: return "Almost Full"
        case .waitlist: return "Waitlist"
        case .full: return "Full"
        }
    }
}

enum SessionFilter: CaseIterable {
    case all
    case available
    case almostFull
    case waitlist
    case today
    case thisWeek

    var displayName: String {
        switch self {
        case .all: return "All"
        case .available: return "Available"
        case .almostFull: return "Almost Full"
        case .waitlist: return "Waitlist"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        }
    }

    func matches(session: SessionData) -> Bool {
        switch self {
        case .all: return true
        case .available: return session.availability == .available
        case .almostFull: return session.availability == .almostFull
        case .waitlist: return session.availability == .waitlist
        case .today: return Calendar.current.isDateInToday(session.date)
        case .thisWeek: return Calendar.current.isDate(session.date, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }
}

enum DateRange: CaseIterable {
    case today
    case thisWeek
    case nextWeek
    case thisMonth

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .nextWeek: return "Next Week"
        case .thisMonth: return "This Month"
        }
    }

    func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .today:
            return calendar.isDateInToday(date)
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .nextWeek:
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) else { return false }
            return calendar.isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }
    }
}

enum SessionDisplayStyle {
    case list
    case grid
}

// MARK: - Configuration Objects

struct ClassSessionsConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let displayStyle: SessionDisplayStyle
    let showFilters: Bool
    let maxVisibleSessions: Int

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        displayStyle: SessionDisplayStyle = .list,
        showFilters: Bool = true,
        maxVisibleSessions: Int = 10
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.displayStyle = displayStyle
        self.showFilters = showFilters
        self.maxVisibleSessions = maxVisibleSessions
    }
}

struct SessionCardConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
    }
}
