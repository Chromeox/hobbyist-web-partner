import SwiftUI

/// Welcome landing page with branding, hero illustration, and call-to-action
struct WelcomeLandingView: View {
    @State private var showContent = false
    @State private var heroOffset: CGFloat = 0
    @State private var showFeatures = false

    let onGetStarted: () -> Void
    let onContinueAsGuest: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            BrandConstants.Gradients.landing
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Hero Section
                    VStack(spacing: 32) {
                        // Hero Illustration with floating animation
                        Image("HeroIllustration")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 320)
                            .cornerRadius(BrandConstants.CornerRadius.xl)
                            .shadow(
                                color: BrandConstants.Shadow.lg.color,
                                radius: BrandConstants.Shadow.lg.radius,
                                x: 0,
                                y: BrandConstants.Shadow.lg.y
                            )
                            .offset(y: heroOffset)
                            .onAppear {
                                // Gentle floating animation
                                withAnimation(
                                    Animation.easeInOut(duration: 2.5)
                                        .repeatForever(autoreverses: true)
                                ) {
                                    heroOffset = -8
                                }
                            }

                        // Speech Bubbles
                        HStack(spacing: 40) {
                            SpeechBubble("Let's create!", alignment: .leading)

                            Spacer()

                            SpeechBubble("Let's go!", alignment: .trailing)
                        }
                        .padding(.horizontal, 40)
                        .offset(y: -20)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(BrandConstants.Animation.standard.delay(0.2), value: showContent)

                    Spacer(minLength: 40)

                    // Content Card
                    GlassmorphicCard {
                        VStack(spacing: 24) {
                            // Title and description
                            VStack(spacing: 16) {
                                Text("Start Creating Now 🚀")
                                    .font(BrandConstants.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)

                                Text("Discover Vancouver's most creative hobby classes and connect with a community of passionate learners.")
                                    .font(BrandConstants.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Action buttons
                            VStack(spacing: 12) {
                                BrandedButton("Get Started", icon: "arrow.right.circle.fill") {
                                    withAnimation(BrandConstants.Animation.spring) {
                                        onGetStarted()
                                    }
                                }

                                OutlineButton("Learn More", icon: "info.circle") {
                                    withAnimation(BrandConstants.Animation.spring) {
                                        showFeatures = true
                                    }
                                }

                                TextButton("Continue as Guest") {
                                    withAnimation(BrandConstants.Animation.spring) {
                                        onContinueAsGuest()
                                    }
                                }
                            }
                        }
                        .padding(BrandConstants.Spacing.xl)
                    }
                    .padding(.horizontal, BrandConstants.Spacing.md)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(BrandConstants.Animation.standard.delay(0.4), value: showContent)

                    Spacer(minLength: 40)
                }
            }

            // Features modal (bottom sheet)
            if showFeatures {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(BrandConstants.Animation.standard) {
                            showFeatures = false
                        }
                    }
                    .transition(.opacity)

                FeaturesModalView(isPresented: $showFeatures)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Trigger entrance animation
            withAnimation(BrandConstants.Animation.standard) {
                showContent = true
            }
        }
    }
}

// MARK: - Features Modal

struct FeaturesModalView: View {
    @Binding var isPresented: Bool

    private let features = [
        Feature(
            icon: "paintpalette.fill",
            title: "12+ Creative Categories",
            description: "Pottery, cooking, painting, photography, and more",
            color: BrandConstants.Colors.Category.ceramics
        ),
        Feature(
            icon: "creditcard.fill",
            title: "Smart Credit System",
            description: "Save money with bonus credits on larger packs",
            color: BrandConstants.Colors.teal
        ),
        Feature(
            icon: "star.fill",
            title: "Earn Achievements",
            description: "Track progress and unlock badges as you learn",
            color: BrandConstants.Colors.coral
        ),
        Feature(
            icon: "person.2.fill",
            title: "Join the Community",
            description: "Follow instructors and discover classes with friends",
            color: BrandConstants.Colors.primary
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Handle bar
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                // Title
                Text("Why HobbyApp?")
                    .font(BrandConstants.Typography.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                // Features list
                VStack(spacing: 20) {
                    ForEach(features) { feature in
                        FeatureRow(feature: feature)
                    }
                }
                .padding(.vertical)

                // Close button
                BrandedButton("Got It!", icon: "checkmark.circle.fill") {
                    withAnimation(BrandConstants.Animation.spring) {
                        isPresented = false
                    }
                }
                .padding(.bottom, BrandConstants.Spacing.lg)
            }
            .padding(.horizontal, BrandConstants.Spacing.xl)
            .padding(.bottom, BrandConstants.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.xl)
                    .fill(Color(.systemBackground))
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Feature Model & Row

struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct FeatureRow: View {
    let feature: Feature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: feature.icon)
                    .font(BrandConstants.Typography.title)
                    .foregroundColor(feature.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)

                Text(feature.description)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeLandingView(
        onGetStarted: { print("Get Started tapped") },
        onContinueAsGuest: { print("Guest mode") }
    )
}
