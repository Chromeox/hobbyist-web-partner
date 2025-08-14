import SwiftUI

// MARK: - Refactored Class Header Component

struct ClassHeaderComponent: View, DataDisplayComponent {
    typealias Configuration = ClassHeaderConfiguration
    typealias DataType = ClassHeaderData
    
    // MARK: - Properties
    let configuration: ClassHeaderConfiguration
    let data: ClassHeaderData
    let isLoading: Bool
    let errorState: String?
    let onFavoriteToggle: ((Bool) -> Void)?
    let onShareTap: (() -> Void)?
    let onBookNow: (() -> Void)?
    
    // MARK: - State
    @State private var isFavorited = false
    @State private var showImageGallery = false
    
    // MARK: - Initializer
    init(
        classHeaderData: ClassHeaderData,
        isLoading: Bool = false,
        errorState: String? = nil,
        onFavoriteToggle: ((Bool) -> Void)? = nil,
        onShareTap: (() -> Void)? = nil,
        onBookNow: (() -> Void)? = nil,
        configuration: ClassHeaderConfiguration = ClassHeaderConfiguration()
    ) {
        self.data = classHeaderData
        self.isLoading = isLoading
        self.errorState = errorState
        self.onFavoriteToggle = onFavoriteToggle
        self.onShareTap = onShareTap
        self.onBookNow = onBookNow
        self.configuration = configuration
        self._isFavorited = State(initialValue: classHeaderData.isFavorited)
    }
    
    // MARK: - Body
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        if isLoading {
            ClassHeaderLoadingView()
        } else if let errorState = errorState {
            ClassHeaderErrorView(message: errorState)
        } else {
            ClassHeaderContent(
                classHeaderData: data,
                isFavorited: $isFavorited,
                showImageGallery: $showImageGallery,
                onFavoriteToggle: onFavoriteToggle,
                onShareTap: onShareTap,
                onBookNow: onBookNow,
                configuration: configuration
            )
        }
    }
}

// MARK: - Class Header Content Sub-Component

struct ClassHeaderContent: View {
    let classHeaderData: ClassHeaderData
    @Binding var isFavorited: Bool
    @Binding var showImageGallery: Bool
    let onFavoriteToggle: ((Bool) -> Void)?
    let onShareTap: (() -> Void)?
    let onBookNow: (() -> Void)?
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        VStack(spacing: 0) {
            if configuration.showHeroImage {
                ClassHeroSection(
                    classHeaderData: classHeaderData,
                    showImageGallery: $showImageGallery,
                    configuration: configuration
                )
            }
            
            ClassInfoSection(
                classHeaderData: classHeaderData,
                isFavorited: $isFavorited,
                onFavoriteToggle: onFavoriteToggle,
                onShareTap: onShareTap,
                configuration: configuration
            )
            
            if configuration.showActionButtons {
                ClassActionSection(
                    classHeaderData: classHeaderData,
                    onBookNow: onBookNow,
                    configuration: configuration
                )
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Class Hero Section Sub-Component

struct ClassHeroSection: View {
    let classHeaderData: ClassHeaderData
    @Binding var showImageGallery: Bool
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ClassHeroImage(
                imageURL: classHeaderData.heroImageURL,
                images: classHeaderData.additionalImages,
                onImageTap: { showImageGallery = true }
            )
            .frame(height: configuration.heroImageHeight)
            
            HeroImageOverlay(
                hasMultipleImages: classHeaderData.additionalImages.count > 1,
                imageCount: classHeaderData.additionalImages.count + 1
            )
        }
        .sheet(isPresented: $showImageGallery) {
            ClassImageGallery(
                images: [classHeaderData.heroImageURL] + classHeaderData.additionalImages,
                classTitle: classHeaderData.title
            )
        }
    }
}

// MARK: - Class Hero Image Sub-Component

struct ClassHeroImage: View {
    let imageURL: URL?
    let images: [URL]
    let onImageTap: () -> Void
    
