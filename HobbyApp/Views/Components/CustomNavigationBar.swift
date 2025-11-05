import SwiftUI

// MARK: - Custom Navigation Bar with Blur Effects for Phase 3 Final

/// Advanced navigation bar system with context-aware styling and blur effects
@MainActor
public class NavigationBarCoordinator: ObservableObject {
    static let shared = NavigationBarCoordinator()

    @Published var currentStyle: NavigationBarStyle = .standard
    @Published var scrollOffset: CGFloat = 0
    @Published var isBlurred = false
    @Published var contextualTitle: String = ""

    private init() {}

    func updateStyle(_ style: NavigationBarStyle, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStyle = style
            }
        } else {
            currentStyle = style
        }
    }

    func updateScrollOffset(_ offset: CGFloat) {
        let threshold: CGFloat = 50
        let newBlurred = offset > threshold

        if newBlurred != isBlurred {
            withAnimation(.easeInOut(duration: 0.2)) {
                isBlurred = newBlurred
                scrollOffset = offset
            }
        } else {
            scrollOffset = offset
        }
    }

    func setContextualTitle(_ title: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            contextualTitle = title
        }
    }
}

// MARK: - Navigation Bar Styles

public enum NavigationBarStyle {
    case standard
    case prominent
    case minimal
    case search
    case profile
    case payment
    case booking

    var backgroundColor: Color {
        switch self {
        case .standard, .minimal:
            return .clear
        case .prominent:
            return Color(.systemBackground).opacity(0.95)
        case .search:
            return Color(.systemGray6).opacity(0.9)
        case .profile:
            return Color.blue.opacity(0.1)
        case .payment:
            return Color.green.opacity(0.05)
        case .booking:
            return Color.orange.opacity(0.08)
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .standard, .prominent:
            return 20
        case .minimal:
            return 10
        case .search, .profile, .payment, .booking:
            return 25
        }
    }

    var borderOpacity: Double {
        switch self {
        case .standard, .minimal:
            return 0.1
        case .prominent:
            return 0.15
        case .search, .profile, .payment, .booking:
            return 0.2
        }
    }

    var titleFont: Font {
        switch self {
        case .standard, .minimal:
            return .headline
        case .prominent:
            return .title2.bold()
        case .search:
            return .title3
        case .profile, .payment, .booking:
            return .title3.weight(.semibold)
        }
    }

    var height: CGFloat {
        switch self {
        case .standard, .minimal, .search:
            return 44
        case .prominent:
            return 60
        case .profile, .payment, .booking:
            return 52
        }
    }
}

// MARK: - Custom Navigation Bar View

public struct CustomNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let style: NavigationBarStyle
    let leading: Leading
    let trailing: Trailing

    @StateObject private var coordinator = NavigationBarCoordinator.shared
    @State private var isVisible = false
    @State private var titleOpacity: Double = 0

    public init(
        title: String,
        style: NavigationBarStyle = .standard,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.style = style
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        ZStack {
            // Blur background
            if coordinator.isBlurred || style != .standard {
                VariableBlurView(
                    maxBlurRadius: style.blurRadius,
                    direction: .blurredTopClearBottom,
                    startOffset: 0
                )
                .background(style.backgroundColor)
                .opacity(backgroundOpacity)
            }

            // Navigation content
            HStack(spacing: 16) {
                // Leading content
                HStack {
                    leading
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Title
                Text(coordinator.contextualTitle.isEmpty ? title : coordinator.contextualTitle)
                    .font(style.titleFont)
                    .foregroundColor(.primary)
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: titleOpacity)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(coordinator.contextualTitle.isEmpty ? title : coordinator.contextualTitle)

                // Trailing content
                HStack {
                    trailing
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .frame(height: style.height)
        }
        .overlay(
            // Bottom border
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator))
                .opacity(style.borderOpacity * borderMultiplier)
                .animation(.easeInOut(duration: 0.2), value: coordinator.isBlurred),
            alignment: .bottom
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -10)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: isVisible)
        .onAppear {
            coordinator.updateStyle(style, animated: false)
            withAnimation {
                isVisible = true
                titleOpacity = 1
            }
        }
        .onChange(of: coordinator.scrollOffset) { offset in
            updateTitleOpacity(for: offset)
        }
    }

    private var backgroundOpacity: Double {
        if coordinator.isBlurred {
            return 0.95
        }
        return style == .standard ? 0 : 0.8
    }

    private var borderMultiplier: Double {
        coordinator.isBlurred ? 1.5 : 1.0
    }

    private var titleScale: CGFloat {
        let scale = 1.0 - (coordinator.scrollOffset * 0.001)
        return max(0.95, min(1.0, scale))
    }

    private func updateTitleOpacity(for offset: CGFloat) {
        let newOpacity = 1.0 - (offset * 0.003)
        let clampedOpacity = max(0.3, min(1.0, newOpacity))

        withAnimation(.easeOut(duration: 0.1)) {
            titleOpacity = clampedOpacity
        }
    }
}

