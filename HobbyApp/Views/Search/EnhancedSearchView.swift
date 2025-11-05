import SwiftUI
import CoreLocation

struct EnhancedSearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @State private var showingFilters = false
    @State private var showingMapView = false
    @State private var selectedResultFilter: SearchFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                SearchHeaderView(
                    searchQuery: $viewModel.searchQuery,
                    isListening: $viewModel.isListeningForVoice,
                    suggestions: viewModel.autocompleteSuggestions,
                    onVoiceSearch: {
                        viewModel.startVoiceSearch()
                    },
                    onSuggestionTap: { suggestion in
                        viewModel.selectAutocompleteSuggestion(suggestion)
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search Scope Selector
                SearchScopeSelector(
                    selectedScope: $viewModel.searchScope,
                    results: viewModel.filteredResults
                )
                .padding(.horizontal)
                
                // Quick Filters
                if !viewModel.hasSearched && viewModel.searchQuery.isEmpty {
                    SearchDiscoveryView(
                        quickFilterPresets: viewModel.quickFilterPresets,
                        recentSearches: viewModel.recentSearches,
                        popularSearches: viewModel.popularSearches,
                        trendingCategories: viewModel.trendingCategories,
                        onQuickFilter: { preset in
                            viewModel.applyQuickFilter(preset)
                        },
                        onRecentSearch: { query in
                            viewModel.useRecentSearch(query)
                        },
                        onPopularSearch: { query in
                            viewModel.usePopularSearch(query)
                        },
                        onTrendingCategory: { category in
                            viewModel.searchByCategory(category)
                        }
                    )
                } else {
                    // Search Results Area
                    VStack(spacing: 0) {
                        // Active Filters and Sort Bar
                        SearchControlsBar(
                            activeFilterCount: viewModel.activeFilterCount,
                            selectedSort: $viewModel.selectedSortOption,
                            showingMapView: $showingMapView,
                            onFiltersPressed: {
                                showingFilters = true
                            },
                            onClearFilters: {
                                viewModel.resetFilters()
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Results Content
                        SearchResultsContent(
                            viewModel: viewModel,
                            selectedFilter: $selectedResultFilter,
                            showingMapView: showingMapView
                        )
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .sheet(isPresented: $showingFilters) {
                EnhancedSearchFiltersView(
                    filters: viewModel.currentFilters,
                    onApply: { filters in
                        viewModel.applyFilters(filters)
                        showingFilters = false
                    },
                    onReset: {
                        viewModel.resetFilters()
                        showingFilters = false
                    }
                )
            }
        }
        .task {
            viewModel.supabaseService = supabaseService
            await viewModel.loadInitialData()
        }
        .onChange(of: viewModel.voiceSearchText) { _, newText in
            if !newText.isEmpty {
                viewModel.searchQuery = newText
            }
        }
    }
}

// MARK: - Search Header View

struct SearchHeaderView: View {
    @Binding var searchQuery: String
    @Binding var isListening: Bool
    let suggestions: [String]
    let onVoiceSearch: () -> Void
    let onSuggestionTap: (String) -> Void
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Search Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("Search classes, instructors, or venues...", text: $searchQuery)
                        .focused($isSearchFocused)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Voice Search Button
                Button(action: onVoiceSearch) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isListening ? .white : BrandConstants.Colors.primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isListening ? BrandConstants.Colors.primary : Color(.systemGray6))
                        )
                        .scaleEffect(isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isListening)
                }
            }
            
            // Autocomplete Suggestions
            if !suggestions.isEmpty && isSearchFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                onSuggestionTap(suggestion)
                                isSearchFocused = false
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(BrandConstants.Colors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(BrandConstants.Colors.primary.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Search Scope Selector

struct SearchScopeSelector: View {
    @Binding var selectedScope: SearchScope
    let results: [SearchResult]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SearchScope.allCases) { scope in
                Button {
                    selectedScope = scope
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: scope.iconName)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(scope.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            
                            if !results.isEmpty {
                                Text("(\(resultCount(for: scope)))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(selectedScope == scope ? BrandConstants.Colors.primary : .secondary)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedScope == scope ? BrandConstants.Colors.primary : .clear)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func resultCount(for scope: SearchScope) -> Int {
        switch scope {
        case .all:
            return results.count
        case .classes:
            return results.filter { if case .class = $0 { return true }; return false }.count
        case .instructors:
            return results.filter { if case .instructor = $0 { return true }; return false }.count
        case .venues:
            return results.filter { if case .venue = $0 { return true }; return false }.count
        }
    }
}

// MARK: - Search Controls Bar

struct SearchControlsBar: View {
    let activeFilterCount: Int
    @Binding var selectedSort: SearchSortOption
    @Binding var showingMapView: Bool
    let onFiltersPressed: () -> Void
    let onClearFilters: () -> Void
    
    var body: some View {
        HStack {
            // Filters Button
            Button(action: onFiltersPressed) {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Filters")
                        .font(.system(size: 14, weight: .medium))
                    
                    if activeFilterCount > 0 {
                        Text("(\(activeFilterCount))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BrandConstants.Colors.primary)
                    }
                }
                .foregroundColor(activeFilterCount > 0 ? BrandConstants.Colors.primary : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(activeFilterCount > 0 ? BrandConstants.Colors.primary.opacity(0.1) : Color(.systemGray6))
                )
            }
            
            if activeFilterCount > 0 {
                Button("Clear", action: onClearFilters)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BrandConstants.Colors.primary)
            }
            
            Spacer()
            
            // Sort Menu
            Menu {
                ForEach(SearchSortOption.allCases, id: \.self) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedSort.iconName)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Sort")
                        .font(.system(size: 14, weight: .medium))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Map Toggle
            Button {
                showingMapView.toggle()
            } label: {
                Image(systemName: showingMapView ? "list.bullet" : "map")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }
}

// MARK: - Search Results Content

struct SearchResultsContent: View {
    @ObservedObject var viewModel: SearchViewModel
    @Binding var selectedFilter: SearchFilter
    let showingMapView: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if showingMapView {
                SearchMapView(
                    results: viewModel.filteredResults,
                    userLocation: viewModel.currentLocation
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if viewModel.isSearching {
                    SearchLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    SearchErrorView(message: error) {
                        Task {
                            await viewModel.performSearch()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredResults.isEmpty && viewModel.hasSearched {
                    SearchEmptyView(query: viewModel.searchQuery)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    SearchResultsList(
                        results: viewModel.filteredResults,
                        hasMoreResults: viewModel.hasMoreResults,
                        isLoadingMore: viewModel.isSearching,
                        onLoadMore: {
                            Task {
                                await viewModel.loadMoreResults()
                            }
                        },
                        onResultTap: { result in
                            // Handle result navigation
                            // This would navigate to the appropriate detail view
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Loading, Error, and Empty States

struct SearchLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(BrandConstants.Colors.primary)
            
            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct SearchErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.orange)
            
            Text("Search Error")
                .font(.system(size: 18, weight: .semibold))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: onRetry)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(BrandConstants.Colors.primary)
                .cornerRadius(8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct SearchEmptyView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.system(size: 18, weight: .semibold))
            
            Text("We couldn't find any results for \"\(query)\". Try adjusting your search or filters.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Suggestions:")
                    .font(.system(size: 14, weight: .medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Check your spelling")
                    Text("• Try more general terms")
                    Text("• Remove some filters")
                    Text("• Search for a different category")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EnhancedSearchView()
        .environmentObject(SimpleSupabaseService.shared)
}