import SwiftUI

struct SearchResultsList: View {
    let results: [SearchResult]
    let hasMoreResults: Bool
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onResultTap: (SearchResult) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: BrandConstants.Spacing.md) {
                ForEach(results) { result in
                    SearchResultCard(
                        result: result,
                        onTap: { onResultTap(result) }
                    )
                }
                
                // Load More Button
                if hasMoreResults {
                    LoadMoreButton(
                        isLoading: isLoadingMore,
                        onLoadMore: onLoadMore
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Enhanced Search Result Card

struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                // Header with type badge and exact match indicator
                HStack {
                    ResultTypeBadge(result: result)
                    
                    Spacer()
                    
                    if result.isExactMatch {
                        ExactMatchBadge()
                    }
                }
                
                // Content based on result type
                switch result {
                case .class(let hobbyClass):
                    ClassResultContent(hobbyClass: hobbyClass)
                case .instructor(let instructor):
                    InstructorResultContent(instructor: instructor)
                case .venue(let venue):
                    VenueResultContent(venue: venue)
                }
            }
            .padding(BrandConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Result Type Badge

struct ResultTypeBadge: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: BrandConstants.Spacing.xs) {
            Image(systemName: result.typeIcon)
                .font(.system(size: 12, weight: .medium))
            
            Text(result.typeLabel)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, BrandConstants.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(result.typeColor.opacity(0.1))
        )
        .foregroundColor(result.typeColor)
    }
}

// MARK: - Exact Match Badge

struct ExactMatchBadge: View {
    var body: some View {
        HStack(spacing: BrandConstants.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
            
            Text("Exact Match")
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, BrandConstants.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
        .foregroundColor(.green)
    }
}

// MARK: - Class Result Content

struct ClassResultContent: View {
    let hobbyClass: HobbyClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            // Title and Description
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(hobbyClass.title)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(hobbyClass.description)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Class Details Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                ClassDetailItem(
                    icon: "person.circle",
                    label: "Instructor",
                    value: hobbyClass.instructor.name
                )
                
                ClassDetailItem(
                    icon: "location",
                    label: "Location",
                    value: hobbyClass.isOnline ? "Online" : hobbyClass.venue.name
                )
                
                ClassDetailItem(
                    icon: "clock",
                    label: "Duration",
                    value: "\(hobbyClass.duration) min"
                )
                
                ClassDetailItem(
                    icon: "dollarsign.circle",
                    label: "Price",
                    value: hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))"
                )
            }
            
            // Next Session and Rating
            HStack {
                // Next session date
                if hobbyClass.startDate > Date() {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(BrandConstants.Colors.primary)
                        
                        Text("Next: \(formatDate(hobbyClass.startDate))")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.primary)
                    }
                }
                
                Spacer()
                
                // Rating
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(hobbyClass.averageRating) ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    Text(String(format: "%.1f", hobbyClass.averageRating))
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("(\(hobbyClass.totalReviews))")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Availability
            if hobbyClass.enrolledCount < hobbyClass.maxParticipants {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("\(hobbyClass.maxParticipants - hobbyClass.enrolledCount) spots available")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            } else {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text("Fully booked")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Class Detail Item

struct ClassDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(BrandConstants.Colors.primary)
                
                Text(label)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BrandConstants.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Instructor Result Content

struct InstructorResultContent: View {
    let instructor: Instructor
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            // Name and Bio
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(instructor.fullName)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let bio = instructor.bio {
                    Text(bio)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Details Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                if let experience = instructor.yearsOfExperience {
                    InstructorDetailItem(
                        icon: "clock.badge.checkmark",
                        label: "Experience",
                        value: "\(experience) years"
                    )
                }
                
                InstructorDetailItem(
                    icon: "star.fill",
                    label: "Rating",
                    value: instructor.formattedRating
                )
            }
            
            // Specialties
            if !instructor.specialties.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Specialties")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(instructor.specialties.prefix(3), id: \.self) { specialty in
                                Text(specialty)
                                    .font(BrandConstants.Typography.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(BrandConstants.Colors.teal.opacity(0.1))
                                    )
                                    .foregroundColor(BrandConstants.Colors.teal)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Instructor Detail Item

struct InstructorDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(BrandConstants.Colors.teal)
                
                Text(label)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BrandConstants.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Venue Result Content

struct VenueResultContent: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            // Name and Address
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(venue.name)
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(venue.address)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(venue.city), \(venue.state)")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Details Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                VenueDetailItem(
                    icon: "person.3",
                    label: "Capacity",
                    value: "\(venue.capacity) people"
                )
                
                VenueDetailItem(
                    icon: "star.fill",
                    label: "Rating",
                    value: String(format: "%.1f", venue.averageRating)
                )
            }
            
            // Amenities
            if !venue.amenities.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amenities")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(venue.amenities.prefix(4), id: \.self) { amenity in
                                Text(amenity)
                                    .font(BrandConstants.Typography.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(BrandConstants.Colors.coral.opacity(0.1))
                                    )
                                    .foregroundColor(BrandConstants.Colors.coral)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Venue Detail Item

struct VenueDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(BrandConstants.Colors.coral)
                
                Text(label)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BrandConstants.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Load More Button

struct LoadMoreButton: View {
    let isLoading: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        Button(action: onLoadMore) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                    
                    Text("Loading...")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Load More Results")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(BrandConstants.Colors.primary)
            )
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchResultsList(
        results: [],
        hasMoreResults: true,
        isLoadingMore: false,
        onLoadMore: {},
        onResultTap: { _ in }
    )
}