// MARK: - Variable Blur Effect

public struct VariableBlurView: UIViewRepresentable {
    let maxBlurRadius: CGFloat
    let direction: BlurDirection
    let startOffset: CGFloat

    public enum BlurDirection {
        case blurredTopClearBottom
        case blurredBottomClearTop
        case blurredLeftClearRight
        case blurredRightClearLeft
    }

    public func makeUIView(context: Context) -> UIVisualEffectView {
        let effect = UIBlurEffect(style: .systemMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.backgroundColor = UIColor.clear
        return effectView
    }

    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // Variable blur effect can be enhanced with custom masking
        // For now, using standard blur with customizable intensity
    }
}

// MARK: - Navigation Bar Preset Views

public struct HomeNavigationBar: View {
    let userName: String
    let onProfileTapped: () -> Void
    let onNotificationsTapped: () -> Void

    public var body: some View {
        CustomNavigationBar(
            title: "Discover",
            style: .prominent,
            leading: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hello")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    Text(userName)
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Hello, \(userName)")
                .accessibilityAddTraits(.isHeader)
            },
            trailing: {
                HStack(spacing: 12) {
                    AnimatedIconButton(
                        icon: "bell",
                        style: .minimal,
                        size: .regular
                    ) {
                        onNotificationsTapped()
                    }

                    AnimatedIconButton(
                        icon: "person.circle",
                        style: .minimal,
                        size: .regular
                    ) {
                        onProfileTapped()
                    }
                }
            }
        )
    }
}

public struct SearchNavigationBar: View {
    @Binding var searchText: String
    let onCancelTapped: () -> Void

    public var body: some View {
        CustomNavigationBar(
            title: "Search",
            style: .search,
            leading: {
                EmptyView()
            },
            trailing: {
                if !searchText.isEmpty {
                    Button("Cancel") {
                        onCancelTapped()
                    }
                    .foregroundColor(.blue)
                    .font(BrandConstants.Typography.body)
                    .accessibilityLabel("Cancel search")
                    .accessibilityHint("Clear search text and return to search results")
                }
            }
        )
    }
}

public struct BookingNavigationBar: View {
    let progress: Double
    let onBackTapped: () -> Void

    public var body: some View {
        CustomNavigationBar(
            title: "Book Class",
            style: .booking,
            leading: {
                AnimatedIconButton(
                    icon: "chevron.left",
                    style: .minimal
                ) {
                    onBackTapped()
                }
            },
            trailing: {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Booking progress")
                .accessibilityValue("\(Int(progress * 100)) percent complete")
                }
            }
        )
    }
}

public struct PaymentNavigationBar: View {
    let onBackTapped: () -> Void

    public var body: some View {
        CustomNavigationBar(
            title: "Payment",
            style: .payment,
            leading: {
                AnimatedIconButton(
                    icon: "chevron.left",
                    style: .minimal
                ) {
                    onBackTapped()
                }
            },
            trailing: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                    Text("Secure")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Secure payment")
                .accessibilityHint("Payment is secured with encryption")
            }
        )
    }
}

// MARK: - Scroll-Aware Container

public struct ScrollAwareContainer<Content: View>: View {
    let content: Content

    @StateObject private var coordinator = NavigationBarCoordinator.shared

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
                .frame(height: 0)

                content
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                coordinator.updateScrollOffset(-value)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Context-Aware Navigation Extensions

public extension View {
    func customNavigationBar<Leading: View, Trailing: View>(
        title: String,
        style: NavigationBarStyle = .standard,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                title: title,
                style: style,
                leading: leading,
                trailing: trailing
            )

            self
        }
        .navigationBarHidden(true)
    }

    func scrollAwareNavigation() -> some View {
        ScrollAwareContainer {
            self
        }
    }
}

// MARK: - Preview

#Preview("Custom Navigation Bars") {
    VStack(spacing: 0) {
        HomeNavigationBar(
            userName: "Alex",
            onProfileTapped: {},
            onNotificationsTapped: {}
        )

        ScrollAwareContainer {
            LazyVStack(spacing: 16) {
                ForEach(0..<20, id: \.self) { index in
                    AnimatedCard(style: .default) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                            Text("Scroll Item \(index + 1)")
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}