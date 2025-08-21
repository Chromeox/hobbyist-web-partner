import Foundation
import SwiftUI

enum PaymentMethod: Equatable {
    case applePay
    case card(String)
}

struct SavedCard: Identifiable {
    let id: String
    let brand: String
    let last4: String
}

struct Discount {
    let code: String
    let percentage: Int
}

@MainActor
class BookingViewModel: ObservableObject {
    // Booking State
    @Published var participantCount = 1
    @Published var participantNames: [Int: String] = [:]
    @Published var specialRequests = ""
    @Published var experienceLevel = "Beginner"
    @Published var selectedEquipment: Set<String> = []
    @Published var emergencyContactName = ""
    @Published var emergencyContactPhone = ""
    
    // Payment State
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var savedCards: [SavedCard] = []
    @Published var appliedDiscount: Discount?
    
    // Processing State
    @Published var isProcessing = false
    @Published var processingMessage = ""
    @Published var processingProgress = 0.0
    @Published var bookingComplete = false
    @Published var confirmationCode = ""
    @Published var agreedToTerms = false
    
    // Pricing
    private var basePrice: Double = 25.0
    private let processingFeeRate = 0.03
    
    init() {
        loadSavedCards()
    }
    
    private func loadSavedCards() {
        // Load sample saved cards
        savedCards = [
            SavedCard(id: "1", brand: "Visa", last4: "4242"),
            SavedCard(id: "2", brand: "Mastercard", last4: "5555")
        ]
    }
    
    func initializeBooking(for classItem: ClassItem) {
        // Parse price from string
        if let priceString = classItem.price.replacingOccurrences(of: "$", with: "").first,
           let price = Double(String(priceString) + "5") {
            basePrice = price
        }
    }
    
    var subtotal: Double {
        basePrice * Double(participantCount)
    }
    
    var equipmentTotal: Double {
        // Calculate equipment rental cost
        // For demo, assume $5 per equipment item
        return Double(selectedEquipment.count) * 5.0
    }
    
    var discountAmount: Double {
        if let discount = appliedDiscount {
            return (subtotal + equipmentTotal) * (Double(discount.percentage) / 100.0)
        }
        return 0
    }
    
    var processingFee: Double {
        return (subtotal + equipmentTotal - discountAmount) * processingFeeRate
    }
    
    var totalPrice: Double {
        return subtotal + equipmentTotal - discountAmount + processingFee
    }
    
    // Formatted prices
    var formattedSubtotal: String {
        return String(format: "$%.2f", subtotal)
    }
    
    var formattedEquipmentTotal: String {
        return String(format: "$%.2f", equipmentTotal)
    }
    
    var formattedDiscountAmount: String {
        return String(format: "$%.2f", discountAmount)
    }
    
    var formattedProcessingFee: String {
        return String(format: "$%.2f", processingFee)
    }
    
    var formattedTotalPrice: String {
        return String(format: "$%.2f", totalPrice)
    }
    
    var paymentMethodDescription: String {
        switch selectedPaymentMethod {
        case .applePay:
            return "Apple Pay"
        case .card(let id):
            if let card = savedCards.first(where: { $0.id == id }) {
                return "\(card.brand) •••• \(card.last4)"
            }
            return "Card"
        case .none:
            return "Not selected"
        }
    }
    
    func applyCoupon(_ code: String) {
        // Validate and apply coupon
        if code.uppercased() == "SAVE20" {
            appliedDiscount = Discount(code: code.uppercased(), percentage: 20)
        } else if code.uppercased() == "FIRST10" {
            appliedDiscount = Discount(code: code.uppercased(), percentage: 10)
        }
    }
    
    func processPayment() async {
        isProcessing = true
        processingMessage = "Processing payment..."
        
        // Simulate payment processing
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            processingProgress = progress
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        // Generate confirmation code
        confirmationCode = "HB\(Int.random(in: 100000...999999))"
        bookingComplete = true
        isProcessing = false
    }
}