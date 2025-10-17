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
            .padding(.top, 12)

            FilterScrollView(
                categories: viewModel.categories,
                selectedCategory: $viewModel.selectedCategory
            ) {
                viewModel.applyFilters()
            }
            .padding(.vertical, 12)

            DateFilterPicker(selectedFilter: $viewModel.dateFilter)
                .padding(.horizontal)
                .padding(.bottom, 12)

            Group {
                if viewModel.isLoading {
                    LoadingStateView()
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
            await viewModel.loadClasses()
        }
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var classes: [SimpleClass] = []
    @Published var filteredClasses: [SimpleClass] = []
    @Published var categories: [String] = []
    @Published var selectedCategory: String?
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dateFilter: DateFilter = .any {
        didSet { applyFilters() }
    }

    var supabaseService: SimpleSupabaseService?
    private var allClasses: [SimpleClass] = []

    enum DateFilter: String, CaseIterable, Identifiable {
        case any = "Any Time"
        case today = "Today"
        case thisWeek = "This Week"

        var id: DateFilter { self }
        var title: String { rawValue }
    }

    func loadClasses() async {
        guard let supabaseService else { return }
        isLoading = true
        errorMessage = nil

        let fetchedClasses = await supabaseService.fetchClasses()

        if !fetchedClasses.isEmpty {
            let sortedClasses = fetchedClasses.sorted { lhs, rhs in
                let leftDate = lhs.startDate ?? Date.distantFuture
                let rightDate = rhs.startDate ?? Date.distantFuture
                return leftDate < rightDate
            }

            allClasses = sortedClasses
            classes = sortedClasses
            categories = Array(Set(sortedClasses.map(\.category))).sorted()
            applyFilters()
        } else if let error = supabaseService.errorMessage {
            errorMessage = error
        } else {
            classes = []
            allClasses = []
            filteredClasses = []
        }

        isLoading = false
    }

    func applyFilters() {
        guard !allClasses.isEmpty else {
            filteredClasses = []
            return
        }

        var result = allClasses

        if let selectedCategory, !selectedCategory.isEmpty {
            result = result.filter { $0.category == selectedCategory }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { classItem in
                classItem.title.lowercased().contains(query) ||
                classItem.description.lowercased().contains(query) ||
                classItem.instructor.lowercased().contains(query) ||
                classItem.category.lowercased().contains(query)
            }
        }

        result = filter(result, by: dateFilter)

        result.sort { lhs, rhs in
            let leftDate = lhs.startDate ?? Date.distantFuture
            let rightDate = rhs.startDate ?? Date.distantFuture
            return leftDate < rightDate
        }

        filteredClasses = result
    }

    private func filter(_ classes: [SimpleClass], by filter: DateFilter) -> [SimpleClass] {
        switch filter {
        case .any:
            return classes
        case .today:
            return classes.filter { simpleClass in
                guard let startDate = simpleClass.startDate else { return false }
                return Calendar.current.isDateInToday(startDate)
            }
        case .thisWeek:
            return classes.filter { simpleClass in
                guard let startDate = simpleClass.startDate else { return false }
                return Calendar.current.isDate(startDate, equalTo: Date(), toGranularity: .weekOfYear)
            }
        }
    }
}

private struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.blue)

            TextField("Search classes, studios, or instructors", text: $text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .onSubmit(onSubmit)
                .onChange(of: text) { _, newValue in
                    if newValue.isEmpty {
                        onClear()
                    } else {
                        onSubmit()
                    }
                }

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct FilterScrollView: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    let onSelect: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                    onSelect()
                }

                ForEach(categories, id: \.self) { category in
                    FilterChip(title: category, isSelected: selectedCategory == category) {
                        if selectedCategory == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                        onSelect()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterChip: View {
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
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

private struct DateFilterPicker: View {
    @Binding var selectedFilter: SearchViewModel.DateFilter

    var body: some View {
        Picker("Date Filter", selection: $selectedFilter) {
            ForEach(SearchViewModel.DateFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "questionmark.folder")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondary)
            Text("No classes match your search.")
                .font(.headline)
            Text("Try adjusting your filters or search for another class name.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView("Searching classes...")
            Text("We're loading the latest data from Supabase.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

private struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Unable to load classes.")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}
