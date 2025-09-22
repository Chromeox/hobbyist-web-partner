import SwiftUI

// MARK: - Flexible Card Component
// Ready to be styled and used for any content

struct HobbyistCard<Content: View>: View {
    let content: () -> Content
    let style: CardStyle
    let padding: CGFloat
    let tapAction: (() -> Void)?

    init(
        style: CardStyle = .default,
        padding: CGFloat = HobbyistSpacing.md,
        tapAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.tapAction = tapAction
        self.content = content
    }

    var body: some View {
        Group {
            if let tapAction = tapAction {
                Button(action: tapAction) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        content()
            .padding(padding)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .hobbyistShadow(style.shadowStyle)
    }
}

// MARK: - Card Styles
extension HobbyistCard {
    enum CardStyle {
        case `default`, elevated, outlined, minimal

        var backgroundColor: Color {
            switch self {
            case .default, .elevated, .outlined: return .hobbyistSurface
            case .minimal: return .clear
            }
        }

        var borderColor: Color {
            switch self {
            case .default, .elevated, .minimal: return .clear
            case .outlined: return Color.gray.opacity(0.2)
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .default, .elevated, .minimal: return 0
            case .outlined: return 1
            }
        }

        var cornerRadius: CGFloat {
            HobbyistRadius.lg
        }

        var shadowStyle: HobbyistShadow {
            switch self {
            case .default, .outlined, .minimal: return .small
            case .elevated: return .large
            }
        }
    }
}

// MARK: - Class Card Example
struct ClassCard: View {
    let className: String
    let instructor: String
    let time: String
    let price: String
    let image: String?
    let onTap: () -> Void

    var body: some View {
        HobbyistCard(style: .elevated, tapAction: onTap) {
            VStack(alignment: .leading, spacing: HobbyistSpacing.sm) {
                // Image placeholder
                if let image = image {
                    AsyncImage(url: URL(string: image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: HobbyistRadius.md))
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.hobbyistPrimary.opacity(0.7), .hobbyistSecondary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: HobbyistRadius.md))
                        .overlay(
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        )
                }

                // Class info
                VStack(alignment: .leading, spacing: HobbyistSpacing.xs) {
                    Text(className)
                        .font(.hobbyistHeadline())
                        .fontWeight(.semibold)
                        .foregroundColor(.hobbyistTextPrimary)
                        .lineLimit(2)

                    Text(instructor)
                        .font(.hobbyistCallout())
                        .foregroundColor(.hobbyistTextSecondary)

                    HStack {
                        Text(time)
                            .font(.hobbyistCaption())
                            .foregroundColor(.hobbyistTextTertiary)

                        Spacer()

                        Text(price)
                            .font(.hobbyistCallout())
                            .fontWeight(.semibold)
                            .foregroundColor(.hobbyistPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Studio Card Example
struct StudioCard: View {
    let studioName: String
    let location: String
    let rating: Double
    let distance: String
    let image: String?
    let onTap: () -> Void

    var body: some View {
        HobbyistCard(tapAction: onTap) {
            HStack(spacing: HobbyistSpacing.md) {
                // Studio image
                if let image = image {
                    AsyncImage(url: URL(string: image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: HobbyistRadius.md))
                } else {
                    Rectangle()
                        .fill(Color.hobbyistSecondary.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: HobbyistRadius.md))
                        .overlay(
                            Image(systemName: "building.2.crop.circle")
                                .font(.title2)
                                .foregroundColor(.hobbyistSecondary)
                        )
                }

                // Studio info
                VStack(alignment: .leading, spacing: HobbyistSpacing.xs) {
                    Text(studioName)
                        .font(.hobbyistHeadline())
                        .fontWeight(.semibold)
                        .foregroundColor(.hobbyistTextPrimary)

                    Text(location)
                        .font(.hobbyistCallout())
                        .foregroundColor(.hobbyistTextSecondary)
                        .lineLimit(2)

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)

                            Text(String(format: "%.1f", rating))
                                .font(.hobbyistCaption())
                                .foregroundColor(.hobbyistTextTertiary)
                        }

                        Spacer()

                        Text(distance)
                            .font(.hobbyistCaption())
                            .foregroundColor(.hobbyistTextTertiary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: HobbyistSpacing.md) {
            HobbyistCard(style: .default) {
                Text("Default Card")
                    .font(.hobbyistBody())
                    .padding()
            }

            HobbyistCard(style: .elevated) {
                Text("Elevated Card")
                    .font(.hobbyistBody())
                    .padding()
            }

            HobbyistCard(style: .outlined) {
                Text("Outlined Card")
                    .font(.hobbyistBody())
                    .padding()
            }

            ClassCard(
                className: "Power Yoga Flow",
                instructor: "Sarah Johnson",
                time: "Today 6:00 PM",
                price: "$25",
                image: nil
            ) {
                print("Class card tapped")
            }

            StudioCard(
                studioName: "Zen Fitness Studio",
                location: "123 Main St, Vancouver",
                rating: 4.8,
                distance: "0.5 km",
                image: nil
            ) {
                print("Studio card tapped")
            }
        }
        .padding()
    }
}