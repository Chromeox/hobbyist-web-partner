# Build Settings Configuration for TestFlight Deployment

## Xcode Build Settings Configuration

### Essential Build Settings for Release Configuration

#### Code Signing Settings
```
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Distribution
PRODUCT_BUNDLE_IDENTIFIER = com.hobbyist.app
DEVELOPMENT_TEAM = [Your Apple Developer Team ID]
PROVISIONING_PROFILE_SPECIFIER = 
```

#### Optimization Settings
```
SWIFT_COMPILATION_MODE = wholemodule
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
ENABLE_BITCODE = NO
STRIP_INSTALLED_PRODUCT = YES
COPY_PHASE_STRIP = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

#### Architecture and Deployment
```
ARCHS = arm64
VALID_ARCHS = arm64
ONLY_ACTIVE_ARCH = NO
IPHONEOS_DEPLOYMENT_TARGET = 16.0
TARGETED_DEVICE_FAMILY = 1,2
```

#### Framework and Linking
```
ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks
FRAMEWORK_SEARCH_PATHS = $(inherited)
OTHER_LDFLAGS = -ObjC
```

#### App Store Specific Settings
```
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = HobbyistSwiftUI/Info.plist
```

### Xcode Configuration Steps

#### Step 1: Project Settings
1. Open `HobbyistSwiftUI.xcodeproj` in Xcode
2. Select project in navigator
3. Select "HobbyistSwiftUI" target
4. Navigate to "Build Settings" tab
5. Filter by "Release" configuration

#### Step 2: Critical Settings to Verify

**Bundle Identifier**
- Search for: `PRODUCT_BUNDLE_IDENTIFIER`
- Set to: `com.hobbyist.app`

**iOS Deployment Target**
- Search for: `IPHONEOS_DEPLOYMENT_TARGET`
- Set to: `16.0`

**Code Signing Identity**
- Search for: `CODE_SIGN_IDENTITY`
- Release: `Apple Distribution`
- Debug: `Apple Development`

**Swift Compilation Mode**
- Search for: `SWIFT_COMPILATION_MODE`
- Release: `wholemodule`
- Debug: `incremental`

**Enable Bitcode**
- Search for: `ENABLE_BITCODE`
- Set to: `NO` (Required for Stripe SDK)

#### Step 3: Scheme Configuration
1. Product → Scheme → Edit Scheme
2. **Build Configuration**:
   - Run: Debug
   - Test: Debug
   - Profile: Release
   - Analyze: Debug
   - Archive: Release

#### Step 4: Capabilities Configuration
Navigate to "Signing & Capabilities" tab and add:

1. **App Groups** 
   - Enable for Apple Watch communication
   - Group: `group.com.hobbyist.app`

2. **Push Notifications**
   - Enable for class reminders
   - Development & Production environments

3. **In-App Purchase**
   - Enable for credit pack purchases

4. **Apple Pay Payment Processing**
   - Enable for Stripe payment processing
   - Merchant ID: `merchant.com.hobbyist.app`

5. **Associated Domains**
   - Add: `applinks:hobbyist.app`
   - Add: `applinks:www.hobbyist.app`

#### Step 5: Swift Package Dependencies
Verify all packages are properly configured:

1. File → Packages → Reset Package Caches
2. Resolve any version conflicts
3. Ensure all products are imported:
   ```
   - Supabase
   - Auth (from supabase-swift)
   - Realtime (from supabase-swift)
   - Storage (from supabase-swift)
   - StripePaymentSheet
   - StripePayments
   - Kingfisher
   - Sentry
   ```

### Build Configuration Verification

#### Pre-Archive Checklist
- [ ] Release configuration selected
- [ ] "Any iOS Device" selected (not simulator)
- [ ] Bundle identifier matches App Store Connect
- [ ] Code signing configured for distribution
- [ ] All capabilities properly enabled
- [ ] Swift packages resolved without conflicts
- [ ] Info.plist properly configured
- [ ] App icons all present and valid

#### Build Validation Commands
```bash
# Clean build folder
⌘+Shift+K

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/HobbyistSwiftUI-*

# Reset package caches
# File → Packages → Reset Package Caches (in Xcode)

# Build for testing
⌘+B

# Build for profiling
⌘+I

# Archive for distribution
⌘+Shift+⇧+A
```

### Common Build Issues and Solutions

#### Issue: "No signing certificate found"
**Solution:**
1. Verify Apple Developer Program membership
2. Download certificates from Apple Developer Portal
3. Install in Keychain Access
4. Refresh provisioning profiles in Xcode

#### Issue: "Swift package product not found"
**Solution:**
1. File → Packages → Reset Package Caches
2. Clean Build Folder (⌘+Shift+K)
3. Restart Xcode
4. Rebuild project

#### Issue: "Bitcode bundle missing"
**Solution:**
1. Ensure `ENABLE_BITCODE = NO` in build settings
2. This is required for Stripe SDK compatibility
3. Modern apps don't require bitcode

#### Issue: "Invalid bundle identifier"
**Solution:**
1. Verify bundle ID matches exactly: `com.hobbyist.app`
2. Check for typos or extra characters
3. Ensure App ID exists in Apple Developer Portal

### Archive Settings Verification

#### Before Creating Archive
1. **Product** → **Destination** → **Any iOS Device**
2. **Product** → **Scheme** → **HobbyistSwiftUI**
3. **Product** → **Clean Build Folder**
4. **Product** → **Archive**

#### Archive Upload Settings
When uploading to App Store Connect:
- **Distribution Method**: App Store Connect
- **Signing**: Automatic (recommended)
- **Include bitcode**: NO
- **Upload symbols**: YES
- **Manage version and build number**: NO

### Performance Optimization Settings

#### Memory and CPU Optimization
```
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
DEAD_CODE_STRIPPING = YES
STRIP_INSTALLED_PRODUCT = YES
```

#### Size Optimization
```
DEPLOYMENT_POSTPROCESSING = YES
STRIP_SWIFT_SYMBOLS = YES
COPY_PHASE_STRIP = YES
```

#### Debugging Information
```
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
GENERATE_INFOPLIST_FILE = NO
```

### Final Validation Checklist

#### Build Quality Assurance
- [ ] No compiler warnings
- [ ] No analyzer warnings
- [ ] All tests pass
- [ ] App launches on physical device
- [ ] Main user flows functional
- [ ] Memory usage reasonable
- [ ] CPU usage optimized

#### Distribution Readiness
- [ ] Archive builds successfully
- [ ] Validation passes in Organizer
- [ ] Upload to App Store Connect succeeds
- [ ] Build processes in App Store Connect
- [ ] TestFlight testing ready

This configuration ensures your HobbyistSwiftUI app meets all App Store technical requirements and optimization standards for successful TestFlight deployment.