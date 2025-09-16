# 🚀 HobbyistSwiftUI TestFlight Setup Guide

## ✅ STATUS CHECK

**Apple Developer Account**: ✅ ENROLLED
- Team ID: 594BDWKT53 (Quantum Hobbyist Group Inc.)
- Development Certificate: ✅ Valid
- Distribution Certificate: ✅ Valid
- Bundle ID: ✅ Fixed to `com.hobbyist.app`

## 📋 IMMEDIATE ACTIONS REQUIRED

### 1. Create App ID (5 minutes)
**🌐 Open:** https://developer.apple.com/account/resources/identifiers/bundleId/add/

**Steps:**
1. Select "App IDs" → "App"
2. **Bundle ID**: `com.hobbyist.app`
3. **Description**: "HobbyistSwiftUI - Class Booking Platform"
4. **Capabilities** (Check these):
   - ✅ Associated Domains
   - ✅ Push Notifications
   - ✅ Apple Pay Processing
   - ✅ In-App Purchase
   - ✅ Sign In with Apple
5. Click "Continue" → "Register"

### 2. Create App Store Connect Record (10 minutes)
**🌐 Open:** https://appstoreconnect.apple.com/apps

**Steps:**
1. Click "+" → "New App"
2. **Platforms**: iOS
3. **Name**: "HobbyistSwiftUI"
4. **Primary Language**: English (U.S.)
5. **Bundle ID**: Select `com.hobbyist.app`
6. **SKU**: `hobbyist-app-001`
7. **User Access**: Full Access
8. Click "Create"

### 3. Generate Provisioning Profiles (5 minutes)
**🌐 Open:** https://developer.apple.com/account/resources/profiles/add

**For Development:**
1. Type: "iOS App Development"
2. App ID: `com.hobbyist.app`
3. Certificates: Select your development certificate
4. Devices: Select your test devices
5. Name: "HobbyistSwiftUI Development"

**For Distribution:**
1. Type: "App Store"
2. App ID: `com.hobbyist.app`
3. Certificate: Select distribution certificate
4. Name: "HobbyistSwiftUI App Store"

## 🛠️ XCODE CONFIGURATION

### Configure Code Signing
```bash
# Open Xcode project
open HobbyistSwiftUI.xcodeproj

# In Xcode:
# 1. Select project → Target "HobbyistSwiftUI"
# 2. Signing & Capabilities tab
# 3. Automatically manage signing: ✅ ON
# 4. Team: Quantum Hobbyist Group Inc. (594BDWKT53)
# 5. Bundle Identifier: com.hobbyist.app
```

### Required Capabilities
Add these in Signing & Capabilities:
- ✅ Push Notifications
- ✅ Apple Pay Processing
- ✅ In-App Purchase
- ✅ Associated Domains

## 📦 CREATE ARCHIVE BUILD

### Method 1: Xcode GUI
```bash
# 1. Open project in Xcode
open HobbyistSwiftUI.xcodeproj

# 2. In Xcode:
# - Select "Any iOS Device (arm64)" as destination
# - Product → Archive
# - Wait for build to complete
# - Click "Distribute App"
# - Choose "App Store Connect"
# - Upload
```

### Method 2: Command Line (if GUI fails)
```bash
# Clean and build for release
xcodebuild clean -project HobbyistSwiftUI.xcodeproj -scheme HobbyistSwiftUI -configuration Release

# Create archive
xcodebuild archive \
  -project HobbyistSwiftUI.xcodeproj \
  -scheme HobbyistSwiftUI \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "./build/HobbyistSwiftUI.xcarchive" \
  -allowProvisioningUpdates

# Export for App Store
xcodebuild -exportArchive \
  -archivePath "./build/HobbyistSwiftUI.xcarchive" \
  -exportPath "./build/" \
  -exportOptionsPlist "./ExportOptions.plist" \
  -allowProvisioningUpdates
```

## 🧪 TESTFLIGHT SETUP

### Beta Testing Configuration
**🌐 Open:** https://appstoreconnect.apple.com/apps

1. **Select your app** → "TestFlight" tab
2. **Internal Testing:**
   - Add yourself and team members
   - Maximum 100 internal testers
3. **External Testing:**
   - Create test group: "Alpha Users"
   - Add up to 10,000 external testers
   - Requires beta app review (24-48 hours)

### Privacy Policy Requirements
**🚨 REQUIRED for TestFlight:**
- Create privacy policy (even simple one)
- Upload to your website or use hosted solution
- Add URL in App Store Connect → App Information

## 🎯 IMMEDIATE NEXT STEPS

1. **🌐 Browser Tasks** (Complete in opened tabs):
   - Create App ID with bundle `com.hobbyist.app`
   - Set up App Store Connect app record
   - Generate provisioning profiles

2. **💻 Xcode Tasks**:
   ```bash
   # Open Xcode and configure signing
   open HobbyistSwiftUI.xcodeproj
   ```

3. **📱 First Archive**:
   - Set destination to "Any iOS Device"
   - Product → Archive
   - Distribute to App Store Connect

## 🆘 TROUBLESHOOTING

### Common Issues:
- **Code Signing Error**: Check provisioning profiles match bundle ID
- **Archive Fails**: Clean build folder (Cmd+Shift+K)
- **Upload Fails**: Verify team membership and certificates

### Quick Fixes:
```bash
# Clean all builds
rm -rf ~/Library/Developer/Xcode/DerivedData/HobbyistSwiftUI-*

# Reset provisioning profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

---

## 📊 SUCCESS METRICS

✅ **App ID created**: com.hobbyist.app
✅ **App Store Connect record**: Created
✅ **Provisioning profiles**: Generated
✅ **First archive**: Successful
✅ **TestFlight upload**: Complete
✅ **Alpha testers added**: Ready for testing

**🎉 GOAL**: Real users testing your app within 2 hours!

---

*Created: 2025-09-15 | Project: HobbyistSwiftUI Alpha Launch*