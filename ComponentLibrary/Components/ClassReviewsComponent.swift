import SwiftUI

// MARK: - Refactored Class Reviews Component

struct ClassReviewsComponent: View, DataDisplayComponent {
    typealias Configuration = ClassReviewsConfiguration
    typealias DataType = ReviewsData

    // MARK: - Properties

    let configuration: ClassReviewsConfiguration
    let data: ReviewsData
    let isLoading: Bool
    let errorState: String?
    let onWriteReview: (() -> Void)?
    let onSeeAllReviews: (() -> Void)?

    // MARK: - Initializer

    init(
        reviewsData: ReviewsData,
        isLoading: Bool = false,
        errorState: String? = nil,
        onWriteReview: (() -> Void)? = nil,
        onSeeAllReviews: (() -> Void)? = nil,
        configuration: ClassReviewsConfiguration = ClassReviewsConfiguration()
    ) {
        data = reviewsData
        self.isLoading = isLoading
        self.errorState = errorState
        self.onWriteReview = onWriteReview
        self.onSeeAllReviews = onSeeAllReviews
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ReviewsHeader(
                reviewsData: data,
                onWriteReview: onWriteReview,
                configuration: configuration
            )

            if isLoading {
                ReviewsLoadingView()
            } else if let errorState = errorState {
                ReviewsErrorView(message: errorState)
            } else {
                ReviewsContent(
                    reviewsData: data,
                    onSeeAllReviews: onSeeAllReviews,
                    configuration: configuration
                )
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Reviews Header Sub-Component

struct ReviewsHeader: View {
    let reviewsData: ReviewsData
    let onWriteReview: (() -> Void)?
    let configuration: ClassReviewsConfiguration

    var body: some View {
        ModularHeader(
            title: "Reviews (\(reviewsData.totalCount))",
            subtitle: formattedAverageRating,
            headerStyle: .medium
        ) {
            AnyView(
                Button(action: { onWriteReview?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text("Write Review")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
            )
        }
    }

    private var formattedAverageRating: String {
        "\(reviewsData.averageRating, specifier: "%.1f") ★ average"
    }
}

// MARK: - Reviews Content Sub-Component

struct ReviewsContent: View {
    let reviewsData: ReviewsData
    let onSeeAllReviews: (() -> Void)?
    let configuration: ClassReviewsConfiguration

    var body: some View {
        VStack(spacing: 16) {
            if !reviewsData.ratingBreakdown.isEmpty {
                RatingBreakdown(breakdown: reviewsData.ratingBreakdown)
            }

            ReviewsList(
                reviews: reviewsData.recentReviews,
                maxItems: configuration.maxVisibleReviews
            )

            if reviewsData.totalCount > configuration.maxVisibleReviews {
                SeeAllButton(
                    totalCount: reviewsData.totalCount,
                    visibleCount: configuration.maxVisibleReviews,
                    onTap: onSeeAllReviews
                )
            }
        }
    }
}

// MARK: - Rating Breakdown Sub-Component

struct RatingBreakdown: View {
    let breakdown: [Int: Int] // [rating: count]

    private var totalReviews: Int {
        breakdown.values.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach((1 ... 5).reversed(), id: \.self) { rating in
                let count = breakdown[rating] ?? 0
                let percentage = totalReviews > 0 ? Double(count) / Double(totalReviews) : 0

                RatingBreakdownRow(
                    rating: rating,
                    count: count,
                    percentage: percentage
                )
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

// MARK: - Rating Breakdown Row Sub-Component

struct RatingBreakdownRow: View {
    let rating: Int
    let count: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(1 ... 5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.yellow)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .animation(.easeOut(duration: 0.8), value: percentage)
                }
            }
            .frame(height: 8)

            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Reviews List Sub-Component

struct ReviewsList: View {
    let reviews: [ReviewData]
    let maxItems: Int

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(reviews.prefix(maxItems).enumerated()), id: \.offset) { index, review in
                EnhancedReviewItem(
                    review: review,
                    showDivider: index < min(reviews.count, maxItems) - 1
                )
            }
        }
    }
}

// MARK: - Enhanced Review Item Sub-Component

struct EnhancedReviewItem: View, InteractiveComponent {
    typealias Configuration = ReviewItemConfiguration
    typealias Action = ReviewAction

    let configuration: ReviewItemConfiguration
    let review: ReviewData
    let showDivider: Bool
    let onAction: ((ReviewAction) -> Void)?

    @State private var isExpanded = false
    @State private var isHelpful = false

    init(
        review: ReviewData,
        showDivider: Bool = false,
        configuration: ReviewItemConfiguration = ReviewItemConfiguration()
    ) {
        self.review = review
        self.showDivider = showDivider
        self.configuration = configuration
        onAction = nil
        _isHelpful = State(initialValue: review.isHelpful)
    }

    var body: some View {
        buildContent()
    }

    @ViewBuilder
    func buildContent() -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                ReviewHeader(review: review)

                ReviewContent(
                    review: review,
                    isExpanded: isExpanded,
                    maxLines: configuration.maxLines
                ) {
                    withAnimation(.easeInOut(duration: configuration.animationDuration)) {
                        isExpanded.toggle()
                    }
                }

                ReviewActions(
                    review: review,
                    isHelpful: $isHelpful,
                    onHelpfulTap: {
                        onAction?(.markHelpful(!isHelpful))
                        isHelpful.toggle()
                    },
                    onReply: { onAction?(.reply) }
                )
            }
            .padding()
            .background(.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.1), lineWidth: 1)
            )

            if showDivider {
                Divider()
                    .padding(.vertical, 8)
            }
        }
        .componentStyle(configuration)
    }

    enum ReviewAction {
        case markHelpful(Bool)
        case reply
        case report
    }
}

