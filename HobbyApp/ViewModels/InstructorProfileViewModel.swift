import Foundation
import SwiftUI

@MainActor
final class InstructorProfileViewModel: ObservableObject {
    @Published var instructor: Instructor?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFollowing = false
    @Published var instructorClasses: [ClassItem] = []
    @Published var reviews: [Review] = []
    @Published var totalClasses = 0
    @Published var totalStudents = 0
    @Published var upcomingClasses = 0
    
    func loadInstructor(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Create sample instructor data
            instructor = createSampleInstructor(id: id)
            
            // Load additional data
            await loadInstructorData()
            
        } catch {
            errorMessage = "Failed to load instructor profile"
        }
        
        isLoading = false
    }
    
    private func loadInstructorData() async {
        guard let instructor = instructor else { return }
        
        // Load classes
        instructorClasses = createSampleClasses(for: instructor)
        
        // Load reviews
        reviews = createSampleReviews(for: instructor)
        
        // Calculate stats
        totalClasses = instructorClasses.count + Int.random(in: 5...25)
        totalStudents = Int.random(in: 50...500)
        upcomingClasses = instructorClasses.filter { $0.startDate > Date() }.count
        
        // Check if following (mock data)
        isFollowing = Bool.random()
    }
    
    func toggleFollow() async {
        guard instructor != nil else { return }
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        isFollowing.toggle()
    }
    
    private func createSampleInstructor(id: String) -> Instructor {
        let firstNames = ["Sarah", "Michael", "Emma", "David", "Lisa", "James", "Maria", "Robert", "Jennifer", "Christopher"]
        let lastNames = ["Chen", "Martinez", "Thompson", "Anderson", "Garcia", "Wilson", "Rodriguez", "Brown", "Davis", "Miller"]
        
        let specialties = [
            ["Pottery", "Ceramics", "Sculpture"],
            ["Watercolor", "Oil Painting", "Digital Art"],
            ["Yoga", "Pilates", "Meditation"],
            ["Italian Cuisine", "Baking", "Vegetarian Cooking"],
            ["Guitar", "Piano", "Voice"],
            ["Photography", "Photo Editing", "Portrait Photography"],
            ["Creative Writing", "Poetry", "Storytelling"],
            ["Jewelry Making", "Metalworking", "Beadwork"],
            ["Woodworking", "Furniture Making", "Carving"],
            ["Dance", "Ballet", "Contemporary"]
        ]
        
        let bios = [
            "Passionate instructor with a love for sharing creative skills and helping students discover their artistic potential.",
            "Experienced teacher dedicated to creating a supportive and inspiring learning environment for all skill levels.",
            "Award-winning artist and educator with a focus on technique, creativity, and personal expression.",
            "Professional instructor committed to helping students build confidence and develop their unique creative voice.",
            "Certified instructor with extensive experience in both traditional and contemporary teaching methods."
        ]
        
        let selectedSpecialties = specialties.randomElement() ?? ["Art", "Creative Expression"]
        
        return Instructor(
            id: UUID(),
            userId: UUID(),
            firstName: firstNames.randomElement() ?? "Instructor",
            lastName: lastNames.randomElement() ?? "Name",
            email: "instructor@example.com",
            phone: "+1 (555) 123-4567",
            bio: bios.randomElement(),
            specialties: selectedSpecialties,
            certificationInfo: createSampleCertifications(),
            rating: Decimal(Double.random(in: 4.2...5.0)),
            totalReviews: Int.random(in: 15...150),
            profileImageUrl: nil,
            yearsOfExperience: Int.random(in: 3...20),
            socialLinks: createSampleSocialLinks(),
            availability: createSampleAvailability(),
            isActive: true,
            createdAt: Date().addingTimeInterval(-TimeInterval.random(in: 86400...31536000)), // Random date in past year
            updatedAt: Date()
        )
    }
    
    private func createSampleCertifications() -> CertificationInfo? {
        let certificationNames = [
            "Certified Creative Arts Instructor",
            "Professional Teaching Certificate",
            "Arts Education Specialist",
            "Workshop Leadership Certification",
            "Creative Learning Facilitator"
        ]
        
        let organizations = [
            "Creative Arts Institute",
            "Professional Teachers Association",
            "Arts Education Council",
            "International Creative Learning Society",
            "Creative Skills Certification Board"
        ]
        
        let certifications = (0..<Int.random(in: 1...3)).map { _ in
            Certification(
                name: certificationNames.randomElement() ?? "Certification",
                issuingOrganization: organizations.randomElement() ?? "Organization",
                issueDate: Date().addingTimeInterval(-TimeInterval.random(in: 86400...1576800000)), // Random date in past 5 years
                expiryDate: Bool.random() ? Date().addingTimeInterval(TimeInterval.random(in: 86400...31536000)) : nil, // Random future date or no expiry
                credentialId: UUID().uuidString.prefix(8).uppercased(),
                verificationUrl: "https://example.com/verify"
            )
        }
        
        return CertificationInfo(
            certifications: certifications,
            verifiedAt: Date()
        )
    }
    
    private func createSampleSocialLinks() -> SocialLinks? {
        if Bool.random() {
            return SocialLinks(
                website: Bool.random() ? "https://instructorwebsite.com" : nil,
                instagram: Bool.random() ? "https://instagram.com/instructor" : nil,
                facebook: Bool.random() ? "https://facebook.com/instructor" : nil,
                twitter: Bool.random() ? "https://twitter.com/instructor" : nil,
                linkedin: Bool.random() ? "https://linkedin.com/in/instructor" : nil,
                youtube: Bool.random() ? "https://youtube.com/instructor" : nil
            )
        }
        return nil
    }
    
    private func createSampleAvailability() -> [AvailabilitySlot]? {
        if Bool.random() {
            return (1...5).compactMap { day in
                if Bool.random() {
                    let startHour = Int.random(in: 9...14)
                    let endHour = startHour + Int.random(in: 2...4)
                    return AvailabilitySlot(
                        dayOfWeek: day,
                        startTime: String(format: "%02d:00", startHour),
                        endTime: String(format: "%02d:00", endHour),
                        isRecurring: Bool.random()
                    )
                }
                return nil
            }
        }
        return nil
    }
    
    private func createSampleClasses(for instructor: Instructor) -> [ClassItem] {
        let classTitles = [
            "Beginner's \(instructor.specialties.first ?? "Art")",
            "Intermediate \(instructor.specialties.first ?? "Art")",
            "Advanced \(instructor.specialties.first ?? "Art")",
            "Weekend \(instructor.specialties.first ?? "Art") Workshop",
            "Evening \(instructor.specialties.first ?? "Art") Session"
        ]
        
        let venues = [
            "Creative Studio Vancouver",
            "Downtown Arts Center",
            "Community Learning Hub",
            "Artisan Workshop Space",
            "Creative Collective Studio"
        ]
        
        return (0..<Int.random(in: 2...5)).map { index in
            let startDate = Date().addingTimeInterval(TimeInterval(86400 * Int.random(in: 1...30))) // 1-30 days from now
            
            return ClassItem(
                id: UUID().uuidString,
                title: classTitles.randomElement() ?? "Creative Class",
                description: "Learn \(instructor.specialties.first ?? "art") techniques in a supportive environment.",
                price: Double.random(in: 25...125),
                duration: Int.random(in: 60...180),
                instructorName: instructor.fullName,
                venueName: venues.randomElement() ?? "Studio",
                startDate: startDate,
                endDate: startDate.addingTimeInterval(7200) // 2 hours later
            )
        }
    }
    
    private func createSampleReviews(for instructor: Instructor) -> [Review] {
        let reviewTexts = [
            "\(instructor.firstName) is an amazing instructor! Really helped me improve my skills.",
            "Great class with \(instructor.firstName). Very patient and knowledgeable.",
            "I loved learning from \(instructor.firstName). Highly recommend their classes!",
            "Excellent teaching style. \(instructor.firstName) makes learning fun and engaging.",
            "Very inspiring instructor. I learned so much in just one session with \(instructor.firstName).",
            "\(instructor.firstName) creates such a supportive learning environment. Perfect for beginners!",
            "Professional and encouraging. \(instructor.firstName) really knows their craft.",
            "Amazing experience! \(instructor.firstName) is patient and really cares about student progress."
        ]
        
        let userNames = [
            "Alex K.", "Jamie L.", "Taylor M.", "Jordan P.", "Casey R.",
            "Riley S.", "Avery T.", "Morgan W.", "Quinn Z.", "Sage B."
        ]
        
        return (0..<Int.random(in: 3...8)).map { _ in
            Review(
                id: UUID().uuidString,
                userName: userNames.randomElement() ?? "Anonymous",
                rating: Int.random(in: 4...5),
                comment: reviewTexts.randomElement() ?? "Great class!",
                date: Date().addingTimeInterval(-TimeInterval.random(in: 86400...2592000)), // Random date in past month
                classTitle: instructor.specialties.first ?? "Art Class",
                isVerifiedPurchase: Bool.random()
            )
        }
    }
}