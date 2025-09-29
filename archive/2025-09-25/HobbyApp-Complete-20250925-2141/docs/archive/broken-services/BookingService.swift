import Foundation

protocol BookingServiceProtocol {
    func createBooking() async throws
}

class BookingService: BookingServiceProtocol {
    func createBooking() async throws {
        // Minimal implementation
    }
}