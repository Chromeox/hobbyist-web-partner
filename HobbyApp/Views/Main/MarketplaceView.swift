import SwiftUI

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        if viewModel.isLoading && viewModel.classes.isEmpty {
                            LoadingSection()
                        } else {
                            // Featured Classes Section
                            if !viewModel.featuredClasses.isEmpty {
                                FeaturedClassesSection(classes: viewModel.featuredClasses)
                            }
                            
                            // Categories Section
                            if !viewModel.categories.isEmpty {
                                CategoriesSection(
                                    categories: viewModel.categories,
                                    selectedCategory: $selectedCategory
                                )
                            }
                            
                            // All Classes Section
                            if !viewModel.classes.isEmpty {
                                AllClassesSection(classes: filteredClasses)
                            }
                            
                            // Popular Instructors Section
                            if !viewModel.nearbyInstructors.isEmpty {
                                PopularInstructorsSection(instructors: viewModel.nearbyInstructors)
                            }
                            
                            // Popular Venues Section
                            if !viewModel.popularVenues.isEmpty {
                                PopularVenuesSection(venues: viewModel.popularVenues)
                            }
                            
                            // Empty State
                            if viewModel.classes.isEmpty && !viewModel.isLoading {
                                EmptyMarketplaceView()
                            }
                        }
                    }
                    .padding(.bottom, 100) // Extra space for tab bar
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadMarketplaceData()
            }
            .refreshable {
                viewModel.loadMarketplaceData()
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
                Button("Retry") {
                    viewModel.loadMarketplaceData()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search classes, instructors, venues...", text: $searchText)
                        .onSubmit {
                            if !searchText.isEmpty {
                                viewModel.searchClasses(query: searchText)
                            }
                        }
                }
                .padding(12)
                .background(BrandConstants.Colors.background)
                .cornerRadius(BrandConstants.CornerRadius.sm)
                
                // Filter Button
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(BrandConstants.Typography.title3)
                        .foregroundColor(BrandConstants.Colors.primary)
                        .padding(12)
                        .background(BrandConstants.Colors.background)
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(BrandConstants.Colors.surface)
    }
    
    private var filteredClasses: [ClassItem] {
        var classes = viewModel.classes
        
        // Filter by category if selected
        if let category = selectedCategory {
            classes = classes.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            classes = classes.filter { classItem in
                classItem.name.localizedCaseInsensitiveContains(searchText) ||
                classItem.instructor.localizedCaseInsensitiveContains(searchText) ||
                classItem.description.localizedCaseInsensitiveContains(searchText) ||
                classItem.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return classes
    }
}

// MARK: - Featured Classes Section

struct FeaturedClassesSection: View {
    let classes: [ClassItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Classes")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    // Navigate to all featured classes
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(classes) { classItem in
                        FeaturedClassCard(classItem: classItem)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedClassCard: View {
    let classItem: ClassItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(classItem.categoryColor.opacity(0.3))
                    .frame(width: 280, height: 160)
                    .overlay(
                        Image(systemName: classItem.icon)
                            .font(.largeTitle)
                            .foregroundColor(classItem.categoryColor)
                    )
                
                // Featured Badge
                Text("FEATURED")
                    .font(BrandConstants.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(4)
                    .padding(8)
            }
            .cornerRadius(BrandConstants.CornerRadius.md)
            
            // Class Info
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("with \(classItem.instructor)")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(classItem.rating)
                            .font(BrandConstants.Typography.caption)
                    }
                    
                    Spacer()
                    
                    Text(classItem.price)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandConstants.Colors.primary)
                }
            }
        }
        .frame(width: 280)
    }
}

// MARK: - Categories Section

struct CategoriesSection: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Categories")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // All Categories Button
                    CategoryChip(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : BrandConstants.Colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? BrandConstants.Colors.primary : BrandConstants.Colors.primary.opacity(0.1))
                .cornerRadius(BrandConstants.CornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - All Classes Section

struct AllClassesSection: View {
    let classes: [ClassItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Classes")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(classes.count) classes")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(classes) { classItem in
                    ClassListCard(classItem: classItem)
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct ClassListCard: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Class Image
            Rectangle()
                .fill(classItem.categoryColor.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: classItem.icon)
                        .font(.title2)
                        .foregroundColor(classItem.categoryColor)
                )
                .cornerRadius(BrandConstants.CornerRadius.sm)
            
            // Class Info
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("with \(classItem.instructor)")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                Text(classItem.venueName)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(classItem.duration)
                            .font(BrandConstants.Typography.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(classItem.rating)
                            .font(BrandConstants.Typography.caption)
                    }
                }
            }
            
            Spacer()
            
            // Price and Book Button
            VStack(alignment: .trailing, spacing: 8) {
                Text(classItem.price)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(BrandConstants.Colors.primary)
                
                Button("Book") {
                    // Navigate to booking
                }
                .font(BrandConstants.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BrandConstants.Colors.primary)
                .cornerRadius(BrandConstants.CornerRadius.sm)
            }
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Popular Instructors Section

struct PopularInstructorsSection: View {
    let instructors: [Instructor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Instructors")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    // Navigate to all instructors
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(instructors) { instructor in
                        InstructorCard(instructor: instructor)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InstructorCard: View {
    let instructor: Instructor
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: instructor.profileImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(BrandConstants.Colors.primary.opacity(0.3))
                    .overlay(
                        Text(String(instructor.name.prefix(1)))
                            .font(BrandConstants.Typography.title2)
                            .foregroundColor(BrandConstants.Colors.primary)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(instructor.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(instructor.specialties.first ?? "Instructor")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", instructor.rating))
                        .font(BrandConstants.Typography.caption)
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Popular Venues Section

struct PopularVenuesSection: View {
    let venues: [Venue]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Venues")
                    .font(BrandConstants.Typography.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    // Navigate to all venues
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(venues) { venue in
                        VenueCard(venue: venue)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VenueCard: View {
    let venue: Venue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Venue Image
            Rectangle()
                .fill(LinearGradient(
                    colors: [BrandConstants.Colors.teal.opacity(0.6), BrandConstants.Colors.primary.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 200, height: 100)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.title)
                        .foregroundColor(.white)
                )
                .cornerRadius(BrandConstants.CornerRadius.sm)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(venue.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("\(venue.address), \(venue.city)")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", venue.rating))
                            .font(BrandConstants.Typography.caption)
                    }
                    
                    Spacer()
                    
                    Text("\(venue.totalClasses) classes")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 200)
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Supporting Views

struct LoadingSection: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading marketplace...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct EmptyMarketplaceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "storefront")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Classes Available")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("Check back later for new classes, or try adjusting your search filters.")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Refresh") {
                // Refresh action
            }
            .padding()
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
}

#Preview {
    MarketplaceView()
}