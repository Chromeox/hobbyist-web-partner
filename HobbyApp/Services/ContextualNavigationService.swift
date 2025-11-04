import SwiftUI
import Combine

// MARK: - Contextual Navigation System for Phase 3 Final

@MainActor
public class ContextualNavigationService: ObservableObject {
    static let shared = ContextualNavigationService()

    @Published var currentContext: NavigationContext = .browsing
    @Published var contextHistory: [NavigationContext] = []
    @Published var transitionInProgress = false

    private let hapticService = HapticFeedbackService.shared

    private init() {}

    // MARK: - Context Management

    func enterContext(_ context: NavigationContext, from source: NavigationContext? = nil) {
        let previousContext = currentContext

        withAnimation(context.entryAnimation) {
            currentContext = context
            if let source = source {
                contextHistory.append(source)
            } else {
                contextHistory.append(previousContext)
            }
        }

        // Haptic feedback based on context
        context.hapticFeedback.forEach { feedbackType in
            switch feedbackType {
            case .light:
                hapticService.playLight()
            case .medium:
                hapticService.playSelection()
            case .heavy:
                hapticService.playSuccess()
            }
        }
    }

    func exitContext() {
        guard let previousContext = contextHistory.popLast() else { return }

        withAnimation(currentContext.exitAnimation) {
            currentContext = previousContext
        }
    }

    func resetToRoot() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentContext = .browsing
            contextHistory.removeAll()
        }
    }

    // MARK: - Transition Coordination

    func performTransition<Content: View>(
        to destination: Content,
        context: NavigationContext,
        completion: (() -> Void)? = nil
    ) -> some View {
        destination
            .modifier(ContextualTransitionModifier(
                context: context,
                service: self,
                completion: completion
            ))
    }

    func getTransition(for context: NavigationContext) -> AnyTransition {
        context.transition
    }
}

// MARK: - Navigation Contexts

public enum NavigationContext: String, CaseIterable {
    case browsing = "browsing"
    case searching = "searching"
    case booking = "booking"
    case profile = "profile"
    case settings = "settings"
    case classDetail = "classDetail"
    case studioDetail = "studioDetail"
    case paymentFlow = "paymentFlow"
    case onboarding = "onboarding"

    var displayName: String {
        switch self {
        case .browsing: return "Browsing"
        case .searching: return "Searching"
        case .booking: return "Booking"
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .classDetail: return "Class Details"
        case .studioDetail: return "Studio Details"
        case .paymentFlow: return "Payment"
        case .onboarding: return "Setup"
        }
    }

    var entryAnimation: Animation {
        switch self {
        case .browsing:
            return .easeInOut(duration: 0.3)
        case .searching:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .booking:
            return .easeOut(duration: 0.25)
        case .profile, .settings:
            return .easeInOut(duration: 0.2)
        case .classDetail, .studioDetail:
            return .spring(response: 0.6, dampingFraction: 0.8)
        case .paymentFlow:
            return .easeIn(duration: 0.2)
        case .onboarding:
            return .spring(response: 0.5, dampingFraction: 0.9)
        }
    }

    var exitAnimation: Animation {
        switch self {
        case .browsing:
            return .easeInOut(duration: 0.25)
        case .searching:
            return .easeOut(duration: 0.2)
        case .booking:
            return .spring(response: 0.4, dampingFraction: 0.7)
        case .profile, .settings:
            return .easeInOut(duration: 0.2)
        case .classDetail, .studioDetail:
            return .easeOut(duration: 0.3)
        case .paymentFlow:
            return .easeOut(duration: 0.25)
        case .onboarding:
            return .easeInOut(duration: 0.3)
        }
    }

    var transition: AnyTransition {
        switch self {
        case .browsing:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .searching:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .booking:
            return .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 1.05).combined(with: .opacity)
            )
        case .profile, .settings:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .classDetail, .studioDetail:
            return .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            )
        case .paymentFlow:
            return .asymmetric(
                insertion: .slide.combined(with: .opacity),
                removal: .slide.combined(with: .opacity)
            )
        case .onboarding:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        }
    }

    var hapticFeedback: [HapticType] {
        switch self {
        case .browsing, .searching:
            return [.light]
        case .booking, .paymentFlow:
            return [.medium]
        case .profile, .settings:
            return [.light]
        case .classDetail, .studioDetail:
            return [.medium]
        case .onboarding:
            return [.light]
        }
    }

    enum HapticType {
        case light, medium, heavy
    }
}

