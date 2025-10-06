import Foundation

struct ClassModel: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let price: Double
    let duration: Int
    let instructorName: String
    let venueName: String
    let startDate: Date
    let endDate: Date

    init(id: UUID = UUID(), title: String = "Sample Class", description: String = "A great class", price: Double = 25.0, duration: Int = 60, instructorName: String = "Instructor", venueName: String = "Studio", startDate: Date = Date(), endDate: Date = Date().addingTimeInterval(3600)) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.duration = duration
        self.instructorName = instructorName
        self.venueName = venueName
        self.startDate = startDate
        self.endDate = endDate
    }
}