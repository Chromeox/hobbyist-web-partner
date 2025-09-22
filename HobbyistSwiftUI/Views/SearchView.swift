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
                                        Task { @MainActor in
                                            viewModel.performSearch()
                                        }
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
                                    // Convert trending name to ClassCategory
                                    if let category = ClassCategory.allCases.first(where: { $0.rawValue == trending.name }) {
                                        viewModel.searchByCategory(category)
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: trending.iconName)
                                            .font(.title2)
                                            .foregroundColor(.accentColor)

                                        Text(trending.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text("\(trending.classCount) classes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
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
        switch result.type {
        case .hobbyClass:
            ClassDetailView(classItem: ClassItem.sample) // Using sample for now
        case .instructor:
            Text("Instructor Detail") // Placeholder until InstructorDetailView is implemented
        case .venue:
            Text("Venue Detail") // Placeholder until VenueDetailView is implemented
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
        switch result.type {
        case .hobbyClass:
            return "sportscourt" // Generic hobby class icon
        case .instructor:
            return "person.circle"
        case .venue:
            return "building.2"
        }
    }
    
    private var titleForResult: String {
        switch result.type {
        case .hobbyClass:
            return result.title
        case .instructor:
            return result.title
        case .venue:
            return result.title
        }
    }
    
    private var subtitleForResult: String {
        switch result.type {
        case .hobbyClass:
            return result.subtitle ?? ""
        case .instructor:
            return result.subtitle ?? ""
        case .venue:
            return result.subtitle ?? ""
        }
    }
    
    private var metadataForResult: String? {
        switch result.type {
        case .hobbyClass:
            if let price = result.price {
                return "$\(String(format: "%.0f", price))"
            }
            return nil
        case .instructor:
            if let rating = result.rating {
                return "\(String(format: "%.1f", rating))⭐"
            }
            return nil
        case .venue:
            if let distance = result.distance {
                return "\(String(format: "%.1f", distance)) km away"
            }
            return nil
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
                    Image(systemName: hobbyClass.category.iconName)
                        .font(.title3)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hobbyClass.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(hobbyClass.instructor.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$\(Int(hobbyClass.price))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Label("\(hobbyClass.averageRating, specifier: "%.1f")", systemImage: "star.fill")
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
                        ForEach(LocationFilter.allCases, id: \.self) { filter in
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
// ClassCategory.icon is already defined in Class.swift


// Placeholder for detail views
struct InstructorDetailView: View {
    let instructor: Instructor
    
    var body: some View {
        Text("Instructor Detail: \(instructor.fullName)")
    }
}

struct VenueDetailView: View {
    let venue: Venue
    
    var body: some View {
        Text("Venue Detail: \(venue.name)")
    }
}
