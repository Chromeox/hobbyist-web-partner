import SwiftUI

// MARK: - Refactored Class Instructor Component

struct ClassInstructorComponent: View, DataDisplayComponent {
    typealias Configuration = ClassInstructorConfiguration
    typealias DataType = InstructorData
    
    // MARK: - Properties
    let configuration: ClassInstructorConfiguration
    let data: InstructorData
    let isLoading: Bool
    let errorState: String?
    let onFollowTap: ((InstructorData) -> Void)?
    let onMessageTap: ((InstructorData) -> Void)?
    let onViewProfile: ((InstructorData) -> Void)?
    
    // MARK: - State
    @State private var isFollowing = false
    @State private var showFullBio = false
    
    // MARK: - Initializer
    init(
        instructorData: InstructorData,
        isLoading: Bool = false,
        errorState: String? = nil,
        onFollowTap: ((InstructorData) -> Void)? = nil,
        onMessageTap: ((InstructorData) -> Void)? = nil,
        onViewProfile: ((InstructorData) -> Void)? = nil,
        configuration: ClassInstructorConfiguration = ClassInstructorConfiguration()
    ) {
        self.data = instructorData
        self.isLoading = isLoading
        self.errorState = errorState
        self.onFollowTap = onFollowTap
        self.onMessageTap = onMessageTap
        self.onViewProfile = onViewProfile
        self.configuration = configuration
        self._isFollowing = State(initialValue: instructorData.isFollowing)
    }
    
    // MARK: - Body
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            InstructorHeader(
                instructorData: data,
                configuration: configuration
            )
            
            if isLoading {
                InstructorLoadingView()
            } else if let errorState = errorState {
                InstructorErrorView(message: errorState)
            } else {
                InstructorContent(
                    instructorData: data,
                    isFollowing: $isFollowing,
                    showFullBio: $showFullBio,
                    onFollowTap: onFollowTap,
                    onMessageTap: onMessageTap,
                    onViewProfile: onViewProfile,
                    configuration: configuration
                )
            }
        }
        .componentStyle(configuration)
    }
}

// MARK: - Instructor Header Sub-Component

struct InstructorHeader: View {
    let instructorData: InstructorData
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        ModularHeader(
            title: "Instructor",
            subtitle: instructorData.name,
            headerStyle: .medium
        ) {
            AnyView(
                HStack(spacing: 8) {
                    if configuration.showSocialLinks {
                        SocialLinksButton(socialLinks: instructorData.socialLinks)
                    }
                    
                    Button("View Profile") {
                        // Handle view profile
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
                }
            )
        }
    }
}

// MARK: - Instructor Content Sub-Component

struct InstructorContent: View {
    let instructorData: InstructorData
    @Binding var isFollowing: Bool
    @Binding var showFullBio: Bool
    let onFollowTap: ((InstructorData) -> Void)?
    let onMessageTap: ((InstructorData) -> Void)?
    let onViewProfile: ((InstructorData) -> Void)?
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        VStack(spacing: 16) {
            InstructorProfileCard(
                instructorData: instructorData,
                isFollowing: $isFollowing,
                onFollowTap: onFollowTap,
                onMessageTap: onMessageTap,
                onViewProfile: onViewProfile,
                configuration: configuration
            )
            
            if configuration.showBio {
                InstructorBioSection(
                    bio: instructorData.bio,
                    showFullBio: $showFullBio,
                    configuration: configuration
                )
            }
            
            if configuration.showStats {
                InstructorStatsSection(
                    stats: instructorData.stats,
                    configuration: configuration
                )
            }
            
            if configuration.showSpecialties {
                InstructorSpecialtiesSection(
                    specialties: instructorData.specialties,
                    configuration: configuration
                )
            }
            
            if configuration.showCertifications {
                InstructorCertificationsSection(
                    certifications: instructorData.certifications,
                    configuration: configuration
                )
            }
            
            if configuration.showUpcomingClasses {
                UpcomingClassesSection(
                    upcomingClasses: instructorData.upcomingClasses,
                    configuration: configuration
                )
            }
        }
    }
}

