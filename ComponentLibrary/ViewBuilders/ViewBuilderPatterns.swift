import SwiftUI

// MARK: - @ViewBuilder Pattern Implementation Framework

/// Advanced @ViewBuilder patterns for flexible component composition
/// This framework demonstrates modern SwiftUI composition techniques using @ViewBuilder

// MARK: - Conditional Content Builder

enum ConditionalContentBuilder {
    /// Build content conditionally based on multiple criteria
    @ViewBuilder
    static func buildContent<Content: View>(
        showContent: Bool,
        isEmpty: Bool = false,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder emptyState: () -> some View = { EmptyView() },
        @ViewBuilder loadingState: () -> some View = { ProgressView() },
        @ViewBuilder errorState: (String) -> some View = { message in
            Text("Error: \(message)")
                .foregroundColor(.red)
        }
    ) -> some View {
        Group {
            if let error = errorMessage {
                errorState(error)
            } else if isLoading {
                loadingState()
            } else if isEmpty {
                emptyState()
            } else if showContent {
                content()
            } else {
                EmptyView()
            }
        }
    }

    /// Build content with optional sections
    @ViewBuilder
    static func buildOptionalSections<Header: View, Content: View, Footer: View>(
        showHeader: Bool = true,
        showContent: Bool = true,
        showFooter: Bool = true,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 16) {
            if showHeader {
                header()
            }

            if showContent {
                content()
            }

            if showFooter {
                footer()
            }
        }
    }
}

// MARK: - Layout Builder

enum LayoutBuilder {
    /// Build adaptive layouts based on screen size and content
    @ViewBuilder
    static func buildAdaptiveLayout<Content: View>(
        @ViewBuilder content: @escaping () -> Content,
        compactLayout: LayoutDirection = .vertical,
        regularLayout: LayoutDirection = .horizontal,
        spacing: CGFloat = 16
    ) -> some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 600

            Group {
                if isCompact {
                    buildLayout(direction: compactLayout, spacing: spacing, content: content)
                } else {
                    buildLayout(direction: regularLayout, spacing: spacing, content: content)
                }
            }
        }
    }

    @ViewBuilder
    private static func buildLayout<Content: View>(
        direction: LayoutDirection,
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        switch direction {
        case .horizontal:
            HStack(spacing: spacing) {
                content()
            }
        case .vertical:
            VStack(spacing: spacing) {
                content()
            }
        case let .grid(columns):
            LazyVGrid(columns: columns, spacing: spacing) {
                content()
            }
        }
    }

    enum LayoutDirection {
        case horizontal
        case vertical
        case grid([GridItem])
    }
}

// MARK: - Collection Builder

enum CollectionBuilder {
    /// Build collections with flexible item rendering
    @ViewBuilder
    static func buildCollection<Item: Identifiable, ItemView: View>(
        items: [Item],
        maxItems: Int? = nil,
        showSeeMore: Bool = true,
        onSeeMore: (() -> Void)? = nil,
        @ViewBuilder itemBuilder: @escaping (Item) -> ItemView
    ) -> some View {
        let displayedItems = Array(items.prefix(maxItems ?? items.count))
        let hasMoreItems = items.count > (maxItems ?? items.count)

        VStack(spacing: 8) {
            ForEach(displayedItems, id: \.id) { item in
                itemBuilder(item)
            }

            if hasMoreItems && showSeeMore {
                Button("See More (\(items.count - displayedItems.count) more)") {
                    onSeeMore?()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                .padding(.top, 4)
            }
        }
    }

    /// Build horizontal scrolling collection
    @ViewBuilder
    static func buildHorizontalCollection<Item: Identifiable, ItemView: View>(
        items: [Item],
        spacing: CGFloat = 12,
        showScrollIndicators: Bool = false,
        @ViewBuilder itemBuilder: @escaping (Item) -> ItemView
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: showScrollIndicators) {
            HStack(spacing: spacing) {
                ForEach(items, id: \.id) { item in
                    itemBuilder(item)
                }
            }
            .padding(.horizontal)
        }
    }

