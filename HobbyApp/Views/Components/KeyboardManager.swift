import SwiftUI
import Combine

// MARK: - Keyboard Manager for Phase 3 Enhanced UX

/// Manages keyboard interactions with smooth animations and dismissal
@MainActor
public class KeyboardManager: ObservableObject {
    static let shared = KeyboardManager()

    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleKeyboardWillHide()
            }
            .store(in: &cancellables)
    }

    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            isKeyboardVisible = true
            keyboardHeight = keyboardFrame.height
        }
    }

    private func handleKeyboardWillHide() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isKeyboardVisible = false
            keyboardHeight = 0
        }
    }

    // MARK: - Public Methods

    public func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Keyboard Dismissal View Modifier

public struct KeyboardDismissalModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager.shared

    public func body(content: Content) -> some View {
        content
            .onTapGesture {
                if keyboardManager.isKeyboardVisible {
                    keyboardManager.dismissKeyboard()
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if keyboardManager.isKeyboardVisible {
                            keyboardManager.dismissKeyboard()
                        }
                    }
            )
    }
}

// MARK: - Enhanced Search Field with Keyboard Management

public struct EnhancedSearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSearchPressed: () -> Void

    @StateObject private var keyboardManager = KeyboardManager.shared
    @FocusState private var isFocused: Bool
    @State private var isActive = false

    public init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchPressed: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchPressed = onSearchPressed
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
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSearchPressed()
                    keyboardManager.dismissKeyboard()
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

            // Cancel Button (when focused)
            if isFocused {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        text = ""
                        isFocused = false
                        keyboardManager.dismissKeyboard()
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
                .optimizedAnimation(
                    .easeInOut(duration: 0.2),
                    type: .essential,
                    priority: .high
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .optimizedSpring(
            response: 0.3,
            dampingFraction: 0.8,
            type: .essential,
            priority: .high
        )
        .onChange(of: isFocused) { focused in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isActive = focused
            }
        }
    }
}

// MARK: - Keyboard-Aware Container

public struct KeyboardAwareContainer<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager.shared

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight - geometry.safeAreaInsets.bottom : 0)
                .optimizedAnimation(
                    .easeInOut(duration: 0.3),
                    type: .navigation,
                    priority: .high
                )
        }
        .modifier(KeyboardDismissalModifier())
    }
}

// MARK: - View Extensions

public extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(KeyboardDismissalModifier())
    }

    func keyboardAware() -> some View {
        KeyboardAwareContainer {
            self
        }
    }
}

// MARK: - Keyboard-Optimized Search Bar for HomeView

public struct HomeSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedNeighborhood: String
    let neighborhoods: [String]

    @StateObject private var keyboardManager = KeyboardManager.shared
    @FocusState private var isSearchFocused: Bool

    public init(
        searchText: Binding<String>,
        selectedNeighborhood: Binding<String>,
        neighborhoods: [String]
    ) {
        self._searchText = searchText
        self._selectedNeighborhood = selectedNeighborhood
        self.neighborhoods = neighborhoods
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header with neighborhood selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover Vancouver")
                        .font(BrandConstants.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))

                    Text("Find your next creative adventure")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Neighborhood Selector
                Menu {
                    ForEach(neighborhoods, id: \.self) { neighborhood in
                        Button(neighborhood) {
                            selectedNeighborhood = neighborhood
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                        Text(selectedNeighborhood)
                            .lineLimit(1)
                    }
                    .font(BrandConstants.Typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(BrandConstants.CornerRadius.lg)
                }
            }

            // Enhanced Search Section
            EnhancedSearchField(
                text: $searchText,
                placeholder: "Search pottery, boxing, cooking..."
            ) {
                // Handle search action
                print("Searching for: \(searchText)")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, keyboardManager.isKeyboardVisible ? 8 : 0)
        .optimizedAnimation(
            .easeInOut(duration: 0.3),
            type: .content,
            priority: .normal
        )
    }
}

// MARK: - Preview

#Preview("Enhanced Search") {
    VStack {
        HomeSearchBar(
            searchText: .constant(""),
            selectedNeighborhood: .constant("All Vancouver"),
            neighborhoods: ["All Vancouver", "Downtown", "Gastown", "Yaletown"]
        )

        Spacer()

        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                        .fill(Color(.systemGray6))
                        .frame(height: 100)
                        .overlay(
                            Text("Content \(index + 1)")
                                .font(BrandConstants.Typography.headline)
                        )
                }
            }
            .padding()
        }
    }
    .keyboardAware()
}