// MARK: - Contextual Transition Modifier

public struct ContextualTransitionModifier: ViewModifier {
    let context: NavigationContext
    let service: ContextualNavigationService
    let completion: (() -> Void)?

    @State private var isVisible = false

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(scaleForContext)
            .offset(offsetForContext)
            .rotation3DEffect(
                rotationAngle,
                axis: rotationAxis
            )
            .onAppear {
                service.enterContext(context)
                withAnimation(context.entryAnimation) {
                    isVisible = true
                }
                completion?()
            }
            .onDisappear {
                service.exitContext()
            }
    }

    private var scaleForContext: CGFloat {
        if !isVisible {
            switch context {
            case .classDetail, .studioDetail, .booking:
                return 0.9
            case .paymentFlow:
                return 0.95
            default:
                return 1.0
            }
        }
        return 1.0
    }

    private var offsetForContext: CGSize {
        if !isVisible {
            switch context {
            case .searching:
                return CGSize(width: 0, height: -20)
            case .profile, .settings:
                return CGSize(width: 0, height: 20)
            case .browsing:
                return CGSize(width: 20, height: 0)
            default:
                return .zero
            }
        }
        return .zero
    }

    private var rotationAngle: Angle {
        if !isVisible {
            switch context {
            case .paymentFlow:
                return .degrees(2)
            case .onboarding:
                return .degrees(-1)
            default:
                return .degrees(0)
            }
        }
        return .degrees(0)
    }

    private var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch context {
        case .paymentFlow:
            return (0, 1, 0)
        case .onboarding:
            return (0, 0, 1)
        default:
            return (0, 0, 1)
        }
    }
}

// MARK: - Context-Aware Navigation Extensions

public extension View {
    func contextualTransition(
        _ context: NavigationContext,
        completion: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ContextualTransitionModifier(
            context: context,
            service: ContextualNavigationService.shared,
            completion: completion
        ))
    }

    func contextualNavigation<Destination: View>(
        to destination: Destination,
        context: NavigationContext
    ) -> some View {
        NavigationLink(destination: destination.contextualTransition(context)) {
            self
        }
    }
}

// MARK: - Context Indicator View

public struct NavigationContextIndicator: View {
    @StateObject private var navigationService = ContextualNavigationService.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(navigationService.currentContext.indicatorColor)
                .frame(width: 8, height: 8)
                .scaleEffect(navigationService.transitionInProgress ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: navigationService.transitionInProgress)

            Text(navigationService.currentContext.displayName)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(BrandConstants.Colors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(BrandConstants.CornerRadius.md)
        .opacity(navigationService.contextHistory.isEmpty ? 0 : 0.7)
        .animation(.easeInOut(duration: 0.3), value: navigationService.contextHistory.isEmpty)
    }
}

// MARK: - Context Extensions

extension NavigationContext {
    var indicatorColor: Color {
        switch self {
        case .browsing: return BrandConstants.Colors.primary
        case .searching: return BrandConstants.Colors.success
        case .booking: return BrandConstants.Colors.warning
        case .profile: return BrandConstants.Colors.coral
        case .settings: return BrandConstants.Colors.secondaryText
        case .classDetail: return BrandConstants.Colors.primary
        case .studioDetail: return BrandConstants.Colors.teal
        case .paymentFlow: return BrandConstants.Colors.error
        case .onboarding: return BrandConstants.Colors.warning
        }
    }
}

// MARK: - Preview

#Preview("Contextual Navigation") {
    VStack(spacing: 20) {
        NavigationContextIndicator()

        VStack(spacing: 12) {
            ForEach(NavigationContext.allCases, id: \.rawValue) { context in
                Button(context.displayName) {
                    ContextualNavigationService.shared.enterContext(context)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(context.indicatorColor.opacity(0.2))
                .cornerRadius(BrandConstants.CornerRadius.sm)
            }
        }
        .padding()
    }
}