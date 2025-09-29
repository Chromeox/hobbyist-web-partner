# Xcode Signing Configuration for HobbyistSwiftUI

## Current Issue
- Debug builds work with automatic signing
- Release builds fail: "Provisioning profile doesn't include in-app-purchase entitlement"
- Bundle ID mismatch between project and Apple Developer Console

## Solution: Manual Signing for Release

### 1. In Xcode Project Settings

**Target: HobbyistSwiftUI**

#### Debug Configuration:
- **Code Signing Style**: Automatic
- **Team**: Quantum Hobbyist Group Inc. (594BDWKT53)
- **Bundle Identifier**: com.hobbyist.app

#### Release Configuration:
- **Code Signing Style**: Manual
- **Provisioning Profile**: "HobbyistSwiftUI Distribution" (create this in Apple Developer Console)
- **Code Signing Identity**: "Apple Distribution: Quantum Hobbyist Group Inc."
- **Bundle Identifier**: com.hobbyist.app

### 2. Create Release Entitlements File

Create `HobbyistSwiftUIRelease.entitlements` with production settings:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- In-App Purchase (REQUIRED) -->
    <key>com.apple.developer.in-app-purchase</key>
    <array>
        <string>ProductionSandbox</string>
    </array>

    <!-- Sign In with Apple (REQUIRED) -->
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>

    <!-- Push Notifications (PRODUCTION) -->
    <key>aps-environment</key>
    <string>production</string>

    <!-- Associated Domains -->
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:hobbyist.app</string>
        <string>webcredentials:hobbyist.app</string>
    </array>

    <!-- HealthKit (if needed) -->
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

### 3. Build Settings Configuration

**Release Configuration Only:**
- **Code Signing Entitlements**: HobbyistSwiftUIRelease.entitlements
- **Provisioning Profile**: Use the Distribution profile you created
- **Code Signing Identity**: Apple Distribution

**Debug Configuration:**
- **Code Signing Entitlements**: HobbyistSwiftUI.entitlements
- **Code Signing Style**: Automatic
- **Code Signing Identity**: Apple Development

### 4. Verification Steps

1. **Clean Build Folder** (Cmd+Shift+K)
2. **Archive for Release** (Product → Archive)
3. **Check Organizer** for successful archive
4. **Validate App** before uploading to TestFlight

### 5. Common Issues & Solutions

**"Profile doesn't include entitlement"**
- Verify bundle ID matches exactly
- Recreate provisioning profile with all required capabilities

**"No matching provisioning profiles found"**
- Download and install the Distribution profile
- Set to Manual signing for Release only

**"Automatic signing failed"**
- Switch Release to Manual signing
- Keep Debug as Automatic for development

### 6. TestFlight Upload Process

1. **Archive** → **Distribute App**
2. **App Store Connect**
3. **Upload** (not Distribute)
4. **Select Distribution Profile** you created
5. **Upload to TestFlight**

## Bundle ID Verification Required

**CRITICAL**: Confirm your actual bundle ID in Apple Developer Console:
- Project shows: `com.hobbyist.app`
- Error mentions: `com.hobbyist.bookingapp`

Update Xcode project to match your registered bundle ID.