    var body: some View {
        Button(action: onImageTap) {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            
                            Text("Class Photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
        .buttonStyle(.plain)
        .clipped()
    }
}

// MARK: - Hero Image Overlay Sub-Component

struct HeroImageOverlay: View {
    let hasMultipleImages: Bool
    let imageCount: Int
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                if hasMultipleImages {
                    ImageCountBadge(count: imageCount)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Image Count Badge Sub-Component

struct ImageCountBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.stack")
                .font(.caption)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.7))
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

// MARK: - Class Info Section Sub-Component

struct ClassInfoSection: View {
    let classHeaderData: ClassHeaderData
    @Binding var isFavorited: Bool
    let onFavoriteToggle: ((Bool) -> Void)?
    let onShareTap: (() -> Void)?
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ClassTitleAndActions(
                title: classHeaderData.title,
                category: classHeaderData.category,
                isFavorited: $isFavorited,
                onFavoriteToggle: onFavoriteToggle,
                onShareTap: onShareTap,
                configuration: configuration
            )
            
            ClassMetadata(
                classHeaderData: classHeaderData,
                configuration: configuration
            )
            
            if configuration.showRating {
                ClassRatingSection(
                    rating: classHeaderData.rating,
                    reviewCount: classHeaderData.reviewCount,
                    configuration: configuration
                )
            }
            
            if configuration.showDescription && !classHeaderData.shortDescription.isEmpty {
                ClassDescriptionSection(
                    description: classHeaderData.shortDescription,
                    configuration: configuration
                )
            }
            
            if configuration.showTags && !classHeaderData.tags.isEmpty {
                ClassTagsSection(
                    tags: classHeaderData.tags,
                    configuration: configuration
                )
            }
        }
        .padding()
    }
}

// MARK: - Class Title and Actions Sub-Component

struct ClassTitleAndActions: View {
    let title: String
    let category: ClassCategory
    @Binding var isFavorited: Bool
    let onFavoriteToggle: ((Bool) -> Void)?
    let onShareTap: (() -> Void)?
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                CategoryBadge(category: category)
            }
            
            Spacer()
            
            ClassHeaderActions(
                isFavorited: $isFavorited,
                onFavoriteToggle: onFavoriteToggle,
                onShareTap: onShareTap
            )
        }
    }
}

// MARK: - Category Badge Sub-Component

struct CategoryBadge: View {
    let category: ClassCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.iconName)
                .font(.caption)
            
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.2))
        .foregroundColor(category.color)
        .cornerRadius(12)
    }
}

// MARK: - Class Header Actions Sub-Component

struct ClassHeaderActions: View {
    @Binding var isFavorited: Bool
    let onFavoriteToggle: ((Bool) -> Void)?
    let onShareTap: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isFavorited.toggle()
                }
                onFavoriteToggle?(isFavorited)
            }) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isFavorited ? .red : .secondary)
                    .scaleEffect(isFavorited ? 1.2 : 1.0)
            }
            .buttonStyle(.plain)
            
            Button(action: { onShareTap?() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Class Metadata Sub-Component

struct ClassMetadata: View {
    let classHeaderData: ClassHeaderData
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                MetadataItem(
                    icon: "clock",
                    title: "Duration",
                    value: "\(classHeaderData.duration) min"
                )
                
                MetadataItem(
                    icon: "person.2",
                    title: "Capacity",
                    value: "\(classHeaderData.maxCapacity) people"
                )
                
                MetadataItem(
                    icon: "flame",
                    title: "Difficulty",
                    value: classHeaderData.difficulty.displayName
                )
            }
            
            HStack(spacing: 16) {
                MetadataItem(
                    icon: "location",
                    title: "Location",
                    value: classHeaderData.locationName
                )
                
                if let equipment = classHeaderData.equipmentProvided, !equipment.isEmpty {
                    MetadataItem(
                        icon: "dumbbell",
                        title: "Equipment",
                        value: "Provided"
                    )
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Metadata Item Sub-Component

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Class Rating Section Sub-Component

struct ClassRatingSection: View {
    let rating: Double
    let reviewCount: Int
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        HStack(spacing: 8) {
            RatingStars(rating: rating, size: .medium)
            
            Text(String(format: "%.1f", rating))
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("(\(reviewCount) reviews)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Rating Stars Sub-Component

struct RatingStars: View {
    let rating: Double
    let size: StarSize
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starIcon(for: star))
                    .font(size.font)
                    .foregroundColor(.yellow)
            }
        }
    }
    
    private func starIcon(for position: Int) -> String {
        let starValue = Double(position)
        if rating >= starValue {
            return "star.fill"
        } else if rating > starValue - 1.0 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
    
    enum StarSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .title3
            }
        }
    }
}

// MARK: - Class Description Section Sub-Component

struct ClassDescriptionSection: View {
    let description: String
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Class")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .lineLimit(configuration.descriptionLineLimit)
        }
    }
}

// MARK: - Class Tags Section Sub-Component

struct ClassTagsSection: View {
    let tags: [ClassTag]
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        TagChip(tag: tag)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Tag Chip Sub-Component

struct TagChip: View {
    let tag: ClassTag
    
