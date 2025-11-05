import SwiftUI

/// Primary branded loading view for the HobbyApp
/// Provides engaging animations with Vancouver creative community themes
struct BrandedLoadingView: View {
    let message: String
    let showLogo: Bool
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var messageOpacity: Double = 0
    @State private var floatingOffset: CGFloat = 0
    
    init(message: String = "Loading your creative journey...", showLogo: Bool = true) {
        self.message = message
        self.showLogo = showLogo
    }
    
    var body: some View {
        ZStack {
            // Brand gradient background
            BrandConstants.Gradients.landing
                .ignoresSafeArea()
            
            VStack(spacing: BrandConstants.Spacing.xl) {
                if showLogo {
                    // Animated logo with pulse effect
                    ZStack {
                        // Pulse background
                        Circle()
                            .fill(BrandConstants.Colors.surface.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseScale)
                            .animation(
                                Animation.easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                        
                        // Logo background
                        Circle()
                            .fill(LinearGradient(
                                colors: [
                                    BrandConstants.Colors.surface.opacity(0.3),
                                    BrandConstants.Colors.surface.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .scaleEffect(logoScale)
                        
                        // App logo with gentle rotation
                        Image(systemName: "figure.yoga")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .scaleEffect(logoScale)
                            .rotationEffect(.degrees(logoRotation))
                        
                        // Floating creative elements
                        FloatingCreativeElements()
                    }
                    .offset(y: floatingOffset)
                }
                
                // Loading message
                VStack(spacing: BrandConstants.Spacing.sm) {
                    Text(message)
                        .font(BrandConstants.Typography.headline)
                        .foregroundColor(BrandConstants.Colors.surface)
                        .multilineTextAlignment(.center)
                        .opacity(messageOpacity)
                    
                    // Animated dots
                    AnimatedLoadingDots()
                        .opacity(messageOpacity)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
        .focusOnAppear()
    }
    
    private func startAnimations() {
        // Logo scale animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
        
        // Message fade in
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            messageOpacity = 1.0
        }
        
        // Gentle floating animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(0.5)) {
            floatingOffset = -8
        }
        
        // Subtle rotation
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false).delay(1.0)) {
            logoRotation = 360
        }
    }
}

/// Floating creative elements around the logo
private struct FloatingCreativeElements: View {
    @State private var paintBrushOffset: CGSize = .zero
    @State private var paletteOffset: CGSize = .zero
    @State private var cameraOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Paint brush
            Image(systemName: "paintbrush.fill")
                .foregroundColor(BrandConstants.Colors.surface.opacity(0.4))
                .font(.title2)
                .offset(x: -80 + paintBrushOffset.width, y: -60 + paintBrushOffset.height)
            
            // Palette
            Image(systemName: "paintpalette.fill")
                .foregroundColor(BrandConstants.Colors.surface.opacity(0.4))
                .font(.title2)
                .offset(x: 70 + paletteOffset.width, y: -80 + paletteOffset.height)
            
            // Camera
            Image(systemName: "camera.fill")
                .foregroundColor(BrandConstants.Colors.surface.opacity(0.4))
                .font(.title2)
                .offset(x: 0 + cameraOffset.width, y: 90 + cameraOffset.height)
        }
        .onAppear {
            startFloatingAnimations()
        }
    }
    
    private func startFloatingAnimations() {
        // Paint brush floating
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(0.5)) {
            paintBrushOffset = CGSize(width: 10, height: 15)
        }
        
        // Palette floating
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.0)) {
            paletteOffset = CGSize(width: -8, height: 12)
        }
        
        // Camera floating
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true).delay(0.2)) {
            cameraOffset = CGSize(width: 12, height: -10)
        }
    }
}

/// Animated loading dots
private struct AnimatedLoadingDots: View {
    @State private var dot1Scale: CGFloat = 1.0
    @State private var dot2Scale: CGFloat = 1.0
    @State private var dot3Scale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: BrandConstants.Spacing.sm) {
            Circle()
                .fill(BrandConstants.Colors.surface)
                .frame(width: 8, height: 8)
                .scaleEffect(dot1Scale)
            
            Circle()
                .fill(BrandConstants.Colors.surface)
                .frame(width: 8, height: 8)
                .scaleEffect(dot2Scale)
            
            Circle()
                .fill(BrandConstants.Colors.surface)
                .frame(width: 8, height: 8)
                .scaleEffect(dot3Scale)
        }
        .onAppear {
            startDotAnimations()
        }
    }
    
    private func startDotAnimations() {
        // Staggered dot animations
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            dot1Scale = 1.5
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2)) {
            dot2Scale = 1.5
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
            dot3Scale = 1.5
        }
    }
}

/// Compact loading indicator for smaller spaces
struct CompactLoadingView: View {
    let message: String?
    
    @State private var rotation: Double = 0
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            // Spinning gradient ring
            ZStack {
                Circle()
                    .stroke(BrandConstants.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [BrandConstants.Colors.primary, BrandConstants.Colors.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
            }
            
            if let message = message {
                Text(message)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

/// Loading overlay for existing content
struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String
    
    init(isLoading: Bool, message: String = "Loading...") {
        self.isLoading = isLoading
        self.message = message
    }
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: BrandConstants.Spacing.md) {
                    CompactLoadingView()
                    
                    Text(message)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(BrandConstants.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                        .fill(Color.black.opacity(0.8))
                )
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Previews
#Preview("Branded Loading") {
    BrandedLoadingView(message: "Welcome to Vancouver's creative community!")
}

#Preview("Compact Loading") {
    VStack(spacing: 40) {
        CompactLoadingView(message: "Syncing classes...")
        CompactLoadingView()
    }
    .padding()
}

#Preview("Loading Overlay") {
    ZStack {
        Color.blue.ignoresSafeArea()
        
        LoadingOverlay(isLoading: true, message: "Booking your class...")
    }
}