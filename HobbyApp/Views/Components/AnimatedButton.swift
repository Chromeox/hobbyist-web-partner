import SwiftUI

// MARK: - Animated Button Component for Phase 3

public struct AnimatedButton: View {
    let title: String
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void

    @State private var isPressed = false
    @State private var isLoading = false

    private let hapticService = HapticFeedbackService.shared

    public init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: {
            // Haptic feedback based on button style
            switch style {
            case .primary, .destructive:
                hapticService.playSelection()
            case .secondary, .tertiary:
                hapticService.playLight()
            case .minimal:
                hapticService.playLight()
            }

            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(textColor)
                        .accessibilityHidden(true)
                } else {
                    Text(title)
                        .font(titleFont)
                        .fontWeight(fontWeight)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .scaleEffect(scaleEffect)
        .optimizedSpring(
            response: 0.3,
            dampingFraction: 0.7,
            type: .essential,
            priority: .high
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
        .accessibilityHint(isLoading ? "Please wait while the action completes" : accessibilityHintForStyle)
        .accessibilityAddTraits(isLoading ? [.updatesFrequently] : [.isButton])
        .accessibilityRemoveTraits(isLoading ? [.isButton] : [])
    }

    // MARK: - Computed Properties

    private var scaleEffect: CGFloat {
        isPressed ? 0.96 : 1.0
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? BrandConstants.Colors.primary.opacity(0.8) : BrandConstants.Colors.primary
        case .secondary:
            return isPressed ? Color(.systemGray5) : Color(.systemGray6)
        case .destructive:
            return isPressed ? BrandConstants.Colors.error.opacity(0.8) : BrandConstants.Colors.error
        case .tertiary:
            return Color.clear
        case .minimal:
            return isPressed ? Color(.systemGray4) : Color.clear
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .tertiary, .minimal:
            return BrandConstants.Colors.primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive, .secondary:
            return Color.clear
        case .tertiary:
            return BrandConstants.Colors.primary
        case .minimal:
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .tertiary:
            return 1.0
        default:
            return 0
        }
    }

    private var buttonHeight: CGFloat {
        switch size {
        case .small:
            return 36
        case .regular:
            return 44
        case .large:
            return 52
        }
    }

    private var titleFont: Font {
        switch size {
        case .small:
            return BrandConstants.Typography.subheadline
        case .regular:
            return BrandConstants.Typography.body
        case .large:
            return BrandConstants.Typography.headline
        }
    }

    private var fontWeight: Font.Weight {
        switch style {
        case .primary, .destructive:
            return .semibold
        case .secondary:
            return .medium
        case .tertiary, .minimal:
            return .regular
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            return BrandConstants.CornerRadius.sm
        case .regular:
            return BrandConstants.CornerRadius.md
        case .large:
            return BrandConstants.CornerRadius.lg
        }
    }
    
    private var accessibilityHintForStyle: String {
        switch style {
        case .primary:
            return "Double tap to perform the primary action"
        case .secondary:
            return "Double tap to perform a secondary action"
        case .tertiary:
            return "Double tap to perform an additional action"
        case .destructive:
            return "Double tap to perform a destructive action. This cannot be undone"
        case .minimal:
            return "Double tap to activate"
        }
    }

    // MARK: - Loading State

    public func loading(_ isLoading: Bool) -> AnimatedButton {
        var button = self
        button.isLoading = isLoading
        return button
    }
}

// MARK: - Button Configurations

public enum ButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case minimal
}

public enum ButtonSize {
    case small
    case regular
    case large
}

// MARK: - Icon Button Variant

public struct AnimatedIconButton: View {
    let icon: String
    let style: ButtonStyle
    let size: IconButtonSize
    let action: () -> Void

    @State private var isPressed = false
    @State private var isLoading = false

    private let hapticService = HapticFeedbackService.shared