    /// Build grid collection with adaptive sizing
    @ViewBuilder
    static func buildGridCollection<Item: Identifiable, ItemView: View>(
        items: [Item],
        minItemWidth: CGFloat = 160,
        spacing: CGFloat = 12,
        @ViewBuilder itemBuilder: @escaping (Item) -> ItemView
    ) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minItemWidth), spacing: spacing)],
            spacing: spacing
        ) {
            ForEach(items, id: \.id) { item in
                itemBuilder(item)
            }
        }
    }
}

// MARK: - Card Builder

enum CardBuilder {
    /// Build cards with flexible content and styling
    @ViewBuilder
    static func buildCard<Content: View>(
        style: CardStyle = .default,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(style.padding)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: style.shadowOffset.x,
                y: style.shadowOffset.y
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
    }

    /// Build expandable card
    @ViewBuilder
    static func buildExpandableCard<Header: View, Content: View>(
        isExpanded: Binding<Bool>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        style: CardStyle = .default
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.wrappedValue.toggle() }) {
                HStack {
                    header()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded.wrappedValue)
                }
                .padding(style.padding)
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
                    .padding([.horizontal, .bottom], style.padding)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
        .shadow(
            color: style.shadowColor,
            radius: style.shadowRadius,
            x: style.shadowOffset.x,
            y: style.shadowOffset.y
        )
    }

    struct CardStyle {
        let backgroundColor: Color
        let cornerRadius: CGFloat
        let padding: CGFloat
        let borderColor: Color
        let borderWidth: CGFloat
        let shadowColor: Color
        let shadowRadius: CGFloat
        let shadowOffset: CGSize

        static let `default` = CardStyle(
            backgroundColor: .background,
            cornerRadius: 12,
            padding: 16,
            borderColor: .gray.opacity(0.2),
            borderWidth: 1,
            shadowColor: .black.opacity(0.1),
            shadowRadius: 2,
            shadowOffset: CGSize(width: 0, height: 1)
        )

        static let elevated = CardStyle(
            backgroundColor: .background,
            cornerRadius: 16,
            padding: 20,
            borderColor: .clear,
            borderWidth: 0,
            shadowColor: .black.opacity(0.15),
            shadowRadius: 8,
            shadowOffset: CGSize(width: 0, height: 4)
        )

        static let minimal = CardStyle(
            backgroundColor: .background,
            cornerRadius: 8,
            padding: 12,
            borderColor: .gray.opacity(0.3),
            borderWidth: 1,
            shadowColor: .clear,
            shadowRadius: 0,
            shadowOffset: .zero
        )
    }
}

// MARK: - Form Builder

enum FormBuilder {
    /// Build forms with flexible field arrangement
    @ViewBuilder
    static func buildForm<Content: View>(
        style: FormStyle = .grouped,
        @ViewBuilder content: () -> Content
    ) -> some View {
        switch style {
        case .grouped:
            VStack(spacing: 24) {
                content()
            }
        case .inline:
            VStack(spacing: 8) {
                content()
            }
        case .sectioned:
            VStack(spacing: 32) {
                content()
            }
        }
    }

    /// Build form section with title
    @ViewBuilder
    static func buildFormSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                content()
            }
        }
    }

    enum FormStyle {
        case grouped
        case inline
        case sectioned
    }
}

// MARK: - Navigation Builder

