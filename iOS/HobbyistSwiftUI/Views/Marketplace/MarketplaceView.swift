import SwiftUI
import CoreLocation

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedInstructor: Instructor?
    @State private var selectedVenue: Venue?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    SearchBarView(text: $searchText)
                        .padding(.horizontal)
                    
                    // Category Filter
                    CategoryFilterView(
                        selectedCategory: $selectedCategory,
                        categories: viewModel.categories
                    )
                    
                    // Featured Section
                    if !viewModel.featuredClasses.isEmpty {
                        FeaturedSection(classes: viewModel.featuredClasses)
                    }
                    
                    // Nearby Instructors
                    if !viewModel.nearbyInstructors.isEmpty {
                        InstructorSection(
                            title: "Nearby Instructors",
                            instructors: viewModel.nearbyInstructors,
                            selectedInstructor: $selectedInstructor
                        )
                    }
                    
                    // Popular Venues
                    if !viewModel.popularVenues.isEmpty {
                        VenueSection(
                            title: "Popular Venues",
                            venues: viewModel.popularVenues,
                            selectedVenue: $selectedVenue
                        )
                    }
                    
                    // All Classes
                    ClassListSection(
                        classes: filteredClasses,
                        isLoading: viewModel.isLoading
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .navigationBarItems(
                trailing: Button(action: { showFilters = true }) {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
            )
            .sheet(isPresented: $showFilters) {
                FilterView(viewModel: viewModel)
            }
            .sheet(item: $selectedInstructor) { instructor in
                InstructorDetailView(instructor: instructor)
            }
            .sheet(item: $selectedVenue) { venue in
                VenueDetailView(venue: venue)
            }
        }
        .onAppear {
            viewModel.loadMarketplaceData()
        }
    }
    
    private var filteredClasses: [ClassItem] {
        viewModel.classes.filter { classItem in
            let matchesSearch = searchText.isEmpty || 
                classItem.name.localizedCaseInsensitiveContains(searchText) ||
                classItem.description?.localizedCaseInsensitiveContains(searchText) ?? false
            
            let matchesCategory = selectedCategory == nil ||
                classItem.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
}

// MARK: - Supporting Views

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search classes, instructors, venues...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["All"] + categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: (category == "All" && selectedCategory == nil) || 
                                   selectedCategory == category,
                        action: {
                            if category == "All" {
                                selectedCategory = nil
                            } else {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
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
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct FeaturedSection: View {
    let classes: [ClassItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Classes")
                .font(.title2)
                .fontWeight(.bold)
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
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 250, height: 150)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let instructorName = classItem.instructorName {
                    Text("with \(instructorName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("\(classItem.duration) min", systemImage: "clock")
                    Spacer()
                    Text("$\(classItem.priceAmount, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
                .font(.caption)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 250)
    }
}

struct InstructorSection: View {
    let title: String
    let instructors: [Instructor]
    @Binding var selectedInstructor: Instructor?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(instructors) { instructor in
                        InstructorCard(
                            instructor: instructor,
                            onTap: { selectedInstructor = instructor }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InstructorCard: View {
    let instructor: Instructor
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(instructor.firstName.prefix(1) + instructor.lastName.prefix(1))
                            .font(.title2)
                            .fontWeight(.semibold)
                    )
                
                Text(instructor.fullName)
                    .font(.caption)
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(instructor.formattedRating)
                        .font(.caption2)
                }
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VenueSection: View {
    let title: String
    let venues: [Venue]
    @Binding var selectedVenue: Venue?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(venues.prefix(5)) { venue in
                Button(action: { selectedVenue = venue }) {
                    VenueRow(venue: venue)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }
}

struct VenueRow: View {
    let venue: Venue
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "building.2")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(venue.name)
                    .font(.headline)
                
                Text(venue.city)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if venue.amenities.count > 0 {
                    Text(venue.amenities.prefix(3).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

struct ClassListSection: View {
    let classes: [ClassItem]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Classes")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if classes.isEmpty {
                Text("No classes found")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(classes) { classItem in
                    NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                        ClassRow(classItem: classItem)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct ClassRow: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let instructorName = classItem.instructorName {
                    Text(instructorName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Label("\(classItem.duration) min", systemImage: "clock")
                        .font(.caption2)
                    
                    Spacer()
                    
                    Text("$\(classItem.priceAmount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Placeholder for detail views
struct ClassDetailView: View {
    let classItem: ClassItem
    
    var body: some View {
        Text("Class Detail: \(classItem.name)")
    }
}

struct InstructorDetailView: View {
    let instructor: Instructor
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with profile image
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(instructor.firstName.prefix(1) + instructor.lastName.prefix(1))
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                            )
                        
                        Text(instructor.fullName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(instructor.formattedRating) ?? 0 ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            Text("(\(instructor.totalReviews) reviews)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // Bio
                    if let bio = instructor.bio {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)
                            Text(bio)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    
                    // Specialties
                    if !instructor.specialties.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specialties")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(instructor.specialties, id: \.self) { specialty in
                                    Text(specialty)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss
            })
        }
    }
}

struct VenueDetailView: View {
    let venue: Venue
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(venue.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    if let description = venue.description {
                        Text(description)
                            .padding(.horizontal)
                    }
                    
                    Text(venue.fullAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                // Dismiss
            })
        }
    }
}

// Helper for flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.replacingUnspecifiedDimensions().width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: frame.origin.x + bounds.minX, y: frame.origin.y + bounds.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            height = y + maxHeight
        }
    }
}

#Preview {
    MarketplaceView()
}