// MARK: - Instructor Profile Card Sub-Component

struct InstructorProfileCard: View, InteractiveComponent {
    typealias Configuration = InstructorProfileConfiguration
    typealias Action = InstructorAction
    
    let configuration: InstructorProfileConfiguration
    let instructorData: InstructorData
    @Binding var isFollowing: Bool
    let onAction: ((InstructorAction) -> Void)?
    
    init(
        instructorData: InstructorData,
        isFollowing: Binding<Bool>,
        onFollowTap: ((InstructorData) -> Void)? = nil,
        onMessageTap: ((InstructorData) -> Void)? = nil,
        onViewProfile: ((InstructorData) -> Void)? = nil,
        configuration: ClassInstructorConfiguration
    ) {
        self.instructorData = instructorData
        self._isFollowing = isFollowing
        self.configuration = InstructorProfileConfiguration()
        self.onAction = { action in
            switch action {
            case .follow:
                onFollowTap?(instructorData)
            case .message:
                onMessageTap?(instructorData)
            case .viewProfile:
                onViewProfile?(instructorData)
            }
        }
    }
    
    var body: some View {
        buildContent()
    }
    
    @ViewBuilder
    func buildContent() -> some View {
        HStack(spacing: 16) {
            InstructorAvatar(
                imageURL: instructorData.imageURL,
                isVerified: instructorData.isVerified,
                size: .large
            )
            
            VStack(alignment: .leading, spacing: 8) {
                InstructorNameAndTitle(
                    name: instructorData.name,
                    title: instructorData.title,
                    isVerified: instructorData.isVerified
                )
                
                InstructorRatingAndExperience(
                    rating: instructorData.rating,
                    reviewCount: instructorData.reviewCount,
                    experienceYears: instructorData.experienceYears
                )
                
                InstructorActions(
                    isFollowing: $isFollowing,
                    followerCount: instructorData.followerCount,
                    onFollowTap: { onAction?(.follow) },
                    onMessageTap: { onAction?(.message) },
                    configuration: configuration
                )
            }
            
            Spacer()
        }
        .padding()
        .background(.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .componentStyle(configuration)
    }
    
    enum InstructorAction {
        case follow
        case message
        case viewProfile
    }
}

// MARK: - Instructor Avatar Sub-Component

struct InstructorAvatar: View {
    let imageURL: URL?
    let isVerified: Bool
    let size: AvatarSize
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.background, lineWidth: 2)
            )
            
            if isVerified {
                VerificationBadge(size: size)
            }
        }
    }
    
    enum AvatarSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            }
        }
        
        var badgeSize: CGFloat {
            dimension * 0.25
        }
    }
}

// MARK: - Verification Badge Sub-Component

