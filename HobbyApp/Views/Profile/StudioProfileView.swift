import SwiftUI
import MapKit

struct StudioProfileView: View {
    let studioID: String
    @StateObject private var viewModel = StudioProfileViewModel()
    @State private var selectedTab = 0
    @State private var showingContact = false
    @State private var showingDirections = false
    @State private var showingFollowSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    private let tabs = ["About", "Classes", "Photos", "Reviews"]
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.studio == nil {
                loadingView
            } else if let studio = viewModel.studio {
                studioProfileContent(studio: studio)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStudio(id: studioID)
        }
        .sheet(isPresented: $showingContact) {
            if let studio = viewModel.studio {
                ContactStudioSheet(studio: studio)
            }
        }
        .sheet(isPresented: $showingDirections) {
            if let studio = viewModel.studio {
                DirectionsSheet(studio: studio)
            }
        }
        .alert("Following", isPresented: $showingFollowSuccess) {
            Button("OK") { }
        } message: {
            Text("You're now following \(viewModel.studio?.name ?? "this studio")")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading studio profile...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Studio Not Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("We couldn't find the studio you're looking for.")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Go Back") {
                dismiss()
            }
            .padding()
            .background(BrandConstants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
    }
    
    private func studioProfileContent(studio: Venue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Image
                studioHeaderImage(studio: studio)
                
                // Studio Info
                studioInfo(studio: studio)
                
                // Stats
                studioStats(studio: studio)
                
                // Action Buttons
                actionButtons(studio: studio)
                
                // Tab Picker
                tabPicker
                
                // Tab Content
                tabContent(studio: studio)
            }
            .padding(.bottom, 100)
        }
        .background(BrandConstants.Colors.background)
    }
    
    private func studioHeaderImage(studio: Venue) -> some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: studio.imageUrls?.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                BrandConstants.Colors.primary.opacity(0.8),
                                BrandConstants.Colors.teal.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 250)
            .clipped()
            
            // Favorite Button
            Button(action: {
                Task {
                    await viewModel.toggleFollow()
                    if viewModel.isFollowing {
                        showingFollowSuccess = true
                    }
                }
            }) {
                Image(systemName: viewModel.isFollowing ? "heart.fill" : "heart")
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(viewModel.isFollowing ? .red : .white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 40, height: 40)
                    )
            }
            .padding(16)
        }
    }
    
    private func studioInfo(studio: Venue) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name and Rating
            VStack(alignment: .leading, spacing: 8) {
                Text(studio.name)
                    .font(BrandConstants.Typography.largeTitle)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < Int(viewModel.averageRating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(BrandConstants.Typography.subheadline)
                    }
                    Text(String(format: "%.1f", viewModel.averageRating))
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                    Text("(\(viewModel.totalReviews) reviews)")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Address
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .foregroundColor(BrandConstants.Colors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(studio.address)
                        .font(BrandConstants.Typography.body)
                    Text("\(studio.city), \(studio.state) \(studio.zipCode)")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Description
            if let description = viewModel.studioDescription {
                Text(description)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            // Amenities
            if !studio.amenities.isEmpty {
                amenitiesSection(amenities: studio.amenities)
            }
        }
        .padding(.horizontal)
    }
    
    private func amenitiesSection(amenities: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amenities")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(amenities, id: \.self) { amenity in
                    HStack(spacing: 8) {
                        Image(systemName: amenityIcon(for: amenity))
                            .foregroundColor(BrandConstants.Colors.primary)
                            .font(BrandConstants.Typography.caption)
                            .frame(width: 16)
                        
                        Text(amenity)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func amenityIcon(for amenity: String) -> String {
        switch amenity.lowercased() {
        case let a where a.contains("parking"):
            return "car.fill"
        case let a where a.contains("wifi"):
            return "wifi"
        case let a where a.contains("material"):
            return "cube.box.fill"
        case let a where a.contains("wheelchair"):
            return "figure.roll"
        case let a where a.contains("storage"):
            return "archivebox.fill"
        case let a where a.contains("changing"):
            return "door.left.hand.open"
        default:
            return "checkmark.circle.fill"
        }
    }
    
    private func studioStats(studio: Venue) -> some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "calendar.badge.plus",
                value: "\(viewModel.totalClasses)",
                label: "Classes Offered",
                color: .blue
            )
            
            StatCard(
                icon: "person.2.fill",
                value: "\(viewModel.totalInstructors)",
                label: "Instructors",
                color: .green
            )
            
            StatCard(
                icon: "clock.fill",
                value: "\(viewModel.hoursOpen)",
                label: "Hours/Week",
                color: .orange
            )
        }
        .padding(.horizontal)
    }
    
    private func actionButtons(studio: Venue) -> some View {
        HStack(spacing: 12) {
            // Contact Button
            Button(action: {
                showingContact = true
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Contact")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(BrandConstants.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
            
            // Directions Button
            Button(action: {
                showingDirections = true
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Directions")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(BrandConstants.Colors.teal)
                .foregroundColor(.white)
                .cornerRadius(BrandConstants.CornerRadius.md)
            }
        }
        .padding(.horizontal)
    }
    
    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? BrandConstants.Colors.primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? BrandConstants.Colors.primary : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(minWidth: 80)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .background(BrandConstants.Colors.surface)
    }
    
    private func tabContent(studio: Venue) -> some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case 0:
                aboutTab(studio: studio)
            case 1:
                classesTab
            case 2:
                photosTab
            case 3:
                reviewsTab
            default:
                EmptyView()
            }
        }
    }
    
    private func aboutTab(studio: Venue) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Hours
            hoursSection
            
            // Parking & Transit
            transportationSection(studio: studio)
            
            // Accessibility
            if let accessibility = studio.accessibilityInfo {
                accessibilitySection(info: accessibility)
            }
            
            // Contact Information
            contactInfoSection(studio: studio)
        }
        .padding()
    }
    
    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hours")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(viewModel.operatingHours, id: \.day) { hours in
                    HourRow(hours: hours)
                }
            }
        }
    }
    
    private func transportationSection(studio: Venue) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Getting There")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            if let parking = studio.parkingInfo {
                InfoRow(icon: "car.fill", title: "Parking", info: parking)
            }
            
            if let transit = studio.publicTransit {
                InfoRow(icon: "bus.fill", title: "Public Transit", info: transit)
            }
        }
    }
    
    private func accessibilitySection(info: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accessibility")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            InfoRow(icon: "figure.roll", title: "Accessibility", info: info)
        }
    }
    
    private func contactInfoSection(studio: Venue) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            if let phone = viewModel.studioPhone {
                ContactRow(icon: "phone.fill", label: "Phone", value: phone, action: {
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                })
            }
            
            if let email = viewModel.studioEmail {
                ContactRow(icon: "envelope.fill", label: "Email", value: email, action: {
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                })
            }
            
            if let website = viewModel.studioWebsite {
                ContactRow(icon: "globe", label: "Website", value: website, action: {
                    if let url = URL(string: website) {
                        UIApplication.shared.open(url)
                    }
                })
            }
        }
    }
    
    private var classesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.studioClasses.isEmpty {
                EmptyStateView(
                    message: "No Classes Available",
                    description: "This studio doesn't have any classes scheduled at the moment.",
                    iconName: "calendar"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.studioClasses) { classItem in
                        StudioClassCard(classItem: classItem)
                    }
                }
                .padding()
            }
        }
    }
    
    private var photosTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.studioPhotos.isEmpty {
                EmptyStateView(
                    message: "No Photos Available",
                    description: "This studio hasn't shared any photos yet.",
                    iconName: "photo"
                )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(viewModel.studioPhotos, id: \.self) { photo in
                        StudioPhotoCard(imageUrl: photo)
                    }
                }
                .padding()
            }
        }
    }
    
    private var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.reviews.isEmpty {
                EmptyStateView(
                    message: "No Reviews Yet",
                    description: "This studio hasn't received any reviews yet.",
                    iconName: "star"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.reviews) { review in
                        ReviewCard(review: review)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Supporting Views

struct HourRow: View {
    let hours: OperatingHours
    
    var body: some View {
        HStack {
            Text(hours.day)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            if hours.isClosed {
                Text("Closed")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(hours.openTime) - \(hours.closeTime)")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let info: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(BrandConstants.Colors.primary)
                .font(BrandConstants.Typography.body)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                
                Text(info)
                    .font(BrandConstants.Typography.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(BrandConstants.Colors.primary)
                    .font(BrandConstants.Typography.body)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(BrandConstants.Typography.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StudioClassCard: View {
    let classItem: ClassItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Class image placeholder
            Rectangle()
                .fill(BrandConstants.Colors.primary.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(BrandConstants.CornerRadius.sm)
                .overlay(
                    Image(systemName: "figure.yoga")
                        .foregroundColor(BrandConstants.Colors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Text("with \(classItem.instructorName)")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(DateFormatter.shortDateTime.string(from: classItem.startDate))
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(Int(classItem.price))")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(BrandConstants.Colors.primary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(BrandConstants.Colors.surface)
        .cornerRadius(BrandConstants.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
    }
}

struct StudioPhotoCard: View {
    let imageUrl: String
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
}

struct ContactStudioSheet: View {
    let studio: Venue
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = ContactReason.general
    @State private var subject = ""
    @State private var message = ""
    
    enum ContactReason: String, CaseIterable {
        case general = "General Inquiry"
        case booking = "Class Information"
        case facility = "Facility Rental"
        case partnership = "Partnership"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact \(studio.name)")
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                        
                        Text("Send a message to this studio")
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Reason Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for Contact")
                            .font(BrandConstants.Typography.headline)
                        
                        Picker("Reason", selection: $selectedReason) {
                            ForEach(ContactReason.allCases, id: \.self) { reason in
                                Text(reason.rawValue).tag(reason)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Subject
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(BrandConstants.Typography.headline)
                        
                        TextField("Enter subject", text: $subject)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(BrandConstants.Typography.headline)
                        
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(BrandConstants.Colors.background)
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Send Button
                    Button("Send Message") {
                        // Handle sending message
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? BrandConstants.Colors.primary : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(BrandConstants.CornerRadius.md)
                    .disabled(!isFormValid)
                }
                .padding()
            }
            .navigationTitle("Contact Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct DirectionsSheet: View {
    let studio: Venue
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map
                Map(coordinateRegion: $region, annotationItems: [studio]) { venue in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude), tint: .red)
                }
                .frame(height: 300)
                
                // Studio Info
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(studio.name)
                                .font(BrandConstants.Typography.headline)
                                .fontWeight(.semibold)
                            
                            Text(studio.address)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(studio.city), \(studio.state) \(studio.zipCode)")
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button("Open in Maps") {
                            openInMaps()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                        
                        Button("Copy Address") {
                            copyAddress()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                    }
                }
                .padding()
                
                Spacer()
            }
            .onAppear {
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: studio.latitude, longitude: studio.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: studio.latitude, longitude: studio.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = studio.name
        mapItem.openInMaps()
    }
    
    private func copyAddress() {
        let fullAddress = "\(studio.address), \(studio.city), \(studio.state) \(studio.zipCode)"
        UIPasteboard.general.string = fullAddress
    }
}

#Preview {
    NavigationStack {
        StudioProfileView(studioID: "sample-studio-123")
    }
}