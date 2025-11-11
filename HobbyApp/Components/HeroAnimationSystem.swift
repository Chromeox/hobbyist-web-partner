import SwiftUI

// MARK: - Hero Animation System for Phase 3 Final

/// Coordinates hero animations between source and destination views
@MainActor
public class HeroAnimationCoordinator: ObservableObject {
    static let shared = HeroAnimationCoordinator()

    @Published var activeTransitions: Set<String> = []
    @Published var transitionProgress: [String: Double] = [:]

    private init() {}

    func startTransition(for heroID: String) {
        withAnimation(.easeInOut(duration: 0.4)) {
            activeTransitions.insert(heroID)
            transitionProgress[heroID] = 1.0
        }
    }

    func completeTransition(for heroID: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.activeTransitions.remove(heroID)
                self.transitionProgress.removeValue(forKey: heroID)
            }
        }
    }
}

// MARK: - Hero Animation View Modifier

public struct HeroAnimationModifier: ViewModifier {
    let heroID: String
    let namespace: Namespace.ID
    let animationType: HeroAnimationType

    @StateObject private var coordinator = HeroAnimationCoordinator.shared
    @State private var isVisible = true

    public func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(
                id: heroID,
                in: namespace,
                properties: animationType.geometryProperties,
                anchor: animationType.anchor,
                isSource: !coordinator.activeTransitions.contains(heroID)
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.98)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
            .onChange(of: coordinator.activeTransitions.contains(heroID)) { isActive in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isVisible = !isActive || animationType.maintainVisibilityDuringTransition
                }
            }
    }
}

public extension View {
    func heroAnimation(
        id: String,
        in namespace: Namespace.ID,
        type: HeroAnimationType = .default
    ) -> some View {
        self.modifier(HeroAnimationModifier(
            heroID: id,
            namespace: namespace,
            animationType: type
        ))
    }
}

// MARK: - Hero Animation Configuration

public enum HeroAnimationType {
    case `default`
    case cardToDetail
    case imageTransition
    case textTransition
    case customBounds

    var geometryProperties: MatchedGeometryProperties {
        switch self {
        case .default, .cardToDetail:
            return .frame
        case .imageTransition:
            return [.frame, .position]
        case .textTransition:
            return [.frame, .position]
        case .customBounds:
            return [.frame, .size, .position]
        }
    }

    var anchor: UnitPoint {
        switch self {
        case .default, .cardToDetail, .imageTransition:
            return .center
        case .textTransition:
            return .leading
        case .customBounds:
            return .topLeading
        }
    }

    var maintainVisibilityDuringTransition: Bool {
        switch self {
        case .default, .cardToDetail:
            return false
        case .imageTransition, .textTransition, .customBounds:
            return true
        }
    }
}

// MARK: - Enhanced Class Card with Hero Animation

public struct HeroClassCard: View {
    let classItem: ClassItem
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false

    public init(classItem: ClassItem, namespace: Namespace.ID, onTap: @escaping () -> Void) {
        self.classItem = classItem
        self.namespace = namespace
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: {
            HapticFeedbackService.shared.playSelection()
            HeroAnimationCoordinator.shared.startTransition(for: "class-\(classItem.id)")
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Hero Image
                AsyncImage(url: URL(string: classItem.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .green.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "figure.yoga")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(.white)
                    )
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md))
                .heroAnimation(
                    id: "class-image-\(classItem.id)",
                    in: namespace,
                    type: .imageTransition
                )

                // Class Information
                VStack(alignment: .leading, spacing: 6) {
                    Text(classItem.title)
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .heroAnimation(
                            id: "class-title-\(classItem.id)",
                            in: namespace,
                            type: .textTransition
                        )

                    Text(classItem.instructor)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .heroAnimation(
                            id: "class-instructor-\(classItem.id)",
                            in: namespace,
                            type: .textTransition
                        )

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                            Text(classItem.duration)
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(classItem.price)
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .heroAnimation(
                                id: "class-price-\(classItem.id)",
                                in: namespace,
                                type: .textTransition
                            )
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md))
            .shadow(
                color: .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .heroAnimation(
            id: "class-card-\(classItem.id)",
            in: namespace,
            type: .cardToDetail
        )
    }
}

// MARK: - Hero-Enhanced Class Detail View

public struct HeroClassDetailView: View {
    let classItem: ClassItem
    let namespace: Namespace.ID
    let onDismiss: () -> Void

    @State private var showContent = false

    public init(classItem: ClassItem, namespace: Namespace.ID, onDismiss: @escaping () -> Void) {
        self.classItem = classItem
        self.namespace = namespace
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                AsyncImage(url: URL(string: classItem.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .green.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "figure.yoga")
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(.white)
                    )
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .heroAnimation(
                    id: "class-image-\(classItem.id)",
                    in: namespace,
                    type: .imageTransition
                )

                VStack(alignment: .leading, spacing: 20) {
                    // Class Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(classItem.title)
                            .font(BrandConstants.Typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .heroAnimation(
                                id: "class-title-\(classItem.id)",
                                in: namespace,
                                type: .textTransition
                            )

                        Text(classItem.instructor)
                            .font(BrandConstants.Typography.title3)
                            .foregroundColor(.secondary)
                            .heroAnimation(
                                id: "class-instructor-\(classItem.id)",
                                in: namespace,
                                type: .textTransition
                            )

                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                Text(classItem.duration)
                                    .font(BrandConstants.Typography.headline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(classItem.price)
                                .font(BrandConstants.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .heroAnimation(
                                    id: "class-price-\(classItem.id)",
                                    in: namespace,
                                    type: .textTransition
                                )
                        }
                    }

                    // Additional content with staggered animation
                    if showContent {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About This Class")
                                .font(BrandConstants.Typography.headline)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

                            Text(classItem.description)
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(.secondary)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)

                            // Book Now Button
                            AnimatedButton("Book Now", style: .primary) {
                                // Handle booking
                            }
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    HeroAnimationCoordinator.shared.completeTransition(for: "class-\(classItem.id)")
                    onDismiss()
                }
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Sample Data Extension

extension ClassItem {
    static let sampleHero = ClassItem(
        id: "sample-1",
        name: "Morning Yoga Flow",
        category: "Fitness",
        instructor: "Sarah Chen",
        instructorInitials: "SC",
        description: "Start your day with this energizing yoga flow designed for all skill levels. Focus on breath work, gentle stretches, and building mindful movement patterns.",
        duration: "60 minutes",
        difficulty: "All Levels",
        price: "$25",
        creditsRequired: 10,
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
        location: "Studio 1",
        venueName: "Serenity Yoga",
        address: "123 Main St, Vancouver",
        coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
        spotsAvailable: 8,
        totalSpots: 12,
        rating: "4.8",
        reviewCount: "24",
        icon: "figure.yoga",
        categoryColor: .green,
        isFeatured: true,
        requirements: ["Yoga mat", "Water bottle"],
        amenities: [
            Amenity(name: "Showers", icon: "drop.fill"),
            Amenity(name: "WiFi", icon: "wifi")
        ],
        equipment: []
    )
}

// MARK: - Preview

#Preview("Hero Animation System") {
    @Namespace var heroNamespace

    return NavigationStack {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    HeroClassCard(
                        classItem: ClassItem.sampleHero,
                        namespace: heroNamespace
                    ) {
                        // Navigation to detail would be handled here
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Classes")
    }
}