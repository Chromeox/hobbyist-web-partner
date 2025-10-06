import SwiftUI

/// Frosted glass-effect card component for modern UI
struct GlassmorphicCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let opacity: Double

    init(
        cornerRadius: CGFloat = BrandConstants.CornerRadius.xl,
        opacity: Double = 0.95,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.opacity = opacity
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemBackground).opacity(opacity))
                    .shadow(
                        color: BrandConstants.Shadow.lg.color,
                        radius: BrandConstants.Shadow.lg.radius,
                        x: BrandConstants.Shadow.lg.x,
                        y: BrandConstants.Shadow.lg.y
                    )
            )
    }
}

/// Speech bubble component for playful UI elements
struct SpeechBubble: View {
    let text: String
    let alignment: Alignment

    init(_ text: String, alignment: Alignment = .leading) {
        self.text = text
        self.alignment = alignment
    }

    var body: some View {
        Text(text)
            .font(BrandConstants.Typography.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                // Tail triangle
                Triangle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(alignment == .leading ? -45 : 135))
                    .offset(
                        x: alignment == .leading ? -16 : 16,
                        y: 12
                    ),
                alignment: alignment == .leading ? .bottomLeading : .bottomTrailing
            )
    }
}

/// Triangle shape for speech bubble tail
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        BrandConstants.Gradients.landing
            .ignoresSafeArea()

        VStack(spacing: 32) {
            GlassmorphicCard {
                VStack(spacing: 16) {
                    Text("Glassmorphic Card")
                        .font(BrandConstants.Typography.title)
                        .fontWeight(.bold)

                    Text("This card has a frosted glass effect with subtle shadows.")
                        .font(BrandConstants.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(BrandConstants.Spacing.lg)
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                SpeechBubble("Let's create!", alignment: .leading)
                SpeechBubble("Let's go!", alignment: .trailing)
            }
        }
    }
}
