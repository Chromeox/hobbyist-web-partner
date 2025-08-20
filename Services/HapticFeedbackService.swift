import UIKit
import CoreHaptics
import AVFoundation

// MARK: - Haptic Feedback Service Protocol
protocol HapticFeedbackServiceProtocol {
    // Authentication Haptics
    func playLoginSuccess()
    func playLoginFailure()
    func playFormValidationError()
    func playFormFieldFocus()
    func playPasswordStrengthChange(strength: PasswordStrength)
    
    // Sign Up Haptics
    func playAccountCreationStep(step: Int, totalSteps: Int)
    func playEmailValidation(isValid: Bool)
    func playUsernameAvailable()
    func playUsernameUnavailable()
    func playSignUpSuccess()
    
    // Onboarding Haptics
    func playOnboardingProgress(progress: Float)
    func playOnboardingMilestone(milestone: OnboardingMilestone)
    func playOnboardingComplete()
    func playFeatureHighlight()
    
    // Core Haptics Patterns
    func playCustomPattern(_ pattern: HapticPattern)
    func prepareHaptics()
}

// MARK: - Supporting Types
enum PasswordStrength: Int {
    case veryWeak = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
}

enum OnboardingMilestone {
    case profileCreated
    case preferencesSet
    case firstClassViewed
    case notificationsEnabled
    case paymentAdded
}

struct HapticPattern {
    let events: [CHHapticEvent]
    let duration: TimeInterval
}

// MARK: - Haptic Feedback Service Implementation
class HapticFeedbackService: HapticFeedbackServiceProtocol {
    
    // MARK: - Properties
    private var hapticEngine: CHHapticEngine?
    private let impactFeedback = UIImpactFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Singleton
    static let shared = HapticFeedbackService()
    
    // MARK: - Initialization
    private init() {
        setupHapticEngine()
        prepareHaptics()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
            // Handle engine stopped
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                self?.setupHapticEngine()
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    func prepareHaptics() {
        impactFeedback.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Authentication Haptics
    
    func playLoginSuccess() {
        // Multi-stage success pattern: gentle build-up to celebration
        let pattern = createMultiStagePattern([
            // Stage 1: Subtle acknowledgment
            (intensity: 0.3, sharpness: 0.2, delay: 0.0),
            // Stage 2: Growing confirmation
            (intensity: 0.5, sharpness: 0.4, delay: 0.1),
            // Stage 3: Success celebration
            (intensity: 0.8, sharpness: 0.7, delay: 0.2),
            // Stage 4: Gentle fadeout
            (intensity: 0.4, sharpness: 0.3, delay: 0.35)
        ])
        
        playCustomPattern(pattern)
        notificationFeedback.notificationOccurred(.success)
        
        // Optional: Coordinate with sound
        playSystemSound("payment_success")
    }
    
    func playLoginFailure() {
        // Sharp, distinct error pattern with warning emphasis
        let pattern = createMultiStagePattern([
            // Stage 1: Sharp attention getter
            (intensity: 0.9, sharpness: 0.9, delay: 0.0),
            // Stage 2: Error emphasis
            (intensity: 0.7, sharpness: 0.8, delay: 0.1),
            // Stage 3: Final warning tap
            (intensity: 0.5, sharpness: 0.6, delay: 0.25)
        ])
        
        playCustomPattern(pattern)
        notificationFeedback.notificationOccurred(.error)
        
        // Coordinate with visual shake animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactFeedback.impactOccurred(intensity: 0.8)
        }
    }
    
    func playFormValidationError() {
        // Quick double-tap pattern for validation errors
        impactFeedback.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.impactFeedback.impactOccurred(intensity: 0.4)
        }
    }
    
    func playFormFieldFocus() {
        // Subtle selection feedback for field focus
        selectionFeedback.selectionChanged()
        
        // Add gentle continuous haptic for active field
        let pattern = createContinuousPattern(
            intensity: 0.15,
            sharpness: 0.1,
            duration: 0.2
        )
        playCustomPattern(pattern)
    }
    
