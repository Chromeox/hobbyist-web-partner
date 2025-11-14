# HobbyApp Type Reference Guide

## Purpose
This document provides a definitive reference for all ID types used in the HobbyApp codebase to prevent UUID/String type mismatches and conversion errors.

---

## Core Data Models

### HobbyClass Model
**File**: `/HobbyApp/Models/HobbyClass.swift`

```swift
struct HobbyClass {
    let id: String                    // ⚠️ STRING (not UUID)
    let instructor: InstructorInfo    // Nested: id is String
    let venue: VenueInfo             // Nested: id is String
}
```

**Key Point**: HobbyClass uses String IDs, not UUID. This is because it's designed to work with database string identifiers.

---

### Instructor Model
**File**: `/HobbyApp/Models/Instructor.swift`

```swift
struct Instructor {
    let id: UUID                     // ✅ UUID
    let userId: UUID                 // ✅ UUID
}
```

**Conversion**: When creating InstructorInfo from Instructor:
```swift
func toInstructorInfo() -> InstructorInfo {
    return InstructorInfo(
        id: self.id.uuidString,      // UUID → String
        // ... other properties
    )
}
```

---

### Venue Model
**File**: `/HobbyApp/Models/Venue.swift`

```swift
struct Venue {
    let id: UUID                     // ✅ UUID
}
```

**Conversion**: When creating VenueInfo from Venue:
```swift
func toVenueInfo() -> VenueInfo {
    return VenueInfo(
        id: self.id.uuidString,      // UUID → String
        // ... other properties
    )
}
```

---

### Booking Model
**File**: `/HobbyApp/Models/Booking.swift`

```swift
struct Booking {
    let id: UUID                     // ✅ UUID
    let classId: UUID                // ✅ UUID
    let userId: UUID                 // ✅ UUID
    let paymentId: UUID?             // ✅ UUID (optional)
}
```

**All Booking IDs are UUID** - no exceptions.

---

## Nested Info Models

### InstructorInfo (nested in HobbyClass)
**File**: `/HobbyApp/Models/HobbyClass.swift`

```swift
struct InstructorInfo {
    let id: String                   // ⚠️ STRING (converted from Instructor.id)
}
```

**Why String?** InstructorInfo is a lightweight DTO used in HobbyClass. Since HobbyClass.id is String, all nested IDs are also String for consistency.

---

### VenueInfo (nested in HobbyClass)
**File**: `/HobbyApp/Models/HobbyClass.swift`

```swift
struct VenueInfo {
    let id: String                   // ⚠️ STRING (converted from Venue.id)
}
```

**Why String?** Same reason as InstructorInfo - consistency with HobbyClass String-based architecture.

---

## Search Models

**File**: `/HobbyApp/Models/SearchModels.swift`

```swift
struct SavedSearch {
    let id: UUID                     // ✅ UUID (line 456)
}

struct SearchHistoryItem {
    let id: UUID                     // ✅ UUID
}

struct TrendingCategory {
    let id: UUID                     // ✅ UUID
}

struct SearchSuggestion {
    let id: UUID                     // ✅ UUID
}

struct QuickFilterPreset {
    let id: UUID                     // ✅ UUID
}
```

**All Search-related models use UUID.**

---

## Service Layer Models

### SimpleUser
**File**: `/HobbyApp/Services/SimpleSupabaseService.swift` (line 1059)

```swift
struct SimpleUser {
    let id: String                   // ⚠️ STRING (not UUID)
    let email: String
    let name: String
}
```

**Critical**: SimpleUser.id is STRING because it comes directly from Supabase auth.user.id which returns String.

---

### SimpleClass
**File**: `/HobbyApp/Services/SimpleSupabaseService.swift`

```swift
struct SimpleClass {
    let id: String                   // ⚠️ STRING
}
```

---

### SimpleBooking
**File**: `/HobbyApp/Services/SimpleSupabaseService.swift`

```swift
struct SimpleBooking {
    let id: String                   // ⚠️ STRING
}
```

---

### SimpleUserProfile
**File**: `/HobbyApp/Services/SimpleSupabaseService.swift`

```swift
struct SimpleUserProfile {
    let id: String                   // ⚠️ STRING
}
```

**Pattern**: All `Simple*` models use String IDs for database compatibility.

---

## Conversion Patterns

### UUID → String (Safe)
```swift
let uuidValue: UUID = UUID()
let stringValue: String = uuidValue.uuidString  // ✅ Always safe
```

