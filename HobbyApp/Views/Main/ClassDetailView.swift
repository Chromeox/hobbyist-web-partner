import SwiftUI
import MapKit

struct ClassDetailView: View {
    let classItem: ClassItem
    @StateObject private var viewModel = ClassDetailViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var isFavorite = false
    @State private var showShareSheet = false
    @State private var showBookingFlow = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                ZStack(alignment: .topTrailing) {
                    // Class Image with Icon Overlay
                    ZStack {
                        // Background Gradient
                        LinearGradient(
                            colors: [classItem.categoryColor.opacity(0.7), classItem.categoryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Large Icon Watermark
                        Image(systemName: classItem.icon)
                            .font(BrandConstants.Typography.heroTitle)
                            .foregroundColor(BrandConstants.Colors.surface.opacity(0.15))
                            .offset(x: 50, y: -20)
                    }
                    .frame(height: 320)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(classItem.category)
                                        .font(BrandConstants.Typography.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(BrandConstants.Colors.surface.opacity(0.9))
                                        .cornerRadius(20)

                                    Text(classItem.name)
                                        .font(BrandConstants.Typography.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(BrandConstants.Colors.surface)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)

                                    HStack(spacing: 16) {
                                        Label(classItem.duration, systemImage: "clock.fill")
                                        Label(classItem.difficulty, systemImage: "chart.bar.fill")
                                    }
                                    .font(BrandConstants.Typography.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    )
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: isFavorite ? "heart.fill" : "heart", accessibilityLabel: isFavorite ? "Remove from favorites" : "Add to favorites") {
                            isFavorite.toggle()
                            hapticService.playLight()
                        }
                        .foregroundColor(isFavorite ? .red : .white)
                        
                        ActionButton(icon: "square.and.arrow.up", accessibilityLabel: "Share class") {
                            hapticService.playLight()
                            showShareSheet = true
                        }
                    }
                    .padding()
                }
                
                // Quick Info Section
                VStack(spacing: 16) {
                    // Instructor Info
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(classItem.instructorInitials)
                                    .font(BrandConstants.Typography.headline)
                                    .foregroundColor(.accentColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(classItem.instructor)
                                .font(BrandConstants.Typography.headline)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.warning)
                                Text(classItem.rating)
                                    .font(BrandConstants.Typography.caption)
                                Text("• \(classItem.reviewCount) reviews")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            hapticService.playLight()
                            // View instructor profile
                        } label: {
                            Text("View Profile")
                                .font(BrandConstants.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Key Details Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        DetailCard(
                            icon: "calendar",
                            title: "Date",
                            value: classItem.startTime.formatted(date: .abbreviated, time: .omitted)
                        )
                        
                        DetailCard(
                            icon: "clock",
                            title: "Time",
                            value: classItem.startTime.formatted(date: .omitted, time: .shortened)
                        )
                        
                        DetailCard(
                            icon: "person.3",
                            title: "Spots Left",
                            value: "\(classItem.spotsAvailable) of \(classItem.totalSpots)"
                        )
                        
                        
                        DetailCard(
                            icon: "creditcard",
                            title: "Credits",
                            value: "\(classItem.creditsRequired) credits"
                        )
                    }
                }
                .padding()
                
                // Tab Section
                VStack(spacing: 0) {
                    // Tab Bar
                    HStack(spacing: 0) {
                        ForEach(["Overview", "Location", "Reviews", "Similar"], id: \.self) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = ["Overview", "Location", "Reviews", "Similar"].firstIndex(of: tab) ?? 0
                                }
                                hapticService.playSelection()
                            } label: {
                                VStack(spacing: 8) {
                                    Text(tab)
                                        .font(BrandConstants.Typography.subheadline)
                                        .fontWeight(selectedTab == ["Overview", "Location", "Reviews", "Similar"].firstIndex(of: tab) ? .semibold : .regular)
                                        .foregroundColor(selectedTab == ["Overview", "Location", "Reviews", "Similar"].firstIndex(of: tab) ? .primary : .secondary)

                                    Rectangle()
                                        .fill(selectedTab == ["Overview", "Location", "Reviews", "Similar"].firstIndex(of: tab) ? Color.accentColor : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)

                    // Tab Content - Scrollable
                    Group {
                        if selectedTab == 0 {
                            OverviewTab(classItem: classItem, viewModel: viewModel)
                        } else if selectedTab == 1 {
                            LocationTab(classItem: classItem)
                        } else if selectedTab == 2 {
                            ReviewsTab(classItem: classItem, viewModel: viewModel)
                        } else {
                            SimilarClassesTab(viewModel: viewModel)
                        }
                    }
                    .frame(minHeight: 400)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .overlay(
            // Custom Navigation Bar
            VStack {
                HStack {
                    Button {
                        hapticService.playLight()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(BrandConstants.Typography.title3)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        )
        .overlay(
            // Book Now Button
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(classItem.creditsRequired) Credits")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                        Text("per session")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        hapticService.playMedium()
                        showBookingFlow = true
                    } label: {
                        Text("Book Now")
                            .font(BrandConstants.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding()
                .background(
                    Color(.systemBackground)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
            }
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Check out this class: \(classItem.name)"])
        }
        .fullScreenCover(isPresented: $showBookingFlow) {
            TemporaryBookingView(classItem: classItem, isPresented: $showBookingFlow)
                .environmentObject(hapticService)
        }
        .task {
            await viewModel.loadClassDetails(for: classItem)
        }
    }
}

// Action Button Component
struct ActionButton: View {
    let icon: String
    let accessibilityLabel: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title3)
                .foregroundColor(BrandConstants.Colors.surface)
                .padding(10)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

// Detail Card Component
struct DetailCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title2)
                .foregroundColor(.accentColor)
                .frame(height: 24)

            VStack(spacing: 4) {
                Text(title)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                    .multilineTextAlignment(.center)

                Text(value)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Overview Tab
struct OverviewTab: View {
    let classItem: ClassItem
    @ObservedObject var viewModel: ClassDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("About this class")
                    .font(BrandConstants.Typography.headline)

                Text(classItem.description)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // What to Bring
            VStack(alignment: .leading, spacing: 8) {
                Text("What to bring")
                    .font(BrandConstants.Typography.headline)

                ForEach(classItem.requirements, id: \.self) { requirement in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.success)
                        Text(requirement)
                            .font(BrandConstants.Typography.subheadline)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                    }
                }
            }

            // Amenities
            VStack(alignment: .leading, spacing: 8) {
                Text("Amenities")
                    .font(BrandConstants.Typography.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(classItem.amenities, id: \.self) { amenity in
                        HStack(spacing: 8) {
                            Image(systemName: amenity.icon)
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.accentColor)
                            Text(amenity.name)
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            // Cancellation Policy
            VStack(alignment: .leading, spacing: 8) {
                Text("Cancellation Policy")
                    .font(BrandConstants.Typography.headline)

                Text("Free cancellation up to 24 hours before class starts. 50% refund for cancellations within 24 hours.")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
            }

            // Bottom padding to account for "Book Now" button overlay
            Spacer()
                .frame(height: 100)
        }
        .padding()
    }
}

// Location Tab
struct LocationTab: View {
    let classItem: ClassItem
    @State private var region: MKCoordinateRegion
    
    init(classItem: ClassItem) {
        self.classItem = classItem
        self._region = State(initialValue: MKCoordinateRegion(
            center: classItem.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Map
            Map(coordinateRegion: $region, annotationItems: [classItem]) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(BrandConstants.Typography.title)
                            .foregroundColor(.accentColor)
                        Text(item.venueName)
                            .font(BrandConstants.Typography.caption)
                            .padding(4)
                            .background(BrandConstants.Colors.surface.opacity(0.9))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            
            // Address
            VStack(alignment: .leading, spacing: 8) {
                Text(classItem.venueName)
                    .font(BrandConstants.Typography.headline)
                
                Text(classItem.address)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                
                Button {
                    // Open in Maps
                } label: {
                    Label("Get Directions", systemImage: "map")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Parking Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Parking")
                    .font(BrandConstants.Typography.headline)
                
                HStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .foregroundColor(.accentColor)
                    Text("Free street parking available")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
            }
            
            // Public Transit
            VStack(alignment: .leading, spacing: 8) {
                Text("Public Transit")
                    .font(BrandConstants.Typography.headline)
                
                HStack(spacing: 8) {
                    Image(systemName: "tram.fill")
                        .foregroundColor(.accentColor)
                    Text("5 minute walk from Central Station")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                }
            }
        }
        .padding()
    }
}

// Reviews Tab
struct ReviewsTab: View {
    let classItem: ClassItem
    @ObservedObject var viewModel: ClassDetailViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rating Summary
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(classItem.rating)
                            .font(BrandConstants.Typography.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(Double(classItem.rating) ?? 0) ? "star.fill" : "star")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.warning)
                            }
                        }
                        
                        Text("Based on \(classItem.reviewCount) reviews")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Rating Distribution
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach((1...5).reversed(), id: \.self) { rating in
                            HStack(spacing: 8) {
                                Text("\(rating)")
                                    .font(BrandConstants.Typography.caption)
                                    .frame(width: 10)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(height: 4)
                                        
                                        Rectangle()
                                            .fill(Color.yellow)
                                            .frame(
                                                width: geometry.size.width * viewModel.ratingDistribution(for: rating),
                                                height: 4
                                            )
                                    }
                                    .cornerRadius(2)
                                }
                                .frame(width: 100, height: 4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Reviews List
            VStack(spacing: 16) {
                ForEach(viewModel.reviews) { review in
                    ReviewCard(review: review)
                }
                
                if viewModel.hasMoreReviews {
                    Button {
                        hapticService.playLight()
                        Task {
                            await viewModel.loadMoreReviews()
                        }
                    } label: {
                        Text("Load More Reviews")
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
    }
}

// Review Card Component
struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // User Avatar
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(review.userInitials ?? "?")
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName ?? "Anonymous")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < review.rating ? "star.fill" : "star")
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(BrandConstants.Colors.warning)
                            }
                        }
                        
                        Text("• \(review.date.formatted(.relative(presentation: .named)))")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            Text(review.comment)
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Similar Classes Tab
struct SimilarClassesTab: View {
    @ObservedObject var viewModel: ClassDetailViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.similarClasses) { classItem in
                    NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                        SimilarClassCard(classItem: classItem)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        hapticService.playMedium()
                    })
                }
            }
            .padding()
        }
    }
}

