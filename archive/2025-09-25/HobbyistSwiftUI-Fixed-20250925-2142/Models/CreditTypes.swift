import Foundation

struct CreditTransactionDisplay: Identifiable, Codable {
    let id: UUID
    let amount: Int
    let description: String
    let date: Date
    let type: String

    init(id: UUID = UUID(), amount: Int = 1, description: String = "Credit transaction", date: Date = Date(), type: String = "purchase") {
        self.id = id
        self.amount = amount
        self.description = description
        self.date = date
        self.type = type
    }
}

struct CreditExpiration: Identifiable, Codable {
    let id: UUID
    let credits: Int
    let expirationDate: Date

    init(id: UUID = UUID(), credits: Int = 5, expirationDate: Date = Date().addingTimeInterval(86400 * 30)) {
        self.id = id
        self.credits = credits
        self.expirationDate = expirationDate
    }
}