// MARK: - Review Header Sub-Component

struct ReviewHeader: View {
    let review: ReviewData

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: review.userImageURL) { image in
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
                HStack {
                    Text(review.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if review.isVerifiedPurchase {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }

                    Spacer()

                    Text(review.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    RatingStars(rating: review.rating)

                    if review.attendedClasses > 1 {
                        Text("• \(review.attendedClasses) classes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Review Content Sub-Component

struct ReviewContent: View {
    let review: ReviewData
    let isExpanded: Bool
    let maxLines: Int
    let onToggle: () -> Void

    private var shouldShowToggle: Bool {
        review.comment.count > 200 // Approximate character limit for truncation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(review.comment)
                .font(.body)
                .lineLimit(isExpanded ? nil : maxLines)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)

            if shouldShowToggle {
                Button(action: onToggle) {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            if !review.images.isEmpty {
                ReviewImages(images: review.images)
            }
        }
    }
}

// MARK: - Review Images Sub-Component

struct ReviewImages: View {
    let images: [URL]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, imageURL in
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Review Actions Sub-Component

struct ReviewActions: View {
    let review: ReviewData
    @Binding var isHelpful: Bool
    let onHelpfulTap: () -> Void
    let onReply: () -> Void

    var body: some View {
        HStack {
            Button(action: onHelpfulTap) {
                HStack(spacing: 4) {
                    Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    Text("Helpful (\(review.helpfulCount))")
                }
                .font(.caption)
                .foregroundColor(isHelpful ? .accentColor : .secondary)
            }

            Spacer()

            Button(action: onReply) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left")
                    Text("Reply")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Rating Stars Sub-Component

struct RatingStars: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1 ... 5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

// MARK: - See All Button Sub-Component

struct SeeAllButton: View {
    let totalCount: Int
    let visibleCount: Int
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack {
                Text("See All \(totalCount) Reviews")
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.accentColor)
            .padding()
            .background(.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading and Error Views

struct ReviewsLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 3, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 60)
                    }
                }
                .padding()
            }
        }
        .background(.background)
        .cornerRadius(12)
        .shimmering()
    }
}

struct ReviewsErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to Load Reviews")
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

struct ReviewsData {
    let totalCount: Int
    let averageRating: Double
    let ratingBreakdown: [Int: Int] // [rating: count]
    let recentReviews: [ReviewData]
}

struct ReviewData: Identifiable {
    let id = UUID()
    let userName: String
    let userImageURL: URL?
    let rating: Int
    let comment: String
    let date: Date
    let isHelpful: Bool
    let helpfulCount: Int
    let isVerifiedPurchase: Bool
    let attendedClasses: Int
    let images: [URL]

    init(
        userName: String,
        userImageURL: URL? = nil,
        rating: Int,
        comment: String,
        date: Date,
        isHelpful: Bool = false,
        helpfulCount: Int = 0,
        isVerifiedPurchase: Bool = false,
        attendedClasses: Int = 1,
        images: [URL] = []
    ) {
        self.userName = userName
        self.userImageURL = userImageURL
        self.rating = rating
        self.comment = comment
        self.date = date
        self.isHelpful = isHelpful
        self.helpfulCount = helpfulCount
        self.isVerifiedPurchase = isVerifiedPurchase
        self.attendedClasses = attendedClasses
        self.images = images
    }
}

// MARK: - Configuration Objects

struct ClassReviewsConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let maxVisibleReviews: Int
    let showRatingBreakdown: Bool
    let allowReviewActions: Bool

    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        maxVisibleReviews: Int = 3,
        showRatingBreakdown: Bool = true,
        allowReviewActions: Bool = true
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.maxVisibleReviews = maxVisibleReviews
        self.showRatingBreakdown = showRatingBreakdown
        self.allowReviewActions = allowReviewActions
    }
}
