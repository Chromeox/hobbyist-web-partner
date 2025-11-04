import SwiftUI

struct ClassListView: View {
    @StateObject private var viewModel = ClassListViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedSortOption = SortOption.recommended
    
    enum SortOption: String, CaseIterable {
        case recommended = "Recommended"
        case priceAsc = "Price: Low to High"
        case priceDesc = "Price: High to Low"
        case distance = "Distance"
        case rating = "Rating"
        case startTime = "Start Time"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.classes.isEmpty && !viewModel.isLoading {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Search and Filter Bar
                            VStack(spacing: 12) {
                                // Search Bar
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Search classes...", text: $searchText)
                                        .onChange(of: searchText) { _, newValue in
                                            hapticService.playLight()
                                            viewModel.searchClasses(query: newValue)
                                        }
                                    
                                    if !searchText.isEmpty {
                                        Button {
                                            searchText = ""
                                            hapticService.playLight()
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
                                
                                // Filter Pills
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // Filter Button
                                        FilterPill(
                                            title: "Filters",
                                            icon: "slider.horizontal.3",
                                            isActive: viewModel.hasActiveFilters,
                                            action: {
                                                hapticService.playSelection()
                                                showingFilters = true
                                            }
                                        )
                                        
                                        Divider()
                                            .frame(height: 20)
                                        
                                        // Category Pills
                                        ForEach(viewModel.availableCategories, id: \.self) { category in
                                            FilterPill(
                                                title: category,
                                                icon: nil,
                                                isActive: viewModel.selectedCategories.contains(category),
                                                action: {
                                                    hapticService.playSelection()
                                                    viewModel.toggleCategory(category)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // Sort Bar
                                HStack {
                                    Text("\(viewModel.classes.count) classes")
                                        .font(BrandConstants.Typography.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(SortOption.allCases, id: \.self) { option in
                                            Button {
                                                hapticService.playSelection()
                                                selectedSortOption = option
                                                viewModel.sortClasses(by: option.rawValue)
                                            } label: {
                                                HStack {
                                                    Text(option.rawValue)
                                                    if selectedSortOption == option {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(selectedSortOption.rawValue)
                                                .font(BrandConstants.Typography.subheadline)
                                            Image(systemName: "chevron.down")
                                                .font(BrandConstants.Typography.caption)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            .padding(.top, 8)
                            
                            // Classes List
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.classes) { classItem in
                                    NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                        ClassListItemView(classItem: classItem)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded { _ in
                                        hapticService.playMedium()
                                    })
                                }
                                
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                        .onAppear {
                                            Task {
                                                await viewModel.loadMoreClasses()
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                        }
                    }
                    .refreshable {
                        hapticService.playMedium()
                        await viewModel.refreshClasses()
                    }
                }
                
                if viewModel.isLoading && viewModel.classes.isEmpty {
                    LoadingView()
                }
            }
            .navigationTitle("Classes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hapticService.playLight()
                        viewModel.toggleMapView()
                    } label: {
                        Image(systemName: viewModel.showMapView ? "list.bullet" : "map")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ClassFiltersView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showMapView) {
                ClassMapView(classes: viewModel.classes)
            }
        }
    }
}

// Filter Pill Component
struct FilterPill: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(BrandConstants.Typography.caption)
                }
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// Class List Item View
struct ClassListItemView: View {
    let classItem: ClassItem
    @State private var isFavorite = false
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Class Image
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [classItem.categoryColor.opacity(0.5), classItem.categoryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                    .overlay(
                        VStack {
                            Image(systemName: classItem.icon)
                                .font(BrandConstants.Typography.title2)
                                .foregroundColor(.white)
                            if classItem.isFeatured {
                                Text("Featured")
                                    .font(BrandConstants.Typography.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(4)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Favorite
                    HStack {
                        Text(classItem.name)
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            isFavorite.toggle()
                            hapticService.playLight()
                        } label: {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .secondary)
                                .font(BrandConstants.Typography.subheadline)
                        }
                    }
                    
                    // Instructor
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(classItem.instructor)
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Time and Duration
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(BrandConstants.Typography.caption)
                            Text(classItem.startTime.formatted(date: .omitted, time: .shortened))
                                .font(BrandConstants.Typography.caption)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(BrandConstants.Typography.caption)
                            Text(classItem.duration)
                                .font(BrandConstants.Typography.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Bottom Row
                    HStack {
                        // Location
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(BrandConstants.Typography.caption)
                            Text(classItem.location)
                                .font(BrandConstants.Typography.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Price
                        Text(classItem.price)
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            
            // Spots Available Banner
            if classItem.spotsAvailable < 5 {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(BrandConstants.Typography.caption)
                    Text("Only \(classItem.spotsAvailable) spots left!")
                        .font(BrandConstants.Typography.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                .foregroundColor(.orange)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(BrandConstants.Typography.heroTitle)
                .foregroundColor(.secondary)
            
            Text("No Classes Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your filters or search criteria")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading classes...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Class Filters View
struct ClassFiltersView: View {
    @ObservedObject var viewModel: ClassListViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        NavigationStack {
            Form {
                // Date Section
                Section("Date") {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, displayedComponents: .date)
                }
                
                // Price Section
                Section("Price Range") {
                    VStack {
                        HStack {
                            Text("$\(Int(viewModel.minPrice))")
                            Spacer()
                            Text("$\(Int(viewModel.maxPrice))")
                        }
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Slider(value: $viewModel.minPrice, in: 0...100)
                                .onChange(of: viewModel.minPrice) { _, _ in
                                    hapticService.playLight()
                                }
                            Text("-")
                            Slider(value: $viewModel.maxPrice, in: 100...500)
                                .onChange(of: viewModel.maxPrice) { _, _ in
                                    hapticService.playLight()
                                }
                        }
                    }
                }
                
                // Difficulty Section
                Section("Difficulty Level") {
                    ForEach(["Beginner", "Intermediate", "Advanced", "All Levels"], id: \.self) { level in
                        HStack {
                            Text(level)
                            Spacer()
                            if viewModel.selectedDifficulty.contains(level) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hapticService.playSelection()
                            viewModel.toggleDifficulty(level)
                        }
                    }
                }
                
                // Class Size Section
                Section("Class Size") {
                    Picker("Maximum Size", selection: $viewModel.maxClassSize) {
                        Text("Any").tag(0)
                        Text("Small (≤10)").tag(10)
                        Text("Medium (≤20)").tag(20)
                        Text("Large (≤30)").tag(30)
                    }
                    .onChange(of: viewModel.maxClassSize) { _, _ in
                        hapticService.playSelection()
                    }
                }
                
                // Amenities Section
                Section("Amenities") {
                    ForEach(["Parking", "Showers", "Lockers", "Equipment Provided", "Refreshments"], id: \.self) { amenity in
                        Toggle(amenity, isOn: Binding(
                            get: { viewModel.selectedAmenities.contains(amenity) },
                            set: { isOn in
                                hapticService.playLight()
                                if isOn {
                                    viewModel.selectedAmenities.insert(amenity)
                                } else {
                                    viewModel.selectedAmenities.remove(amenity)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        hapticService.playLight()
                        viewModel.resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        hapticService.playMedium()
                        viewModel.applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// Class Map View
struct ClassMapView: View {
    let classes: [ClassItem]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Map View - \(classes.count) classes")
                .navigationTitle("Map View")
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

struct ClassListView_Previews: PreviewProvider {
    static var previews: some View {
        ClassListView()
            .environmentObject(HapticFeedbackService.shared)
    }
}