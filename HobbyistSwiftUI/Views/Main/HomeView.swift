import SwiftUI

struct HomeView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Success message
                    VStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("🎉 HOME SCREEN SUCCESS! 🎉")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text("Second screen working!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Search section
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search hobby classes...", text: $searchText)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Mock featured classes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Classes")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(mockClasses, id: \.id) { mockClass in
                                    ClassCardView(title: mockClass.title, instructor: mockClass.instructor, price: mockClass.price)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(mockCategories, id: \.self) { category in
                                CategoryCardView(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover Hobbies")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var mockClasses: [MockClass] {
        [
            MockClass(id: 1, title: "Pottery Basics", instructor: "Sarah Chen", price: "$45"),
            MockClass(id: 2, title: "Yoga Flow", instructor: "Emma Wilson", price: "$25"),
            MockClass(id: 3, title: "Cooking Italian", instructor: "Marco Rossi", price: "$65")
        ]
    }

    private var mockCategories: [String] {
        ["Art & Craft", "Fitness", "Cooking", "Music", "Dance", "Technology"]
    }
}

struct MockClass {
    let id: Int
    let title: String
    let instructor: String
    let price: String
}

struct ClassCardView: View {
    let title: String
    let instructor: String
    let price: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 80)
                .cornerRadius(8)

            Text(title)
                .font(.headline)
                .lineLimit(1)

            Text("with \(instructor)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(price)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .frame(width: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CategoryCardView: View {
    let category: String

    var body: some View {
        HStack {
            Image(systemName: "paintbrush.fill")
                .foregroundColor(.blue)
            Text(category)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    HomeView()
}