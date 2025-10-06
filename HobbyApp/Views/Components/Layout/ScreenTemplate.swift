import SwiftUI

// MARK: - Screen Template
// Use this as a base for implementing designer screens quickly

struct ScreenTemplate<Content: View>: View {
    let title: String?
    let showBackButton: Bool
    let showNavigation: Bool
    let backgroundColor: Color
    let content: () -> Content

    init(
        title: String? = nil,
        showBackButton: Bool = false,
        showNavigation: Bool = true,
        backgroundColor: Color = .hobbyistBackground,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.showNavigation = showNavigation
        self.backgroundColor = backgroundColor
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Header (if needed)
            if showNavigation, let title = title {
                CustomNavigationHeader(
                    title: title,
                    showBackButton: showBackButton
                )
            }

            // Main Content Area
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Custom Navigation Header
struct CustomNavigationHeader: View {
    let title: String
    let showBackButton: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.hobbyistHeadline())
                        .foregroundColor(.hobbyistTextPrimary)
                }
            }

            Spacer()

            Text(title)
                .font(.hobbyistTitle())
                .fontWeight(.semibold)
                .foregroundColor(.hobbyistTextPrimary)

            Spacer()

            if showBackButton {
                // Invisible spacer to center title
                Image(systemName: "chevron.left")
                    .font(.hobbyistHeadline())
                    .opacity(0)
            }
        }
        .padding(.horizontal, HobbyistSpacing.md)
        .padding(.vertical, HobbyistSpacing.sm)
        .background(.regularMaterial)
    }
}

// MARK: - Loading State Template
struct LoadingScreenTemplate: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        ScreenTemplate {
            VStack(spacing: HobbyistSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.hobbyistPrimary)

                Text(message)
                    .font(.hobbyistBody())
                    .foregroundColor(.hobbyistTextSecondary)
            }
        }
    }
}

// MARK: - Empty State Template
struct EmptyStateTemplate: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: HobbyistSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.hobbyistTextTertiary)

            VStack(spacing: HobbyistSpacing.sm) {
                Text(title)
                    .font(.hobbyistTitle())
                    .fontWeight(.semibold)
                    .foregroundColor(.hobbyistTextPrimary)

                Text(message)
                    .font(.hobbyistBody())
                    .foregroundColor(.hobbyistTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                HobbyistButton(actionTitle, style: .primary, action: action)
                    .padding(.top, HobbyistSpacing.md)
            }
        }
        .padding(HobbyistSpacing.xl)
    }
}

// MARK: - Error State Template
struct ErrorStateTemplate: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        EmptyStateTemplate(
            icon: "exclamationmark.triangle.fill",
            title: title,
            message: message,
            actionTitle: retryAction != nil ? "Try Again" : nil,
            action: retryAction
        )
    }
}

// MARK: - Preview
#Preview("Screen Template") {
    ScreenTemplate(
        title: "Example Screen",
        showBackButton: true
    ) {
        VStack(spacing: HobbyistSpacing.lg) {
            Text("This is the main content area")
                .font(.hobbyistBody())

            HobbyistButton("Example Button") {
                print("Button tapped")
            }
        }
        .padding()
    }
}

#Preview("Loading State") {
    LoadingScreenTemplate(message: "Loading classes...")
}

#Preview("Empty State") {
    EmptyStateTemplate(
        icon: "calendar.badge.plus",
        title: "No Classes Yet",
        message: "When you book your first class, it will appear here.",
        actionTitle: "Browse Classes"
    ) {
        print("Browse classes tapped")
    }
}

#Preview("Error State") {
    ErrorStateTemplate(
        message: "Unable to load classes. Please check your internet connection."
    ) {
        print("Retry tapped")
    }
}