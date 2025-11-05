import SwiftUI
import CoreLocation

struct EnhancedSearchFiltersView: View {
    @Binding var filters: SearchFilters
    let currentLocation: CLLocation?
    let onApply: (SearchFilters) -> Void
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: SearchFilters
    @State private var selectedTab: FilterTab = .categories
    
    enum FilterTab: String, CaseIterable, Identifiable {
        case categories = "Categories"
        case price = "Price"
        case time = "Time"
        case location = "Location"
        case details = "Details"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .categories: return "tag.fill"
            case .price: return "dollarsign.circle.fill"
            case .time: return "clock.fill"
            case .location: return "location.fill"
            case .details: return "slider.horizontal.3"
            }
        }
    }
    
    init(filters: Binding<SearchFilters>, currentLocation: CLLocation?, onApply: @escaping (SearchFilters) -> Void, onReset: @escaping () -> Void) {
        self._filters = filters
        self.currentLocation = currentLocation
        self.onApply = onApply
        self.onReset = onReset
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Tabs
                FilterTabsView(
                    selectedTab: $selectedTab,
                    activeFilterCounts: getActiveFilterCounts()
                )
                .padding(.top)
                
                // Filter Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        switch selectedTab {
                        case .categories:
                            CategoriesFilterView(filters: $tempFilters)
                        case .price:
                            PriceFilterView(filters: $tempFilters)
                        case .time:
                            TimeFilterView(filters: $tempFilters)
                        case .location:
                            LocationFilterView(filters: $tempFilters, currentLocation: currentLocation)
                        case .details:
                            DetailsFilterView(filters: $tempFilters)
                        }
                    }
                    .padding()
                }
                
                // Apply Button
                VStack(spacing: BrandConstants.Spacing.sm) {
                    if tempFilters.hasActiveFilters {
                        HStack {
                            Text("\(tempFilters.activeFilterCount) active filters")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: BrandConstants.Spacing.md) {
                        Button("Reset All") {
                            tempFilters = SearchFilters()
                            onReset()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!tempFilters.hasActiveFilters)
                        
                        Button("Apply Filters") {
                            onApply(tempFilters)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BrandConstants.Colors.primary)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 1, y: -1)
                )
            }
            .navigationTitle("Filters")
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
    
    private func getActiveFilterCounts() -> [FilterTab: Int] {
        var counts: [FilterTab: Int] = [:]
        
        counts[.categories] = tempFilters.categories.isEmpty ? 0 : 1
        counts[.price] = (tempFilters.minPrice > 0 || tempFilters.maxPrice < 500 || !tempFilters.includeFree) ? 1 : 0
        counts[.time] = (tempFilters.dateRange != .any || !tempFilters.timeOfDay.isEmpty || !tempFilters.daysOfWeek.isEmpty) ? 1 : 0
        counts[.location] = (tempFilters.distance != .anywhere || !tempFilters.neighborhoods.isEmpty) ? 1 : 0
        counts[.details] = (tempFilters.duration != .any || tempFilters.classSize != .any || tempFilters.minRating > 0 || tempFilters.hasParking || tempFilters.isAccessible) ? 1 : 0
        
        return counts
    }
}

// MARK: - Filter Tabs View

