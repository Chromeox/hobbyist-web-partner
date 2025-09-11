# Xcode Configuration Guide for HobbyistSwiftUI iOS App

## Overview
This guide provides step-by-step instructions for configuring the HobbyistSwiftUI iOS app in Xcode for TestFlight deployment and App Store submission.

## Prerequisites
- Xcode 15.0 or later
- macOS 14.0 (Sonoma) or later
- Active Apple Developer Program membership ($99/year)
- HobbyistSwiftUI project files

## Step 1: Open Project in Xcode

1. Navigate to: `/Users/chromefang.exe/HobbyistSwiftUI/iOS/`
2. Double-click `HobbyistSwiftUI.xcodeproj` to open in Xcode
3. Ensure you're using Xcode 15.0+ for iOS 16+ deployment

## Step 2: Configure Project Settings

### General Tab Configuration

1. **Project Navigator** → Select `HobbyistSwiftUI` (blue project icon)
2. **Targets** → Select `HobbyistSwiftUI` target
3. **General Tab** → Configure the following:

```
Display Name: HobbyistSwiftUI
Bundle Identifier: com.yourcompany.hobbyistswiftui
Version: 1.0.0
Build: 1

Deployment Info:
- iOS Deployment Target: 16.0
- iPhone Orientation: Portrait
- iPad Orientation: Portrait, Landscape Left, Landscape Right
- Requires Full Screen: ✓ (checked)
- Status Bar Style: Default
- Hide Status Bar: ☐ (unchecked)

App Icons and Launch Screen:
- App Icons Source: AppIcon (from Assets.xcassets)
- Launch Screen File: LaunchScreen (leave empty for default)
```

### Signing & Capabilities Tab

1. **Automatically manage signing**: ✓ (recommended for initial setup)
2. **Team**: Select your Apple Developer Team
3. **Bundle Identifier**: Must match App Store Connect app record
4. **Provisioning Profile**: Xcode Managed Profile

#### Required Capabilities to Add:
- **Push Notifications**: For class reminders and booking confirmations
- **Background Modes**: 
  - Background processing (for data sync)
  - Remote notifications (for push notifications)
- **In-App Purchase**: For credit purchasing and premium features
- **Apple Pay**: For payment processing

To add capabilities:
1. Click "+" next to Capability
2. Search for each capability
3. Configure settings as needed

## Step 3: Configure Build Settings

### Build Settings Tab Configuration

#### Key Build Settings to Configure:

**Basic Settings:**
- Product Name: `HobbyistSwiftUI`
- Product Bundle Identifier: `com.yourcompany.hobbyistswiftui`
- iOS Deployment Target: `16.0`

**Code Signing Settings:**
- Code Signing Style: `Automatic`
- Development Team: `Your Apple Developer Team`
- Provisioning Profile (Debug): `Automatic`
- Provisioning Profile (Release): `Automatic`

**Swift Compiler Settings:**
- Optimization Level (Debug): `No Optimization [-Onone]`
- Optimization Level (Release): `Optimize for Speed [-O]`
- Swift Language Version: `Swift 5`

**Linking Settings:**
- Enable Bitcode: `No` (required for Stripe SDK)
- Strip Debug Symbols During Copy: `Yes` (Release only)

**Build Options:**
- Compiler for C/C++/Objective-C: `Default compiler (Apple Clang)`
- Enable Modules (C and Objective-C): `Yes`

## Step 4: Configure Swift Package Dependencies

### Add Package Dependencies in Xcode:

1. **File** → **Add Package Dependencies**
2. Add each package URL and configure versions:

```
Supabase Swift SDK:
URL: https://github.com/supabase/supabase-swift.git
Version: Exact version 2.31.2
Products to add: Supabase, Auth, Realtime, Storage, Functions

Stripe iOS SDK:
URL: https://github.com/stripe/stripe-ios.git
Version: Exact version 24.15.0
Products to add: StripePaymentSheet, StripePayments, StripeCore

Kingfisher:
URL: https://github.com/onevcat/Kingfisher.git
Version: Exact version 8.5.0
Products to add: Kingfisher
```

