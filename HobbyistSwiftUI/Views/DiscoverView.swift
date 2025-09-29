import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    let categories = ["Fitness", "Arts", "Music", "Cooking", "Dance", "Technology", "Language", "Photography"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField(NSLocalizedString("search_classes", comment: ""), text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category)
                                        .font(.callout)
                                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color.accentColor : Color(.systemGray6))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .cornerRadius(999)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Featured Classes
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("featured_classes", comment: ""))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                        
                        ForEach(0..<5) { _ in
                            NavigationLink(destination: Text("Class Details Coming Soon")) {
                                ClassListItem()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(NSLocalizedString("discover", comment: ""))
        }
    }
}


struct ClassListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Guitar Lessons for Beginners")
                    .font(.headline)
                    .lineLimit(1)
                
                Text("Learn the basics of guitar playing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("4.9", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("$45/session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "heart")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
