import SwiftUI

struct HomeView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var searchText = ""
    @State private var selectedNeighborhood = "All Vancouver"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discover Vancouver")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(LinearGradient(
                                        colors: [.primary, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))

                                Text("Find your next creative adventure")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Neighborhood Selector
                            Menu {
                                ForEach(vancouverNeighborhoods, id: \.self) { neighborhood in
                                    Button(neighborhood) {
                                        selectedNeighborhood = neighborhood
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                    Text(selectedNeighborhood)
                                        .lineLimit(1)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Enhanced Search Section
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                            TextField("Search pottery, boxing, cooking...", text: $searchText)
                                .submitLabel(.search)
                                .onSubmit {
                                    // Handle search
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    // Featured Vancouver Classes
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Featured This Week")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)

                            Spacer()

                            Button("View All") {
                                // Navigate to full list
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(vancouverFeaturedClasses, id: \.id) { classItem in
                                    VancouverClassCard(classItem: classItem)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Vancouver Neighborhoods & Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Explore by Category")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(vancouverCategories, id: \.name) { category in
                                VancouverCategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Popular Studios Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Studios")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(vancouverStudios, id: \.id) { studio in
                                    StudioCard(studio: studio)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Vancouver Data

    private var vancouverNeighborhoods: [String] {
        ["All Vancouver", "Downtown", "Gastown", "Yaletown", "West End", "Kitsilano", "Commercial Drive", "Mount Pleasant", "Fairview", "North Vancouver"]
    }

    private var vancouverFeaturedClasses: [VancouverClass] {
        [
            VancouverClass(id: 1, title: "Pottery Wheel Basics", studio: "Claymates Studio", instructor: "Maria Chen", price: "$65", creditsRequired: 18, neighborhood: "Commercial Drive", category: "Ceramics", rating: 4.8, imageColor: .orange),
            VancouverClass(id: 2, title: "Sourdough Bread Making", studio: "Culinary Studio", instructor: "Chef David Park", price: "$75", creditsRequired: 20, neighborhood: "Gastown", category: "Cooking", rating: 4.7, imageColor: .yellow),
            VancouverClass(id: 3, title: "Urban Photography Walk", studio: "Lens & Light", instructor: "Emma Wilson", price: "$45", creditsRequired: 12, neighborhood: "Downtown", category: "Photography", rating: 4.6, imageColor: .blue),
            VancouverClass(id: 4, title: "Watercolor Painting", studio: "Creative Arts Collective", instructor: "Sofia Rodriguez", price: "$55", creditsRequired: 15, neighborhood: "Kitsilano", category: "Dance & Movement", rating: 4.8, imageColor: .purple)
        ]
    }

    private var vancouverCategories: [VancouverCategory] {
        [
            VancouverCategory(name: "Ceramics", icon: "paintpalette.fill", color: .orange, classCount: 12),
            VancouverCategory(name: "Cooking & Baking", icon: "fork.knife.circle.fill", color: .yellow, classCount: 15),
            VancouverCategory(name: "Arts & Crafts", icon: "paintbrush.fill", color: .purple, classCount: 10),
            VancouverCategory(name: "Photography", icon: "camera.fill", color: .blue, classCount: 7),
            VancouverCategory(name: "Music & Sound", icon: "music.note", color: .green, classCount: 9),
            VancouverCategory(name: "Movement", icon: "figure.dance", color: .pink, classCount: 6)
        ]
    }

    private var vancouverStudios: [VancouverStudio] {
        [
            VancouverStudio(id: 1, name: "Claymates Studio", neighborhood: "Commercial Drive", rating: 4.8, classCount: 6, specialty: "Ceramics"),
            VancouverStudio(id: 2, name: "Creative Arts Collective", neighborhood: "Mount Pleasant", rating: 4.9, classCount: 8, specialty: "Mixed Media"),
            VancouverStudio(id: 3, name: "The Cooking School", neighborhood: "Gastown", rating: 4.7, classCount: 12, specialty: "Culinary"),
            VancouverStudio(id: 4, name: "Vancouver Art Studio", neighborhood: "Kitsilano", rating: 4.6, classCount: 8, specialty: "Arts")
        ]
    }
}

// MARK: - Vancouver Data Models

struct VancouverClass {
    let id: Int
    let title: String
    let studio: String
    let instructor: String
    let price: String
    let creditsRequired: Int
    let neighborhood: String
    let category: String
    let rating: Double
    let imageColor: Color
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
}

// MARK: - Enhanced Card Views

struct VancouverClassCard: View {
    let classItem: VancouverClass

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder with category color
            Rectangle()
                .fill(LinearGradient(
                    colors: [classItem.imageColor.opacity(0.6), classItem.imageColor.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(String(format: "%.1f", classItem.rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(classItem.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(classItem.neighborhood)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("at \(classItem.studio)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    Text("\(classItem.creditsRequired) credits")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Spacer()

                    Text(classItem.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(classItem.imageColor.opacity(0.2))
                        .foregroundColor(classItem.imageColor)
                        .cornerRadius(8)
                }
            }
        }
        .frame(width: 200)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct VancouverCategoryCard: View {
    let category: VancouverCategory

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(category.color)
            }

            VStack(spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(category.classCount) classes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StudioCard: View {
    let studio: VancouverStudio

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue.opacity(0.4), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 80)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text(studio.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(studio.neighborhood)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", studio.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Text("\(studio.classCount) classes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(studio.specialty)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .frame(width: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
}