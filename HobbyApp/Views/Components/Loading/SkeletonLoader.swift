import SwiftUI

/// Skeleton loading system for smooth content transitions
/// Provides shimmer effects that match actual content layouts
struct SkeletonLoader: View {
    let type: SkeletonType
    
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        switch type {
        case .classCard:
            ClassCardSkeleton()
        case .instructorProfile:
            InstructorProfileSkeleton()
        case .searchResult:
            SearchResultSkeleton()
        case .bookingItem:
            BookingItemSkeleton()
        case .textLine(let width):
            TextLineSkeleton(width: width)
        case .avatar(let size):
            AvatarSkeleton(size: size)
        }
    }
}

enum SkeletonType {
    case classCard
    case instructorProfile
    case searchResult
    case bookingItem
    case textLine(width: CGFloat)
    case avatar(size: CGFloat)
}

// MARK: - Skeleton Components

/// Class card skeleton matching ClassItemView layout
private struct ClassCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            // Image placeholder
            ShimmerRectangle(height: 120)
                .cornerRadius(BrandConstants.CornerRadius.md)
            
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                // Title
                ShimmerRectangle(height: 16, width: 180)
                
                // Instructor name
                ShimmerRectangle(height: 14, width: 120)
                
                // Price and time
                HStack {
                    ShimmerRectangle(height: 14, width: 60)
                    Spacer()
                    ShimmerRectangle(height: 14, width: 80)
                }
            }
            .padding(.horizontal, BrandConstants.Spacing.sm)
            .padding(.bottom, BrandConstants.Spacing.sm)
        }
        .background(Color(.systemBackground))
        .cornerRadius(BrandConstants.CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

/// Instructor profile skeleton
private struct InstructorProfileSkeleton: View {
    var body: some View {
        HStack(spacing: BrandConstants.Spacing.md) {
            // Avatar
            ShimmerCircle(size: 60)
            
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                // Name
                ShimmerRectangle(height: 16, width: 140)
                
                // Specialties
                ShimmerRectangle(height: 14, width: 100)
                
                // Rating
                HStack(spacing: BrandConstants.Spacing.xs) {
                    ForEach(0..<5, id: \.self) { _ in
                        ShimmerRectangle(height: 12, width: 12)
                    }
                    ShimmerRectangle(height: 12, width: 40)
                }
            }
            
            Spacer()
        }
        .padding(BrandConstants.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

/// Search result skeleton
private struct SearchResultSkeleton: View {
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: BrandConstants.Spacing.md) {
                    // Image
                    ShimmerRectangle(height: 80, width: 80)
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                    
                    VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                        // Type badge
                        ShimmerRectangle(height: 12, width: 50)
                        
                        // Title
                        ShimmerRectangle(height: 16, width: 160)
                        
                        // Subtitle
                        ShimmerRectangle(height: 14, width: 120)
                        
                        // Details
                        ShimmerRectangle(height: 12, width: 100)
                    }
                    
                    Spacer()
                }
                .padding(BrandConstants.Spacing.md)
                .background(Color(.systemBackground))
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
        }
    }
}

/// Booking item skeleton
private struct BookingItemSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            HStack {
                // Status indicator
                ShimmerCircle(size: 12)
                
                // Class name
                ShimmerRectangle(height: 16, width: 150)
                
                Spacer()
                
                // Price
                ShimmerRectangle(height: 14, width: 60)
            }
            
            // Date and time
            ShimmerRectangle(height: 14, width: 200)
            
            // Location
            ShimmerRectangle(height: 12, width: 180)
        }
        .padding(BrandConstants.Spacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

/// Text line skeleton with customizable width
private struct TextLineSkeleton: View {
    let width: CGFloat
    
    var body: some View {
        ShimmerRectangle(height: 16, width: width)
    }
}

/// Avatar skeleton with customizable size
private struct AvatarSkeleton: View {
    let size: CGFloat
    
    var body: some View {
        ShimmerCircle(size: size)
    }
}

// MARK: - Base Shimmer Components

/// Base shimmer rectangle with animated gradient
private struct ShimmerRectangle: View {
    let height: CGFloat
    let width: CGFloat?
    
    @State private var shimmerOffset: CGFloat = -200
    
    init(height: CGFloat, width: CGFloat? = nil) {
        self.height = height
        self.width = width
    }
    
    var body: some View {
        Rectangle()
            .fill(shimmerGradient)
            .frame(height: height)
            .frame(width: width)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGray6),
                Color(.systemGray5),
                Color(.systemGray6)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// Base shimmer circle
private struct ShimmerCircle: View {
    let size: CGFloat
    
    @State private var shimmerOffset: CGFloat = -100
    
    var body: some View {
        Circle()
            .fill(shimmerGradient)
            .frame(width: size, height: size)
            .mask(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 100
                }
            }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemGray6),
                Color(.systemGray5),
                Color(.systemGray6)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - List Skeleton Containers

/// Skeleton loader for lists of content
struct SkeletonList: View {
    let type: SkeletonType
    let count: Int
    
    init(_ type: SkeletonType, count: Int = 3) {
        self.type = type
        self.count = count
    }
    
    var body: some View {
        LazyVStack(spacing: BrandConstants.Spacing.md) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonLoader(type: type)
            }
        }
    }
}

/// Skeleton loader for grid layouts
struct SkeletonGrid: View {
    let type: SkeletonType
    let columns: Int
    let count: Int
    
    init(_ type: SkeletonType, columns: Int = 2, count: Int = 6) {
        self.type = type
        self.columns = columns
        self.count = count
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            spacing: BrandConstants.Spacing.md
        ) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonLoader(type: type)
            }
        }
    }
}

// MARK: - View Modifier for Easy Integration

extension View {
    /// Shows skeleton loading while content is loading
    func skeletonLoading<Content: View>(
        _ isLoading: Bool,
        skeleton: @escaping () -> Content
    ) -> some View {
        Group {
            if isLoading {
                skeleton()
            } else {
                self
            }
        }
    }
    
    /// Shows skeleton loading with default type
    func skeletonLoading(
        _ isLoading: Bool,
        type: SkeletonType,
        count: Int = 3
    ) -> some View {
        Group {
            if isLoading {
                SkeletonList(type, count: count)
            } else {
                self
            }
        }
    }
}

// MARK: - Previews
#Preview("Class Card Skeleton") {
    SkeletonLoader(type: .classCard)
        .padding()
}

#Preview("Instructor Profile Skeleton") {
    SkeletonLoader(type: .instructorProfile)
        .padding()
}

#Preview("Search Results Skeleton") {
    SkeletonLoader(type: .searchResult)
        .padding()
}

#Preview("Skeleton List") {
    ScrollView {
        SkeletonList(.classCard, count: 5)
            .padding()
    }
}

#Preview("Skeleton Grid") {
    ScrollView {
        SkeletonGrid(.classCard, columns: 2, count: 6)
            .padding()
    }
}