import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var supabaseService: SimpleSupabaseService
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                text: $viewModel.searchText,
                onSubmit: {
                    viewModel.applyFilters()
                },
                onClear: {
                    viewModel.searchText = ""
                    viewModel.applyFilters()
                }
            )
            .padding(.horizontal)
            .padding(.top, BrandConstants.Spacing.md)

            FilterScrollView(
                categories: viewModel.categories,
                selectedCategory: $viewModel.selectedCategory
            ) {
                viewModel.applyFilters()
            }
            .padding(.vertical, BrandConstants.Spacing.md)

            DateFilterPicker(selectedFilter: $viewModel.dateFilter)
                .padding(.horizontal)
                .padding(.bottom, BrandConstants.Spacing.md)

            Group {
                if viewModel.isLoading {
                    SkeletonList(.searchResult, count: 6)
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        Task { await viewModel.loadClasses() }
                    }
                } else if viewModel.filteredClasses.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(viewModel.filteredClasses, id: \.id) { classItem in
                            HomeClassCard(classItem: classItem, style: .standard)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Search")
        .task {
            viewModel.supabaseService = supabaseService
            await viewModel.loadClasses()
        }
        .refreshable {
            // Refresh search results if there's an active search
            if viewModel.hasSearched {
                Task { await viewModel.performSearch() }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleQuickAction(_ action: QuickAction) {
        switch action {
        case .nearby:
            viewModel.searchNearby()
        case .free:
            viewModel.searchFreeClasses()
        case .weekend:
            viewModel.searchThisWeekend()
        case .tonight:
            // Could implement tonight search
            break
        }
    }
    
    private func handleResultTap(_ result: SearchResult) {
        // Navigate to appropriate detail view based on result type
        switch result {
        case .class(let hobbyClass):
            // Navigate to class detail
            break
        case .instructor(let instructor):
            // Navigate to instructor profile
            break
        case .venue(let venue):
            // Navigate to venue detail
            break
        }
    }
}

// MARK: - Quick Action Enum

enum QuickAction {
    case nearby
    case free
    case weekend
    case tonight
}

// Old SearchView components removed - now using comprehensive SearchViewModel and enhanced components
