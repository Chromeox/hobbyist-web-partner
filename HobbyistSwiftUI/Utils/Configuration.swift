import Foundation
import SwiftUI

struct Configuration {
    static let shared = Configuration()

    let appleMerchantId = "merchant.com.hobbyist.app"

    private init() {}
}

// MARK: - Brand Design System

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
    }

    // MARK: - Typography

    struct Typography {
        static let heroTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .medium)
        static let caption = Font.system(size: 13, weight: .medium)
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
    }
}