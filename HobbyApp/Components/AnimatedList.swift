import SwiftUI

// MARK: - Animated List Components for Phase 3

public struct AnimatedListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    let staggerDelay: Double
    let animationType: ListAnimationType

    @State private var visibleItems: Set<String> = []

    public init(
        items: [Item],
        staggerDelay: Double = 0.1,
        animationType: ListAnimationType = .fadeSlide,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.staggerDelay = staggerDelay
        self.animationType = animationType
        self.content = content
    }

    public var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let itemID = "\(item.id)"

                content(item)
                    .opacity(visibleItems.contains(itemID) ? 1 : 0)
                    .offset(y: visibleItems.contains(itemID) ? 0 : offsetForAnimation)
                    .scaleEffect(visibleItems.contains(itemID) ? 1 : scaleForAnimation)
                    .optimizedSpring(
                        response: 0.6,
                        dampingFraction: 0.8,
                        type: .content,
                        priority: .normal
                    )
                    .onAppear {
                        withAnimation {
                            visibleItems.insert(itemID)
                        }
                    }
                    .onDisappear {
                        visibleItems.remove(itemID)
                    }
            }
        }
    }

    private var offsetForAnimation: CGFloat {
        switch animationType {
        case .fadeSlide:
            return 20
        case .fadeScale:
            return 0
        case .slideFromLeft:
            return 0
        case .slideFromRight:
            return 0
        }
    }

    private var scaleForAnimation: CGFloat {
        switch animationType {
        case .fadeSlide, .slideFromLeft, .slideFromRight:
            return 1.0
        case .fadeScale:
            return 0.8
        }
    }
}

public enum ListAnimationType {
    case fadeSlide
    case fadeScale
    case slideFromLeft
    case slideFromRight
}

// MARK: - Animated Grid Component

public struct AnimatedGridView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: [GridItem]
    let content: (Item) -> Content
    let staggerDelay: Double

    @State private var visibleItems: Set<String> = []

    public init(
        items: [Item],
        columns: [GridItem],
        staggerDelay: Double = 0.05,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.staggerDelay = staggerDelay
        self.content = content
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let itemID = "\(item.id)"

                content(item)
                    .opacity(visibleItems.contains(itemID) ? 1 : 0)
                    .scaleEffect(visibleItems.contains(itemID) ? 1 : 0.8)
                    .offset(y: visibleItems.contains(itemID) ? 0 : 10)
                    .optimizedSpring(
                        response: 0.5,
                        dampingFraction: 0.7,
                        type: .content,
                        priority: .normal
                    )
                    .onAppear {
                        withAnimation {
                            visibleItems.insert(itemID)
                        }
                    }
                    .onDisappear {
                        visibleItems.remove(itemID)
                    }
            }
        }
    }
}

// MARK: - Animated Card Component

public struct AnimatedCard<Content: View>: View {
    let content: Content
    let cardStyle: CardStyle

    @State private var isPressed = false
    @State private var isVisible = false

    public init(
        style: CardStyle = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.cardStyle = style
        self.content = content()
    }

    public var body: some View {
        content
            .padding(cardStyle.padding)
            .background(cardStyle.backgroundColor)
            .cornerRadius(cardStyle.cornerRadius)
            .shadow(
                color: cardStyle.shadowColor,
                radius: cardStyle.shadowRadius,
                x: 0,
                y: cardStyle.shadowY
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .optimizedSpring(
                response: 0.3,
                dampingFraction: 0.7,
                type: .essential,
                priority: .high
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .optimizedSpring(
                response: 0.6,
                dampingFraction: 0.8,
                type: .content,
                priority: .normal
            )
            .onAppear {
                withAnimation {
                    isVisible = true
                }
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

public struct CardStyle {
    let padding: EdgeInsets
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    public static let `default` = CardStyle(
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: Color(.systemBackground),
        cornerRadius: 12,
        shadowColor: Color.black.opacity(0.1),
        shadowRadius: 8,
        shadowY: 4
    )

    public static let elevated = CardStyle(
        padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        backgroundColor: Color(.systemBackground),
        cornerRadius: 16,
        shadowColor: Color.black.opacity(0.15),
        shadowRadius: 12,
        shadowY: 6
    )

    public static let minimal = CardStyle(
        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        backgroundColor: Color(.systemGray6),
        cornerRadius: 8,
        shadowColor: Color.clear,
        shadowRadius: 0,
        shadowY: 0
    )
}

// MARK: - Animated Search Bar

public struct AnimatedSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @State private var isFocused = false

    let placeholder: String
    let onSearchButtonPressed: () -> Void

    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonPressed: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonPressed = onSearchButtonPressed
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(isFocused ? .blue : .secondary)
                .scaleEffect(isFocused ? 1.1 : 1.0)
                .optimizedSpring(
                    response: 0.3,
                    dampingFraction: 0.7,
                    type: .essential,
                    priority: .high
                )

            // Search Field
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isEditing = editing
                    isFocused = editing
                }
            })
            .submitLabel(.search)
            .onSubmit {
                onSearchButtonPressed()
            }

            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Cancel Button (when editing)
            if isEditing {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        text = ""
                        isEditing = false
                        isFocused = false
                        hideKeyboard()
                    }
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(BrandConstants.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .stroke(isFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .optimizedSpring(
            response: 0.3,
            dampingFraction: 0.8,
            type: .essential,
            priority: .high
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Sample Data for Preview

struct SampleItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

// MARK: - Preview

#Preview("Animated Lists") {
    ScrollView {
        VStack(spacing: 30) {
            Text("Phase 3 Animated Components")
                .font(BrandConstants.Typography.headline)
                .padding()

            VStack(alignment: .leading, spacing: 16) {
                Text("Animated Search Bar")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)

                AnimatedSearchBar(text: .constant("")) {
                    print("Search pressed")
                }
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Staggered List Animation")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)

                AnimatedListView(
                    items: [
                        SampleItem(title: "Pottery Class", subtitle: "Learn ceramics", systemImage: "paintbrush.fill"),
                        SampleItem(title: "Yoga Session", subtitle: "Morning flow", systemImage: "figure.yoga"),
                        SampleItem(title: "Cooking Class", subtitle: "Italian cuisine", systemImage: "fork.knife"),
                    ],
                    staggerDelay: 0.1,
                    animationType: .fadeSlide
                ) { item in
                    AnimatedCard(style: .default) {
                        HStack(spacing: 12) {
                            Image(systemName: item.systemImage)
                                .font(BrandConstants.Typography.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(BrandConstants.Typography.headline)
                                Text(item.subtitle)
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Animated Grid")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)

                AnimatedGridView(
                    items: Array(0..<6).map { index in
                        SampleItem(title: "Item \(index + 1)", subtitle: "Subtitle", systemImage: "star.fill")
                    },
                    columns: Array(repeating: GridItem(.flexible()), count: 2)
                ) { item in
                    AnimatedCard(style: .minimal) {
                        VStack(spacing: 8) {
                            Image(systemName: item.systemImage)
                                .font(BrandConstants.Typography.largeTitle)
                                .foregroundColor(.blue)
                            Text(item.title)
                                .font(BrandConstants.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .frame(height: 60)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}