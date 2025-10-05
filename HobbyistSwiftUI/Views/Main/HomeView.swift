import SwiftUI

struct HomeView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedNeighborhood = "All Vancouver"

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                BrandConstants.Gradients.darkBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Enhanced Header
                        DiscoveryHeader(selectedLocation: $selectedNeighborhood)

                        // Glassmorphic Search Bar
                        GlassmorphicSearchBar(searchText: $searchText)

                        // Featured Classes Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "Featured This Week",
                                actionTitle: "View All",
                                action: { /* Navigate to full list */ }
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vancouverFeaturedClasses, id: \.id) { classItem in
                                        EnhancedFeaturedCard(classItem: classItem)
                                            .frame(width: 280)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Categories Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "Explore by Category",
                                actionTitle: nil,
                                action: nil
                            )

                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 16
                            ) {
                                ForEach(vancouverCategories, id: \.name) { category in
                                    EnhancedCategoryCard(category: category)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Popular Studios Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "Popular Studios",
                                actionTitle: "View All",
                                action: { /* Navigate */ }
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(vancouverStudios, id: \.id) { studio in
                                        EnhancedStudioCard(studio: studio)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Bottom padding for tab bar
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }

    // MARK: - Helper Methods

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Vancouver Data

    private var vancouverNeighborhoods: [String] {
        ["All Vancouver", "Downtown", "Gastown", "Yaletown", "West End", "Kitsilano", "Commercial Drive", "Mount Pleasant", "Fairview", "North Vancouver"]
    }

    private var vancouverFeaturedClasses: [VancouverClass] {
        [
            VancouverClass(
                id: 1,
                title: "Pottery Wheel Basics",
                studio: "Claymates Studio",
                instructor: "Maria Chen",
                creditsRequired: 18,
                neighborhood: "Commercial Drive",
                category: "Ceramics",
                rating: 4.8,
                imageGradient: [Color(hex: "#8B5A3C"), Color(hex: "#6B4423")],
                icon: "paintpalette.fill",
                categoryColor: CategoryColors.ceramics
            ),
            VancouverClass(
                id: 2,
                title: "Sourdough Bread Making",
                studio: "Culinary Studio",
                instructor: "Chef David Park",
                creditsRequired: 20,
                neighborhood: "Gastown",
                category: "Cooking",
                rating: 4.9,
                imageGradient: [Color(hex: "#D4A574"), Color(hex: "#B8860B")],
                icon: "fork.knife",
                categoryColor: CategoryColors.cooking
            ),
            VancouverClass(
                id: 3,
                title: "Urban Photography Walk",
                studio: "Lens & Light",
                instructor: "Emma Wilson",
                creditsRequired: 12,
                neighborhood: "Downtown",
                category: "Photography",
                rating: 4.7,
                imageGradient: [Color(hex: "#5A9FD4"), Color(hex: "#2C5F8D")],
                icon: "camera.fill",
                categoryColor: CategoryColors.photography
            ),
            VancouverClass(
                id: 4,
                title: "Watercolor Painting",
                studio: "Creative Arts Collective",
                instructor: "Sofia Rodriguez",
                creditsRequired: 15,
                neighborhood: "Kitsilano",
                category: "Arts & Crafts",
                rating: 4.8,
                imageGradient: [Color(hex: "#C48ED8"), Color(hex: "#8B3FA8")],
                icon: "paintbrush.fill",
                categoryColor: CategoryColors.arts
            )
        ]
    }

    private var vancouverCategories: [VancouverCategory] {
        [
            VancouverCategory(name: "Ceramics", icon: "paintpalette.fill", color: CategoryColors.ceramics, classCount: 12),
            VancouverCategory(name: "Cooking & Baking", icon: "fork.knife", color: CategoryColors.cooking, classCount: 15),
            VancouverCategory(name: "Arts & Crafts", icon: "paintbrush.fill", color: CategoryColors.arts, classCount: 10),
            VancouverCategory(name: "Photography", icon: "camera.fill", color: CategoryColors.photography, classCount: 7),
            VancouverCategory(name: "Music & Sound", icon: "music.note", color: CategoryColors.music, classCount: 9),
            VancouverCategory(name: "Movement", icon: "figure.dance", color: CategoryColors.movement, classCount: 6)
        ]
    }

    private var vancouverStudios: [VancouverStudio] {
        [
            VancouverStudio(id: 1, name: "Claymates Studio", neighborhood: "Commercial Drive", rating: 4.8, classCount: 6, specialty: "Ceramics", gradientColors: [CategoryColors.ceramics.opacity(0.6), CategoryColors.ceramics.opacity(0.3)]),
            VancouverStudio(id: 2, name: "Creative Arts Collective", neighborhood: "Mount Pleasant", rating: 4.9, classCount: 8, specialty: "Mixed Media", gradientColors: [CategoryColors.arts.opacity(0.6), CategoryColors.arts.opacity(0.3)]),
            VancouverStudio(id: 3, name: "The Cooking School", neighborhood: "Gastown", rating: 4.7, classCount: 12, specialty: "Culinary", gradientColors: [CategoryColors.cooking.opacity(0.6), CategoryColors.cooking.opacity(0.3)]),
            VancouverStudio(id: 4, name: "Vancouver Art Studio", neighborhood: "Kitsilano", rating: 4.6, classCount: 8, specialty: "Arts", gradientColors: [CategoryColors.photography.opacity(0.6), CategoryColors.photography.opacity(0.3)])
        ]
    }
}

// MARK: - Data Models

struct VancouverClass {
    let id: Int
    let title: String
    let studio: String
    let instructor: String
    let creditsRequired: Int
    let neighborhood: String
    let category: String
    let rating: Double
    let imageGradient: [Color]
    let icon: String
    let categoryColor: Color
}

struct VancouverCategory {
    let name: String
    let icon: String
    let color: Color
    let classCount: Int
}

struct VancouverStudio {
    let id: Int
    let name: String
    let neighborhood: String
    let rating: Double
    let classCount: Int
    let specialty: String
    let gradientColors: [Color]
}

// MARK: - Enhanced Components

struct DiscoveryHeader: View {
    @Binding var selectedLocation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Title with gradient
                    HStack(spacing: 0) {
                        Text("Discover")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text(" Vancouver")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#4ECDC4"),  // Teal
                                        Color(hex: "#FF6B6B")   // Coral
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    Text("Find your next creative adventure")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Location selector
                Menu {
                    ForEach(["All Vancouver", "Downtown", "Gastown", "Yaletown", "Kitsilano", "Commercial Drive"], id: \.self) { location in
                        Button(location) {
                            selectedLocation = location
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        Text(selectedLocation)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(BrandConstants.Colors.teal)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(BrandConstants.Colors.teal.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct GlassmorphicSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(
                    isFocused ?
                        BrandConstants.Colors.teal :
                        Color.white.opacity(0.6)
                )

            TextField("Search pottery, cooking, arts...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    // Handle search
                    isFocused = false
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isFocused ? 0.2 : 0.15),
                            Color.white.opacity(isFocused ? 0.12 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isFocused ?
                                        BrandConstants.Colors.teal.opacity(0.5) :
                                        Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isFocused ?
                BrandConstants.Colors.teal.opacity(0.3) :
                Color.black.opacity(0.1),
            radius: isFocused ? 15 : 10,
            y: 5
        )
        .animation(BrandConstants.Animation.spring, value: isFocused)
        .padding(.horizontal, 20)
    }
}

struct EnhancedCategoryCard: View {
    let category: VancouverCategory
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            // Navigate to category
        }) {
            VStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    category.color.opacity(0.3),
                                    category.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: category.color.opacity(0.4),
                            radius: isPressed ? 8 : 12,
                            y: isPressed ? 3 : 6
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text("\(category.classCount) classes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .black.opacity(isPressed ? 0.15 : 0.1),
                        radius: isPressed ? 8 : 12,
                        y: isPressed ? 3 : 6
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(BrandConstants.Animation.spring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EnhancedFeaturedCard: View {
    let classItem: VancouverClass

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with gradient and decorative icon
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: classItem.imageGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 180)
                .overlay(
                    // Decorative icon
                    Image(systemName: classItem.icon)
                        .font(.system(size: 70, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.15))
                        .offset(x: 30, y: 20)
                        .rotationEffect(.degrees(-15))
                )

                // Rating badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", classItem.rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                )
                .padding(12)
            }

            // Details section
            VStack(alignment: .leading, spacing: 10) {
                Text(classItem.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BrandConstants.Colors.teal)
                        Text(classItem.neighborhood)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Text("at \(classItem.studio)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }

                HStack {
                    Text("\(classItem.creditsRequired) credits")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BrandConstants.Colors.coral)

                    Spacer()

                    // Category badge
                    Text(classItem.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(classItem.categoryColor.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(classItem.categoryColor.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
    }
}

struct EnhancedStudioCard: View {
    let studio: VancouverStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Studio header with gradient
            Rectangle()
                .fill(LinearGradient(
                    colors: studio.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 100)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text(String(format: "%.1f", studio.rating))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(999)
                            .padding(8)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(studio.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(BrandConstants.Colors.teal)
                    Text(studio.neighborhood)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Text("\(studio.classCount) classes • \(studio.specialty)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 200)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
}

struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BrandConstants.Colors.teal)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    HomeView()
}
