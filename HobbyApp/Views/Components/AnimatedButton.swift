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
                } else {
                    Text(title)
                        .font(titleFont)
                        .fontWeight(fontWeight)
                        .foregroundColor(textColor)
                        .lineLimit(1)
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
    }

    // MARK: - Computed Properties

    private var scaleEffect: CGFloat {
        isPressed ? 0.96 : 1.0
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? Color.blue.opacity(0.8) : Color.blue
        case .secondary:
            return isPressed ? Color(.systemGray5) : Color(.systemGray6)
        case .destructive:
            return isPressed ? Color.red.opacity(0.8) : Color.red
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
            return .blue
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive, .secondary:
            return Color.clear
        case .tertiary:
            return .blue
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
            return 8
        case .regular:
            return 10
        case .large:
            return 12
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
    }

    // MARK: - Computed Properties

    private var scaleEffect: CGFloat {
        isPressed ? 0.9 : 1.0
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? Color.blue.opacity(0.8) : Color.blue
        case .secondary:
            return isPressed ? Color(.systemGray5) : Color(.systemGray6)
        case .destructive:
            return isPressed ? Color.red.opacity(0.8) : Color.red
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
            return .blue
        }
    }

    private var borderColor: Color {
        switch style {
        case .tertiary:
            return .blue
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
            return 8
        case .regular:
            return 10
        case .large:
            return 12
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