struct FilterTabsView: View {
    @Binding var selectedTab: EnhancedSearchFiltersView.FilterTab
    let activeFilterCounts: [EnhancedSearchFiltersView.FilterTab: Int]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BrandConstants.Spacing.sm) {
                ForEach(EnhancedSearchFiltersView.FilterTab.allCases) { tab in
                    FilterTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        activeCount: activeFilterCounts[tab] ?? 0,
                        onTap: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterTabButton: View {
    let tab: EnhancedSearchFiltersView.FilterTab
    let isSelected: Bool
    let activeCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: tab.iconName)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(tab.rawValue)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.red))
                    }
                }
                .padding(.horizontal, BrandConstants.Spacing.md)
                .padding(.vertical, BrandConstants.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                        .fill(isSelected ? BrandConstants.Colors.primary : Color(.secondarySystemBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Categories Filter View

struct CategoriesFilterView: View {
    @Binding var filters: SearchFilters
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.lg) {
            FilterSectionHeader(
                title: "Class Categories",
                description: "Select the types of classes you're interested in"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.md) {
                ForEach(ClassCategory.allCases, id: \.self) { category in
                    CategorySelectionCard(
                        category: category,
                        isSelected: filters.categories.contains(category),
                        onToggle: {
                            if filters.categories.contains(category) {
                                filters.categories.remove(category)
                            } else {
                                filters.categories.insert(category)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct CategorySelectionCard: View {
    let category: ClassCategory
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: BrandConstants.Spacing.sm) {
                Image(systemName: category.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : categoryColor(for: category))
                
                Text(category.rawValue)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(BrandConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(isSelected ? BrandConstants.Colors.primary : categoryColor(for: category).opacity(0.1))
                    .stroke(isSelected ? BrandConstants.Colors.primary : categoryColor(for: category).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryColor(for category: ClassCategory) -> Color {
        switch category {
        case .arts: return BrandConstants.Colors.Category.arts
        case .cooking: return BrandConstants.Colors.Category.cooking
        case .photography: return BrandConstants.Colors.Category.photography
        case .music: return BrandConstants.Colors.Category.music
        default: return BrandConstants.Colors.primary
        }
    }
}

// MARK: - Price Filter View

struct PriceFilterView: View {
    @Binding var filters: SearchFilters
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.lg) {
            FilterSectionHeader(
                title: "Price Range",
                description: "Set your budget for classes"
            )
            
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                // Price Range Slider
                VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                    HStack {
                        Text("$\(Int(filters.minPrice))")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("$\(Int(filters.maxPrice))")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                    }
                    
                    // Custom Range Slider
                    PriceRangeSlider(
                        minValue: $filters.minPrice,
                        maxValue: $filters.maxPrice,
                        range: 0...500
                    )
                }
                
                // Include Free Classes Toggle
                Toggle("Include free classes", isOn: $filters.includeFree)
                    .font(BrandConstants.Typography.subheadline)
                
                // Quick Price Buttons
                VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                    Text("Quick selections:")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BrandConstants.Spacing.sm) {
                            QuickPriceButton(title: "Free Only", range: 0...0, filters: $filters)
                            QuickPriceButton(title: "Under $25", range: 0...25, filters: $filters)
                            QuickPriceButton(title: "$25-$50", range: 25...50, filters: $filters)
                            QuickPriceButton(title: "$50-$100", range: 50...100, filters: $filters)
                            QuickPriceButton(title: "$100+", range: 100...500, filters: $filters)
                        }
                    }
                }
            }
        }
    }
}

struct QuickPriceButton: View {
    let title: String
    let range: ClosedRange<Double>
    @Binding var filters: SearchFilters
    
    private var isSelected: Bool {
        return filters.minPrice == range.lowerBound && filters.maxPrice == range.upperBound
    }
    
    var body: some View {
        Button {
            filters.minPrice = range.lowerBound
            filters.maxPrice = range.upperBound
            if range.lowerBound == 0 && range.upperBound == 0 {
                filters.includeFree = true
            }
        } label: {
            Text(title)
                .font(BrandConstants.Typography.caption)
                .fontWeight(.medium)
                .padding(.horizontal, BrandConstants.Spacing.sm)
                .padding(.vertical, BrandConstants.Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? BrandConstants.Colors.primary : Color(.secondarySystemBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Time Filter View

struct TimeFilterView: View {
    @Binding var filters: SearchFilters
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.lg) {
            // Date Range
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "When",
                    description: "Choose when you'd like to take classes"
                )
                
                ForEach(DateRange.allCases, id: \.self) { dateRange in
                    FilterSelectionRow(
                        title: dateRange.rawValue,
                        isSelected: filters.dateRange == dateRange,
                        onTap: { filters.dateRange = dateRange }
                    )
                }
            }
            
            Divider()
            
            // Time of Day
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Time of Day",
                    description: "Select preferred times"
                )
                
                ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                    FilterSelectionRow(
                        title: timeOfDay.rawValue,
                        isSelected: filters.timeOfDay.contains(timeOfDay),
                        onTap: {
                            if filters.timeOfDay.contains(timeOfDay) {
                                filters.timeOfDay.remove(timeOfDay)
                            } else {
                                filters.timeOfDay.insert(timeOfDay)
                            }
                        }
                    )
                }
            }
            
            Divider()
            
            // Days of Week
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Days of Week",
                    description: "Select available days"
                )
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                    ForEach(DayOfWeek.allCases, id: \.self) { dayOfWeek in
                        DaySelectionButton(
                            day: dayOfWeek,
                            isSelected: filters.daysOfWeek.contains(dayOfWeek),
                            onToggle: {
                                if filters.daysOfWeek.contains(dayOfWeek) {
                                    filters.daysOfWeek.remove(dayOfWeek)
                                } else {
                                    filters.daysOfWeek.insert(dayOfWeek)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Location Filter View

struct LocationFilterView: View {
    @Binding var filters: SearchFilters
    let currentLocation: CLLocation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.lg) {
            // Distance
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Distance",
                    description: currentLocation != nil ? "Find classes near your location" : "Enable location for distance filtering"
                )
                
                ForEach(DistanceRange.allCases, id: \.self) { distanceRange in
                    FilterSelectionRow(
                        title: distanceRange.rawValue,
                        isSelected: filters.distance == distanceRange,
                        isDisabled: currentLocation == nil && distanceRange != .anywhere,
                        onTap: { filters.distance = distanceRange }
                    )
                }
            }
            
            Divider()
            
            // Neighborhoods
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Vancouver Neighborhoods",
                    description: "Select specific areas"
                )
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                    ForEach(VancouverNeighborhoods.popular, id: \.self) { neighborhood in
                        NeighborhoodSelectionButton(
                            neighborhood: neighborhood,
                            isSelected: filters.neighborhoods.contains(neighborhood),
                            onToggle: {
                                if filters.neighborhoods.contains(neighborhood) {
                                    filters.neighborhoods.remove(neighborhood)
                                } else {
                                    filters.neighborhoods.insert(neighborhood)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Details Filter View

struct DetailsFilterView: View {
    @Binding var filters: SearchFilters
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrandConstants.Spacing.lg) {
            // Duration
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Class Duration",
                    description: "How long would you like classes to be?"
                )
                
                ForEach(DurationRange.allCases, id: \.self) { duration in
                    FilterSelectionRow(
                        title: duration.rawValue,
                        isSelected: filters.duration == duration,
                        onTap: { filters.duration = duration }
                    )
                }
            }
            
            Divider()
            
            // Class Size
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Class Size",
                    description: "Preferred group size"
                )
                
                ForEach(ClassSizeRange.allCases, id: \.self) { classSize in
                    FilterSelectionRow(
                        title: classSize.rawValue,
                        isSelected: filters.classSize == classSize,
                        onTap: { filters.classSize = classSize }
                    )
                }
            }
            
            Divider()
            
            // Rating Filter
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Minimum Rating",
                    description: "Only show highly rated classes"
                )
                
                HStack {
                    Text("Any Rating")
                        .font(BrandConstants.Typography.subheadline)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", filters.minRating))+ stars")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                }
                
                Slider(value: $filters.minRating, in: 0...5, step: 0.5)
                    .tint(BrandConstants.Colors.primary)
            }
            
            Divider()
            
            // Additional Options
            VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                FilterSectionHeader(
                    title: "Additional Requirements",
                    description: "Special accommodations and features"
                )
                
                VStack(spacing: BrandConstants.Spacing.sm) {
                    Toggle("Available parking", isOn: $filters.hasParking)
                        .font(BrandConstants.Typography.subheadline)
                    
                    Toggle("Wheelchair accessible", isOn: $filters.isAccessible)
                        .font(BrandConstants.Typography.subheadline)
                    
                    Toggle("Include online classes", isOn: $filters.allowsOnline)
                        .font(BrandConstants.Typography.subheadline)
                    
                    Toggle("Only upcoming classes", isOn: $filters.onlyUpcoming)
                        .font(BrandConstants.Typography.subheadline)
                    
                    Toggle("Only available spots", isOn: $filters.onlyAvailable)
                        .font(BrandConstants.Typography.subheadline)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterSectionHeader: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(BrandConstants.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FilterSelectionRow: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    init(title: String, isSelected: Bool, isDisabled: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BrandConstants.Colors.primary)
                }
            }
            .padding(.vertical, BrandConstants.Spacing.sm)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

struct DaySelectionButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(day.rawValue)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BrandConstants.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                        .fill(isSelected ? BrandConstants.Colors.primary : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NeighborhoodSelectionButton: View {
    let neighborhood: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(neighborhood)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BrandConstants.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                        .fill(isSelected ? BrandConstants.Colors.teal : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Price Range Slider

struct PriceRangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minPosition = CGFloat((minValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * width
            let maxPosition = CGFloat((maxValue - range.lowerBound) / (range.upperBound - range.lowerBound)) * width
            
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Active range
                Rectangle()
                    .fill(BrandConstants.Colors.primary)
                    .frame(width: maxPosition - minPosition, height: 4)
                    .offset(x: minPosition)
                    .cornerRadius(2)
                
                // Min thumb
                Circle()
                    .fill(BrandConstants.Colors.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: minPosition - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(0, value.location.x), maxPosition)
                                minValue = range.lowerBound + (Double(newPosition / width) * (range.upperBound - range.lowerBound))
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(BrandConstants.Colors.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: maxPosition - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(minPosition, value.location.x), width)
                                maxValue = range.lowerBound + (Double(newPosition / width) * (range.upperBound - range.lowerBound))
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}

#Preview {
    EnhancedSearchFiltersView(
        filters: .constant(SearchFilters()),
        currentLocation: nil,
        onApply: { _ in },
        onReset: {}
    )
}