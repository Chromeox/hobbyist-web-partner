import SwiftUI

/// Wrapper for BookingFlowView that works with classID strings for navigation
struct NavigationBookingFlowView: View {
    let classID: String
    @State private var classItem: ClassItem?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let classItem = classItem {
                BookingFlowView(classItem: classItem)
            } else {
                errorView
            }
        }
        .task {
            await loadClassData()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading booking details...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandConstants.Colors.background)
        .navigationTitle("Book Class")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Class Not Found")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text("We couldn't find the class you're looking for.")
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
        .navigationTitle("Book Class")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadClassData() async {
        isLoading = true
        
        // Simulate loading class data by ID
        // In a real app, this would make an API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Create a sample class item based on the ID
        classItem = createSampleClassItem(for: classID)
        
        isLoading = false
    }
    
    private func createSampleClassItem(for id: String) -> ClassItem {
        // Create a sample class item based on the ID
        // In a real app, this would fetch from your data source
        let categories = ["Arts & Crafts", "Cooking & Baking", "Fitness & Wellness", "Music & Performance", "Photography"]
        let category = categories.randomElement() ?? "Arts & Crafts"
        
        let titles = [
            "Pottery Basics", "Watercolor Painting", "Digital Photography", 
            "Italian Cooking", "Yoga Flow", "Guitar Fundamentals"
        ]
        
        let instructors = [
            "Sarah Chen", "David Martinez", "Emma Thompson", 
            "Michael Park", "Lisa Rodriguez", "James Wilson"
        ]
        
        let venues = [
            "Creative Studio Vancouver", "Art Space Downtown", "The Pottery Barn",
            "Music Academy", "Culinary Institute", "Fitness Center"
        ]
        
        let price = Double.random(in: 25...85)
        let startTime = Date().addingTimeInterval(86400) // Tomorrow
        let endTime = startTime.addingTimeInterval(7200) // 2 hours later
        
        return ClassItem(
            id: id,
            name: titles.randomElement() ?? "Creative Class",
            category: category,
            instructor: instructors.randomElement() ?? "Instructor",
            instructorInitials: String((instructors.randomElement() ?? "IN").prefix(2)),
            description: "Learn new skills in a fun and supportive environment. This class is perfect for beginners and those looking to explore their creative side. All materials and equipment are provided.",
            duration: "2 hours",
            difficulty: "Beginner",
            price: price == 0 ? "Free" : String(format: "$%.0f", price),
            creditsRequired: price <= 0 ? 0 : max(Int(ceil(price / 3.5)), 1),
            startTime: startTime,
            endTime: endTime,
            location: "Vancouver, BC",
            venueName: venues.randomElement() ?? "Creative Studio",
            address: "123 Main Street, Vancouver, BC",
            coordinate: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
            spotsAvailable: Int.random(in: 2...8),
            totalSpots: 12,
            rating: String(format: "%.1f", Double.random(in: 4.0...5.0)),
            reviewCount: String(Int.random(in: 8...45)),
            icon: getIconForCategory(category),
            categoryColor: getCategoryColor(category),
            isFeatured: Bool.random(),
            requirements: ["No experience required", "Wear comfortable clothes"],
            amenities: [
                Amenity(name: "Parking Available", icon: "car"),
                Amenity(name: "WiFi", icon: "wifi"),
                Amenity(name: "Materials Provided", icon: "box")
            ],
            equipment: [
                Equipment(name: "Pottery Tools", price: "$5"),
                Equipment(name: "Apron", price: "$3")
            ]
        )
    }
    
    private func getIconForCategory(_ category: String) -> String {
        switch category {
        case "Arts & Crafts": return "paintbrush"
        case "Cooking & Baking": return "fork.knife"
        case "Fitness & Wellness": return "figure.walk"
        case "Music & Performance": return "music.note"
        case "Photography": return "camera"
        default: return "star"
        }
    }
    
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "Arts & Crafts": return BrandConstants.Colors.Category.arts
        case "Cooking & Baking": return BrandConstants.Colors.Category.cooking
        case "Fitness & Wellness": return BrandConstants.Colors.teal
        case "Music & Performance": return BrandConstants.Colors.Category.music
        case "Photography": return BrandConstants.Colors.Category.photography
        default: return BrandConstants.Colors.coral
        }
    }
}

#Preview {
    NavigationStack {
        NavigationBookingFlowView(classID: "sample-booking-123")
            .environmentObject(HapticFeedbackService.shared)
    }
}