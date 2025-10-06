import Foundation
import SwiftUI

struct CreditTransactionDisplay: Identifiable, Codable {
    let id: UUID
    let description: String
    let date: Date
    let amount: Int
    let balanceAfter: Int
    let type: TransactionType

    enum TransactionType: String, Codable, CaseIterable {
        case purchase, usage, bonus, rollover, expiration
    }

    init(description: String, date: Date, amount: Int, balanceAfter: Int, type: TransactionType) {
        self.id = UUID()
        self.description = description
        self.date = date
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.type = type
    }

    var amountText: String {
        switch type {
        case .purchase, .bonus, .rollover:
            return "+\(amount)"
        case .usage, .expiration:
            return "-\(amount)"
        }
    }

    var color: Color {
        switch type {
        case .purchase: return .blue
        case .usage: return .red
        case .bonus: return .green
        case .rollover: return .orange
        case .expiration: return .gray
        }
    }

    var iconName: String {
        switch type {
        case .purchase: return "creditcard.fill"
        case .usage: return "minus.circle.fill"
        case .bonus: return "gift.fill"
        case .rollover: return "arrow.triangle.2.circlepath"
        case .expiration: return "clock.badge.xmark"
        }
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