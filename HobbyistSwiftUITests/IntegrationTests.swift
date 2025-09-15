import XCTest
import Supabase
@testable import HobbyistSwiftUI

/// Integration tests to verify iOS app works with web portal backend
final class IntegrationTests: XCTestCase {
    
    var supabaseService: SupabaseService!
    var testUserId: UUID!
    var testClassId: UUID!
    var testInstructorId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize Supabase service with test credentials
        supabaseService = SupabaseService.shared
        
        // Create test user for integration tests
        testUserId = UUID()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try await cleanupTestData()
        try await super.tearDown()
    }
    
    // MARK: - Instructor Marketplace Tests
    
    func testFetchInstructorProfiles() async throws {
        // Test: Fetch instructor profiles from marketplace
        let instructors = try await supabaseService.fetchInstructorProfiles()
        
        XCTAssertFalse(instructors.isEmpty, "Should have instructor profiles")
        
        // Verify instructor data structure
        if let firstInstructor = instructors.first {
            XCTAssertNotNil(firstInstructor.id)
            XCTAssertNotNil(firstInstructor.displayName)
            XCTAssertNotNil(firstInstructor.averageRating)
            XCTAssertNotNil(firstInstructor.specialties)
        }
    }
    
    func testFollowInstructor() async throws {
        // Test: Follow an instructor
        let instructors = try await supabaseService.fetchInstructorProfiles()
        guard let instructor = instructors.first else {
            XCTFail("No instructors available for testing")
            return
        }
        
        // Follow instructor
        try await supabaseService.followInstructor(
            instructorId: instructor.id,
            userId: testUserId
        )
        
        // Verify following relationship exists
        let following = try await supabaseService.getFollowedInstructors(userId: testUserId)
        XCTAssertTrue(following.contains { $0.id == instructor.id }, "Should be following instructor")
        
        // Unfollow instructor
        try await supabaseService.unfollowInstructor(
            instructorId: instructor.id,
            userId: testUserId
        )
        
        // Verify unfollowed
        let followingAfter = try await supabaseService.getFollowedInstructors(userId: testUserId)
        XCTAssertFalse(followingAfter.contains { $0.id == instructor.id }, "Should not be following instructor")
    }
    
    // MARK: - Location Tests
    
    func testFetchStudioLocations() async throws {
        // Test: Fetch studio locations
        let locations = try await supabaseService.fetchStudioLocations()
        
        XCTAssertFalse(locations.isEmpty, "Should have studio locations")
        
        // Verify location data
        if let firstLocation = locations.first {
            XCTAssertNotNil(firstLocation.id)
            XCTAssertNotNil(firstLocation.name)
            XCTAssertNotNil(firstLocation.address)
            XCTAssertNotNil(firstLocation.latitude)
            XCTAssertNotNil(firstLocation.longitude)
        }
    }
    
    func testFilterClassesByLocation() async throws {
        // Test: Filter classes by location
        let locations = try await supabaseService.fetchStudioLocations()
        guard let location = locations.first else {
            XCTFail("No locations available for testing")
            return
        }
        
        let classes = try await supabaseService.fetchClasses(locationId: location.id)
        
        // Verify all classes belong to the specified location
        for classItem in classes {
            XCTAssertEqual(classItem.locationId, location.id, "Class should belong to filtered location")
        }
    }
    
    // MARK: - Review System Tests
    
    func testSubmitReview() async throws {
        // Test: Submit a review for a completed booking
        
        // First, create a test booking
        let classes = try await supabaseService.fetchClasses()
        guard let testClass = classes.first else {
            XCTFail("No classes available for testing")
            return
        }
        
        // Create review
        let review = Review(
            id: UUID(),
            userId: testUserId,
            targetType: .class,
            targetId: testClass.id,
            rating: 5,
            title: "Great class!",
            content: "Really enjoyed this pottery class. The instructor was amazing!",
            isVerifiedBooking: true,
            helpfulCount: 0,
            images: nil,
            instructorResponse: nil,
            instructorRespondedAt: nil,
            createdAt: Date(),
            updatedAt: nil,
            userName: "Test User",
            userImageUrl: nil
        )
        
        try await supabaseService.submitReview(review)
        
        // Verify review was created
        let reviews = try await supabaseService.fetchReviews(for: testClass.id, type: .class)
        XCTAssertTrue(reviews.contains { $0.id == review.id }, "Review should be saved")
    }
    
    func testFetchReviewsForInstructor() async throws {
        // Test: Fetch reviews for an instructor
        let instructors = try await supabaseService.fetchInstructorProfiles()
        guard let instructor = instructors.first else {
            XCTFail("No instructors available for testing")
            return
        }
        
        let reviews = try await supabaseService.fetchReviews(for: instructor.id, type: .instructor)
        
        // Verify review data
        for review in reviews {
            XCTAssertEqual(review.targetId, instructor.id, "Review should be for the instructor")
            XCTAssertEqual(review.targetType, .instructor, "Review type should be instructor")
            XCTAssertGreaterThanOrEqual(review.rating, 1, "Rating should be at least 1")
            XCTAssertLessThanOrEqual(review.rating, 5, "Rating should be at most 5")
        }
    }
    
    // MARK: - Subscription Tests
    
    func testFetchSubscriptionTiers() async throws {
        // Test: Fetch available subscription tiers
        let tiers = try await supabaseService.fetchSubscriptionTiers()
        
        XCTAssertFalse(tiers.isEmpty, "Should have subscription tiers")
        
        // Verify tier structure
        for tier in tiers {
            XCTAssertNotNil(tier.id)
            XCTAssertNotNil(tier.name)
            XCTAssertNotNil(tier.price)
            XCTAssertNotNil(tier.features)
            XCTAssertGreaterThan(tier.price, 0, "Price should be positive")
        }
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeClassUpdates() async throws {
        // Test: Real-time updates when new class is created
        let expectation = XCTestExpectation(description: "Receive real-time class update")
        
        // Subscribe to class updates
        let subscription = await supabaseService.subscribeToClassUpdates { event in
            if event.type == .insert {
                expectation.fulfill()
            }
        }
        
        // Wait for real-time update (this would be triggered by web portal creating a class)
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Clean up subscription
        await subscription.unsubscribe()
    }
    
    func testRealTimeBookingConfirmation() async throws {
        // Test: Real-time booking confirmation
        let expectation = XCTestExpectation(description: "Receive booking confirmation")
        
        // Subscribe to booking updates for user
        let subscription = await supabaseService.subscribeToUserBookings(userId: testUserId) { booking in
            if booking.status == "confirmed" {
                expectation.fulfill()
            }
        }
        
        // Create a test booking
        let classes = try await supabaseService.fetchClasses()
        guard let testClass = classes.first else {
            XCTFail("No classes available for testing")
            return
        }
        
        try await supabaseService.bookClass(classId: testClass.id, userId: testUserId)
        
        // Wait for real-time confirmation
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Clean up
        await subscription.unsubscribe()
    }
    
    // MARK: - End-to-End Flow Tests
    
    func testCompleteBookingFlow() async throws {
        // Test: Complete booking flow from discovery to review
        
        // 1. Discover classes
        let classes = try await supabaseService.fetchClasses()
        XCTAssertFalse(classes.isEmpty, "Should have classes available")
        
        guard let selectedClass = classes.first else { return }
        
        // 2. Check instructor profile
        if let instructorId = selectedClass.instructorId {
            let instructor = try await supabaseService.fetchInstructorProfile(id: instructorId)
            XCTAssertNotNil(instructor, "Should fetch instructor profile")
        }
        
        // 3. Book the class
        let booking = try await supabaseService.bookClass(
            classId: selectedClass.id,
            userId: testUserId
        )
        XCTAssertNotNil(booking, "Should create booking")
        XCTAssertEqual(booking.status, "confirmed", "Booking should be confirmed")
        
        // 4. Mark attendance (simulate class completion)
        try await supabaseService.markAttendance(bookingId: booking.id)
        
        // 5. Submit review
        let review = Review(
            id: UUID(),
            userId: testUserId,
            targetType: .class,
            targetId: selectedClass.id,
            rating: 5,
            title: "Amazing experience!",
            content: "Loved every minute of it",
            isVerifiedBooking: true,
            helpfulCount: 0,
            images: nil,
            instructorResponse: nil,
            instructorRespondedAt: nil,
            createdAt: Date(),
            updatedAt: nil,
            userName: "Test User",
            userImageUrl: nil
        )
        
        try await supabaseService.submitReview(review)
        
        // Verify complete flow
        let userBookings = try await supabaseService.fetchUserBookings(userId: testUserId)
        XCTAssertTrue(userBookings.contains { $0.id == booking.id }, "Should have booking in history")
    }
    
    // MARK: - Performance Tests
    
    func testFetchClassesPerformance() throws {
        // Test: Measure performance of fetching classes
        measure {
            let expectation = XCTestExpectation()
            
            Task {
                _ = try await supabaseService.fetchClasses()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testSearchPerformance() throws {
        // Test: Measure search performance
        measure {
            let expectation = XCTestExpectation()
            
            Task {
                _ = try await supabaseService.searchClasses(query: "pottery")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() async throws {
        // Clean up any test data created during tests
        // This would typically delete test bookings, reviews, follows, etc.
    }
}

// MARK: - Mock Data Extensions

extension IntegrationTests {
    func createMockInstructor() -> InstructorProfile {
        return InstructorProfile(
            id: UUID(),
            userId: UUID(),
            displayName: "Test Instructor",
            slug: "test-instructor",
            bio: "Test bio",
            tagline: "Test tagline",
            profileImageUrl: nil,
            coverImageUrl: nil,
            specialties: ["Pottery", "Ceramics"],
            certifications: [],
            yearsExperience: 5,
            languages: ["English"],
            isVerified: true,
            isFeatured: false,
            averageRating: 4.5,
            totalReviews: 10,
            totalStudents: 50,
            totalClassesTaught: 25,
            hourlyRate: 75,
            travelRadius: 10,
            availability: [:],
            social: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}