    func playPasswordStrengthChange(strength: PasswordStrength) {
        // Progressive haptic intensity based on password strength
        let intensityMap: [PasswordStrength: (intensity: Float, sharpness: Float)] = [
            .veryWeak: (0.2, 0.1),
            .weak: (0.35, 0.25),
            .medium: (0.5, 0.4),
            .strong: (0.7, 0.6),
            .veryStrong: (0.9, 0.8)
        ]
        
        guard let config = intensityMap[strength] else { return }
        
        // Create ascending pattern for stronger passwords
        if strength.rawValue >= PasswordStrength.medium.rawValue {
            let pattern = createAscendingPattern(
                startIntensity: 0.2,
                endIntensity: config.intensity,
                sharpness: config.sharpness,
                steps: strength.rawValue + 1
            )
            playCustomPattern(pattern)
        } else {
            // Simple tap for weak passwords
            impactFeedback.impactOccurred(intensity: CGFloat(config.intensity))
        }
        
        // Add selection feedback for any change
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Sign Up Haptics
    
    func playAccountCreationStep(step: Int, totalSteps: Int) {
        // Progressive intensity as user advances through signup
        let progress = Float(step) / Float(totalSteps)
        let intensity = 0.3 + (progress * 0.5) // Range: 0.3 to 0.8
        
        // Create step pattern with increasing confidence
        let pattern = createMultiStagePattern([
            (intensity: intensity * 0.7, sharpness: 0.3, delay: 0.0),
            (intensity: intensity, sharpness: 0.5, delay: 0.1)
        ])
        
        playCustomPattern(pattern)
        
        // Add selection feedback for step transition
        selectionFeedback.selectionChanged()
    }
    
    func playEmailValidation(isValid: Bool) {
        if isValid {
            // Positive validation: gentle confirmation
            let pattern = createMultiStagePattern([
                (intensity: 0.3, sharpness: 0.4, delay: 0.0),
                (intensity: 0.5, sharpness: 0.6, delay: 0.08)
            ])
            playCustomPattern(pattern)
            impactFeedback.impactOccurred(intensity: 0.5)
        } else {
            // Invalid email: subtle warning
            impactFeedback.impactOccurred(intensity: 0.3)
        }
    }
    
    func playUsernameAvailable() {
        // Success pattern: username is available
        let pattern = createCelebrationPattern(intensity: 0.6)
        playCustomPattern(pattern)
        notificationFeedback.notificationOccurred(.success)
    }
    
    func playUsernameUnavailable() {
        // Gentle warning: username taken
        impactFeedback.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactFeedback.impactOccurred(intensity: 0.3)
        }
    }
    
    func playSignUpSuccess() {
        // Grand success pattern for account creation
        let pattern = createMultiStagePattern([
            // Build-up
            (intensity: 0.2, sharpness: 0.2, delay: 0.0),
            (intensity: 0.4, sharpness: 0.3, delay: 0.1),
            (intensity: 0.6, sharpness: 0.5, delay: 0.2),
            // Celebration
            (intensity: 0.9, sharpness: 0.8, delay: 0.3),
            (intensity: 0.7, sharpness: 0.6, delay: 0.4),
            // Completion
            (intensity: 0.5, sharpness: 0.4, delay: 0.5),
            (intensity: 0.3, sharpness: 0.2, delay: 0.6)
        ])
        
        playCustomPattern(pattern)
        notificationFeedback.notificationOccurred(.success)
        
        // Coordinate with confetti animation
        playSystemSound("celebration")
    }
    
    // MARK: - Onboarding Haptics
    
