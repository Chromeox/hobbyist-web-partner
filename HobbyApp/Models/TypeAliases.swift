//
//  TypeAliases.swift
//  HobbyApp
//
//  Type aliases for better code clarity and documentation
//  See: /docs/type-reference-guide.md for complete type mappings
//

import Foundation

// MARK: - ID Type Aliases

/// Type alias for class identifiers (String-based)
///
/// HobbyClass uses String IDs for database compatibility
/// ```swift
/// let classId: ClassID = "class_12345"
/// let hobbyClass = HobbyClass(id: classId, ...)
/// ```
typealias ClassID = String

/// Type alias for booking identifiers (UUID-based)
///
/// All Booking-related IDs use UUID
/// ```swift
/// let bookingId: BookingID = UUID()
/// let booking = Booking(id: bookingId, ...)
/// ```
typealias BookingID = UUID

/// Type alias for user identifiers (String-based from Supabase)
///
/// SimpleUser.id returns String from Supabase auth
/// ```swift
/// let user: SimpleUser = ...
/// let userId: UserID = user.id  // String
/// ```
typealias UserID = String

/// Type alias for instructor identifiers (UUID-based for core model)
///
/// Instructor model uses UUID, but InstructorInfo uses String
/// ```swift
/// let instructor: Instructor  // instructor.id is UUID
/// let instructorId: InstructorID = instructor.id
/// ```
typealias InstructorID = UUID

/// Type alias for venue identifiers (UUID-based for core model)
///
/// Venue model uses UUID, but VenueInfo uses String
/// ```swift
/// let venue: Venue  // venue.id is UUID
/// let venueId: VenueID = venue.id
/// ```
typealias VenueID = UUID

/// Type alias for payment identifiers (UUID-based)
///
/// All payment-related IDs use UUID
/// ```swift
/// let paymentId: PaymentID = UUID()
/// let booking = Booking(..., paymentId: paymentId)
/// ```
typealias PaymentID = UUID

/// Type alias for saved search identifiers (UUID-based)
///
/// All search-related models use UUID
/// ```swift
/// let savedSearch: SavedSearch  // savedSearch.id is UUID
/// let searchId: SavedSearchID = savedSearch.id
/// ```
typealias SavedSearchID = UUID

// MARK: - Usage Examples

/*

 RECOMMENDED USAGE:

 1. Use type aliases in function signatures for clarity:

    ✅ GOOD:
    func bookClass(classId: ClassID, userId: UserID) -> BookingID {
        // Clear what types are expected
    }

    ❌ LESS CLEAR:
    func bookClass(classId: String, userId: String) -> UUID {
        // Unclear which IDs are which type
    }

 2. Use in model initializers:

    struct Booking {
        let id: BookingID
        let classId: ClassID  // Note: Stored as String in class references
        let userId: UserID
        let paymentId: PaymentID?
    }

 3. Use in ViewModels:

    class BookingViewModel {
        func createBooking(
            classId: ClassID,
            userId: UserID
        ) async throws -> BookingID {
            // Implementation
        }
    }

 CONVERSION PATTERNS:

 1. ClassID (String) to BookingID (UUID):
    let classId: ClassID = "class_12345"
    guard let classUUID: UUID = UUID(uuidString: classId) else {
        throw BookingError.invalidClassID
    }
    let booking = Booking(id: UUID(), classId: classUUID, ...)

 2. UserID (String) to BookingID (UUID):
    let userId: UserID = "user_12345"
    guard let userUUID: UUID = UUID(uuidString: userId) else {
        throw BookingError.invalidUserID
    }
    let booking = Booking(id: UUID(), userId: userUUID, ...)

 3. InstructorID (UUID) to InstructorInfo.id (String):
    let instructor: Instructor
    let instructorInfo = InstructorInfo(
        id: instructor.id.uuidString,  // UUID → String
        name: instructor.fullName
    )

 QUICK REFERENCE:

 String-based IDs:
 - ClassID
 - UserID

 UUID-based IDs:
 - BookingID
 - InstructorID (core model)
 - VenueID (core model)
 - PaymentID
 - SavedSearchID

 Mixed (depends on context):
 - InstructorInfo.id is String (nested in HobbyClass)
 - VenueInfo.id is String (nested in HobbyClass)

 See /docs/type-reference-guide.md for complete documentation.

 */
