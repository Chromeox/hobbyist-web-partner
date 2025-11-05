import SwiftUI

struct SearchDiscoveryView: View {
    let recentSearches: [String]
    let popularSearches: [String]
    let trendingCategories: [TrendingCategory]
    let suggestedClasses: [HobbyClass]
    let nearbyClasses: [HobbyClass]
    let savedSearches: [SavedSearch]
    
    let onRecentSearchTap: (String) -> Void
    let onPopularSearchTap: (String) -> Void
    let onCategoryTap: (ClassCategory) -> Void
    let onSavedSearchTap: (SavedSearch) -> Void
    let onQuickActionTap: (QuickAction) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: BrandConstants.Spacing.lg) {
                
                // Quick Actions Section
                QuickActionsSection(onActionTap: onQuickActionTap)
                
                // Saved Searches (if any)
                if !savedSearches.isEmpty {
                    SavedSearchesSection(
                        savedSearches: savedSearches,
                        onSavedSearchTap: onSavedSearchTap
                    )
                }
                
                // Recent Searches (if any)
                if !recentSearches.isEmpty {
                    RecentSearchesSection(
                        recentSearches: recentSearches,
                        onRecentSearchTap: onRecentSearchTap
                    )
                }
                
                // Trending Categories
                TrendingCategoriesSection(
                    trendingCategories: trendingCategories,
                    onCategoryTap: onCategoryTap
                )
                
                // Popular Searches
                PopularSearchesSection(
                    popularSearches: popularSearches,
                    onPopularSearchTap: onPopularSearchTap
                )
                
                // Nearby Classes (if location available)
                if !nearbyClasses.isEmpty {
                    NearbyClassesSection(
                        nearbyClasses: nearbyClasses
                    )
                }
                
                // Suggested Classes
                if !suggestedClasses.isEmpty {
                    SuggestedClassesSection(
                        suggestedClasses: suggestedClasses
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let onActionTap: (QuickAction) -> Void
    
    private let quickActions: [(QuickAction, String, String, Color)] = [
        (.nearby, "Near Me", "location.fill", BrandConstants.Colors.teal),
        (.free, "Free Classes", "gift.fill", BrandConstants.Colors.coral),
        (.weekend, "This Weekend", "calendar.badge.clock", BrandConstants.Colors.primary),
        (.tonight, "Tonight", "moon.stars.fill", .purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            SectionHeader(title: "Quick Search", iconName: "bolt.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.md) {
                ForEach(quickActions, id: \.0) { action, title, iconName, color in
                    QuickActionCard(
                        title: title,
                        iconName: iconName,
                        color: color,
                        onTap: { onActionTap(action) }
                    )
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let iconName: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: BrandConstants.Spacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(BrandConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Saved Searches Section

struct SavedSearchesSection: View {
    let savedSearches: [SavedSearch]
    let onSavedSearchTap: (SavedSearch) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            SectionHeader(title: "Saved Searches", iconName: "bookmark.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BrandConstants.Spacing.sm) {
                    ForEach(savedSearches.prefix(5)) { savedSearch in
                        SavedSearchChip(
                            savedSearch: savedSearch,
                            onTap: { onSavedSearchTap(savedSearch) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SavedSearchChip: View {
    let savedSearch: SavedSearch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(savedSearch.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(savedSearch.query)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 140, alignment: .leading)
            .padding(BrandConstants.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                    .fill(BrandConstants.Colors.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Searches Section

struct RecentSearchesSection: View {
    let recentSearches: [String]
    let onRecentSearchTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            SectionHeader(title: "Recent Searches", iconName: "clock.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                ForEach(recentSearches.prefix(6), id: \.self) { search in
                    RecentSearchChip(
                        searchText: search,
                        onTap: { onRecentSearchTap(search) }
                    )
                }
            }
        }
    }
}

struct RecentSearchChip: View {
    let searchText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(searchText)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, BrandConstants.Spacing.sm)
            .padding(.vertical, BrandConstants.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trending Categories Section

struct TrendingCategoriesSection: View {
    let trendingCategories: [TrendingCategory]
    let onCategoryTap: (ClassCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            SectionHeader(title: "Trending Categories", iconName: "chart.line.uptrend.xyaxis")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.md) {
                ForEach(trendingCategories.prefix(6)) { category in
                    TrendingCategoryCard(
                        category: category,
                        onTap: {
                            if let categoryEnum = ClassCategory(rawValue: category.name) {
                                onCategoryTap(categoryEnum)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct TrendingCategoryCard: View {
    let category: TrendingCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                HStack {
                    Image(systemName: category.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(category.color)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                    Text(category.name)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(category.classCount) classes")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BrandConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(category.color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Popular Searches Section

struct PopularSearchesSection: View {
    let popularSearches: [String]
    let onPopularSearchTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            SectionHeader(title: "Popular Searches", iconName: "flame.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BrandConstants.Spacing.sm) {
                    ForEach(popularSearches.prefix(8), id: \.self) { search in
                        PopularSearchChip(
                            searchText: search,
                            onTap: { onPopularSearchTap(search) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PopularSearchChip: View {
    let searchText: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BrandConstants.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                
                Text(searchText)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, BrandConstants.Spacing.md)
            .padding(.vertical, BrandConstants.Spacing.sm)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nearby Classes Section

struct NearbyClassesSection: View {
    let nearbyClasses: [HobbyClass]
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            HStack {
                SectionHeader(title: "Near You", iconName: "location.fill")
                Spacer()
                Button("See All") {
                    // Navigate to full nearby results
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BrandConstants.Spacing.md) {
                    ForEach(nearbyClasses.prefix(3)) { hobbyClass in
                        CompactClassCard(hobbyClass: hobbyClass)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Suggested Classes Section

struct SuggestedClassesSection: View {
    let suggestedClasses: [HobbyClass]
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
            HStack {
                SectionHeader(title: "Recommended for You", iconName: "star.fill")
                Spacer()
                Button("See All") {
                    // Navigate to full suggestions
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BrandConstants.Spacing.md) {
                    ForEach(suggestedClasses.prefix(3)) { hobbyClass in
                        CompactClassCard(hobbyClass: hobbyClass)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Compact Class Card

struct CompactClassCard: View {
    let hobbyClass: HobbyClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
            // Image placeholder
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                .fill(LinearGradient(
                    colors: [BrandConstants.Colors.primary.opacity(0.3), BrandConstants.Colors.teal.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 80)
                .overlay(
                    Image(systemName: hobbyClass.category.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                Text(hobbyClass.title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(hobbyClass.instructor.name)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))")
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(BrandConstants.Colors.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", hobbyClass.averageRating))
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: 160)
        .padding(BrandConstants.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: BrandConstants.Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BrandConstants.Colors.primary)
            
            Text(title)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    SearchDiscoveryView(
        recentSearches: ["pottery", "cooking", "photography"],
        popularSearches: ["ceramics", "baking", "painting", "guitar", "yoga"],
        trendingCategories: [
            TrendingCategory(name: "Arts & Crafts", classCount: 23, trendingScore: 0.9),
            TrendingCategory(name: "Cooking & Baking", classCount: 18, trendingScore: 0.8)
        ],
        suggestedClasses: [],
        nearbyClasses: [],
        savedSearches: [],
        onRecentSearchTap: { _ in },
        onPopularSearchTap: { _ in },
        onCategoryTap: { _ in },
        onSavedSearchTap: { _ in },
        onQuickActionTap: { _ in }
    )
}