enum NavigationBuilder {
    /// Build navigation with flexible back button and actions
    @ViewBuilder
    static func buildNavigationHeader<Actions: View>(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        HStack {
            if showBackButton {
                Button(action: { onBack?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.body)
                    .foregroundColor(.accentColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            actions()
        }
        .padding()
    }

    /// Build tab-style navigation
    @ViewBuilder
    static func buildTabNavigation<Content: View>(
        selectedTab: Binding<Int>,
        tabs: [TabItem],
        @ViewBuilder content: @escaping (Int) -> Content
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(tabs.indices, id: \.self) { index in
                        TabButton(
                            tab: tabs[index],
                            isSelected: selectedTab.wrappedValue == index,
                            action: { selectedTab.wrappedValue = index }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)

            content(selectedTab.wrappedValue)
        }
    }

    struct TabItem {
        let title: String
        let icon: String?
        let badge: String?

        init(title: String, icon: String? = nil, badge: String? = nil) {
            self.title = title
            self.icon = icon
            self.badge = badge
        }
    }

    private struct TabButton: View {
        let tab: TabItem
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    if let icon = tab.icon {
                        Image(systemName: icon)
                            .font(.subheadline)
                    }

                    Text(tab.title)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    if let badge = tab.badge {
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    isSelected ? .accentColor.opacity(0.1) : .clear
                )
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - State Builder

enum StateBuilder {
    /// Build content based on loading state
    @ViewBuilder
    static func buildLoadingState<Content: View, Loading: View, Error: View>(
        isLoading: Bool,
        error: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loading: () -> Loading,
        @ViewBuilder errorView: (String) -> Error
    ) -> some View {
        Group {
            if let error = error {
                errorView(error)
            } else if isLoading {
                loading()
            } else {
                content()
            }
        }
    }

    /// Build content with empty state
    @ViewBuilder
    static func buildEmptyState<Content: View, Empty: View>(
        isEmpty: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder empty: () -> Empty
    ) -> some View {
        Group {
            if isEmpty {
                empty()
            } else {
                content()
            }
        }
    }
}

// MARK: - Animation Builder

enum AnimationBuilder {
    /// Build content with entrance animations
    @ViewBuilder
    static func buildWithEntranceAnimation<Content: View>(
        delay: Double = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity
            ))
            .animation(
                .easeOut(duration: 0.6).delay(delay),
                value: true
            )
    }

    /// Build staggered animations for collections
    @ViewBuilder
    static func buildStaggeredAnimation<Item: Identifiable, ItemView: View>(
        items: [Item],
        staggerDelay: Double = 0.1,
        @ViewBuilder itemBuilder: @escaping (Item, Int) -> ItemView
    ) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            itemBuilder(item, index)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .leading)),
                    removal: .opacity
                ))
                .animation(
                    .easeOut(duration: 0.5).delay(Double(index) * staggerDelay),
                    value: items.count
                )
        }
    }
}

// MARK: - Composition Examples

enum ComponentCompositionExamples {
    /// Example of complex component composition using @ViewBuilder
    @ViewBuilder
    static func buildClassDetailView(
        classData: ClassHeaderData,
        instructorData: InstructorData,
        reviewsData: ReviewsData,
        sessionsData: SessionsData,
        locationData: LocationData
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with hero image and actions
                ClassHeaderComponent(
                    classHeaderData: classData,
                    configuration: ClassHeaderConfiguration(
                        heroImageHeight: 300,
                        showActionButtons: true
                    )
                )

                // Content sections with conditional display
                ConditionalContentBuilder.buildOptionalSections(
                    showHeader: true,
                    showContent: true,
                    showFooter: true
                ) {
                    // Header: Instructor info
                    ClassInstructorComponent(
                        instructorData: instructorData,
                        configuration: ClassInstructorConfiguration(
                            showUpcomingClasses: false
                        )
                    )
                } content: {
                    // Content: Sessions and reviews
                    VStack(spacing: 20) {
                        ClassSessionsComponent(
                            sessionsData: sessionsData,
                            configuration: ClassSessionsConfiguration(
                                displayStyle: .grid
                            )
                        )

                        ClassReviewsComponent(
                            reviewsData: reviewsData,
                            configuration: ClassReviewsConfiguration(
                                maxVisibleReviews: 3
                            )
                        )
                    }
                } footer: {
                    // Footer: Location info
                    ClassLocationComponent(
                        locationData: locationData,
                        configuration: ClassLocationConfiguration(
                            mapHeight: 200
                        )
                    )
                }
            }
            .padding()
        }
    }

    /// Example of multi-step booking flow composition
    @ViewBuilder
    static func buildBookingFlow() -> some View {
        NavigationBuilder.buildTabNavigation(
            selectedTab: .constant(0),
            tabs: [
                .init(title: "Classes", icon: "list.bullet"),
                .init(title: "Times", icon: "clock"),
                .init(title: "Payment", icon: "creditcard"),
            ]
        ) { selectedTab in
            switch selectedTab {
            case 0:
                MultiClassSelectionGrid(
                    classes: [],
                    selectedClasses: Set(),
                    onSelectionChange: { _ in }
                )
            case 1:
                ClassSessionsComponent(
                    sessionsData: SessionsData(
                        sessions: [],
                        totalCount: 0,
                        availableCount: 0,
                        waitlistCount: 0
                    )
                )
            case 2:
                // Payment view would go here
                Text("Payment")
            default:
                EmptyView()
            }
        }
    }
}
