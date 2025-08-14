import SwiftUI

// MARK: - Refactored Class Requirements Component

struct ClassRequirementsComponent: View, DataDisplayComponent {
    typealias Configuration = ClassRequirementsConfiguration
    typealias DataType = [RequirementData]
    
    // MARK: - Properties
    let configuration: ClassRequirementsConfiguration
    let data: [RequirementData]
    let isLoading: Bool
    let errorState: String?
    
    // MARK: - Initializer
    init(
        requirements: [RequirementData],
        isLoading: Bool = false,
        errorState: String? = nil,
        configuration: ClassRequirementsConfiguration = ClassRequirementsConfiguration()
    ) {
        self.data = requirements
        self.isLoading = isLoading
        self.errorState = errorState
        self.configuration = configuration
    }
    
    // MARK: - Body
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ModularHeader(
                title: "Requirements",
                subtitle: "What you need to know",
                headerStyle: .medium
            )
            
            if isLoading {
                RequirementsLoadingView()
            } else if let errorState = errorState {
                RequirementsErrorView(message: errorState)
            } else {
                RequirementsList(requirements: data, configuration: configuration)
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Requirements List Sub-Component

struct RequirementsList: View {
    let requirements: [RequirementData]
    let configuration: ClassRequirementsConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(requirements.indices, id: \.self) { index in
                let requirement = requirements[index]
                
                RequirementRow(
                    title: requirement.title,
                    value: requirement.description,
                    icon: requirement.iconName,
                    isRequired: requirement.isRequired
                )
                
                if index < requirements.count - 1 {
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Enhanced Requirement Row with Additional Features

struct EnhancedRequirementRow: View, InteractiveComponent {
    typealias Configuration = RequirementRowConfiguration
    typealias Action = RequirementAction
    
    let configuration: RequirementRowConfiguration
    let requirement: RequirementData
    let onAction: ((RequirementAction) -> Void)?
    
    @State private var isExpanded = false
    
    init(
        requirement: RequirementData,
        onAction: ((RequirementAction) -> Void)? = nil,
        configuration: RequirementRowConfiguration = RequirementRowConfiguration()
    ) {
        self.requirement = requirement
        self.onAction = onAction
        self.configuration = configuration
    }
    
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        VStack(spacing: 0) {
            Button(action: {
                if requirement.hasDetails {
                    withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                        isExpanded.toggle()
                    }
                    onAction?(.toggle)
                }
            }) {
                HStack(spacing: 12) {
                    RequirementIcon(
                        iconName: requirement.iconName,
                        isRequired: requirement.isRequired,
                        category: requirement.category
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(requirement.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(requirement.description)
                            .font(.body)
                            .fontWeight(requirement.isRequired ? .semibold : .regular)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    RequirementBadge(requirement: requirement)
                    
                    if requirement.hasDetails {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: configuration.animationDuration), value: isExpanded)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            
            if isExpanded && requirement.hasDetails {
                RequirementDetails(requirement: requirement)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
            }
        }
        .componentStyle(configuration)
    }
    
    enum RequirementAction {
        case toggle
        case moreInfo
    }
}

// MARK: - Requirement Icon Sub-Component

struct RequirementIcon: View {
    let iconName: String
    let isRequired: Bool
    let category: RequirementCategory
    
    var body: some View {
        ZStack {
            Circle()
                .fill(category.backgroundColor)
                .frame(width: 32, height: 32)
            
            Image(systemName: iconName)
                .foregroundColor(isRequired ? .white : category.iconColor)
                .font(.system(size: 14, weight: .medium))
        }
        .overlay(
            Circle()
                .stroke(isRequired ? .red : category.borderColor, lineWidth: isRequired ? 2 : 1)
        )
    }
}

// MARK: - Requirement Badge Sub-Component

struct RequirementBadge: View {
    let requirement: RequirementData
    
    var body: some View {
        Group {
            if requirement.isRequired {
                Text("Required")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
            } else if requirement.isRecommended {
                Text("Recommended")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            } else {
                Text("Optional")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Requirement Details Sub-Component

struct RequirementDetails: View {
    let requirement: RequirementData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let details = requirement.details {
                Text(details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 44) // Align with main content
            }
            
            if !requirement.alternatives.isEmpty {
                Text("Alternatives:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.leading, 44)
                
                ForEach(requirement.alternatives, id: \.self) { alternative in
                    HStack {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(alternative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.leading, 50)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Loading and Error Views

struct RequirementsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                HStack {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 16)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .shimmering()
    }
}

struct RequirementsErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Unable to Load Requirements")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
    }
}

// MARK: - Data Models

struct RequirementData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let category: RequirementCategory
    let isRequired: Bool
    let isRecommended: Bool
    let hasDetails: Bool
    let details: String?
    let alternatives: [String]
    
    init(
        title: String,
        description: String,
        iconName: String,
        category: RequirementCategory = .general,
        isRequired: Bool = false,
        isRecommended: Bool = false,
        details: String? = nil,
        alternatives: [String] = []
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.isRequired = isRequired
        self.isRecommended = isRecommended
        self.hasDetails = details != nil || !alternatives.isEmpty
        self.details = details
        self.alternatives = alternatives
    }
}

enum RequirementCategory {
    case equipment
    case experience
    case health
    case clothing
    case general
    
    var backgroundColor: Color {
        switch self {
        case .equipment: return .blue.opacity(0.1)
        case .experience: return .purple.opacity(0.1)
        case .health: return .green.opacity(0.1)
        case .clothing: return .orange.opacity(0.1)
        case .general: return .gray.opacity(0.1)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .equipment: return .blue
        case .experience: return .purple
        case .health: return .green
        case .clothing: return .orange
        case .general: return .gray
        }
    }
    
    var borderColor: Color {
        iconColor.opacity(0.3)
    }
}

// MARK: - Configuration Objects

struct ClassRequirementsConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let showCategoryFilter: Bool
    let allowExpansion: Bool
    
    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        showCategoryFilter: Bool = false,
        allowExpansion: Bool = true
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.showCategoryFilter = showCategoryFilter
        self.allowExpansion = allowExpansion
    }
}

// MARK: - View Extensions

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}