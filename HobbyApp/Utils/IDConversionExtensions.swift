//
//  IDConversionExtensions.swift
//  HobbyApp
//
//  Created to prevent UUID/String type conversion errors
//  See: /docs/type-reference-guide.md for complete type mappings
//

import Foundation

// MARK: - UUID Extensions

extension UUID {
    /// Safely convert UUID to String
    /// - Returns: String representation of the UUID
    ///
    /// Example:
    /// ```swift
    /// let uuid = UUID()
    /// let string = uuid.asString  // "550e8400-e29b-41d4-a716-446655440000"
    /// ```
    var asString: String {
        return self.uuidString
    }

    /// Validate if a string is a valid UUID format
    /// - Parameter string: String to validate
    /// - Returns: True if string is valid UUID format
    ///
    /// Example:
    /// ```swift
    /// UUID.isValid("550e8400-e29b-41d4-a716-446655440000")  // true
    /// UUID.isValid("invalid-uuid")  // false
    /// ```
    static func isValid(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
}

// MARK: - String Extensions

extension String {
    /// Safely convert String to UUID
    /// - Returns: UUID if string is valid UUID format, nil otherwise
    ///
    /// Example:
    /// ```swift
    /// let string = "550e8400-e29b-41d4-a716-446655440000"
    /// let uuid = string.asUUID  // UUID object
    ///
    /// let invalid = "not-a-uuid"
    /// let failed = invalid.asUUID  // nil
    /// ```
    var asUUID: UUID? {
        return UUID(uuidString: self)
    }

    /// Convert String to UUID with a fallback default
    /// - Parameter defaultUUID: UUID to return if conversion fails (default: random UUID)
    /// - Returns: Converted UUID or default
    ///
    /// Example:
    /// ```swift
    /// let string = "invalid-uuid"
    /// let uuid = string.asUUID(default: UUID())  // Returns new random UUID
    /// ```
    func asUUID(default defaultUUID: UUID = UUID()) -> UUID {
        return UUID(uuidString: self) ?? defaultUUID
    }

    /// Check if string is a valid UUID format
    ///
    /// Example:
    /// ```swift
    /// "550e8400-e29b-41d4-a716-446655440000".isValidUUID  // true
    /// "not-a-uuid".isValidUUID  // false
    /// ```
    var isValidUUID: Bool {
        return UUID(uuidString: self) != nil
    }
}

// MARK: - Collection Extensions for ID Conversion

extension Collection where Element == UUID {
    /// Convert array of UUIDs to array of Strings
    ///
    /// Example:
    /// ```swift
    /// let uuids: [UUID] = [UUID(), UUID(), UUID()]
    /// let strings = uuids.asStrings  // ["550e...", "660f...", "770g..."]
    /// ```
    var asStrings: [String] {
        return self.map { $0.uuidString }
    }
}

extension Collection where Element == String {
    /// Convert array of Strings to array of UUIDs (filters out invalid UUIDs)
    ///
    /// Example:
    /// ```swift
    /// let strings = ["550e8400-e29b-41d4-a716-446655440000", "invalid", "660f..."]
    /// let uuids = strings.asUUIDs  // [UUID("550e..."), UUID("660f...")]
    /// // "invalid" is filtered out
    /// ```
    var asUUIDs: [UUID] {
        return self.compactMap { UUID(uuidString: $0) }
    }
}

// MARK: - Optional UUID Extensions

extension Optional where Wrapped == UUID {
    /// Safely convert optional UUID to optional String
    ///
    /// Example:
    /// ```swift
    /// let uuid: UUID? = UUID()
    /// let string = uuid.asString  // "550e..."
    ///
    /// let nilUUID: UUID? = nil
    /// let nilString = nilUUID.asString  // nil
    /// ```
    var asString: String? {
        return self?.uuidString
    }
}

extension Optional where Wrapped == String {
    /// Safely convert optional String to optional UUID
    ///
    /// Example:
    /// ```swift
    /// let string: String? = "550e8400-e29b-41d4-a716-446655440000"
    /// let uuid = string.asUUID  // UUID object
    ///
    /// let nilString: String? = nil
    /// let nilUUID = nilString.asUUID  // nil
    /// ```
    var asUUID: UUID? {
        guard let self = self else { return nil }
        return UUID(uuidString: self)
    }
}

// MARK: - Usage Examples & Guidelines

/*

 USAGE GUIDELINES:

 1. UUID to String (Always Safe):
    let uuid = UUID()
    let string = uuid.asString  // ✅ Safe

 2. String to UUID (May Fail):
    let string = "550e8400-e29b-41d4-a716-446655440000"
    if let uuid = string.asUUID {
        // ✅ Valid UUID
    } else {
        // ❌ Invalid UUID format
    }

 3. String to UUID with Default:
    let string = "possibly-invalid"
    let uuid = string.asUUID(default: UUID())  // ✅ Always returns UUID

 4. Validation Before Conversion:
    let string = "550e8400-e29b-41d4-a716-446655440000"
    if string.isValidUUID {
        let uuid = string.asUUID!  // ✅ Safe to force unwrap
    }

 5. Array Conversions:
    let uuids: [UUID] = [UUID(), UUID()]
    let strings = uuids.asStrings  // ✅ [String]

    let stringArray = ["550e...", "invalid", "660f..."]
    let uuidArray = stringArray.asUUIDs  // ✅ Valid UUIDs only

 COMMON PITFALLS:

 ❌ DON'T: Try to convert UUID to UUID
    let uuid = UUID()
    let converted = UUID(uuidString: uuid)  // ERROR!

 ✅ DO: Just use it directly
    let uuid = UUID()
    let copy = uuid  // It's already UUID

 ❌ DON'T: Call .uuidString on String
    let string = "550e..."
    let result = string.uuidString  // ERROR!

 ✅ DO: It's already String
    let string = "550e..."
    let copy = string  // It's already String

 See /docs/type-reference-guide.md for complete model type mappings.

 */
