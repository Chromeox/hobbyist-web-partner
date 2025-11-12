# Remove Unused Swift Packages - MANUAL REMOVAL REQUIRED

## ⚠️ IMPORTANT: Remove Manually in Xcode
**Do NOT use automated scripts** - they can corrupt the project.pbxproj file.
Follow the step-by-step instructions below.

## Problem
Stripe package alone takes 5-15 minutes to index, and we're not using it (credits-only system).
Facebook SDK is also not imported in any production code.

## Packages to Remove

### 1. Stripe iOS SDK
- **Package**: `https://github.com/stripe/stripe-ios`
- **Why Remove**: Stubbed out in PaymentService.swift, using credits-only system
- **Size Impact**: Large package with 25+ modules, major indexing slowdown

### 2. Facebook iOS SDK
- **Package**: `https://github.com/facebook/facebook-ios-sdk`
- **Why Remove**: Not imported in ProductionApp or any active Services/ViewModels
- **Size Impact**: Medium package with 10+ modules

## Packages to Keep

### 1. Supabase Swift
- **Package**: `https://github.com/supabase/supabase-swift`
- **Why Keep**: Core backend - used in ProductionApp and SimpleSupabaseService
- **Status**: CRITICAL - DO NOT REMOVE

### 2. Google Sign-In iOS
- **Package**: `https://github.com/google/GoogleSignIn-iOS`
- **Why Keep**: Used in SimpleSupabaseService for authentication
- **Status**: CRITICAL - DO NOT REMOVE

## How to Remove in Xcode

1. Open `HobbyApp.xcodeproj` in Xcode
2. Select project in navigator (top level)
3. Select "HobbyApp" target
4. Go to "Frameworks, Libraries, and Embedded Content" section
5. Find these entries and click the "-" button:
   - Stripe
   - StripeApplePay
   - FacebookCore
   - FacebookLogin
6. Go to "Package Dependencies" tab
7. Select `stripe-ios` package → Click "-" button
8. Select `facebook-ios-sdk` package → Click "-" button
9. Clean build folder (Cmd+Shift+K)
10. Build (Cmd+B)

## Expected Results

- **Indexing time**: Reduced from 15-20 min → 3-5 min
- **Derived data size**: ~40% smaller
- **Build time**: Faster incremental builds
- **No code changes needed**: Already removed imports from active code

## Verification

After removal, confirm these still work:
- ✅ Supabase authentication
- ✅ Google Sign-In
- ✅ Credit pack purchases (StoreKit)
- ✅ User profiles and data

## Rollback (if needed)

If you need Stripe back later:
1. File → Add Package Dependencies
2. Enter: `https://github.com/stripe/stripe-ios`
3. Version: 25.0.0 or newer
4. Add to target: HobbyApp
