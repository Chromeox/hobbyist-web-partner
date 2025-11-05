import SwiftUI

// MARK: - Primary Button Component
// Ready to be styled with designer specifications

struct HobbyistButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool

    init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: HobbyistSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(style.foregroundColor)
                        .accessibilityHidden(true)
                }

                if !isLoading {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: size.height)
            .frame(maxWidth: size.maxWidth)
            .foregroundColor(style.foregroundColor)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .hobbyistShadow(style.shadowStyle)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
        .accessibilityHint(isDisabled ? "This button is currently disabled" : style.accessibilityHint)
        .accessibilityAddTraits(isDisabled ? [.notEnabled] : [])
        .accessibilityAddTraits(isLoading ? [.updatesFrequently] : [.isButton])
        .accessibilityRemoveTraits(isLoading ? [.isButton] : [])
    }
}

// MARK: - Button Styles
extension HobbyistButton {
    enum ButtonStyle {
        case primary, secondary, tertiary, destructive, ghost

        var backgroundColor: Color {
            switch self {
            case .primary: return .hobbyistPrimary
            case .secondary: return .hobbyistSecondary
            case .tertiary: return .hobbyistSurface
            case .destructive: return .hobbyistError
            case .ghost: return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .destructive: return .white
            case .tertiary: return .hobbyistTextPrimary
            case .ghost: return .hobbyistPrimary
            }
        }

        var borderColor: Color {
            switch self {
            case .primary, .secondary, .destructive: return .clear
            case .tertiary: return Color.gray.opacity(0.3)
            case .ghost: return .hobbyistPrimary
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .primary, .secondary, .destructive: return 0
            case .tertiary, .ghost: return 1
            }
        }

        var shadowStyle: HobbyistShadow {
            switch self {
            case .primary, .secondary: return .medium
            case .tertiary: return .small
            case .destructive, .ghost: return .small
            }
        }
        
        var accessibilityHint: String {
            switch self {
            case .primary: return "Double tap to perform the primary action"
            case .secondary: return "Double tap to perform a secondary action"
            case .tertiary: return "Double tap to perform an additional action"
            case .destructive: return "Double tap to perform a destructive action. This cannot be undone"
            case .ghost: return "Double tap to activate"
            }
        }
    }

    enum ButtonSize {
        case small, medium, large

        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 48
            case .large: return 56
            }
        }

        var font: Font {
            switch self {
            case .small: return .hobbyistCallout()
            case .medium: return .hobbyistBody()
            case .large: return .hobbyistHeadline()
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return HobbyistRadius.sm
            case .medium: return HobbyistRadius.md
            case .large: return HobbyistRadius.lg
            }
        }

        var maxWidth: CGFloat? {
            switch self {
            case .small, .medium: return nil
            case .large: return .infinity
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: HobbyistSpacing.md) {
        HobbyistButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }

        HobbyistButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }

        HobbyistButton("Tertiary Button", style: .tertiary) {
            print("Tertiary tapped")
        }

        HobbyistButton("Loading...", style: .primary, isLoading: true) {
            print("Loading tapped")
        }

        HobbyistButton("Disabled", style: .primary, isDisabled: true) {
            print("Disabled tapped")
        }

        HobbyistButton("Small Button", style: .primary, size: .small) {
            print("Small tapped")
        }

        HobbyistButton("Large Button", style: .primary, size: .large) {
            print("Large tapped")
        }
    }
    .padding()
}