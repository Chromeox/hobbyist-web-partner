# Xcode Project Configuration for TestFlight Deployment

## Critical Project Settings

### Bundle Identifier Configuration
**Required Bundle ID**: `com.hobbyist.app`

### Deployment Target Settings
- **iOS Deployment Target**: 16.0 (minimum supported version)
- **Supported Device Families**: iPhone, iPad
- **Supported Orientations**: 
  - iPhone: Portrait, Landscape Left, Landscape Right
  - iPad: All orientations

### Build Settings (Release Configuration)

#### Code Signing Settings
```
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = [Your Team ID from Apple Developer Portal]
PRODUCT_BUNDLE_IDENTIFIER = com.hobbyist.app
CODE_SIGN_IDENTITY = Apple Distribution
PROVISIONING_PROFILE_SPECIFIER = (Automatic)
```

#### Compilation Settings
```
SWIFT_COMPILATION_MODE = wholemodule
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
ENABLE_BITCODE = NO (Required for Stripe SDK)
STRIP_INSTALLED_PRODUCT = YES
COPY_PHASE_STRIP = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

#### Architecture Settings
```
ARCHS = arm64
VALID_ARCHS = arm64
ONLY_ACTIVE_ARCH = NO
```

#### Framework and Library Settings
```
ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks
FRAMEWORK_SEARCH_PATHS = $(inherited)
```

### Info.plist Configuration Updates

#### App Information
```xml
<key>CFBundleDisplayName</key>
<string>Hobbyist</string>
<key>CFBundleName</key>
<string>Hobbyist</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

#### Required Device Capabilities
```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
    <string>telephony</string>
    <string>location-services</string>
</array>
```

#### Background Modes
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

### App Transport Security Configuration
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>supabase.co</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>stripe.com</key>
        <dict>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Swift Package Manager Configuration

#### Package Dependencies (Already configured in Package.swift)
- ✅ Supabase 2.31.2 (Latest stable)
- ✅ Stripe 24.15.0 (Latest stable)
- ✅ Kingfisher 8.5.0 (Image loading)
- ✅ Sentry 8.36.0 (Crash reporting)

#### Required Linker Flags
```
OTHER_LDFLAGS = -ObjC
```

### App Capabilities Setup

#### Required Capabilities (Enable in Apple Developer Portal)
1. **App Groups** (for Apple Watch communication)
2. **Push Notifications** (for class reminders)
3. **In-App Purchase** (for credit purchases)
4. **Apple Pay** (for payment processing)
5. **Associated Domains** (for deep linking)

#### Entitlements File Configuration
```xml
<key>aps-environment</key>
<string>production</string>
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
<key>com.apple.developer.in-app-payments</key>
<array>
    <string>merchant.com.hobbyist.app</string>
</array>
```

## Xcode Configuration Steps

### Step 1: Open Project in Xcode
```bash
# Ensure Xcode is installed (not just Command Line Tools)
# Download from Mac App Store or Apple Developer Portal
open /Users/chromefang.exe/HobbyistSwiftUI/iOS/HobbyistSwiftUI.xcodeproj
```

### Step 2: Project Settings Configuration
1. **Select Project**: Click on "HobbyistSwiftUI" in the navigator
2. **Target Settings**: Select "HobbyistSwiftUI" target
3. **General Tab**:
   - Display Name: `Hobbyist`
   - Bundle Identifier: `com.hobbyist.app`
   - Version: `1.0.0`
   - Build: `1`
   - Deployment Target: `iOS 16.0`

### Step 3: Signing & Capabilities
1. **Automatically manage signing**: ✅ Enabled
2. **Team**: Select your Apple Developer Team
3. **Capabilities**: Add required capabilities listed above

### Step 4: Build Settings
1. **Switch to Release Configuration**
2. **Apply all settings** from the configuration above
3. **Verify Swift Package dependencies** are resolved

### Step 5: Scheme Configuration
1. **Edit Scheme** (Product → Scheme → Edit Scheme)
2. **Run Configuration**: Debug
3. **Archive Configuration**: Release
4. **Build Configuration**: Release

## Verification Checklist

### Pre-Build Verification
- [ ] Bundle identifier matches `com.hobbyist.app`
- [ ] iOS deployment target is 16.0
- [ ] Automatic signing is enabled
- [ ] Team is selected
- [ ] All capabilities are configured
- [ ] Swift packages resolved successfully
- [ ] No build warnings or errors

### Build Verification
- [ ] Project builds successfully on device
- [ ] Archive builds without errors
- [ ] App launches properly on physical device
- [ ] All main features functional
- [ ] No crashes during basic testing

### Code Signing Verification
- [ ] Development certificate installed
- [ ] Distribution certificate available
- [ ] Provisioning profiles generated
- [ ] App ID matches bundle identifier
- [ ] All capabilities enabled in provisioning profile

## Common Configuration Issues

### Bundle Identifier Mismatch
```
Error: "No profiles for 'com.hobbyist.app' were found"
Solution: Ensure App ID exists in Apple Developer Portal
```

### Missing Capabilities
```
Error: "Entitlement not supported"
Solution: Enable required capabilities in App ID configuration
```

### Swift Package Resolution Failures
```
Error: "Package resolution failed"
Solution: 
1. File → Packages → Reset Package Caches
2. Clean Build Folder (⌘+Shift+K)
3. Restart Xcode
```

### Code Signing Issues
```
Error: "Code signing is required for product type 'Application'"
Solution: 
1. Verify Apple Developer Program membership
2. Install certificates from Developer Portal
3. Enable automatic signing in Xcode
```

This configuration ensures your HobbyistSwiftUI app meets all App Store requirements and is ready for TestFlight deployment.