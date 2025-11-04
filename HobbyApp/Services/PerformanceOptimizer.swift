import SwiftUI
import Combine

// MARK: - Performance Optimizer for 60fps Animation System

/// Monitors and optimizes animation performance across all device capabilities
@MainActor
public class PerformanceOptimizer: ObservableObject {
    static let shared = PerformanceOptimizer()

    @Published var currentPerformanceLevel: PerformanceLevel = .high
    @Published var frameRate: Double = 60.0
    @Published var isPerformanceOptimized = false
    @Published var animationQuality: AnimationQuality = .full

    private var frameRateMonitor: DisplayLink?
    private var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    private var deviceCapability: DeviceCapability = .unknown

    private init() {
        detectDeviceCapability()
        startPerformanceMonitoring()
        optimizeForDevice()
    }

    // MARK: - Device Capability Detection

    private func detectDeviceCapability() {
        let modelName = UIDevice.current.modelName

        switch modelName {
        case let model where model.contains("iPhone 15") || model.contains("iPhone 14"):
            deviceCapability = .high
        case let model where model.contains("iPhone 13") || model.contains("iPhone 12"):
            deviceCapability = .medium
        case let model where model.contains("iPhone 11") || model.contains("iPhone X"):
            deviceCapability = .medium
        case let model where model.contains("iPhone SE") || model.contains("iPhone 8"):
            deviceCapability = .low
        default:
            deviceCapability = .medium
        }

        // Adjust for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            deviceCapability = deviceCapability == .low ? .medium : .high
        }
    }

    // MARK: - Performance Monitoring

    private func startPerformanceMonitoring() {
        frameRateMonitor = DisplayLink { [weak self] in
            self?.updateFrameRate()
        }
        frameRateMonitor?.start()
    }

    private func updateFrameRate() {
        performanceMetrics.recordFrame()

        let currentFPS = performanceMetrics.averageFrameRate

        DispatchQueue.main.async { [weak self] in
            self?.frameRate = currentFPS
            self?.adjustPerformanceLevel(basedOnFPS: currentFPS)
        }
    }

    private func adjustPerformanceLevel(basedOnFPS fps: Double) {
        let newLevel: PerformanceLevel
        let newQuality: AnimationQuality

        switch fps {
        case 55...:
            newLevel = .high
            newQuality = .full
        case 45..<55:
            newLevel = .medium
            newQuality = .balanced
        case 30..<45:
            newLevel = .low
            newQuality = .reduced
        default:
            newLevel = .minimal
            newQuality = .minimal
        }

        if newLevel != currentPerformanceLevel {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPerformanceLevel = newLevel
                animationQuality = newQuality
            }
        }
    }

    // MARK: - Device-Specific Optimizations

    private func optimizeForDevice() {
        switch deviceCapability {
        case .high:
            currentPerformanceLevel = .high
            animationQuality = .full
        case .medium:
            currentPerformanceLevel = .medium
            animationQuality = .balanced
        case .low:
            currentPerformanceLevel = .low
            animationQuality = .reduced
        case .unknown:
            currentPerformanceLevel = .medium
            animationQuality = .balanced
        }

        isPerformanceOptimized = true
    }

    // MARK: - Animation Configuration

    public func optimizedAnimation(
        _ baseAnimation: Animation,
        priority: AnimationPriority = .normal
    ) -> Animation {
        switch (animationQuality, priority) {
        case (.full, _):
            return baseAnimation
        case (.balanced, .high):
            return baseAnimation
        case (.balanced, .normal):
            return baseAnimation.speed(1.2)
        case (.balanced, .low):
            return baseAnimation.speed(1.5)
        case (.reduced, .high):
            return baseAnimation.speed(1.3)
        case (.reduced, .normal):
            return baseAnimation.speed(1.6)
        case (.reduced, .low):
            return .easeInOut(duration: 0.2)
        case (.minimal, _):
            return .easeInOut(duration: 0.15)
        }
    }

    public func shouldEnableAnimation(_ type: AnimationType) -> Bool {
        switch animationQuality {
        case .full:
            return true
        case .balanced:
            return type != .decorative
        case .reduced:
            return type == .essential || type == .navigation
        case .minimal:
            return type == .essential
        }
    }

    public func optimizedSpringAnimation(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        priority: AnimationPriority = .normal
    ) -> Animation {
        let optimizedResponse: Double
        let optimizedDamping: Double

        switch animationQuality {
        case .full:
            optimizedResponse = response
            optimizedDamping = dampingFraction
        case .balanced:
            optimizedResponse = response * 0.8
            optimizedDamping = min(dampingFraction + 0.1, 1.0)
        case .reduced:
            optimizedResponse = response * 0.6
            optimizedDamping = min(dampingFraction + 0.2, 1.0)
        case .minimal:
            optimizedResponse = 0.3
            optimizedDamping = 0.9
        }

        return .spring(response: optimizedResponse, dampingFraction: optimizedDamping)
    }

    deinit {
        frameRateMonitor?.stop()
    }
}

// MARK: - Performance Configuration Types

public enum PerformanceLevel: String, CaseIterable {
    case high = "High Performance"
    case medium = "Balanced"
    case low = "Power Efficient"
    case minimal = "Minimal"

