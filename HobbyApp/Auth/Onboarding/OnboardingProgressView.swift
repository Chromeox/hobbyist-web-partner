import SwiftUI

/// Enhanced onboarding progress view with encouraging animations
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    @State private var animatedProgress: Double = 0
    @State private var celebrationScale: CGFloat = 1.0
    
    private var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStep) / Double(totalSteps - 1)
    }
    
    private var encouragementText: String {
        switch currentStep {
        case 0:
            return "Let's get started! ✨"
        case 1:
            return "Getting to know you... 👋"
        case 2:
            return "Great! Tell us more 📝"
        case 3:
            return "Almost there! 🚀"
        case 4:
            return "What interests you? 🎨"
        case 5:
            return "Stay connected! 📱"
        case totalSteps - 1:
            return "You're all set! 🎉"
        default:
            return "Looking good! 👍"
        }
    }
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            // Progress bar
            VStack(spacing: BrandConstants.Spacing.sm) {
                HStack {
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandConstants.Colors.surface)
                }
                
                // Animated progress bar
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(BrandConstants.Colors.surface.opacity(0.2))
                        .frame(height: 6)
                    
                    // Progress fill with gradient
                    Capsule()
                        .fill(LinearGradient(
                            colors: [BrandConstants.Colors.surface, BrandConstants.Colors.surface.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, CGFloat(animatedProgress) * UIScreen.main.bounds.width * 0.8), height: 6)
                        .animation(.easeInOut(duration: 0.6), value: animatedProgress)
                }
            }
            
            // Encouragement text with celebration animation
            Text(encouragementText)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(BrandConstants.Colors.surface)
                .scaleEffect(celebrationScale)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, BrandConstants.Spacing.xl)
        .padding(.vertical, BrandConstants.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                .fill(BrandConstants.Colors.surface.opacity(0.1))
        )
        .onChange(of: currentStep) { _, newStep in
            // Animate progress bar
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedProgress = progress
            }
            
            // Celebration animation for milestone steps
            if newStep > 0 && newStep % 2 == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    celebrationScale = 1.15
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        celebrationScale = 1.0
                    }
                }
            }
        }
        .onAppear {
            // Initial animation
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}

/// Navigation controls for onboarding with smart button states
struct OnboardingNavigationView: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var nextButtonPulse: CGFloat = 1.0
    
    private var isFirstStep: Bool {
        currentStep == 0
    }
    
    private var isLastStep: Bool {
        currentStep == totalSteps - 1
    }
    
    private var nextButtonTitle: String {
        if isLastStep {
            return "Complete! 🎉"
        } else if currentStep == 1 {
            return "Continue"
        } else {
            return "Next"
        }
    }
    
    private var showSkipButton: Bool {
        // Show skip button for optional steps (demographics, interests)
        currentStep == 1 || currentStep == 4
    }
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            // Main navigation buttons
            HStack(spacing: BrandConstants.Spacing.md) {
                // Back button
                if !isFirstStep {
                    Button(action: onBack) {
                        HStack(spacing: BrandConstants.Spacing.sm) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BrandConstants.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                                .stroke(BrandConstants.Colors.surface.opacity(0.5), lineWidth: 1)
                        )
                    }
                } else {
                    // Empty space to keep next button centered
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                
                // Next/Continue button
                Button(action: onNext) {
                    HStack(spacing: BrandConstants.Spacing.sm) {
                        Text(nextButtonTitle)
                        
                        if !isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BrandConstants.Colors.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BrandConstants.Spacing.md)
                    .background(BrandConstants.Colors.surface)
                    .cornerRadius(BrandConstants.CornerRadius.lg)
                    .scaleEffect(nextButtonPulse)
                    .shadow(color: BrandConstants.Colors.surface.opacity(0.3), radius: 4, y: 2)
                }
            }
            
            // Skip button for optional steps
            if showSkipButton {
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.surface.opacity(0.7))
                        .underline()
                }
                .padding(.top, BrandConstants.Spacing.xs)
            }
        }
        .padding(.horizontal, BrandConstants.Spacing.xl)
        .padding(.bottom, BrandConstants.Spacing.xl)
        .onChange(of: isLastStep) { _, isLast in
            if isLast {
                // Pulse animation for completion button
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    nextButtonPulse = 1.05
                }
            } else {
                nextButtonPulse = 1.0
            }
        }
    }
}

// MARK: - Previews
#Preview("Progress View") {
    ZStack {
        BrandConstants.Gradients.landing
            .ignoresSafeArea()
        
        VStack {
            OnboardingProgressView(currentStep: 3, totalSteps: 7)
            
            Spacer()
            
            OnboardingNavigationView(
                currentStep: 3,
                totalSteps: 7,
                onBack: {},
                onNext: {},
                onSkip: {}
            )
        }
    }
}