    func playOnboardingProgress(progress: Float) {
        // Subtle progress indication
        let intensity = 0.2 + (progress * 0.3) // Range: 0.2 to 0.5
        
        let pattern = createProgressPattern(
            progress: progress,
            baseIntensity: intensity
        )
        playCustomPattern(pattern)
        
        // Add milestone feedback at 25%, 50%, 75%
        let milestoneProgress = Int(progress * 100)
        if [25, 50, 75].contains(milestoneProgress) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.impactFeedback.impactOccurred(intensity: CGFloat(intensity * 1.5))
            }
        }
    }
    
    func playOnboardingMilestone(milestone: OnboardingMilestone) {
        // Different patterns for different milestones
        switch milestone {
        case .profileCreated:
            // Gentle success
            let pattern = createMultiStagePattern([
                (intensity: 0.4, sharpness: 0.3, delay: 0.0),
                (intensity: 0.6, sharpness: 0.5, delay: 0.1)
            ])
            playCustomPattern(pattern)
            
        case .preferencesSet:
            // Selection confirmation
            selectionFeedback.selectionChanged()
            impactFeedback.impactOccurred(intensity: 0.5)
            
        case .firstClassViewed:
            // Discovery celebration
            let pattern = createCelebrationPattern(intensity: 0.7)
            playCustomPattern(pattern)
            
        case .notificationsEnabled:
            // Permission granted success
            notificationFeedback.notificationOccurred(.success)
            
        case .paymentAdded:
            // Secure confirmation
            let pattern = createMultiStagePattern([
                (intensity: 0.5, sharpness: 0.6, delay: 0.0),
                (intensity: 0.7, sharpness: 0.8, delay: 0.1),
                (intensity: 0.4, sharpness: 0.5, delay: 0.2)
            ])
            playCustomPattern(pattern)
        }
    }
    
    func playOnboardingComplete() {
        // Grand finale pattern
        let pattern = createGrandFinalePattern()
        playCustomPattern(pattern)
        
        // Add notification success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.notificationFeedback.notificationOccurred(.success)
        }
        
        // Coordinate with completion animation
        playSystemSound("onboarding_complete")
    }
    
    func playFeatureHighlight() {
        // Attention-drawing pattern for feature discovery
        let pattern = createAttentionPattern()
        playCustomPattern(pattern)
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Custom Pattern Playback
    
    func playCustomPattern(_ pattern: HapticPattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            // Fallback to UIKit haptics
            impactFeedback.impactOccurred()
            return
        }
        
        do {
            let player = try engine.makePlayer(with: pattern.events)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play custom haptic pattern: \(error)")
            // Fallback to UIKit haptics
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Pattern Creation Helpers
    
    private func createMultiStagePattern(_ stages: [(intensity: Float, sharpness: Float, delay: TimeInterval)]) -> HapticPattern {
        var events: [CHHapticEvent] = []
        
        for stage in stages {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: stage.intensity
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: stage.sharpness
            )
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: stage.delay
            )
            events.append(event)
        }
        
        let duration = stages.last?.delay ?? 0.0 + 0.1
        return HapticPattern(events: events, duration: duration)
    }
    
    private func createContinuousPattern(intensity: Float, sharpness: Float, duration: TimeInterval) -> HapticPattern {
        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: intensity
        )
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: sharpness
        )
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )
        
        return HapticPattern(events: [event], duration: duration)
    }
    
    private func createAscendingPattern(startIntensity: Float, endIntensity: Float, sharpness: Float, steps: Int) -> HapticPattern {
        var events: [CHHapticEvent] = []
        let stepDuration = 0.05
        
        for i in 0..<steps {
            let progress = Float(i) / Float(steps - 1)
            let intensity = startIntensity + (endIntensity - startIntensity) * progress
            
            let intensityParam = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: intensity
            )
            let sharpnessParam = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: sharpness * (0.5 + progress * 0.5)
            )
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: Double(i) * stepDuration
            )
            events.append(event)
        }
        
        return HapticPattern(events: events, duration: Double(steps) * stepDuration)
    }
    
    private func createCelebrationPattern(intensity: Float) -> HapticPattern {
        return createMultiStagePattern([
            (intensity: intensity * 0.5, sharpness: 0.4, delay: 0.0),
            (intensity: intensity * 0.7, sharpness: 0.6, delay: 0.05),
            (intensity: intensity, sharpness: 0.8, delay: 0.1),
            (intensity: intensity * 0.8, sharpness: 0.6, delay: 0.15),
            (intensity: intensity * 0.6, sharpness: 0.4, delay: 0.2)
        ])
    }
    
    private func createProgressPattern(progress: Float, baseIntensity: Float) -> HapticPattern {
        let tapCount = Int(progress * 10) % 3 + 1 // 1-3 taps based on progress
        var events: [CHHapticEvent] = []
        
        for i in 0..<tapCount {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: baseIntensity
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.3
            )
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.08
            )
            events.append(event)
        }
        
        return HapticPattern(events: events, duration: Double(tapCount) * 0.08)
    }
    
    private func createGrandFinalePattern() -> HapticPattern {
        return createMultiStagePattern([
            // Build-up phase
            (intensity: 0.2, sharpness: 0.2, delay: 0.0),
            (intensity: 0.3, sharpness: 0.3, delay: 0.1),
            (intensity: 0.4, sharpness: 0.4, delay: 0.2),
            (intensity: 0.5, sharpness: 0.5, delay: 0.3),
            // Climax
            (intensity: 0.9, sharpness: 0.9, delay: 0.4),
            (intensity: 0.8, sharpness: 0.8, delay: 0.5),
            (intensity: 0.9, sharpness: 0.9, delay: 0.6),
            // Resolution
            (intensity: 0.6, sharpness: 0.5, delay: 0.7),
            (intensity: 0.4, sharpness: 0.3, delay: 0.8),
            (intensity: 0.2, sharpness: 0.2, delay: 0.9)
        ])
    }
    
    private func createAttentionPattern() -> HapticPattern {
        return createMultiStagePattern([
            (intensity: 0.7, sharpness: 0.8, delay: 0.0),
            (intensity: 0.5, sharpness: 0.6, delay: 0.05),
            (intensity: 0.7, sharpness: 0.8, delay: 0.1)
        ])
    }
    
    // MARK: - Sound Coordination
    
    private func playSystemSound(_ soundName: String) {
        // This would coordinate with your audio service
        // For now, using system sounds as placeholder
        switch soundName {
        case "payment_success":
            AudioServicesPlaySystemSound(1519) // Purchased
        case "celebration":
            AudioServicesPlaySystemSound(1522) // Bloom
        case "onboarding_complete":
            AudioServicesPlaySystemSound(1521) // Calypso
        default:
            break
        }
    }
}

