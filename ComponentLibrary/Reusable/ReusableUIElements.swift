import SwiftUI

// MARK: - Reusable UI Element Library

/// Reusable grid cell component for class selection
struct GridCell<Content: View>: View, ReusableComponent {
    typealias Configuration = GridCellConfiguration

    let configuration: GridCellConfiguration
    let content: Content
    let onTap: (() -> Void)?

    init(
        configuration: GridCellConfiguration = GridCellConfiguration(),
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.content = content()
        self.onTap = onTap
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        Button(action: { onTap?() }) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(configuration.backgroundColor)
                .cornerRadius(configuration.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: configuration.cornerRadius)
                        .stroke(configuration.borderColor, lineWidth: configuration.borderWidth)
                )
        }
        .buttonStyle(.plain)
        .componentStyle(configuration)
    }
}

/// Reusable requirement row component
struct RequirementRow: View, ReusableComponent {
    typealias Configuration = RequirementRowConfiguration

    let configuration: RequirementRowConfiguration
    let title: String
    let value: String
    let icon: String?
    let isRequired: Bool

    init(
        title: String,
        value: String,
        icon: String? = nil,
        isRequired: Bool = false,
        configuration: RequirementRowConfiguration = RequirementRowConfiguration()
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.isRequired = isRequired
        self.configuration = configuration
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isRequired ? .red : .primary)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(isRequired ? .semibold : .regular)
            }

            Spacer()

            if isRequired {
                Text("Required")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .componentStyle(configuration)
    }
}

/// Reusable review item component
struct ReviewItem: View, DataDisplayComponent {
    typealias Configuration = ReviewItemConfiguration
    typealias DataType = ReviewData

    let configuration: ReviewItemConfiguration
    let data: ReviewData
    let isLoading: Bool
    let errorState: String?

    init(
        data: ReviewData,
        isLoading: Bool = false,
        errorState: String? = nil,
        configuration: ReviewItemConfiguration = ReviewItemConfiguration()
    ) {
        self.data = data
        self.isLoading = isLoading
        self.errorState = errorState
        self.configuration = configuration
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AsyncImage(url: data.userImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 2) {
                        ForEach(0 ..< 5, id: \.self) { index in
                            Image(systemName: index < data.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }

                        Spacer()

                        Text(data.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Text(data.comment)
                .font(.body)
                .lineLimit(configuration.maxLines)

            if data.isHelpful {
                HStack {
                    Image(systemName: "hand.thumbsup")
                    Text("Helpful")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .componentStyle(configuration)
    }
}

/// Reusable session detail component
struct SessionDetail: View, ReusableComponent {
    typealias Configuration = SessionDetailConfiguration

    let configuration: SessionDetailConfiguration
    let session: SessionData
    let onSelect: ((SessionData) -> Void)?

    init(
        session: SessionData,
        onSelect: ((SessionData) -> Void)? = nil,
        configuration: SessionDetailConfiguration = SessionDetailConfiguration()
    ) {
        self.session = session
        self.onSelect = onSelect
        self.configuration = configuration
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        Button(action: { onSelect?(session) }) {
            HStack(spacing: 16) {
                VStack(alignment: .center, spacing: 4) {
                    Text(session.date.formatted(.dateTime.weekday(.wide)))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(session.date.formatted(.dateTime.day()))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(session.date.formatted(.dateTime.month(.abbreviated)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(session.time)
                        .font(.headline)
                        .fontWeight(.medium)

                    HStack {
                        Image(systemName: "person.2")
                        Text("\(session.spotsLeft) spots left")

                        Spacer()

                        Text("$\(session.price, specifier: "%.0f")")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    if session.isWaitlisted {
                        HStack {
                            Image(systemName: "clock")
                            Text("Join Waitlist")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding()
        .background(.background)
        .cornerRadius(12)
        .componentStyle(configuration)
    }
}

/// Reusable header component
struct ModularHeader: View, HeaderComponent {
    typealias Configuration = HeaderConfiguration

    let configuration: HeaderConfiguration
    let title: String
    let subtitle: String?
    let headerStyle: HeaderStyle
    let actionButton: (() -> AnyView)?

    init(
        title: String,
        subtitle: String? = nil,
        headerStyle: HeaderStyle = .medium,
        configuration: HeaderConfiguration = HeaderConfiguration(),
        @ViewBuilder actionButton: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.headerStyle = headerStyle
        self.configuration = configuration
        self.actionButton = actionButton
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: headerStyle.spacing / 2) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(headerStyle.font)
                        .fontWeight(headerStyle == .featured ? .bold : .semibold)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let actionButton = actionButton {
                    actionButton()
                }
            }
        }
        .padding(.bottom, headerStyle.spacing)
        .componentStyle(configuration)
    }
}

// MARK: - Data Models

struct ReviewData {
    let userName: String
    let userImageURL: URL?
    let rating: Int
    let comment: String
    let date: Date
    let isHelpful: Bool
}

struct SessionData {
    let id: UUID
    let date: Date
    let time: String
    let spotsLeft: Int
    let price: Double
    let isWaitlisted: Bool
}

// MARK: - Configuration Objects

struct GridCellConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        backgroundColor: Color = .background,
        borderColor: Color = .gray.opacity(0.3),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 12
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
}

struct RequirementRowConfiguration: ComponentConfiguration {
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

struct ReviewItemConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let maxLines: Int

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        maxLines: Int = 3
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.maxLines = maxLines
    }
}

struct SessionDetailConfiguration: ComponentConfiguration {
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

struct HeaderConfiguration: ComponentConfiguration {
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
