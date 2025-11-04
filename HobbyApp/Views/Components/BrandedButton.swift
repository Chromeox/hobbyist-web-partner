import SwiftUI

/// Primary branded button component with gradient background and animations
struct BrandedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let gradient: LinearGradient

    init(
        _ title: String,
        icon: String? = nil,
        gradient: LinearGradient = BrandConstants.Gradients.primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandConstants.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(BrandConstants.Typography.headline)
                }

                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isDisabled ?
                    LinearGradient(
                        colors: [.gray.opacity(0.5), .gray.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : gradient
            )
            .cornerRadius(BrandConstants.CornerRadius.lg)
            .shadow(
                color: isDisabled ? .clear : BrandConstants.Shadow.md.color,
                radius: BrandConstants.Shadow.md.radius,
                x: BrandConstants.Shadow.md.x,
                y: BrandConstants.Shadow.md.y
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(BrandConstants.Animation.spring, value: isLoading)
    }
}

/// Secondary button with outline style
struct OutlineButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let borderColor: Color

    init(
        _ title: String,
        icon: String? = nil,
        borderColor: Color = BrandConstants.Colors.primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.borderColor = borderColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandConstants.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(BrandConstants.Typography.headline)
                }

                Text(title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(borderColor)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color(.systemBackground))
            .cornerRadius(BrandConstants.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.lg)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Tertiary text button style
struct TextButton: View {
    let title: String
    let action: () -> Void
    let color: Color

    init(_ title: String, color: Color = BrandConstants.Colors.primary, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .underline()
        }
    }
}

// MARK: - Button Styles

/// Scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(BrandConstants.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        BrandedButton("Get Started", icon: "arrow.right") {
            print("Tapped!")
        }

        BrandedButton("Sign In", gradient: BrandConstants.Gradients.teal, isLoading: true) {
            print("Loading...")
        }

        BrandedButton("Disabled", isDisabled: true) {
            print("Won't fire")
        }

        OutlineButton("Learn More", icon: "info.circle") {
            print("Learn more")
        }

        TextButton("Skip for now") {
            print("Skipped")
        }
    }
    .padding()
}
