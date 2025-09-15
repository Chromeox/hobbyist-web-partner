import SwiftUI
import MapKit
import UIKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    searchSection
                    categoriesSection
                    featuredSection
                    instructorsSection
                    upcomingClassesSection
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hapticService.playLight()
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView(viewModel: viewModel)
            }
        }
    }

    private var searchSection: some View {
        SearchBarView(text: $searchText)
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: searchText) { _ in
                hapticService.playLight()
                viewModel.searchClasses(query: searchText)
            }
    }

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    HomeCategoryChip(
                        title: category.name,
                        icon: category.icon,
                        isSelected: selectedCategory == category.name,
                        action: {
                            hapticService.playSelection()
                            if selectedCategory == category.name {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category.name
                            }
                            viewModel.filterByCategory(selectedCategory)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }

    private var featuredSection: some View {
        Group {
            if !viewModel.featuredClasses.isEmpty {
                SectionHeader(
                    title: "Featured Classes",
                    actionTitle: "See All",
                    action: {
                        hapticService.playLight()
                        // Navigate to featured classes
                    }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.featuredClasses) { classItem in
                            NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                FeaturedClassCard(classItem: classItem)
                            }
                            .simultaneousGesture(TapGesture().onEnded { _ in
                                hapticService.playMedium()
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var instructorsSection: some View {
        Group {
            if !viewModel.popularInstructors.isEmpty {
                SectionHeader(
                    title: "Popular Instructors",
                    actionTitle: "See All",
                    action: {
                        hapticService.playLight()
                        // Navigate to instructors
                    }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.popularInstructors) { instructor in
                            InstructorCardView(instructor: instructor)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var upcomingClassesSection: some View {
        Group {
            if !viewModel.upcomingClasses.isEmpty {
                SectionHeader(
                    title: "Starting Soon",
                    actionTitle: "View Schedule",
                    action: {
                        hapticService.playLight()
                        // Navigate to schedule
                    }
                )

                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingClasses) { classItem in
                        NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                            UpcomingClassRow(classItem: classItem)
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            hapticService.playMedium()
                        })
                    }
                }
                .padding(.horizontal)
            }
        }
    }
                    
                    // Featured Classes Section
                    if !viewModel.featuredClasses.isEmpty {
                        SectionHeader(
                            title: "Featured Classes",
                            actionTitle: "See All",
                            action: {
                                hapticService.playLight()
                                // Navigate to featured classes
                            }
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.featuredClasses) { classItem in
                                    NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                        FeaturedClassCard(classItem: classItem)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded { _ in
                                        hapticService.playMedium()
                                    })
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Nearby Classes Map Section
                    SectionHeader(
                        title: "Classes Near You",
                        actionTitle: "Map View",
                        action: {
                            hapticService.playLight()
                            viewModel.showMapView = true
                        }
                    )
                    
                    NearbyClassesMapView(classes: viewModel.nearbyClasses)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .onTapGesture {
                            hapticService.playMedium()
                            viewModel.showMapView = true
                        }
                    
                    // Upcoming Classes Section
                    if !viewModel.upcomingClasses.isEmpty {
                        SectionHeader(
                            title: "Starting Soon",
                            actionTitle: "View Schedule",
                            action: {
                                hapticService.playLight()
                                // Navigate to schedule
                            }
                        )
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.upcomingClasses) { classItem in
                                NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                    UpcomingClassRow(classItem: classItem)
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    hapticService.playMedium()
                                })
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Popular Instructors Section
                    if !viewModel.popularInstructors.isEmpty {
                        SectionHeader(
                            title: "Popular Instructors",
                            actionTitle: "See All",
                            action: {
                                hapticService.playLight()
                                // Navigate to instructors
                            }
                        )
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.popularInstructors) { instructor in
                                    InstructorCardView(instructor: instructor)
                                        .onTapGesture {
                                            hapticService.playMedium()
                                            // Navigate to instructor profile
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recommendations Section
                    if !viewModel.recommendedClasses.isEmpty {
                        SectionHeader(
                            title: "Recommended for You",
                            actionTitle: nil,
                            action: {}
                        )
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.recommendedClasses) { classItem in
                                NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                    RecommendedClassCard(classItem: classItem)
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    hapticService.playMedium()
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        hapticService.playLight()
                        // Open profile
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            hapticService.playLight()
                            showingFilters = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                        }
                        
                        Button {
                            hapticService.playLight()
                            // Open notifications
                        } label: {
                            ZStack {
                                Image(systemName: "bell")
                                    .font(.title3)
                                
                                if viewModel.hasNotifications {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                hapticService.playMedium()
                await viewModel.refreshContent()
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showMapView) {
                FullMapView(classes: viewModel.nearbyClasses)
            }
        }
    }
}

// Search Bar Component
struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search classes, instructors...", text: $text)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Category Chip Component
struct HomeCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// Section Header Component
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            if let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

// Featured Class Card Component
struct FeaturedClassCard: View {
    let classItem: ClassItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color.accentColor.opacity(0.6), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 280, height: 160)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if classItem.isFeatured {
                                Label("Featured", systemImage: "star.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                        }
                        Spacer()
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(classItem.instructor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(classItem.duration, systemImage: "clock")
                    Spacer()
                    Text(classItem.price)
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 280)
    }
}

// Nearby Classes Map View
struct NearbyClassesMapView: View {
    let classes: [ClassItem]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: classes) { classItem in
            MapAnnotation(coordinate: classItem.coordinate) {
                VStack {
                    Image(systemName: "figure.yoga")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                    
                    Text(classItem.name)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(4)
                }
            }
        }
        .disabled(true) // Disable interaction for preview
    }
}

// Upcoming Class Row Component
struct UpcomingClassRow: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Time Badge
            VStack {
                Text(classItem.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(classItem.startTime.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Label(classItem.instructor, systemImage: "person")
                    Spacer()
                    Label(classItem.spotsLeft, systemImage: "person.3")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Instructor Card Component
struct InstructorCardView: View {
    let instructor: Instructor
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(instructor.name.prefix(2)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(instructor.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", instructor.rating))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100)
    }
}

// Recommended Class Card Component
struct RecommendedClassCard: View {
    let classItem: ClassItem
    @State private var isFavorite = false
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        HStack(spacing: 12) {
            // Class Image
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.accentColor.opacity(0.4), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: classItem.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(classItem.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(classItem.instructor)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(classItem.duration, systemImage: "clock")
                        .font(.caption2)
                    Spacer()
                    Text(classItem.price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Button {
                isFavorite.toggle()
                hapticService.playLight()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Filters View
struct FiltersView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price Range")
                            .font(.headline)
                        
                        HStack {
                            Text("$\(Int(viewModel.minPrice))")
                            Slider(value: $viewModel.minPrice, in: 0...200)
                                .onChange(of: viewModel.minPrice) { _ in
                                    hapticService.playLight()
                                }
                            Text("$\(Int(viewModel.maxPrice))")
                            Slider(value: $viewModel.maxPrice, in: 0...200)
                                .onChange(of: viewModel.maxPrice) { _ in
                                    hapticService.playLight()
                                }
                        }
                    }
                    
                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Distance")
                            .font(.headline)
                        
                        Picker("Distance", selection: $viewModel.selectedDistance) {
                            Text("1 mile").tag(1)
                            Text("5 miles").tag(5)
                            Text("10 miles").tag(10)
                            Text("25 miles").tag(25)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedDistance) { _ in
                            hapticService.playSelection()
                        }
                    }
                    
                    // Time of Day
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time of Day")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(["Morning", "Afternoon", "Evening", "Weekend"], id: \.self) { time in
                                Button {
                                    hapticService.playLight()
                                    if viewModel.selectedTimes.contains(time) {
                                        viewModel.selectedTimes.remove(time)
                                    } else {
                                        viewModel.selectedTimes.insert(time)
                                    }
                                } label: {
                                    Text(time)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            viewModel.selectedTimes.contains(time) 
                                            ? Color.accentColor 
                                            : Color(.systemGray6)
                                        )
                                        .foregroundColor(
                                            viewModel.selectedTimes.contains(time)
                                            ? .white
                                            : .primary
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Difficulty Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Difficulty Level")
                            .font(.headline)
                        
                        ForEach(["Beginner", "Intermediate", "Advanced", "All Levels"], id: \.self) { level in
                            HStack {
                                Text(level)
                                Spacer()
                                if viewModel.selectedDifficulty == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hapticService.playSelection()
                                viewModel.selectedDifficulty = level
                            }
                        }
                    }
                }
                .padding()
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

// Full Map View
struct FullMapView: View {
    let classes: [ClassItem]
    @Environment(\.dismiss) var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: classes) { classItem in
                MapAnnotation(coordinate: classItem.coordinate) {
                    NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                        VStack {
                            Image(systemName: classItem.icon)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                            
                            Text(classItem.name)
                                .font(.caption2)
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Classes Near You")
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HapticFeedbackService.shared)
    }
}