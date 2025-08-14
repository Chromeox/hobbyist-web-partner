import SwiftUI

// MARK: - Component Protocols for Standardization

/// Base protocol for all reusable UI components
protocol ReusableComponent: View {
    associatedtype Content: View
    associatedtype Configuration: ComponentConfiguration
    
    var configuration: Configuration { get }
    
    @ViewBuilder
    func buildContent() -> Content
}

/// Protocol for component configuration objects
protocol ComponentConfiguration {
    var isAccessibilityEnabled: Bool { get }
    var animationDuration: Double { get }
}

/// Protocol for components that handle user interactions
protocol InteractiveComponent: ReusableComponent {
    associatedtype Action
    
    var onAction: ((Action) -> Void)? { get }
}

/// Protocol for components that display data
protocol DataDisplayComponent: ReusableComponent {
    associatedtype DataType
    
    var data: DataType { get }
    var isLoading: Bool { get }
    var errorState: String? { get }
}

/// Protocol for grid-based components
protocol GridComponent: ReusableComponent {
    var columns: [GridItem] { get }
    var spacing: CGFloat { get }
    var alignment: HorizontalAlignment { get }
}

/// Protocol for header components
protocol HeaderComponent: ReusableComponent {
    var title: String { get }
    var subtitle: String? { get }
    var headerStyle: HeaderStyle { get }
}

/// Header style enumeration
enum HeaderStyle {
    case large
    case medium
    case compact
    case featured
    
    var font: Font {
        switch self {
        case .large: return .largeTitle
        case .medium: return .title
        case .compact: return .headline
        case .featured: return .title.bold()
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .large: return 24
        case .medium: return 16
        case .compact: return 8
        case .featured: return 20
        }
    }
}

/// Protocol for list item components
protocol ListItemComponent: InteractiveComponent {
    var isSelected: Bool { get }
    var selectionStyle: SelectionStyle { get }
}

/// Selection style for list items
enum SelectionStyle {
    case checkmark
    case highlight
    case border
    case none
}

// MARK: - Default Configuration Implementations

struct DefaultComponentConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    
    init(isAccessibilityEnabled: Bool = true, animationDuration: Double = 0.3) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
    }
}

struct GridConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let columns: [GridItem]
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    
    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        columns: [GridItem] = [GridItem(.adaptive(minimum: 160))],
        spacing: CGFloat = 16,
        alignment: HorizontalAlignment = .center
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.columns = columns
        self.spacing = spacing
        self.alignment = alignment
    }
}

// MARK: - ViewBuilder Extensions

extension View {
    /// Apply consistent component styling
    @ViewBuilder
    func componentStyle<T: ComponentConfiguration>(_ configuration: T) -> some View {
        self
            .accessibilityEnabled(configuration.isAccessibilityEnabled)
            .animation(.easeInOut(duration: configuration.animationDuration), value: true)
    }
    
    /// Apply conditional modifiers based on configuration
    @ViewBuilder
    func conditionalModifier<Content: View>(
        @ViewBuilder content: @escaping (Self) -> Content
    ) -> Content {
        content(self)
    }
}