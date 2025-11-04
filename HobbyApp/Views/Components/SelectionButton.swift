import SwiftUI

public struct SelectionButton: View {
    let text: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    // Initialize with default enabled state
    init(_ text: String, isSelected: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                // Add haptic feedback
                HapticFeedbackService.shared.playSelection()
                action()
            }
        }) {
            Text(text)
                .font(BrandConstants.Typography.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(backgroundColorForState)
                .foregroundColor(textColorForState)
                .cornerRadius(BrandConstants.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                        .stroke(borderColorForState, lineWidth: borderWidthForState)
                )
                .scaleEffect(scaleForState)
                .opacity(opacityForState)
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    // MARK: - Visual State Calculations

    private var backgroundColorForState: Color {
        if !isEnabled {
            return Color(.systemGray6)
        } else if isSelected {
            return isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
        } else if isPressed {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }

    private var textColorForState: Color {
        if !isEnabled {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }

    private var borderColorForState: Color {
        if isSelected && isEnabled {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.clear
        }
    }

    private var borderWidthForState: CGFloat {
        return isSelected ? 1 : 0
    }

    private var scaleForState: CGFloat {
        if !isEnabled {
            return 1.0
        } else if isPressed {
            return 0.98
        } else {
            return 1.0
        }
    }

    private var opacityForState: Double {
        return isEnabled ? 1.0 : 0.6
    }
}

// MARK: - Grid Layout Support

struct SelectionButtonGrid: View {
    let items: [String]
    let selectedItems: Set<String>
    let isEnabled: Bool
    let onSelectionChanged: (String) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(items: [String], selectedItems: Set<String>, isEnabled: Bool = true, onSelectionChanged: @escaping (String) -> Void) {
        self.items = items
        self.selectedItems = selectedItems
        self.isEnabled = isEnabled
        self.onSelectionChanged = onSelectionChanged
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                SelectionButton(
                    item,
                    isSelected: selectedItems.contains(item),
                    isEnabled: isEnabled,
                    action: {
                        onSelectionChanged(item)
                    }
                )
            }
        }
    }
}

// MARK: - Horizontal Chip Style

public struct SelectionChip: View {
    let text: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(_ text: String, isSelected: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                HapticFeedbackService.shared.playSelection()
                action()
            }
        }) {
            Text(text)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(backgroundColorForState)
                .foregroundColor(textColorForState)
                .cornerRadius(BrandConstants.CornerRadius.full)
                .scaleEffect(scaleForState)
                .opacity(opacityForState)
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private var backgroundColorForState: Color {
        if !isEnabled {
            return Color(.systemGray6)
        } else if isSelected {
            return isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
        } else if isPressed {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }

    private var textColorForState: Color {
        if !isEnabled {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }

    private var scaleForState: CGFloat {
        if !isEnabled {
            return 1.0
        } else if isPressed {
            return 0.95
        } else {
            return 1.0
        }
    }

    private var opacityForState: Double {
        return isEnabled ? 1.0 : 0.6
    }
}

// MARK: - Preview

#Preview("Selection Button") {
    VStack(spacing: 20) {
        Group {
            SelectionButton("Default", isSelected: false) {}
            SelectionButton("Selected", isSelected: true) {}
            SelectionButton("Disabled", isSelected: false, isEnabled: false) {}
            SelectionButton("Selected Disabled", isSelected: true, isEnabled: false) {}
        }

        Divider()

        Text("Grid Layout")
            .font(BrandConstants.Typography.headline)

        SelectionButtonGrid(
            items: ["Morning", "Afternoon", "Evening", "Weekend"],
            selectedItems: ["Morning", "Evening"],
            onSelectionChanged: { _ in }
        )

        Divider()

        Text("Chip Style")
            .font(BrandConstants.Typography.headline)

        HStack {
            SelectionChip("Pottery", isSelected: false) {}
            SelectionChip("Yoga", isSelected: true) {}
            SelectionChip("Cooking", isSelected: false) {}
        }
    }
    .padding()
}