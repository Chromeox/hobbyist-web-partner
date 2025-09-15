import Foundation
import SwiftUI

@MainActor
class ClassDetailViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var similarClasses: [ClassItem] = []
    @Published var hasMoreReviews = false
    @Published var isLoadingReviews = false
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // Load sample reviews
        reviews = [
            Review(
                id: "1",
                userName: "John Doe",
                userInitials: "JD",
                rating: 5,
                comment: "Amazing class! Sarah is an excellent instructor who really takes time to ensure proper form.",
                date: Date().addingTimeInterval(-86400)
            ),
            Review(
                id: "2",
                userName: "Jane Smith",
                userInitials: "JS",
                rating: 4,
                comment: "Great workout, loved the energy. Studio could use better ventilation though.",
                date: Date().addingTimeInterval(-172800)
            )
        ]
        
        // Load similar classes
        similarClasses = [ClassItem.sample]
        hasMoreReviews = true
    }
    
    func loadClassDetails(for classItem: ClassItem) async {
        // Load class-specific details
        loadSampleData()
    }
    
    func loadMoreReviews() async {
        guard !isLoadingReviews else { return }
        isLoadingReviews = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Add more sample reviews
        let newReviews = [
            Review(
                id: UUID().uuidString,
                userName: "Alice Johnson",
                userInitials: "AJ",
                rating: 5,
                comment: "Perfect for beginners!",
                date: Date().addingTimeInterval(-259200)
            )
        ]
        
        reviews.append(contentsOf: newReviews)
        hasMoreReviews = reviews.count < 20
        isLoadingReviews = false
    }
    
    func ratingDistribution(for rating: Int) -> Double {
        // Calculate rating distribution
        let count = reviews.filter { $0.rating == rating }.count
        return Double(count) / Double(max(reviews.count, 1))
    }
}