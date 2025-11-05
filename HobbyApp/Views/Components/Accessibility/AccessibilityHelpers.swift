import SwiftUI

/// Accessibility helpers for improved app usability
struct AccessibilityHelpers {
    
    /// Adds proper accessibility labels for loading states
    static func loadingAccessibility(message: String = "Loading content") -> some View {
        EmptyView()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(message)
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Creates accessible skeleton loading announcement
    static func skeletonAccessibility(type: String, count: Int = 1) -> some View {
        EmptyView()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading \(count) \(type)\(count > 1 ? "s" : "")")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// View modifier for enhanced loading accessibility
struct LoadingAccessibilityModifier: ViewModifier {
    let isLoading: Bool
    let loadingMessage: String
    let loadedMessage: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: isLoading ? .ignore : .contain)
            .accessibilityLabel(isLoading ? loadingMessage : (loadedMessage ?? ""))
            .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}

/// View modifier for reduced motion support
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let fallbackAnimation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? fallbackAnimation : animation, value: UUID())
    }
}

/// Enhanced accessibility for onboarding steps
struct OnboardingAccessibilityModifier: ViewModifier {
    let currentStep: Int
    let totalSteps: Int
    let stepTitle: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps): \(stepTitle)")
            .accessibilityAddTraits(.isHeader)
            .accessibilityScrollAction { edge in
                // Announce scroll actions for screen readers
                if edge == .trailing {
                    return .handled
                }
                return .ignored
            }
    }
}

/// Performance-optimized image loading with accessibility
struct AccessibleAsyncImage: View {
    let url: URL?
    let placeholder: String
    let accessibilityLabel: String
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isLoaded = false
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .onAppear {
                    withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.3)) {
                        isLoaded = true
                    }
                }
        } placeholder: {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                
                if !isLoaded {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Image(systemName: placeholder)
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .opacity(isLoaded ? 0 : 1)
            }
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: isLoaded)
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies loading accessibility with custom messages
    func loadingAccessibility(
        isLoading: Bool,
        loadingMessage: String = "Loading content",
        loadedMessage: String? = nil
    ) -> some View {
        modifier(LoadingAccessibilityModifier(
            isLoading: isLoading,
            loadingMessage: loadingMessage,
            loadedMessage: loadedMessage
        ))
    }
    
    /// Applies reduced motion support to animations
    func adaptiveAnimation(
        _ animation: Animation,
        fallback: Animation = .none
    ) -> some View {
        modifier(ReducedMotionModifier(
            animation: animation,
            fallbackAnimation: fallback
        ))
    }
    
    /// Enhances onboarding step accessibility
    func onboardingAccessibility(
        currentStep: Int,
        totalSteps: Int,
        stepTitle: String
    ) -> some View {
        modifier(OnboardingAccessibilityModifier(
            currentStep: currentStep,
            totalSteps: totalSteps,
            stepTitle: stepTitle
        ))
    }
    
    /// Adds semantic accessibility for loading states
    func semanticLoading(
        _ isLoading: Bool,
        announcement: String = "Content is loading"
    ) -> some View {
        Group {
            if isLoading {
                self.overlay(
                    AccessibilityHelpers.loadingAccessibility(message: announcement)
                )
            } else {
                self
            }
        }
    }
    
    /// Performance-optimized conditional view rendering
    func conditionalRender<T: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> T
    ) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
    
    /// Adds proper focus management for navigation
    func focusOnAppear(
        _ isFocused: Bool = true,
        delay: Double = 0.5
    ) -> some View {
        self
            .onAppear {
                if isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        // Announce the new screen to VoiceOver
                        UIAccessibility.post(notification: .screenChanged, argument: nil)
                    }
                }
            }
    }
}

// MARK: - Performance Optimizations

/// Memory-efficient lazy loading container
struct LazyContentView<Content: View>: View {
    let isVisible: Bool
    @ViewBuilder let content: () -> Content
    
    @State private var hasAppeared = false
    
    var body: some View {
        Group {
            if hasAppeared || isVisible {
                content()
                    .onAppear {
                        hasAppeared = true
                    }
            } else {
                Color.clear
                    .onAppear {
                        // Preload content slightly before it becomes visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            hasAppeared = true
                        }
                    }
            }
        }
    }
}

/// High-performance image cache configuration
struct ImageCacheConfig {
    static let shared = ImageCacheConfig()
    
    private init() {
        // Configure URLCache for optimal image loading
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50MB memory
            diskCapacity: 200 * 1024 * 1024,  // 200MB disk
            diskPath: "hobbyapp_images"
        )
        URLCache.shared = cache
    }
}

/// Memory pressure monitoring
class MemoryPressureMonitor: ObservableObject {
    @Published var shouldReduceQuality = false
    
    init() {
        setupMemoryWarningNotification()
    }
    
    private func setupMemoryWarningNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.shouldReduceQuality = true
            
            // Reset after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self.shouldReduceQuality = false
            }
        }
    }
}

// MARK: - Accessibility Announcements

/// Helper for making accessibility announcements
struct AccessibilityAnnouncer {
    /// Announces important state changes to screen readers
    static func announce(_ message: String, priority: UIAccessibility.NotificationFeedback = .medium) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Announces page transitions
    static func announcePageChange(to page: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(
                notification: .screenChanged,
                argument: "Navigated to \(page)"
            )
        }
    }
    
    /// Announces loading completion
    static func announceLoadingComplete(itemType: String, count: Int = 1) {
        let message = count == 1 
            ? "Finished loading \(itemType)"
            : "Finished loading \(count) \(itemType)s"
        announce(message)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AccessibleAsyncImage(
            url: URL(string: "https://example.com/image.jpg"),
            placeholder: "photo",
            accessibilityLabel: "Class preview image"
        )
        .frame(width: 200, height: 150)
        .cornerRadius(12)
        
        Text("Accessibility optimized content")
            .loadingAccessibility(
                isLoading: false,
                loadingMessage: "Loading class details",
                loadedMessage: "Class details loaded"
            )
    }
    .padding()
}