import SwiftUI

// MARK: - Refactored Multi-Class Selection Grid Component

struct MultiClassSelectionGrid: View, GridComponent {
    typealias Configuration = MultiClassGridConfiguration

    // MARK: - Properties

    let configuration: MultiClassGridConfiguration
    let classes: [ClassData]
    let selectedClasses: Set<UUID>
    let onSelectionChange: (UUID) -> Void

    // GridComponent Protocol Requirements
    var columns: [GridItem] { configuration.columns }
    var spacing: CGFloat { configuration.spacing }
    var alignment: HorizontalAlignment { configuration.alignment }

    // MARK: - Initializer

    init(
        classes: [ClassData],
        selectedClasses: Set<UUID>,
        onSelectionChange: @escaping (UUID) -> Void,
        configuration: MultiClassGridConfiguration = MultiClassGridConfiguration()
    ) {
        self.classes = classes
        self.selectedClasses = selectedClasses
        self.onSelectionChange = onSelectionChange
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        LazyVGrid(columns: columns, spacing: spacing, alignment: alignment) {
            ForEach(classes, id: \.id) { classData in
                ClassSelectionCard(
                    classData: classData,
                    isSelected: selectedClasses.contains(classData.id),
                    onTap: { onSelectionChange(classData.id) }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedClasses)
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Class Selection Card Sub-Component

struct ClassSelectionCard: View, ListItemComponent {
    typealias Configuration = ClassSelectionCardConfiguration
    typealias Action = CardAction

    // MARK: - Properties

    let configuration: ClassSelectionCardConfiguration
    let classData: ClassData
    let isSelected: Bool
    let onAction: ((CardAction) -> Void)?
    let selectionStyle: SelectionStyle

    init(
        classData: ClassData,
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        configuration: ClassSelectionCardConfiguration = ClassSelectionCardConfiguration(),
        selectionStyle: SelectionStyle = .border
    ) {
        self.classData = classData
        self.isSelected = isSelected
        self.configuration = configuration
        self.selectionStyle = selectionStyle
        onAction = { action in
            switch action {
            case .tap:
                onTap?()
            case .favorite:
                break // Handle favorite action if needed
            }
        }
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        GridCell(
            configuration: GridCellConfiguration(
                backgroundColor: isSelected ? .accentColor.opacity(0.1) : .background,
                borderColor: isSelected ? .accentColor : .gray.opacity(0.3),
                borderWidth: isSelected ? 2 : 1
            ),
            onTap: { onAction?(.tap) }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                // Class Image
                AsyncImage(url: classData.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 6) {
                    // Class Title
                    Text(classData.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    // Instructor and Duration
                    HStack {
                        Text(classData.instructor)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(classData.duration)min")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.gray.opacity(0.2))
                            .cornerRadius(4)
                    }

                    // Price and Difficulty
                    HStack {
                        Text("$\(classData.price, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        DifficultyIndicator(level: classData.difficulty)
                    }

                    // Selection Indicator
                    if isSelected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Selected")
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .componentStyle(configuration)
    }

    enum CardAction {
        case tap
        case favorite
    }
}

// MARK: - Difficulty Indicator Sub-Component

struct DifficultyIndicator: View {
    let level: DifficultyLevel

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1 ... 3, id: \.self) { index in
                Circle()
                    .fill(index <= level.rawValue ? level.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Data Models

struct ClassData: Identifiable {
    let id = UUID()
    let title: String
    let instructor: String
    let duration: Int
    let price: Double
    let difficulty: DifficultyLevel
    let imageURL: URL?
}

enum DifficultyLevel: Int, CaseIterable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3

    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - Configuration Objects

struct MultiClassGridConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let columns: [GridItem]
    let spacing: CGFloat
    let alignment: HorizontalAlignment

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        columns: [GridItem] = [
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16),
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16),
        ],
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

struct ClassSelectionCardConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
    }
}
