import SwiftUI

/// HobbyApp Brand Design System
/// Central source of truth for colors, typography, spacing, and other design tokens
struct BrandConstants {

    // MARK: - Colors

    struct Colors {
        /// Primary brand color - Deep Blue (#2563EB)
        static let primary = Color("BrandPrimary")

        /// Secondary brand color - Vibrant Teal (#06B6D4)
        static let teal = Color("BrandTeal")

        /// Accent brand color - Warm Coral (#FB7185)
        static let coral = Color("BrandCoral")

        /// Landing page gradient colors
        static let gradientStart = Color("LandingGradientStart")
        static let gradientEnd = Color("LandingGradientEnd")

        /// Semantic colors for UI elements
        static let text = Color.primary
        static let secondaryText = Color.secondary
        static let surface = Color(UIColor.systemBackground)
        static let background = Color(UIColor.systemGroupedBackground)
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
        static let link = primary
        
        /// Category-specific colors
        struct Category {
            static let ceramics = Color(red: 0.573, green: 0.251, blue: 0.055)
            static let cooking = Color(red: 0.086, green: 0.639, blue: 0.290)
            static let arts = Color(red: 0.114, green: 0.306, blue: 0.847)
            static let photography = Color(red: 0.486, green: 0.227, blue: 0.929)
            static let music = Color(red: 0.310, green: 0.275, blue: 0.898)
            static let dance = Color(red: 0.859, green: 0.153, blue: 0.467)
            static let writing = Color(red: 0.471, green: 0.208, blue: 0.059)
            static let jewelry = Color(red: 0.033, green: 0.569, blue: 0.698)
            static let woodworking = Color(red: 0.918, green: 0.345, blue: 0.075)
        }
    }

    // MARK: - Typography

    struct Typography {
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 24, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .medium)
        static let caption = Font.system(size: 12, weight: .medium)
        static let footnote = Font.system(size: 13, weight: .regular)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    struct Shadow {
        static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let md = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    }

    // MARK: - Animation

    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }

    // MARK: - Gradients

    struct Gradients {
        static let landing = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let teal = LinearGradient(
            colors: [Colors.teal, Colors.teal.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let coral = LinearGradient(
            colors: [Colors.coral, Colors.coral.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - View Extensions for Easy Access

extension View {
    /// Apply standard brand shadow
    func brandShadow(_ size: BrandConstants.Shadow.Type = BrandConstants.Shadow.self) -> some View {
        self.shadow(
            color: BrandConstants.Shadow.md.color,
            radius: BrandConstants.Shadow.md.radius,
            x: BrandConstants.Shadow.md.x,
            y: BrandConstants.Shadow.md.y
        )
    }

    /// Apply rounded corners with brand radius
    func brandCornerRadius(_ size: CGFloat = BrandConstants.CornerRadius.md) -> some View {
        self.cornerRadius(size)
    }
}

// MARK: - Color Extension for Brand Colors
// Note: These extensions were removed to fix duplicate declaration errors
// Use BrandConstants.Colors.primary, .teal, .coral directly instead