// Similar Class Card Component
struct SimilarClassCard: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [classItem.categoryColor.opacity(0.4), classItem.categoryColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: classItem.icon)
                        .font(BrandConstants.Typography.title2)
                        .foregroundColor(BrandConstants.Colors.surface)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(classItem.instructor)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(BrandConstants.Colors.secondaryText)
                
                HStack {
                    Label(classItem.duration, systemImage: "clock")
                        .font(BrandConstants.Typography.caption)
                    Spacer()
                    Text(classItem.price)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(BrandConstants.Typography.caption)
                .foregroundColor(BrandConstants.Colors.secondaryText)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Temporary Booking View (until BookingFlowView is added to Xcode project)
struct TemporaryBookingView: View {
    let classItem: ClassItem
    @Binding var isPresented: Bool
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var participantCount = 1
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Class Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(classItem.name)
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)

                        HStack {
                            Label(classItem.startTime.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                            Spacer()
                            Label(classItem.duration, systemImage: "clock")
                        }
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(BrandConstants.Colors.secondaryText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Participants
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Participants")
                            .font(BrandConstants.Typography.headline)

                        HStack {
                            Button {
                                if participantCount > 1 {
                                    participantCount -= 1
                                    hapticService.playLight()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(BrandConstants.Typography.title2)
                                    .foregroundColor(participantCount > 1 ? .accentColor : .gray)
                            }

                            Text("\(participantCount)")
                                .font(BrandConstants.Typography.title)
                                .fontWeight(.semibold)
                                .frame(minWidth: 50)

                            Button {
                                if participantCount < min(classItem.spotsAvailable, 10) {
                                    participantCount += 1
                                    hapticService.playLight()
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(BrandConstants.Typography.title2)
                                    .foregroundColor(participantCount < min(classItem.spotsAvailable, 10) ? .accentColor : .gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Price Summary
                    VStack(spacing: 8) {
                        HStack {
                            Text("Price per person")
                            Spacer()
                            Text(classItem.price)
                        }
                        if participantCount > 1 {
                            HStack {
                                Text("× \(participantCount) participants")
                                Spacer()
                            }
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(BrandConstants.Colors.secondaryText)
                        }
                        Divider()
                        HStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(classItem.creditsRequired * participantCount) credits")
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Book Button
                    Button {
                        hapticService.playSuccess()
                        showConfirmation = true
                    } label: {
                        Text("Confirm Booking")
                            .font(BrandConstants.Typography.headline)
                            .foregroundColor(BrandConstants.Colors.surface)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Book Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Booking Confirmed!", isPresented: $showConfirmation) {
                Button("Done") {
                    isPresented = false
                }
            } message: {
                Text("Your spot is reserved! Confirmation code: \(String(format: "%06d", Int.random(in: 100000...999999)))")
            }
        }
    }
}

struct ClassDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ClassDetailView(classItem: ClassItem.sample)
            .environmentObject(HapticFeedbackService.shared)
    }
}
