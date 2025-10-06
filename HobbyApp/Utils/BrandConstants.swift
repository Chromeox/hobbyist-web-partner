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

        /// Category-specific colors
        struct Category {
            static let ceramics = Color(red: 0.573, green: 0.251, blue: 0.055)  // Earthy Brown
            static let cooking = Color(red: 0.086, green: 0.639, blue: 0.290)   // Fresh Green
            static let arts = Color(red: 0.114, green: 0.306, blue: 0.847)      // Royal Blue
            static let photography = Color(red: 0.486, green: 0.227, blue: 0.929) // Deep Purple
            static let music = Color(red: 0.310, green: 0.275, blue: 0.898)     // Vibrant Indigo
            static let dance = Color(red: 0.859, green: 0.153, blue: 0.467)     // Playful Pink
            static let writing = Color(red: 0.471, green: 0.208, blue: 0.059)   // Rich Brown
            static let jewelry = Color(red: 0.033, green: 0.569, blue: 0.698)   // Luxe Cyan
            static let woodworking = Color(red: 0.918, green: 0.345, blue: 0.075) // Natural Orange
        }
    }

    // MARK: - Typography

    struct Typography {
        /// Large titles for hero sections
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)

        /// Page headers and major sections
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)

        /// Section titles
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)

        /// Subsection headers
        static let headline = Font.system(size: 18, weight: .semibold)

        /// Body text
        static let body = Font.system(size: 16, weight: .regular)

        /// Secondary information
        static let subheadline = Font.system(size: 15, weight: .medium)

        /// Small labels and captions
        static let caption = Font.system(size: 13, weight: .medium)

        /// Tiny text for metadata
        static let footnote = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing

    struct Spacing {
        /// Extra small spacing - 4pt
        static let xs: CGFloat = 4

        /// Small spacing - 8pt
        static let sm: CGFloat = 8

        /// Medium spacing - 16pt (default)
        static let md: CGFloat = 16

        /// Large spacing - 24pt
        static let lg: CGFloat = 24

        /// Extra large spacing - 32pt
        static let xl: CGFloat = 32

        /// 2x Extra large spacing - 48pt
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    struct CornerRadius {
        /// Small radius for chips and tags - 8pt
        static let sm: CGFloat = 8

        /// Medium radius for cards - 12pt
        static let md: CGFloat = 12

        /// Large radius for buttons and prominent elements - 20pt
        static let lg: CGFloat = 20

        /// Extra large radius for hero elements - 24pt
        static let xl: CGFloat = 24

        /// Full circle/pill shape
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    struct Shadow {
        /// Subtle shadow for slight elevation
        static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))

        /// Medium shadow for cards
        static let md = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))

        /// Large shadow for prominent elements
        static let lg = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))

        /// Extra large shadow for modals and overlays
        static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
    }

    // MARK: - Animation

    struct Animation {
        /// Fast animation - 150ms for quick feedback
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)

        /// Standard animation - 300ms for most transitions
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)

        /// Slow animation - 500ms for dramatic effects
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        /// Spring animation for bouncy effects
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)

        /// Gentle spring for subtle bounce
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
    }

    // MARK: - Gradients

    struct Gradients {
        /// Landing page background gradient
        static let landing = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Primary brand gradient
        static let primary = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )

        /// Teal accent gradient
        static let teal = LinearGradient(
            colors: [Colors.teal, Colors.teal.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Coral accent gradient
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

extension Color {
    static var brandPrimary: Color { BrandConstants.Colors.primary }
    static var brandTeal: Color { BrandConstants.Colors.teal }
    static var brandCoral: Color { BrandConstants.Colors.coral }
}