struct VerificationBadge: View {
    let size: InstructorAvatar.AvatarSize
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue)
                .frame(width: size.badgeSize, height: size.badgeSize)
            
            Image(systemName: "checkmark")
                .font(.system(size: size.badgeSize * 0.6, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Instructor Name and Title Sub-Component

struct InstructorNameAndTitle: View {
    let name: String
    let title: String?
    let isVerified: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Instructor Rating and Experience Sub-Component

struct InstructorRatingAndExperience: View {
    let rating: Double
    let reviewCount: Int
    let experienceYears: Int
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(String(format: "%.1f", rating))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(reviewCount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(experienceYears) years")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Instructor Actions Sub-Component

struct InstructorActions: View {
    @Binding var isFollowing: Bool
    let followerCount: Int
    let onFollowTap: () -> Void
    let onMessageTap: () -> Void
    let configuration: InstructorProfileConfiguration
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFollowing.toggle()
                }
                onFollowTap()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isFollowing ? "person.fill.checkmark" : "person.badge.plus")
                    Text(isFollowing ? "Following" : "Follow")
                    Text("(\(followerCount))")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isFollowing ? .green.opacity(0.1) : .accentColor.opacity(0.1))
                .foregroundColor(isFollowing ? .green : .accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Button(action: onMessageTap) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                    Text("Message")
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.1))
                .foregroundColor(.primary)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Instructor Bio Section Sub-Component

struct InstructorBioSection: View {
    let bio: String?
    @Binding var showFullBio: Bool
    let configuration: ClassInstructorConfiguration
    
    private var shouldShowToggle: Bool {
        guard let bio = bio else { return false }
        return bio.count > 150
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let bio = bio {
                Text(bio)
                    .font(.subheadline)
                    .lineLimit(showFullBio ? nil : 3)
                    .animation(.easeInOut(duration: configuration.animationDuration), value: showFullBio)
                
                if shouldShowToggle {
                    Button(action: { showFullBio.toggle() }) {
                        Text(showFullBio ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
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

// MARK: - Instructor Stats Section Sub-Component

struct InstructorStatsSection: View {
    let stats: InstructorStats
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                StatItem(
                    title: "Classes Taught",
                    value: "\(stats.classesTaught)",
                    icon: "graduationcap"
                )
                
                StatItem(
                    title: "Students",
                    value: "\(stats.totalStudents)",
                    icon: "person.2"
                )
                
                StatItem(
                    title: "Avg Rating",
                    value: String(format: "%.1f", stats.averageRating),
                    icon: "star"
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

// MARK: - Stat Item Sub-Component

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Instructor Specialties Section Sub-Component

struct InstructorSpecialtiesSection: View {
    let specialties: [Specialty]
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specialties")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(specialties, id: \.id) { specialty in
                    SpecialtyChip(specialty: specialty)
                }
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

// MARK: - Specialty Chip Sub-Component

struct SpecialtyChip: View {
    let specialty: Specialty
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: specialty.iconName)
                .font(.caption)
                .foregroundColor(specialty.color)
            
            Text(specialty.name)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(specialty.color.opacity(0.1))
        .foregroundColor(specialty.color)
        .cornerRadius(12)
    }
}

// MARK: - Instructor Certifications Section Sub-Component

struct InstructorCertificationsSection: View {
    let certifications: [Certification]
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(certifications, id: \.id) { certification in
                    CertificationRow(certification: certification)
                }
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

// MARK: - Certification Row Sub-Component

struct CertificationRow: View {
    let certification: Certification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(certification.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(certification.organization)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let expiryDate = certification.expiryDate {
                    Text("Expires: \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if certification.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Upcoming Classes Section Sub-Component

struct UpcomingClassesSection: View {
    let upcomingClasses: [UpcomingClass]
    let configuration: ClassInstructorConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Classes")
                .font(.headline)
                .fontWeight(.semibold)
            
            if upcomingClasses.isEmpty {
                Text("No upcoming classes scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(upcomingClasses.prefix(3), id: \.id) { upcomingClass in
                        UpcomingClassRow(upcomingClass: upcomingClass)
                    }
                    
                    if upcomingClasses.count > 3 {
                        Button("View All Classes") {
                            // Handle view all action
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                    }
                }
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

// MARK: - Upcoming Class Row Sub-Component

struct UpcomingClassRow: View {
    let upcomingClass: UpcomingClass
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 2) {
                Text(upcomingClass.date.formatted(.dateTime.day()))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(upcomingClass.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(upcomingClass.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(upcomingClass.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text("\(upcomingClass.spotsLeft) spots left")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("$\(upcomingClass.price, specifier: "%.0f")")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            Button("Book") {
                // Handle booking
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.accentColor)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Social Links Button Sub-Component

struct SocialLinksButton: View {
    let socialLinks: [SocialLink]
    @State private var showingSocialLinks = false
    
    var body: some View {
        Button(action: { showingSocialLinks.toggle() }) {
            Image(systemName: "link")
                .foregroundColor(.accentColor)
        }
        .popover(isPresented: $showingSocialLinks) {
            SocialLinksPopover(socialLinks: socialLinks)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Social Links Popover Sub-Component

struct SocialLinksPopover: View {
    let socialLinks: [SocialLink]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Social Links")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(socialLinks, id: \.id) { link in
                Button(action: { /* Open link */ }) {
                    HStack(spacing: 8) {
                        Image(systemName: link.platform.iconName)
                            .foregroundColor(link.platform.color)
                        
                        Text(link.platform.displayName)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(minWidth: 150)
    }
}

// MARK: - Loading and Error Views

struct InstructorLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 100)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 12)
                        .frame(width: 120)
                }
                
                Spacer()
            }
            .padding()
            
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.3))
                        .frame(height: 60)
                }
            }
        }
        .shimmering()
    }
}

struct InstructorErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Unable to Load Instructor")
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

struct InstructorData: Identifiable {
    let id = UUID()
    let name: String
    let title: String?
    let imageURL: URL?
    let bio: String?
    let rating: Double
    let reviewCount: Int
    let experienceYears: Int
    let isVerified: Bool
    let isFollowing: Bool
    let followerCount: Int
    let specialties: [Specialty]
    let certifications: [Certification]
    let stats: InstructorStats
    let socialLinks: [SocialLink]
    let upcomingClasses: [UpcomingClass]
}

struct InstructorStats {
    let classesTaught: Int
    let totalStudents: Int
    let averageRating: Double
}

struct Specialty: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let color: Color
}

struct Certification: Identifiable {
    let id = UUID()
    let name: String
    let organization: String
    let issueDate: Date
    let expiryDate: Date?
    let isVerified: Bool
}

struct SocialLink: Identifiable {
    let id = UUID()
    let platform: SocialPlatform
    let url: URL
}

enum SocialPlatform {
    case instagram
    case facebook
    case twitter
    case youtube
    case tiktok
    case linkedin
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .twitter: return "Twitter"
        case .youtube: return "YouTube"
        case .tiktok: return "TikTok"
        case .linkedin: return "LinkedIn"
        }
    }
    
    var iconName: String {
        switch self {
        case .instagram: return "camera"
        case .facebook: return "f.circle"
        case .twitter: return "bird"
        case .youtube: return "play.rectangle"
        case .tiktok: return "music.note"
        case .linkedin: return "person.badge.plus"
        }
    }
    
    var color: Color {
        switch self {
        case .instagram: return .pink
        case .facebook: return .blue
        case .twitter: return .cyan
        case .youtube: return .red
        case .tiktok: return .black
        case .linkedin: return .blue
        }
    }
}

struct UpcomingClass: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let time: String
    let spotsLeft: Int
    let price: Double
}

// MARK: - Configuration Objects

struct ClassInstructorConfiguration: ComponentConfiguration {
    let isAccessibilityEnabled: Bool
    let animationDuration: Double
    let showBio: Bool
    let showStats: Bool
    let showSpecialties: Bool
    let showCertifications: Bool
    let showUpcomingClasses: Bool
    let showSocialLinks: Bool
    
    init(
        isAccessibilityEnabled: Bool = true,
        animationDuration: Double = 0.3,
        showBio: Bool = true,
        showStats: Bool = true,
        showSpecialties: Bool = true,
        showCertifications: Bool = true,
        showUpcomingClasses: Bool = true,
        showSocialLinks: Bool = true
    ) {
        self.isAccessibilityEnabled = isAccessibilityEnabled
        self.animationDuration = animationDuration
        self.showBio = showBio
        self.showStats = showStats
        self.showSpecialties = showSpecialties
        self.showCertifications = showCertifications
        self.showUpcomingClasses = showUpcomingClasses
        self.showSocialLinks = showSocialLinks
    }
}

struct InstructorProfileConfiguration: ComponentConfiguration {
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