### Alternative: Use Local Package.swift

If you prefer to use the configured Package.swift:
1. **File** → **Add Local...**
2. Navigate to iOS directory
3. Select `Package.swift`
4. Add `HobbyistSwiftUIDependencies` product to target

## Step 5: Configure Schemes

### Debug Scheme Configuration:

1. **Product** → **Scheme** → **Edit Scheme**
2. **Run** → **Info** → **Build Configuration**: `Debug`
3. **Run** → **Options** → **Console**: `Use Terminal`
4. **Run** → **Arguments** → **Environment Variables** (add as needed):
   ```
   SUPABASE_DEBUG=1
   NETWORKING_DEBUG=1
   ```

### Release Scheme Configuration:

1. Create new scheme: **Product** → **Scheme** → **New Scheme**
2. Name: `HobbyistSwiftUI-Release`
3. **Run** → **Info** → **Build Configuration**: `Release`
4. **Archive** → **Build Configuration**: `Release`

## Step 6: Configure Info.plist

The Info.plist has been pre-configured with:
- Privacy permission descriptions
- URL schemes for deep linking
- Background modes
- Required device capabilities

Verify the following keys are properly set:
- `CFBundleDisplayName`: Your app's display name
- `CFBundleVersion`: Build number (increment for each TestFlight build)
- `CFBundleShortVersionString`: Marketing version (1.0.0)

## Step 7: Configure Assets

### App Icons:
1. **Assets.xcassets** → **AppIcon**
2. Drag app icon files to appropriate slots
3. Required sizes: 20pt, 29pt, 40pt, 60pt (all @2x and @3x)
4. App Store icon: 1024x1024 (without transparency)

### Launch Screen:
1. **Assets.xcassets** → **LaunchScreen** (if using asset-based launch screen)
2. Or configure LaunchScreen.storyboard

## Step 8: Build and Test

### Debug Build Test:
1. Select iPhone Simulator (iOS 16.0+)
2. **Product** → **Build** (⌘+B)
3. **Product** → **Run** (⌘+R)
4. Test core functionality

### Release Build Test:
1. Select "Any iOS Device" or physical device
2. Switch to Release scheme
3. **Product** → **Build for** → **Running**
4. Test performance and functionality

## Step 9: Archive for TestFlight

### Prepare for Archive:
1. Clean build folder: **Product** → **Clean Build Folder** (⌘+Shift+K)
2. Select "Any iOS Device" (not simulator)
3. Switch to Release scheme

### Create Archive:
1. **Product** → **Archive**
2. Wait for archive process to complete
3. Organizer window will open with your archive

### Upload to App Store Connect:
1. In Organizer, select your archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Follow the upload process

## Troubleshooting Common Issues

### Build Failures:
- **"Cannot find type"**: Check imports and Package.swift dependencies
- **Code signing errors**: Verify Apple Developer account and certificates
- **Swift Package resolution**: Clean Package cache and re-resolve

### Package Manager Issues:
- **File** → **Packages** → **Reset Package Caches**
- **File** → **Packages** → **Update to Latest Package Versions**

### Simulator Issues:
- Use iOS 16.0+ simulator
- Reset simulator if app crashes: **Device** → **Erase All Content and Settings**

### TestFlight Issues:
- Ensure version numbers are properly incremented
- Check for App Store Review Guidelines compliance
- Verify all privacy descriptions are included

## Next Steps

After successful archive and upload:
1. Configure TestFlight beta testing
2. Add external testers
3. Submit for App Store review
4. Monitor crash reports and feedback

For detailed TestFlight setup, refer to `TESTFLIGHT_DEPLOYMENT_GUIDE.md`.