    var body: some View {
        Text(tag.name)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(12)
    }
}

// MARK: - Class Action Section Sub-Component

struct ClassActionSection: View {
    let classHeaderData: ClassHeaderData
    let onBookNow: (() -> Void)?
    let configuration: ClassHeaderConfiguration
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let originalPrice = classHeaderData.originalPrice, originalPrice > classHeaderData.price {
                        Text("$\(originalPrice, specifier: "%.0f")")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Text("$\(classHeaderData.price, specifier: "%.0f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                if classHeaderData.spotsLeft <= 5 {
                    Text("\(classHeaderData.spotsLeft) spots left")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            BookNowButton(
                isAvailable: classHeaderData.spotsLeft > 0,
                isWaitlisted: classHeaderData.spotsLeft == 0,
                onBookNow: onBookNow
            )
        }
        .padding()
        .background(.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - Book Now Button Sub-Component

struct BookNowButton: View {
    let isAvailable: Bool
    let isWaitlisted: Bool
    let onBookNow: (() -> Void)?
    
    var body: some View {
        Button(action: { onBookNow?() }) {
            HStack(spacing: 8) {
                Image(systemName: buttonIcon)
                    .font(.subheadline)
                
                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(buttonColor)
            .cornerRadius(25)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable && !isWaitlisted)
    }
    
    private var buttonTitle: String {
        if isWaitlisted {
            return "Join Waitlist"
        } else if isAvailable {
            return "Book Now"
        } else {
            return "Unavailable"
        }
    }
    
    private var buttonIcon: String {
        if isWaitlisted {
            return "clock"
        } else if isAvailable {
            return "calendar.badge.plus"
        } else {
            return "xmark.circle"
        }
    }
    
    private var buttonColor: Color {
        if isWaitlisted {
            return .orange
        } else if isAvailable {
            return .accentColor
        } else {
            return .gray
        }
    }
}

// MARK: - Class Image Gallery Sub-Component

struct ClassImageGallery: View {
    let images: [URL?]
    let classTitle: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView {
                ForEach(images.indices, id: \.self) { index in
                    AsyncImage(url: images[index]) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle(classTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Loading and Error Views

struct ClassHeaderLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 250)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 24)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 16)
                        .frame(width: 120)
                }
                
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.3))
                                .frame(height: 16)
                        }
                    }
                    
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.3))
                    .frame(height: 60)
            }
            .padding()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(width: 80)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 100)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 120, height: 50)
            }
            .padding()
        }
        .shimmering()
    }
}

struct ClassHeaderErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Unable to Load Class")
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

struct ClassHeaderData: Identifiable {
    let id = UUID()
    let title: String
    let shortDescription: String
    let category: ClassCategory
    let difficulty: DifficultyLevel
    let duration: Int
    let maxCapacity: Int
    let spotsLeft: Int
    let price: Double
    let originalPrice: Double?
    let rating: Double
    let reviewCount: Int
    let locationName: String
    let heroImageURL: URL?
    let additionalImages: [URL]
    let tags: [ClassTag]
    let equipmentProvided: [String]?
    let isFavorited: Bool
}

enum ClassCategory {
    case yoga
    case pilates
    case hiit
    case strength
    case cardio
    case dance
    case meditation
    case flexibility
    
    var displayName: String {
        switch self {
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .hiit: return "HIIT"
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .dance: return "Dance"
        case .meditation: return "Meditation"
        case .flexibility: return "Flexibility"
        }
    }
    
    var iconName: String {
        switch self {
        case .yoga: return "figure.mind.and.body"
        case .pilates: return "figure.flexibility"
        case .hiit: return "flame"
        case .strength: return "dumbbell"
        case .cardio: return "heart.circle"
        case .dance: return "music.note"
        case .meditation: return "brain.head.profile"
        case .flexibility: return "figure.flexibility"
        }
    }
    
    var color: Color {
        switch self {
        case .yoga: return .purple
        case .pilates: return .pink
        case .hiit: return .orange
        case .strength: return .blue
        case .cardio: return .red
        case .dance: return .green
        case .meditation: return .indigo
        case .flexibility: return .teal
        }
    }
}

struct ClassTag: Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Configuration Objects

struct ClassHeaderConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let showHeroImage: Bool
    let heroImageHeight: CGFloat
    let showRating: Bool
    let showDescription: Bool
    let showTags: Bool
    let showActionButtons: Bool
    let descriptionLineLimit: Int?
    
    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        showHeroImage: Bool = true,
        heroImageHeight: CGFloat = 250,
        showRating: Bool = true,
        showDescription: Bool = true,
        showTags: Bool = true,
        showActionButtons: Bool = true,
        descriptionLineLimit: Int? = 3
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.showHeroImage = showHeroImage
        self.heroImageHeight = heroImageHeight
        self.showRating = showRating
        self.showDescription = showDescription
        self.showTags = showTags
        self.showActionButtons = showActionButtons
        self.descriptionLineLimit = descriptionLineLimit
    }
}