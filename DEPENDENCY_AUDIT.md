# HobbyistSwiftUI Dependency Audit
*Generated: September 16, 2025*

## ✅ Currently Installed (via Swift Package Manager)

### 1. **Supabase** ✅
- **Version**: 2.31.2
- **Purpose**: Backend services, authentication, database, real-time updates
- **Status**: ✅ Installed and working
- **Imports Used**:
  - `import Supabase`
  - `import Realtime`

### 2. **Swift Dependencies** (Supabase sub-dependencies) ✅
- swift-asn1 (1.4.0)
- swift-clocks (1.0.6)
- swift-concurrency-extras (1.3.2)
- swift-crypto (3.15.0)
- swift-http-types (1.4.0)
- xctest-dynamic-overlay (1.6.1)

## ⚠️ Missing Dependencies (Need to Install)

### 1. **Stripe** ❌
- **Required for**: Payment processing
- **Imports Found**:
  - `import StripePaymentSheet` (PaymentService.swift)
  - `import StripeApplePay` (StripePaymentService.swift)
- **Action**: Add package: `https://github.com/stripe/stripe-ios`
- **Temporary Fix**: Commented out imports

### 2. **ConfettiSwiftUI** ❌
- **Required for**: Celebration animations
- **Imports Found**: `import ConfettiSwiftUI`
- **Action**: Add package: `https://github.com/simibac/ConfettiSwiftUI`

### 3. **Sentry** ❌
- **Required for**: Crash reporting and monitoring
- **Imports Found**: `import Sentry` (ServiceContainer.swift)
- **Action**: Add package: `https://github.com/getsentry/sentry-cocoa`

## ✅ System Frameworks (No Action Needed)

These are built-in iOS frameworks that don't need installation:

- ✅ AuthenticationServices - Sign in with Apple
- ✅ CoreLocation - Location services
- ✅ CryptoKit - Encryption/hashing
- ✅ Darwin - System calls
- ✅ LocalAuthentication - Face ID/Touch ID
- ✅ MapKit - Maps
- ✅ os.log - Logging
- ✅ PassKit - Apple Pay
- ✅ PhotosUI - Photo picker
- ✅ Security - Keychain
- ✅ StoreKit - In-app purchases
- ✅ UIKit - UI components
- ✅ UserNotifications - Push notifications

## 📋 Installation Instructions

### To Install Missing Dependencies in Xcode:

1. Open `HobbyistSwiftUI.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies...**
3. Add each missing package:

#### Stripe (Payment Processing)
```
URL: https://github.com/stripe/stripe-ios
Products to add:
- StripePaymentSheet
- StripeApplePay
```

#### ConfettiSwiftUI (Animations)
```
URL: https://github.com/simibac/ConfettiSwiftUI
Products to add:
- ConfettiSwiftUI
```

#### Sentry (Crash Reporting)
```
URL: https://github.com/getsentry/sentry-cocoa
Products to add:
- Sentry
```

## 🔧 Configuration Notes

### Stripe Configuration
- Requires API keys in environment configuration
- Need to set up webhook endpoints
- Configure Apple Pay merchant ID

### Sentry Configuration
- Need to set DSN in CrashReportingService.swift
- Currently placeholder: `"https://your-sentry-dsn@sentry.io/project-id"`

### Supabase Configuration
- Already configured in AppConfiguration
- Using Config-Dev.plist for environment settings

## 📱 Capabilities Required in Xcode

Make sure these capabilities are enabled in your app target:

- [ ] Push Notifications (for NotificationService)
- [ ] Sign In with Apple (for AuthenticationServices)
- [ ] Apple Pay (for PassKit/Stripe)
- [ ] Location Services (for CoreLocation)
- [ ] Face ID (add usage description in Info.plist)

## 🎯 Priority Order

1. **High Priority**:
   - Stripe (if payments are needed immediately)
   - Sentry (for production crash reporting)

2. **Medium Priority**:
   - ConfettiSwiftUI (nice-to-have UI enhancement)

3. **Low Priority**:
   - All system frameworks are already available

## ✅ Build Status After Dependencies

Once all dependencies are installed:
- All import statements should resolve
- No "No such module" errors
- Clean build should succeed

## 🔍 Files Affected by Missing Dependencies

1. **Stripe**: 
   - PaymentService.swift
   - StripePaymentService.swift
   - StripeWebhookValidator.swift

2. **ConfettiSwiftUI**:
   - Need to check which views use this

3. **Sentry**:
   - ServiceContainer.swift (CrashReportingService)