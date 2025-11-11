# Technical Debt - HobbyApp

## Priority: High

### AppError.swift Contains Duplicate Service Definitions

**File**: `/Users/chromefang.exe/HobbyApp/HobbyApp/Models/AppError.swift`
**Line Count**: 2,271 lines (should be ~100-200 for error definitions)

**Issue**:
The `AppError.swift` file contains duplicate definitions of entire service classes that already exist elsewhere in the codebase:

1. **Duplicate `SearchService` class** (line 1871-2060)
   - Original location: `/HobbyApp/Services/SearchService.swift`
   - Includes nested `SavedSearch` struct (line 2032) conflicting with `SearchModels.swift:455`

2. **Duplicate `AnalyticsService` class** (line 2062+)
   - Original location: `/HobbyApp/Services/AnalyticsService.swift`

3. **LocationService code** appears to also be duplicated (line ~1700+)

**Impact**:
- Causes Swift compiler type ambiguity errors
- Confuses code completion and navigation
- Increases build times
- Makes refactoring dangerous (changes in one location don't reflect in duplicates)

**Root Cause**:
Likely caused by:
- Accidental paste of entire service files into AppError.swift
- Merge conflict resolution gone wrong
- Copy-paste during debugging that was never removed

**Recommended Fix**:
1. Backup current `AppError.swift`
2. Extract only actual error type definitions (should be minimal - enums/structs for errors)
3. Remove all service class definitions
4. Verify all references resolve to the correct service files
5. Run full project build to ensure no breakage

**Workaround Applied** (November 10, 2025):
- Modified `SearchViewModel` to explicitly map between `SavedSearch` types
- Updated `SavedSearch` initializer in `SearchModels.swift` to accept all parameters
- This allows compilation but doesn't solve the underlying duplication issue

**Next Steps**:
- Schedule AppError.swift cleanup as dedicated task
- Add linting rule to catch files > 500 lines in Models/ directory
- Consider using Swift's access control to prevent accidental imports of wrong types

---

## Priority: Medium

### Other Technical Debt Items
_(Add future issues here as they arise)_
