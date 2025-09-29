import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 0.8
    @State private var fadeOpacity: Double = 0.6

    var body: some View {
        ZStack {
            // Background gradient matching welcome screen
            LinearGradient(
                colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: HobbyistSpacing.xl) {
                // Pulsing logo container
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale * 1.2)
                        .opacity(fadeOpacity)

                    // Main logo background
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .green.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)

                    // App icon
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .scaleEffect(pulseScale)
                }

                // App title and loading text
                VStack(spacing: HobbyistSpacing.sm) {
                    Text("Hobbyist")
                        .font(.hobbyistTitle(28))
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))

                    Text("Loading Vancouver's creative classes...")
                        .font(.hobbyistBody())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(fadeOpacity)
                }

                // Loading indicator
                HStack(spacing: HobbyistSpacing.xs) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.top, HobbyistSpacing.md)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Start loading dots animation
        isAnimating = true

        // Main pulsing animation
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.2
            fadeOpacity = 1.0
        }

        // Subtle secondary pulse for the outer ring
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
            .delay(0.3)
        ) {
            fadeOpacity = 0.3
        }
    }
}

// MARK: - Preview

#Preview {
    LoadingView()
}