### String → UUID (Requires Validation)
```swift
let stringValue: String = "550e8400-e29b-41d4-a716-446655440000"
let uuidValue: UUID? = UUID(uuidString: stringValue)  // ⚠️ Can return nil

// Safe unwrapping:
guard let uuid = UUID(uuidString: stringValue) else {
    // Handle invalid UUID string
    return
}
```

### Common Mistakes

❌ **WRONG**: Passing UUID where String expected
```swift
let user: SimpleUser = ...
let booking = Booking(userId: user.id)  // ERROR: String vs UUID
```

✅ **CORRECT**: Convert String to UUID
```swift
let user: SimpleUser = ...
guard let userId = UUID(uuidString: user.id) else { return }
let booking = Booking(userId: userId)
```

❌ **WRONG**: Trying to convert UUID to UUID via String
```swift
let saved: SavedSearch = ...  // saved.id is UUID
guard let uuid = UUID(uuidString: saved.id) else { return }  // ERROR!
```

✅ **CORRECT**: Use UUID directly
```swift
let saved: SavedSearch = ...
let newSearch = SavedSearch(id: saved.id, ...)  // Just copy it
```

❌ **WRONG**: Calling .uuidString on String
```swift
let user: SimpleUser = ...
let idString = user.id.uuidString  // ERROR: String has no .uuidString
```

✅ **CORRECT**: It's already a String
```swift
let user: SimpleUser = ...
let idString = user.id  // It's already String
```

---

## Quick Reference Table

| Model | ID Type | Notes |
|-------|---------|-------|
| HobbyClass | String | Database string IDs |
| Instructor | UUID | Core entity |
| Venue | UUID | Core entity |
| Booking | UUID | All booking IDs are UUID |
| InstructorInfo | String | Nested in HobbyClass |
| VenueInfo | String | Nested in HobbyClass |
| SavedSearch | UUID | All search models use UUID |
| SearchHistoryItem | UUID | All search models use UUID |
| SimpleUser | String | Supabase auth returns String |
| SimpleClass | String | Database compatibility |
| SimpleBooking | String | Database compatibility |

---

## Decision Tree for ID Conversions

```
Do I have a UUID and need a String?
├─ YES → Use .uuidString property
└─ NO → Continue

Do I have a String and need a UUID?
├─ YES → Use UUID(uuidString:) with optional handling
└─ NO → Continue

Are both sides the same type?
├─ YES → Just assign/copy directly
└─ NO → Review model definitions (might be a bug)
```

---

## Common Scenarios

### Scenario 1: Creating a Booking from SimpleUser
```swift
let user: SimpleUser  // id is String
let classId: String   // From HobbyClass

// Convert String IDs to UUID for Booking
guard let userUUID = UUID(uuidString: user.id),
      let classUUID = UUID(uuidString: classId) else {
    throw BookingError.invalidID
}

let booking = Booking(
    id: UUID(),
    classId: classUUID,
    userId: userUUID,
    paymentId: nil
)
```

### Scenario 2: Converting Instructor to InstructorInfo
```swift
let instructor: Instructor  // id is UUID

let info = InstructorInfo(
    id: instructor.id.uuidString,  // UUID → String
    name: instructor.fullName,
    // ... other properties
)
```

### Scenario 3: Working with SavedSearch
```swift
// ✅ CORRECT - Both use UUID
let serviceSearch: SavedSearch  // from SearchService
let viewModelSearch = SavedSearch(
    id: serviceSearch.id,  // UUID → UUID (direct copy)
    name: serviceSearch.name,
    query: serviceSearch.query,
    filters: serviceSearch.filters,
    createdAt: serviceSearch.createdAt
)

// Or even simpler:
let viewModelSearches = searchService.savedSearches  // Direct assignment
```

---

## Prevention Tips

1. **Check the type** before converting
2. **Use compiler errors as hints** - they tell you exactly what's wrong
3. **Refer to this document** when uncertain
4. **Use extensions** (see IDConversionExtensions.swift) for safe conversions
5. **Use type aliases** (see TypeAliases.swift) for clarity

---

## Related Files

- **Conversion Extensions**: `/HobbyApp/Utils/IDConversionExtensions.swift`
- **Type Aliases**: `/HobbyApp/Models/TypeAliases.swift`
- **Swift Build Fixer Prompt**: `/docs/swift-build-error-agent-prompt.md`

---

*Last Updated: 2025-01-14*
*Version: 1.0*