// MARK: - Mock Implementation for Testing
class MockHapticFeedbackService: HapticFeedbackServiceProtocol {
    
    var hapticEvents: [String] = []
    var lastPattern: HapticPattern?
    var prepareHapticsCallCount = 0
    
    func playLoginSuccess() {
        hapticEvents.append("loginSuccess")
    }
    
    func playLoginFailure() {
        hapticEvents.append("loginFailure")
    }
    
    func playFormValidationError() {
        hapticEvents.append("formValidationError")
    }
    
    func playFormFieldFocus() {
        hapticEvents.append("formFieldFocus")
    }
    
    func playPasswordStrengthChange(strength: PasswordStrength) {
        hapticEvents.append("passwordStrength:\(strength)")
    }
    
    func playAccountCreationStep(step: Int, totalSteps: Int) {
        hapticEvents.append("accountStep:\(step)/\(totalSteps)")
    }
    
    func playEmailValidation(isValid: Bool) {
        hapticEvents.append("emailValidation:\(isValid)")
    }
    
    func playUsernameAvailable() {
        hapticEvents.append("usernameAvailable")
    }
    
    func playUsernameUnavailable() {
        hapticEvents.append("usernameUnavailable")
    }
    
    func playSignUpSuccess() {
        hapticEvents.append("signUpSuccess")
    }
    
    func playOnboardingProgress(progress: Float) {
        hapticEvents.append("onboardingProgress:\(progress)")
    }
    
    func playOnboardingMilestone(milestone: OnboardingMilestone) {
        hapticEvents.append("onboardingMilestone:\(milestone)")
    }
    
    func playOnboardingComplete() {
        hapticEvents.append("onboardingComplete")
    }
    
    func playFeatureHighlight() {
        hapticEvents.append("featureHighlight")
    }
    
    func playCustomPattern(_ pattern: HapticPattern) {
        lastPattern = pattern
        hapticEvents.append("customPattern")
    }
    
    func prepareHaptics() {
        prepareHapticsCallCount += 1
    }
    
    func reset() {
        hapticEvents.removeAll()
        lastPattern = nil
        prepareHapticsCallCount = 0
    }
}