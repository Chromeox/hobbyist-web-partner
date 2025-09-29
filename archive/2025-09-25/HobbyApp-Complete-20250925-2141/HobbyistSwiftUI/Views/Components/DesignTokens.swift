import SwiftUI

// MARK: - Design Tokens
// This file will be updated when we receive the designer's specifications

extension Color {
    // Primary Colors (Update with designer's palette)
    static let hobbyistPrimary = Color("PrimaryBlue") // Designer will provide
    static let hobbyistSecondary = Color("AccentGreen")
    static let hobbyistTertiary = Color("AccentOrange")

    // Semantic Colors
    static let hobbyistBackground = Color("BackgroundGray")
    static let hobbyistSurface = Color("SurfaceWhite")
    static let hobbyistOnPrimary = Color.white
    static let hobbyistOnSurface = Color("TextDark")

    // Text Colors
    static let hobbyistTextPrimary = Color("TextDark")
    static let hobbyistTextSecondary = Color("TextMedium")
    static let hobbyistTextTertiary = Color("TextLight")

    // State Colors
    static let hobbyistSuccess = Color("StateGreen")
    static let hobbyistWarning = Color("StateOrange")
    static let hobbyistError = Color("StateRed")
    static let hobbyistInfo = Color("StateBlue")

    // Fallback colors for development (remove when assets added)
    static var fallbackPrimary: Color { Color.blue }
    static var fallbackSecondary: Color { Color.green }
    static var fallbackBackground: Color { Color(UIColor.systemBackground) }
}

extension Font {
    // Typography Scale (Update with designer's specifications)
    static func hobbyistDisplay(_ size: CGFloat = 32) -> Font {
        .custom("SF Pro Display", size: size, relativeTo: .largeTitle)
    }

    static func hobbyistTitle(_ size: CGFloat = 24) -> Font {
        .custom("SF Pro Display", size: size, relativeTo: .title)
    }

    static func hobbyistHeadline(_ size: CGFloat = 18) -> Font {
        .custom("SF Pro Text", size: size, relativeTo: .headline)
    }

    static func hobbyistBody(_ size: CGFloat = 16) -> Font {
        .custom("SF Pro Text", size: size, relativeTo: .body)
    }

    static func hobbyistCallout(_ size: CGFloat = 14) -> Font {
        .custom("SF Pro Text", size: size, relativeTo: .callout)
    }

    static func hobbyistCaption(_ size: CGFloat = 12) -> Font {
        .custom("SF Pro Text", size: size, relativeTo: .caption)
    }
}

// MARK: - Spacing System
enum HobbyistSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum HobbyistRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Shadow Styles
extension View {
    func hobbyistShadow(_ style: HobbyistShadow = .medium) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

enum HobbyistShadow {
    case small, medium, large

    var color: Color {
        Color.black.opacity(0.1)
    }

    var radius: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 8
        case .large: return 16
        }
    }

    var x: CGFloat { 0 }

    var y: CGFloat {
        switch self {
        case .small: return 1
        case .medium: return 4
        case .large: return 8
        }
    }
}