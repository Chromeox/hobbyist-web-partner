import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var searchResults: [MockSearchClass] = []
    @State private var recentSearches: [String] = ["Pottery", "Yoga", "Cooking"]
    @State private var isSearching = false

    private let categories = ["All", "Art & Craft", "Fitness", "Cooking", "Music", "Dance", "Technology"]
    private let allClasses = MockSearchClass.sampleClasses

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        TextField("Search classes, studios, or instructors...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                            .onChange(of: searchText) { _, newValue in
                                if newValue.isEmpty {
                                    searchResults = []
                                    isSearching = false
                                } else {
                                    performSearch()
                                }
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                isSearching = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                CategoryChipView(
                                    title: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                    performSearch()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)

                // Content
                if searchText.isEmpty {
                    // Empty State - Recent Searches and Suggestions
                    EmptySearchStateView(recentSearches: recentSearches) { searchTerm in
                        searchText = searchTerm
                        performSearch()
                    }
                } else {
                    // Search Results
                    SearchResultsView(
                        results: searchResults,
                        isSearching: isSearching,
                        searchText: searchText
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func performSearch() {
        isSearching = true

        // Add to recent searches if not empty and not already present
        if !searchText.isEmpty && !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 5 {
                recentSearches.removeLast()
            }
        }

        // Simulate search delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            searchResults = filteredClasses()
            isSearching = false
        }
    }

    private func filteredClasses() -> [MockSearchClass] {
        var filtered = allClasses

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { classItem in
                classItem.title.localizedCaseInsensitiveContains(searchText) ||
                classItem.instructor.localizedCaseInsensitiveContains(searchText) ||
                classItem.studio.localizedCaseInsensitiveContains(searchText) ||
                classItem.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }

        return filtered
    }
}

struct CategoryChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmptySearchStateView: View {
    let recentSearches: [String]
    let onSearchTap: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Searches")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(recentSearches, id: \.self) { search in
                            Button(action: { onSearchTap(search) }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)

                                    Text(search)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Image(systemName: "arrow.up.left")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Popular Classes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular This Week")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(MockSearchClass.popularClasses, id: \.id) { classItem in
                        PopularClassRowView(classItem: classItem)
                            .padding(.horizontal)
                    }
                }

                // Browse by Category
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse Categories")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(["Art & Craft", "Fitness", "Cooking", "Music"], id: \.self) { category in
                            CategoryBrowseCard(category: category) {
                                onSearchTap(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct SearchResultsView: View {
    let results: [MockSearchClass]
    let isSearching: Bool
    let searchText: String

    var body: some View {
        if isSearching {
            VStack {
                Spacer()
                ProgressView("Searching...")
                Spacer()
            }
        } else if results.isEmpty {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)

                Text("No results found")
                    .font(.headline)

                Text("Try adjusting your search or browse popular classes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results, id: \.id) { classItem in
                        SearchResultRowView(classItem: classItem)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct PopularClassRowView: View {
    let classItem: MockSearchClass

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: classItem.iconName)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(classItem.studio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < classItem.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                    Text("(\(classItem.reviewCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(classItem.price)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct SearchResultRowView: View {
    let classItem: MockSearchClass

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: classItem.iconName)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.title)
                    .font(.headline)
                    .lineLimit(1)

                Text("with \(classItem.instructor)")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text(classItem.studio)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    ForEach(0..<5) { star in
                        Image(systemName: star < classItem.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                    Text("(\(classItem.reviewCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(classItem.nextClass)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(classItem.price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Button("Book") {
                    // Handle booking
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct CategoryBrowseCard: View {
    let category: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 30))
                    .foregroundColor(.blue)

                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Art & Craft": return "paintbrush.fill"
        case "Fitness": return "figure.run"
        case "Cooking": return "fork.knife"
        case "Music": return "music.note"
        default: return "star.fill"
        }
    }
}

struct MockSearchClass {
    let id = UUID()
    let title: String
    let instructor: String
    let studio: String
    let category: String
    let price: String
    let rating: Int
    let reviewCount: Int
    let nextClass: String
    let iconName: String

    static let sampleClasses = [
        MockSearchClass(title: "Pottery Basics", instructor: "Sarah Chen", studio: "Clay Studio Vancouver", category: "Art & Craft", price: "$45", rating: 5, reviewCount: 24, nextClass: "Tomorrow 10AM", iconName: "paintbrush.fill"),
        MockSearchClass(title: "Yoga Flow", instructor: "Emma Wilson", studio: "Zen Yoga Studio", category: "Fitness", price: "$25", rating: 4, reviewCount: 18, nextClass: "Today 6PM", iconName: "figure.yoga"),
        MockSearchClass(title: "Italian Cooking", instructor: "Marco Rossi", studio: "Culinary Arts Center", category: "Cooking", price: "$65", rating: 5, reviewCount: 32, nextClass: "Saturday 2PM", iconName: "fork.knife"),
        MockSearchClass(title: "Guitar Basics", instructor: "Alex Johnson", studio: "Music Hub", category: "Music", price: "$40", rating: 4, reviewCount: 15, nextClass: "Wednesday 7PM", iconName: "music.note"),
        MockSearchClass(title: "Watercolor Painting", instructor: "Lisa Park", studio: "Art Collective", category: "Art & Craft", price: "$35", rating: 5, reviewCount: 28, nextClass: "Friday 1PM", iconName: "paintbrush"),
        MockSearchClass(title: "HIIT Training", instructor: "Mike Chen", studio: "FitLife Gym", category: "Fitness", price: "$30", rating: 4, reviewCount: 22, nextClass: "Daily 8AM", iconName: "figure.run"),
    ]

    static let popularClasses = Array(sampleClasses.prefix(3))
}

#Preview {
    SearchView()
}