    public init(
        icon: String,
        style: ButtonStyle = .secondary,
        size: IconButtonSize = .regular,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: {
            hapticService.playLight()
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .foregroundColor(iconColor)
                } else {
                    Image(systemName: icon)
                        .font(iconFont)
                        .foregroundColor(iconColor)
                }
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .scaleEffect(scaleEffect)
        .optimizedSpring(
            response: 0.3,
            dampingFraction: 0.7,
            type: .essential,
            priority: .high
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Loading" : iconAccessibilityLabel)
        .accessibilityHint(isLoading ? "Please wait while the action completes" : iconAccessibilityHintForStyle)
        .accessibilityAddTraits(isLoading ? [.updatesFrequently] : [.isButton])
        .accessibilityRemoveTraits(isLoading ? [.isButton] : [])
    }

    // MARK: - Computed Properties

    private var scaleEffect: CGFloat {
        isPressed ? 0.9 : 1.0
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? BrandConstants.Colors.primary.opacity(0.8) : BrandConstants.Colors.primary
        case .secondary:
            return isPressed ? Color(.systemGray5) : Color(.systemGray6)
        case .destructive:
            return isPressed ? BrandConstants.Colors.error.opacity(0.8) : BrandConstants.Colors.error
        case .tertiary:
            return Color.clear
        case .minimal:
            return isPressed ? Color(.systemGray4) : Color.clear
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .tertiary, .minimal:
            return BrandConstants.Colors.primary
        }
    }

    private var borderColor: Color {
        switch style {
        case .tertiary:
            return BrandConstants.Colors.primary
        default:
            return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .tertiary:
            return 1.0
        default:
            return 0
        }
    }

    private var buttonSize: CGFloat {
        switch size {
        case .small:
            return 32
        case .regular:
            return 40
        case .large:
            return 48
        }
    }

    private var iconFont: Font {
        switch size {
        case .small:
            return BrandConstants.Typography.footnote
        case .regular:
            return BrandConstants.Typography.subheadline
        case .large:
            return BrandConstants.Typography.headline
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            return BrandConstants.CornerRadius.sm
        case .regular:
            return BrandConstants.CornerRadius.md
        case .large:
            return BrandConstants.CornerRadius.lg
        }
    }
    
    private var iconAccessibilityLabel: String {
        switch icon {
        case "heart": return "Favorite"
        case "heart.fill": return "Unfavorite"
        case "bookmark": return "Save"
        case "bookmark.fill": return "Unsave"
        case "share": return "Share"
        case "trash": return "Delete"
        case "plus": return "Add"
        case "minus": return "Remove"
        case "xmark": return "Close"
        case "chevron.left": return "Back"
        case "chevron.right": return "Forward"
        case "ellipsis": return "More options"
        case "gear": return "Settings"
        case "info.circle": return "Information"
        default: return icon.replacingOccurrences(of: ".", with: " ")
        }
    }
    
    private var iconAccessibilityHintForStyle: String {
        switch style {
        case .primary:
            return "Double tap to perform the primary action"
        case .secondary:
            return "Double tap to perform a secondary action"
        case .tertiary:
            return "Double tap to perform an additional action"
        case .destructive:
            return "Double tap to delete. This cannot be undone"
        case .minimal:
            return "Double tap to activate"
        }
    }
}

public enum IconButtonSize {
    case small
    case regular
    case large
}

// MARK: - Preview

#Preview("Animated Buttons") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Phase 3 Animated Buttons")
                .font(BrandConstants.Typography.headline)
                .padding()

            VStack(spacing: 12) {
                AnimatedButton("Primary Button", style: .primary) {}
                AnimatedButton("Secondary Button", style: .secondary) {}
                AnimatedButton("Tertiary Button", style: .tertiary) {}
                AnimatedButton("Destructive Button", style: .destructive) {}
                AnimatedButton("Minimal Button", style: .minimal) {}
            }
            .padding(.horizontal)

            Text("Icon Buttons")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                AnimatedIconButton(icon: "heart", style: .primary) {}
                AnimatedIconButton(icon: "bookmark", style: .secondary) {}
                AnimatedIconButton(icon: "share", style: .tertiary) {}
                AnimatedIconButton(icon: "trash", style: .destructive) {}
            }
            .padding(.horizontal)

            Text("Different Sizes")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                AnimatedButton("Small Button", style: .primary, size: .small) {}
                AnimatedButton("Regular Button", style: .primary, size: .regular) {}
                AnimatedButton("Large Button", style: .primary, size: .large) {}
            }
            .padding(.horizontal)
        }
    }
}