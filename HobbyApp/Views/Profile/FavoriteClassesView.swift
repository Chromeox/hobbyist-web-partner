import SwiftUI

struct FavoriteClassesView: View {
    @StateObject private var viewModel = FavoriteClassesViewModel()
    @State private var showingFilters = false
    @State private var selectedClass: HobbyClass?
    @State private var showingClassDetail = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                Group {
                    if viewModel.isLoading && viewModel.favoriteClasses.isEmpty {
                        loadingView
                    } else if viewModel.filteredClasses.isEmpty && !searchText.isEmpty {
                        searchEmptyView
                    } else if viewModel.favoriteClasses.isEmpty {
                        emptyFavoritesView
                    } else {
                        favoritesContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Favorite Classes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFilters = true }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: { viewModel.sortBy(.recent) }) {
                            Label("Recently Added", systemImage: "clock")
                        }
                        
                        Button(action: { viewModel.sortBy(.alphabetical) }) {
                            Label("Alphabetical", systemImage: "textformat.abc")
                        }
                        
                        Button(action: { viewModel.sortBy(.price) }) {
                            Label("Price", systemImage: "dollarsign.circle")
                        }
                        
                        Button(action: { viewModel.sortBy(.rating) }) {
                            Label("Rating", systemImage: "star")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.loadFavorites()
            }
            .onAppear {
                Task {
                    await viewModel.loadFavorites()
                }
            }
            .sheet(isPresented: $showingFilters) {
                FavoritesFiltersSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingClassDetail) {
                if let hobbyClass = selectedClass {
                    ClassDetailSheet(hobbyClass: hobbyClass)
                }
            }
            .onChange(of: searchText) { newValue in
                viewModel.updateSearchQuery(newValue)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search favorite classes...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.sm)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your favorites...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your search terms")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyFavoritesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Favorite Classes Yet")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("Start exploring classes and tap the heart icon to save your favorites here!")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Discover Classes") {
                // Navigate to discovery/search
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var favoritesContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredClasses) { hobbyClass in
                    FavoriteClassCard(
                        hobbyClass: hobbyClass,
                        onTap: {
                            selectedClass = hobbyClass
                            showingClassDetail = true
                        },
                        onRemoveFavorite: {
                            Task {
                                await viewModel.removeFavorite(hobbyClass)
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

struct FavoriteClassCard: View {
    let hobbyClass: HobbyClass
    let onTap: () -> Void
    let onRemoveFavorite: () -> Void
    @State private var showingRemoveAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with image and favorite button
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: hobbyClass.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        hobbyClass.category.color.opacity(0.6),
                                        hobbyClass.category.color.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: hobbyClass.category.iconName)
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(height: 120)
                    .clipped()
                    
                    // Remove favorite button
                    Button(action: {
                        showingRemoveAlert = true
                    }) {
                        Image(systemName: "heart.fill")
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(.red)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 32, height: 32)
                            )
                    }
                    .padding(12)
                }
                
                // Class information
                VStack(alignment: .leading, spacing: 8) {
                    // Title and category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hobbyClass.title)
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(hobbyClass.category.rawValue)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(hobbyClass.category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(hobbyClass.category.color.opacity(0.1))
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                    }
                    
                    // Instructor and venue
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.secondary)
                                .font(BrandConstants.Typography.caption)
                            
                            Text(hobbyClass.instructor.name)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                                .font(BrandConstants.Typography.caption)
                            
                            Text(hobbyClass.venue.name)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Rating and price
                    HStack {
                        // Rating
                        HStack(spacing: 4) {
                            ForEach(0..<5) { star in
                                Image(systemName: star < Int(hobbyClass.averageRating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(BrandConstants.Typography.caption)
                            }
                            Text("(\(hobbyClass.totalReviews))")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Price
                        Text(hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(BrandConstants.Colors.primary)
                    }
                    
                    // Next available date
                    if hobbyClass.startDate > Date() {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(BrandConstants.Colors.primary)
                                .font(BrandConstants.Typography.caption)
                            
                            Text("Next: \(DateFormatter.relativeFuture.string(from: hobbyClass.startDate))")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BrandConstants.Colors.primary.opacity(0.1))
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.lg)
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .alert("Remove Favorite", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemoveFavorite()
            }
        } message: {
            Text("Are you sure you want to remove this class from your favorites?")
        }
    }
}

struct FavoritesFiltersSheet: View {
    @ObservedObject var viewModel: FavoriteClassesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: FavoritesFilters
    
    init(viewModel: FavoriteClassesViewModel) {
        self.viewModel = viewModel
        self._tempFilters = State(initialValue: viewModel.filters)
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
                
                Section("Difficulty") {
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        HStack {
                            Text(difficulty.rawValue)
                            Spacer()
                            if tempFilters.difficulties.contains(difficulty) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if tempFilters.difficulties.contains(difficulty) {
                                tempFilters.difficulties.remove(difficulty)
                            } else {
                                tempFilters.difficulties.insert(difficulty)
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
                        
                        Text("Free classes included" + (tempFilters.minPrice > 0 ? " if minimum is $0" : ""))
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Availability") {
                    Toggle("Only show upcoming classes", isOn: $tempFilters.onlyUpcoming)
                    Toggle("Only show classes with spots available", isOn: $tempFilters.onlyAvailable)
                }
            }
            .navigationTitle("Filter Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilters = FavoritesFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.applyFilters(tempFilters)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ClassDetailSheet: View {
    let hobbyClass: HobbyClass
    @Environment(\.dismiss) private var dismiss
    @State private var showingBookingFlow = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Image
                    AsyncImage(url: URL(string: hobbyClass.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        hobbyClass.category.color.opacity(0.6),
                                        hobbyClass.category.color.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: hobbyClass.category.iconName)
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and details
                        VStack(alignment: .leading, spacing: 8) {
                            Text(hobbyClass.title)
                                .font(BrandConstants.Typography.title)
                                .fontWeight(.bold)
                            
                            Text(hobbyClass.description)
                                .font(BrandConstants.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Quick info
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            QuickInfoCard(icon: "person.circle", label: "Instructor", value: hobbyClass.instructor.name)
                            QuickInfoCard(icon: "location", label: "Location", value: hobbyClass.venue.name)
                            QuickInfoCard(icon: "clock", label: "Duration", value: "\(hobbyClass.duration) min")
                            QuickInfoCard(icon: "dollarsign.circle", label: "Price", value: hobbyClass.price == 0 ? "Free" : "$\(String(format: "%.0f", hobbyClass.price))")
                        }
                        
                        // Next available date
                        if hobbyClass.startDate > Date() {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Next Available")
                                    .font(BrandConstants.Typography.headline)
                                    .fontWeight(.semibold)
                                
                                Text(DateFormatter.fullDateTime.string(from: hobbyClass.startDate))
                                    .font(BrandConstants.Typography.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(BrandConstants.Colors.background)
                            .cornerRadius(BrandConstants.CornerRadius.md)
                        }
                        
                        // Book now button
                        if hobbyClass.startDate > Date() {
                            Button("Book This Class") {
                                showingBookingFlow = true
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
        .sheet(isPresented: $showingBookingFlow) {
            // Booking flow would go here
            Text("Booking Flow")
        }
    }
}

struct QuickInfoCard: View {
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

// MARK: - Date Formatters

extension DateFormatter {
    static let relativeFuture: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    FavoriteClassesView()
}