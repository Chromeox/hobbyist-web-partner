import SwiftUI

struct SavedSearchesView: View {
    @StateObject private var searchService = SearchService.shared
    @State private var showingCreateSearch = false
    @State private var searchToEdit: SavedSearch?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if searchService.savedSearches.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchService.savedSearches) { savedSearch in
                            SavedSearchRow(
                                savedSearch: savedSearch,
                                onEdit: {
                                    searchToEdit = savedSearch
                                },
                                onDelete: {
                                    searchService.removeSavedSearch(savedSearch)
                                },
                                onUse: {
                                    // This would trigger using the saved search
                                    dismiss()
                                }
                            )
                        }
                        .onDelete(perform: deleteSavedSearches)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved Searches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingCreateSearch = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BrandConstants.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BrandConstants.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateSearch) {
            CreateSavedSearchView { name, query, filters in
                searchService.saveSearch(name: name, query: query, filters: filters)
                showingCreateSearch = false
            }
        }
        .sheet(item: $searchToEdit) { savedSearch in
            EditSavedSearchView(savedSearch: savedSearch) { updatedSearch in
                searchService.removeSavedSearch(savedSearch)
                searchService.saveSearch(
                    name: updatedSearch.name,
                    query: updatedSearch.query,
                    filters: updatedSearch.filters
                )
                searchToEdit = nil
            }
        }
    }
    
    private func deleteSavedSearches(offsets: IndexSet) {
        for index in offsets {
            let savedSearch = searchService.savedSearches[index]
            searchService.removeSavedSearch(savedSearch)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("No Saved Searches")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Save your favorite searches for quick access later")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Saved Search Row

struct SavedSearchRow: View {
    let savedSearch: SavedSearch
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and Date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(savedSearch.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Created \(formatDate(savedSearch.createdAt))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Use Search", action: onUse)
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Query
            if !savedSearch.query.isEmpty {
                Text("Query: \"\(savedSearch.query)\"")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Active Filters Summary
            if savedSearch.filters.hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(getFilterSummary(savedSearch.filters), id: \.self) { filterText in
                            Text(filterText)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(BrandConstants.Colors.primary.opacity(0.1))
                                )
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onUse)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func getFilterSummary(_ filters: SearchFilters) -> [String] {
        var summary: [String] = []
        
        if !filters.categories.isEmpty {
            summary.append("\(filters.categories.count) categories")
        }
        
        if filters.minPrice > 0 || filters.maxPrice < 500 {
            summary.append("Price: $\(Int(filters.minPrice))-$\(Int(filters.maxPrice))")
        }
        
        if filters.dateRange != .any {
            summary.append(filters.dateRange.rawValue)
        }
        
        if filters.distance != .anywhere {
            summary.append(filters.distance.rawValue)
        }
        
        if filters.minRating > 0 {
            summary.append("\(String(format: "%.1f", filters.minRating))+ stars")
        }
        
        return summary
    }
}

// MARK: - Create Saved Search View

struct CreateSavedSearchView: View {
    let onSave: (String, String, SearchFilters) -> Void
    
    @State private var name = ""
    @State private var query = ""
    @State private var filters = SearchFilters()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Search Details") {
                    TextField("Search Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Search Query (optional)", text: $query)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Filters") {
                    NavigationLink("Configure Filters") {
                        EnhancedSearchFiltersView(
                            filters: filters,
                            onApply: { newFilters in
                                filters = newFilters
                            },
                            onReset: {
                                filters = SearchFilters()
                            }
                        )
                    }
                    
                    if filters.hasActiveFilters {
                        Text("\(filters.activeFilterCount) active filters")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Saved Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, query, filters)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Saved Search View

struct EditSavedSearchView: View {
    let savedSearch: SavedSearch
    let onSave: (SavedSearch) -> Void
    
    @State private var name: String
    @State private var query: String
    @State private var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss
    
    init(savedSearch: SavedSearch, onSave: @escaping (SavedSearch) -> Void) {
        self.savedSearch = savedSearch
        self.onSave = onSave
        self._name = State(initialValue: savedSearch.name)
        self._query = State(initialValue: savedSearch.query)
        self._filters = State(initialValue: savedSearch.filters)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Search Details") {
                    TextField("Search Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Search Query", text: $query)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Filters") {
                    NavigationLink("Configure Filters") {
                        EnhancedSearchFiltersView(
                            filters: filters,
                            onApply: { newFilters in
                                filters = newFilters
                            },
                            onReset: {
                                filters = SearchFilters()
                            }
                        )
                    }
                    
                    if filters.hasActiveFilters {
                        Text("\(filters.activeFilterCount) active filters")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedSearch = SavedSearch(
                            name: name,
                            query: query,
                            filters: filters
                        )
                        onSave(updatedSearch)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Search History View

struct SearchHistoryView: View {
    @StateObject private var searchService = SearchService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if searchService.recentSearches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("No Recent Searches")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("Your search history will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchService.recentSearches) { historyItem in
                            SearchHistoryRow(
                                historyItem: historyItem,
                                onUse: {
                                    // Use this search
                                    dismiss()
                                },
                                onDelete: {
                                    searchService.removeFromSearchHistory(historyItem.query)
                                }
                            )
                        }
                        .onDelete(perform: deleteHistoryItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchService.recentSearches.isEmpty {
                        Button("Clear All") {
                            searchService.clearSearchHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BrandConstants.Colors.primary)
                }
            }
        }
    }
    
    private func deleteHistoryItems(offsets: IndexSet) {
        for index in offsets {
            let historyItem = searchService.recentSearches[index]
            searchService.removeFromSearchHistory(historyItem.query)
        }
    }
}

// MARK: - Search History Row

struct SearchHistoryRow: View {
    let historyItem: SearchHistoryItem
    let onUse: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(historyItem.query)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack {
                    Text(formatDate(historyItem.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(historyItem.resultCount) results")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Use") {
                onUse()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(BrandConstants.Colors.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(BrandConstants.Colors.primary.opacity(0.1))
            )
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Use Search", action: onUse)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SavedSearchesView()
}