import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showingFilters = false
    @FocusState private var isSearchFocused: Bool
    
    // Performance optimization: Debounce search input
    @State private var searchDebounceTimer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Header
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search classes, instructors, venues...", text: $viewModel.searchQuery)
                            .focused($isSearchFocused)
                            .onSubmit {
                                viewModel.performSearch()
                            }
                            .onChange(of: viewModel.searchQuery) { newValue in
                                // Debounce search to improve performance
                                searchDebounceTimer?.invalidate()
                                searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    if !newValue.isEmpty {
                                        viewModel.performSearch()
                                    }
                                }
                            }
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Search Scope Picker
                    Picker("Search Scope", selection: $viewModel.searchScope) {
                        ForEach(SearchViewModel.SearchScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                // Content
                if viewModel.searchQuery.isEmpty {
                    // Default state - show suggestions and trending
                    EmptySearchView(viewModel: viewModel)
                } else if viewModel.isSearching {
                    // Loading state
                    SearchLoadingView()
                } else if viewModel.searchResults.isEmpty {
                    // No results
                    NoResultsView(query: viewModel.searchQuery)
                } else {
                    // Search results
                    SearchResultsList(viewModel: viewModel)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent Searches
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline)
                            Spacer()
                            Button("Clear All") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(viewModel.recentSearches, id: \.self) { search in
                                Button {
                                    viewModel.performQuickSearch(query: search)
                                } label: {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                        Text(search)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Popular Searches
                if !viewModel.popularSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular This Week")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.popularSearches, id: \.self) { search in
                                    Button {
                                        viewModel.performQuickSearch(query: search)
                                    } label: {
                                        HStack {
                                            Image(systemName: "flame")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            Text(search)
                                                .font(.subheadline)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Trending Categories
                if !viewModel.trendingCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending Categories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.trendingCategories) { trending in
                                Button {
                                    viewModel.searchByCategory(trending.category)
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: trending.category.icon)
                                            .font(.title2)
                                            .foregroundColor(.accentColor)
                                        
                                        Text(trending.category.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("+\(Int(trending.weeklyGrowth))%")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Suggested Classes
                if !viewModel.suggestedClasses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested for You")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.suggestedClasses) { hobbyClass in
                            SuggestedClassRow(hobbyClass: hobbyClass)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Search Loading View
struct SearchLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No results for '\(query)'")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Try searching with different keywords or check the spelling")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Results List
struct SearchResultsList: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.searchResults) { result in
                NavigationLink(destination: destinationView(for: result)) {
                    SearchResultRow(result: result)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            
            if viewModel.hasMoreResults {
                HStack {
                    Spacer()
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Load More") {
                            Task {
                                await viewModel.loadMoreResults()
                            }
                        }
                        .foregroundColor(.accentColor)
                    }
                    Spacer()
                }
                .padding()
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            viewModel.performSearch()
        }
    }
    
    @ViewBuilder
    private func destinationView(for result: SearchResult) -> some View {
        switch result {
        case .hobbyClass(let hobbyClass):
            ClassDetailView(classItem: ClassItem.sample) // Using sample for now
        case .instructor(let instructor):
            InstructorDetailView(instructor: instructor)
        case .venue(let venue):
            VenueDetailView(venue: venue)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon/Image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: iconForResult)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titleForResult)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(subtitleForResult)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let metadata = metadataForResult {
                    Text(metadata)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var iconForResult: String {
        switch result {
        case .hobbyClass(let hobbyClass):
            return hobbyClass.category.icon
        case .instructor:
            return "person.circle"
        case .venue:
            return "building.2"
        }
    }
    
    private var titleForResult: String {
        switch result {
        case .hobbyClass(let hobbyClass):
            return hobbyClass.name
        case .instructor(let instructor):
            return instructor.name
        case .venue(let venue):
            return venue.name
        }
    }
    
    private var subtitleForResult: String {
        switch result {
        case .hobbyClass(let hobbyClass):
            return hobbyClass.description
        case .instructor(let instructor):
            return instructor.specialties.joined(separator: ", ")
        case .venue(let venue):
            return venue.address
        }
    }
    
    private var metadataForResult: String? {
        switch result {
        case .hobbyClass(let hobbyClass):
            return "\(hobbyClass.price) • \(hobbyClass.duration)"
        case .instructor(let instructor):
            return "\(instructor.rating)⭐ • \(instructor.reviewCount) reviews"
        case .venue(let venue):
            return "\(venue.classCount) classes available"
        }
    }
}

// MARK: - Suggested Class Row
struct SuggestedClassRow: View {
    let hobbyClass: HobbyClass
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: hobbyClass.category.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hobbyClass.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(hobbyClass.instructor)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(hobbyClass.price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Label("\(hobbyClass.rating)", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Search Filters View
struct SearchFiltersView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Location Filter", selection: $viewModel.locationFilter) {
                        ForEach(SearchViewModel.LocationFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    
                    if viewModel.locationFilter == .custom {
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text("\(Int(viewModel.searchRadius)) miles")
                        }
                        
                        Slider(
                            value: $viewModel.searchRadius,
                            in: 1...50,
                            step: 1
                        )
                    }
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

// MARK: - Extensions for Missing Models
extension ClassCategory {
    var icon: String {
        switch self {
        case .fitness:
            return "figure.run"
        case .arts:
            return "paintbrush"
        case .music:
            return "music.note"
        case .cooking:
            return "fork.knife"
        case .dance:
            return "figure.dance"
        case .technology:
            return "laptopcomputer"
        case .language:
            return "textformat.abc"
        case .photography:
            return "camera"
        default:
            return "star"
        }
    }
}

// Mock enum for compilation
enum ClassCategory: String, CaseIterable {
    case fitness = "Fitness"
    case arts = "Arts"
    case music = "Music" 
    case cooking = "Cooking"
    case dance = "Dance"
    case technology = "Technology"
    case language = "Language"
    case photography = "Photography"
}

// Placeholder for detail views
struct InstructorDetailView: View {
    let instructor: Instructor
    
    var body: some View {
        Text("Instructor Detail: \(instructor.name)")
    }
}

struct VenueDetailView: View {
    let venue: Venue
    
    var body: some View {
        Text("Venue Detail: \(venue.name)")
    }
}