    var description: String {
        switch self {
        case .high:
            return "Full animations and effects"
        case .medium:
            return "Balanced performance and battery"
        case .low:
            return "Reduced animations for better performance"
        case .minimal:
            return "Essential animations only"
        }
    }
}

public enum AnimationQuality {
    case full
    case balanced
    case reduced
    case minimal
}

public enum AnimationPriority {
    case high      // Navigation, user feedback
    case normal    // Content transitions
    case low       // Decorative, secondary animations
}

public enum AnimationType {
    case essential    // User feedback, loading states
    case navigation   // Screen transitions, tab switches
    case content      // List animations, card reveals
    case decorative   // Background effects, ambient animations
}

enum DeviceCapability {
    case high
    case medium
    case low
    case unknown
}

// MARK: - Performance Metrics

private class PerformanceMetrics {
    private var frameTimes: [CFTimeInterval] = []
    private let maxSamples = 60
    private var lastFrameTime: CFTimeInterval = 0

    var averageFrameRate: Double {
        guard frameTimes.count > 10 else { return 60.0 }

        let totalTime = frameTimes.reduce(0, +)
        let averageFrameTime = totalTime / Double(frameTimes.count)

        return averageFrameTime > 0 ? 1.0 / averageFrameTime : 60.0
    }

    func recordFrame() {
        let currentTime = CACurrentMediaTime()

        if lastFrameTime > 0 {
            let frameTime = currentTime - lastFrameTime
            frameTimes.append(frameTime)

            if frameTimes.count > maxSamples {
                frameTimes.removeFirst()
            }
        }

        lastFrameTime = currentTime
    }
}

// MARK: - Display Link for Frame Rate Monitoring

private class DisplayLink {
    private var displayLink: CADisplayLink?
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(frame))
        displayLink?.add(to: .main, forMode: .default)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func frame() {
        callback()
    }
}

// MARK: - Device Extension

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
}

// MARK: - Optimized Animation View Modifiers

public struct OptimizedAnimationModifier: ViewModifier {
    let animation: Animation
    let type: AnimationType
    let priority: AnimationPriority

    @StateObject private var optimizer = PerformanceOptimizer.shared

    public func body(content: Content) -> some View {
        content
            .animation(
                optimizer.shouldEnableAnimation(type)
                    ? optimizer.optimizedAnimation(animation, priority: priority)
                    : nil,
                value: optimizer.animationQuality
            )
    }
}

public struct OptimizedSpringModifier: ViewModifier {
    let response: Double
    let dampingFraction: Double
    let priority: AnimationPriority
    let type: AnimationType

    @StateObject private var optimizer = PerformanceOptimizer.shared

    public func body(content: Content) -> some View {
        content
            .animation(
                optimizer.shouldEnableAnimation(type)
                    ? optimizer.optimizedSpringAnimation(
                        response: response,
                        dampingFraction: dampingFraction,
                        priority: priority
                    )
                    : nil,
                value: optimizer.animationQuality
            )
    }
}

// MARK: - Performance-Aware View Extensions

public extension View {
    func optimizedAnimation(
        _ animation: Animation,
        type: AnimationType = .content,
        priority: AnimationPriority = .normal
    ) -> some View {
        modifier(OptimizedAnimationModifier(
            animation: animation,
            type: type,
            priority: priority
        ))
    }

    func optimizedSpring(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        type: AnimationType = .content,
        priority: AnimationPriority = .normal
    ) -> some View {
        modifier(OptimizedSpringModifier(
            response: response,
            dampingFraction: dampingFraction,
            priority: priority,
            type: type
        ))
    }

    func performanceOptimized() -> some View {
        self.onAppear {
            _ = PerformanceOptimizer.shared
        }
    }
}

// MARK: - Performance Dashboard (Debug)

public struct PerformanceDebugView: View {
    @StateObject private var optimizer = PerformanceOptimizer.shared

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Monitor")
                .font(BrandConstants.Typography.headline)

            HStack {
                Text("FPS:")
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                Text("\(optimizer.frameRate, specifier: "%.1f")")
                    .fontWeight(.semibold)
                    .foregroundColor(fpsColor)
            }

            HStack {
                Text("Level:")
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                Text(optimizer.currentPerformanceLevel.rawValue)
                    .fontWeight(.medium)
            }

            HStack {
                Text("Quality:")
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                Text(qualityDescription)
                    .fontWeight(.medium)
            }

            Text(optimizer.currentPerformanceLevel.description)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(BrandConstants.Colors.secondaryText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(BrandConstants.CornerRadius.md)
    }

    private var fpsColor: Color {
        switch optimizer.frameRate {
        case 55...:
            return .green
        case 45..<55:
            return .orange
        default:
            return .red
        }
    }

    private var qualityDescription: String {
        switch optimizer.animationQuality {
        case .full:
            return "Full"
        case .balanced:
            return "Balanced"
        case .reduced:
            return "Reduced"
        case .minimal:
            return "Minimal"
        }
    }
}

// MARK: - Preview

#Preview("Performance Optimizer") {
    VStack(spacing: 20) {
        PerformanceDebugView()

        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(BrandConstants.Colors.primary.opacity(0.3))
                    .frame(height: 60)
                    .scaleEffect(1.0)
                    .optimizedSpring(
                        response: 0.6,
                        dampingFraction: 0.7,
                        type: .content,
                        priority: .normal
                    )
            }
        }
        .padding()
    }
    .performanceOptimized()
}