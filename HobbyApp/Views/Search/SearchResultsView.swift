import SwiftUI

struct SearchResultsView: View {
    let query: String
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedFilter: SearchFilter = .all
    @State private var showingFilters = false
    @State private var selectedClass: HobbyClass?
    @State private var showingClassDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Search header
            searchHeader
            
            // Filter chips
            filterChips
            
            // Results content
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasSearched && viewModel.allResults.isEmpty {
                    noResultsView
                } else if !viewModel.hasSearched {
                    searchPromptView
                } else {
                    resultsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Search Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .onAppear {
            viewModel.searchQuery = query
            Task {
                await viewModel.performSearch()
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersSheet(filters: $viewModel.currentFilters) { filters in
                viewModel.applyFilters(filters)
            }
        }
        .sheet(isPresented: $showingClassDetail) {
            if let hobbyClass = selectedClass {
                SearchClassDetailSheet(hobbyClass: hobbyClass)
            }
        }
    }
    
    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Results for \"\(query)\"")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.hasSearched {
                    Text("\(viewModel.filteredResults.count) found")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if !viewModel.suggestedQueries.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestedQueries, id: \.self) { suggestion in
                            Button(suggestion) {
                                viewModel.searchQuery = suggestion
                                Task {
                                    await viewModel.performSearch()
                                }
                            }
                            .font(BrandConstants.Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(BrandConstants.Colors.primary.opacity(0.1))
                            .foregroundColor(BrandConstants.Colors.primary)
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(BrandConstants.Colors.surface)
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        count: viewModel.resultCount(for: filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(BrandConstants.Colors.surface)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching for \"\(query)\"...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("We couldn't find any classes matching \"\(query)\"")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if !viewModel.searchSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Try searching for:")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(viewModel.searchSuggestions, id: \.self) { suggestion in
                        Button(suggestion.text) {
                            viewModel.selectSearchSuggestion(suggestion)
                        }
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(BrandConstants.Colors.background)
                .cornerRadius(BrandConstants.CornerRadius.md)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Enter a search term")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("Search for classes, instructors, or venues")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.resultsForFilter(selectedFilter)) { result in
                    SearchResultCard(
                        result: result,
                        onTap: {
                            if case .class(let hobbyClass) = result {
                                selectedClass = hobbyClass
                                showingClassDetail = true
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.3))
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? BrandConstants.Colors.primary : BrandConstants.Colors.background)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(BrandConstants.CornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Type icon
                    Image(systemName: result.typeIcon)
                        .foregroundColor(result.typeColor)
                        .font(BrandConstants.Typography.subheadline)
                        .frame(width: 20)
                    
                    // Type label
                    Text(result.typeLabel)
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(result.typeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(result.typeColor.opacity(0.1))
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                    
                    Spacer()
                    
                    // Match indicator
                    if result.isExactMatch {
                        Text("Exact Match")
                            .font(BrandConstants.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                    }
                }
                
                // Content based on result type
                switch result {
                case .class(let hobbyClass):
                    classResultContent(hobbyClass)
                case .instructor(let instructor):
                    instructorResultContent(instructor)
                case .venue(let venue):
                    venueResultContent(venue)
                }
            }
            .padding()
            .background(BrandConstants.Colors.surface)
            .cornerRadius(BrandConstants.CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func classResultContent(_ hobbyClass: HobbyClass) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hobbyClass.title)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(hobbyClass.description)
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                // Instructor
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.secondary)
                        .font(BrandConstants.Typography.caption)
                    
                    Text(hobbyClass.instructor.name)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Price
                Text(hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(BrandConstants.Colors.primary)
            }
            
            // Next session date if available
            if hobbyClass.startDate > Date() {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .font(BrandConstants.Typography.caption)
                    
                    Text("Next: \(DateFormatter.relativeFuture.string(from: hobbyClass.startDate))")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(BrandConstants.Colors.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func instructorResultContent(_ instructor: Instructor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(instructor.fullName)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let bio = instructor.bio {
                Text(bio)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                // Rating
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(NSDecimalNumber(decimal: instructor.rating).doubleValue) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(BrandConstants.Typography.caption)
                    }
                    Text(instructor.formattedRating)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Experience
                if let experience = instructor.yearsOfExperience {
                    Text("\(experience) years exp.")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Specialties
            if !instructor.specialties.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(instructor.specialties.prefix(3), id: \.self) { specialty in
                            Text(specialty)
                                .font(BrandConstants.Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BrandConstants.Colors.primary.opacity(0.1))
                                .foregroundColor(BrandConstants.Colors.primary)
                                .cornerRadius(BrandConstants.CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func venueResultContent(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(venue.name)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(venue.address)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(.secondary)
                
                Text("\(venue.city), \(venue.state)")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Amenities
            if !venue.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(venue.amenities.prefix(3), id: \.self) { amenity in
                            Text(amenity)
                                .font(BrandConstants.Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(BrandConstants.CornerRadius.sm)
                        }
                    }
                }
            }
        }
    }
}

struct SearchFiltersSheet: View {
    @Binding var filters: SearchFilters
    let onApply: (SearchFilters) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: SearchFilters
    
    init(filters: Binding<SearchFilters>, onApply: @escaping (SearchFilters) -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    ForEach(ClassCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundColor(category.color)
                                .frame(width: 20)
                            
                            Text(category.rawValue)
                            
                            Spacer()
                            
                            if tempFilters.categories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if tempFilters.categories.contains(category) {
                                tempFilters.categories.remove(category)
                            } else {
                                tempFilters.categories.insert(category)
                            }
                        }
                    }
                }
                
                Section("Price Range") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("$\(Int(tempFilters.minPrice))")
                                .frame(width: 40, alignment: .leading)
                            
                            Slider(value: $tempFilters.minPrice, in: 0...500, step: 5)
                            
                            Text("$\(Int(tempFilters.maxPrice))")
                                .frame(width: 40, alignment: .trailing)
                        }
                        
                        Toggle("Include free classes", isOn: $tempFilters.includeFree)
                    }
                }
                
                Section("Availability") {
                    Toggle("Only upcoming classes", isOn: $tempFilters.onlyUpcoming)
                    Toggle("Only available spots", isOn: $tempFilters.onlyAvailable)
                }
                
                Section("Sort By") {
                    ForEach(SearchSortOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.displayName)
                            Spacer()
                            if tempFilters.sortBy == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempFilters.sortBy = option
                        }
                    }
                }
            }
            .navigationTitle("Filter Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilters = SearchFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(tempFilters)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchClassDetailSheet: View {
    let hobbyClass: HobbyClass
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(hobbyClass.title)
                            .font(BrandConstants.Typography.title)
                            .fontWeight(.bold)
                        
                        Text(hobbyClass.description)
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick details
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        SearchDetailCard(icon: "person.circle", label: "Instructor", value: hobbyClass.instructor.name)
                        SearchDetailCard(icon: "location", label: "Venue", value: hobbyClass.venue.name)
                        SearchDetailCard(icon: "clock", label: "Duration", value: "\(hobbyClass.duration) min")
                        SearchDetailCard(icon: "dollarsign.circle", label: "Price", value: hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))")
                    }
                    
                    // Book button
                    if hobbyClass.startDate > Date() {
                        Button("Book This Class") {
                            // Handle booking
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                        .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Class Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchDetailCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(BrandConstants.Colors.primary)
                    .font(BrandConstants.Typography.caption)
                
                Text(label)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        SearchResultsView(query: "pottery")
    }
}