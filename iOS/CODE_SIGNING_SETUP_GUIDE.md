# Code Signing & Provisioning Profile Setup Guide

## Overview
This guide walks you through setting up code signing and provisioning profiles for the HobbyistSwiftUI iOS app. Proper code signing is essential for TestFlight distribution and App Store submission.

## Prerequisites
- Active Apple Developer Program membership ($99/year)
- macOS with Xcode 15.0+ installed
- Access to Apple Developer portal (developer.apple.com)
- Physical iOS device for testing (recommended)

## Step 1: Apple Developer Account Verification

### Verify Developer Program Status:
1. Visit [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Account** → **Membership**
4. Verify status shows "Active" with expiration date
5. Note your **Team ID** (10-character alphanumeric)

### Required Information:
```
Team Name: [Your Developer Team Name]
Team ID: [10-character identifier]
Apple ID: [Your developer account email]
Role: Account Holder, Admin, or Developer
```

## Step 2: Certificates Management

### Development Certificate:
1. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
2. Enter your email address and name
3. Select "Saved to disk" and "Let me specify key pair information"
4. Save the Certificate Signing Request (.certSigningRequest file)

5. **Apple Developer Portal** → **Certificates, Identifiers & Profiles** → **Certificates**
6. Click "+" to create new certificate
7. Select **iOS App Development**
8. Upload your .certSigningRequest file
9. Download and double-click to install in Keychain

### Distribution Certificate:
1. Follow same process as Development Certificate
2. Select **iOS Distribution** instead of iOS App Development
3. This certificate is used for TestFlight and App Store submission

### Certificate Management Best Practices:
- Export certificates with private keys (.p12 format) for backup
- Store certificates securely (encrypted backup)
- Set calendar reminders for renewal (certificates expire annually)
- Share certificates with team members if needed

## Step 3: App ID Configuration

### Create App ID:
1. **Apple Developer Portal** → **Identifiers** → **App IDs**
2. Click "+" to register new App ID
3. Configure the following:

```
App ID Configuration:
- Type: App
- Description: HobbyistSwiftUI iOS App
- Bundle ID: Explicit
- Bundle ID Value: com.yourcompany.hobbyistswiftui
- Platform: iOS, tvOS
```

### Enable Required Capabilities:
Select the following capabilities for your App ID:

✅ **Push Notifications**
- For class reminders and booking confirmations

✅ **In-App Purchase**
- For credit purchases and premium subscriptions

✅ **Apple Pay**
- For seamless payment processing

✅ **Background Modes**
- For background data sync and remote notifications

✅ **Associated Domains**
- For universal links and deep linking

✅ **Personal VPN**
- If using VPN for security (optional)

### Optional Capabilities (add if needed):
- Sign In with Apple
- Wallet
- Wireless Accessory Configuration
- NFC Tag Reading
- HotSpot Helper

## Step 4: Device Registration

### Register Development Devices:
1. **Apple Developer Portal** → **Devices**
2. Click "+" to register new device
3. Get device UDID:
   - **Xcode**: Window → Devices and Simulators → select device → copy UDID
   - **Finder**: Select device → click serial number to reveal UDID

```
Device Registration:
- Device Name: [Descriptive name, e.g., "John's iPhone 15 Pro"]
- Device Type: iPhone, iPad, Apple Watch, etc.
- UDID: [40-character device identifier]
```

### Device Limits:
- **iPhone/iPad**: 100 devices per year
- **Apple Watch**: 100 devices per year
- **Apple TV**: 100 devices per year
- **Mac**: 100 devices per year

## Step 5: Provisioning Profiles

### Development Provisioning Profile:
1. **Apple Developer Portal** → **Profiles** → **+**
2. Select **iOS App Development**
3. Choose your App ID: `com.yourcompany.hobbyistswiftui`
4. Select development certificates
5. Select registered devices for testing
6. Profile Name: `HobbyistSwiftUI Development`
7. Download and double-click to install

### Distribution Provisioning Profile:
1. **Apple Developer Portal** → **Profiles** → **+**
2. Select **App Store** (for App Store submission)
3. Choose your App ID: `com.yourcompany.hobbyistswiftui`
4. Select distribution certificate
5. Profile Name: `HobbyistSwiftUI Distribution`
6. Download and double-click to install

### Ad Hoc Provisioning Profile (Optional):
For distributing to specific devices outside TestFlight:
1. Select **Ad Hoc** distribution type
2. Include specific devices for testing
3. Useful for pre-TestFlight testing

## Step 6: Xcode Configuration

### Automatic Signing (Recommended for beginners):
1. **Xcode** → Select project → **Signing & Capabilities**
2. Check **Automatically manage signing**
3. Select your **Team** from dropdown
4. Verify **Bundle Identifier** matches App ID
5. Xcode will automatically create and manage profiles

### Manual Signing (Advanced users):
1. Uncheck **Automatically manage signing**
2. **Provisioning Profile (Debug)**: Select development profile
3. **Provisioning Profile (Release)**: Select distribution profile
4. **Signing Certificate**: Should auto-populate

### Verification Steps:
```
Debug Configuration:
✅ Code Signing Identity: iPhone Developer
✅ Provisioning Profile: HobbyistSwiftUI Development
✅ Development Team: [Your Team Name]

Release Configuration:
✅ Code Signing Identity: iPhone Distribution
✅ Provisioning Profile: HobbyistSwiftUI Distribution
✅ Development Team: [Your Team Name]
```

## Step 7: Testing Code Signing

### Device Testing:
1. Connect physical iOS device
2. Select device in Xcode
3. **Product** → **Build and Run** (⌘+R)
4. Accept any security prompts on device
5. App should install and launch successfully

### Archive Testing:
1. Select **Any iOS Device** or connected device
2. **Product** → **Archive**
3. Process should complete without errors
4. Organizer window opens with successful archive

## Step 8: Troubleshooting Common Issues

### Code Signing Error: "No signing certificate found"
**Solution:**
1. Verify development certificate is installed in Keychain
2. Check certificate hasn't expired
3. Ensure certificate matches selected provisioning profile

### Error: "Provisioning profile doesn't include device"
**Solution:**
1. Add device UDID to Apple Developer Portal
2. Regenerate provisioning profile with new device
3. Download and install updated profile

### Error: "Bundle identifier doesn't match"
**Solution:**
1. Verify Xcode bundle identifier matches App ID exactly
2. Check for typos in bundle identifier
3. Ensure App ID exists in Apple Developer Portal

### Error: "Team not found"
**Solution:**
1. Verify Apple Developer Program membership is active
2. Check that Apple ID has access to developer team
3. Sign out and back into Xcode with correct Apple ID

### Keychain Issues:
**Solution:**
1. **Keychain Access** → **Preferences** → **Reset My Default Keychain**
2. Re-download and install certificates
3. Restart Xcode

## Step 9: Certificate Backup and Security

### Backup Strategy:
1. Export certificates with private keys (.p12 format)
2. Use strong password for export
3. Store securely (encrypted cloud storage or physical media)
4. Document passwords in secure password manager

### Team Certificate Sharing:
1. Export development certificates as .p12
2. Share securely with team members
3. Each team member installs in their Keychain
4. Alternatively, use automatic signing and let Xcode manage

### Security Best Practices:
- Never share private keys publicly
- Use strong passwords for certificate exports
- Regularly audit team member access
- Revoke certificates for departed team members
- Monitor certificate usage in Apple Developer Portal

## Step 10: Renewal and Maintenance

### Certificate Renewal (Annual):
1. Set calendar reminders 30 days before expiration
2. Generate new Certificate Signing Request
3. Create new certificate in Apple Developer Portal
4. Update provisioning profiles with new certificate
5. Test signing with updated certificates

### Provisioning Profile Updates:
- Automatically renewed with certificate updates
- Manual updates required when adding devices
- Regular cleanup of unused profiles recommended

### Team Management:
- Review team member access quarterly
- Remove access for departed team members
- Update roles and permissions as needed
- Monitor certificate and profile usage

## Next Steps

After successful code signing setup:
1. Complete TestFlight configuration
2. Upload first build to App Store Connect
3. Set up beta testing groups
4. Begin internal testing process
5. Prepare for external beta testing

For TestFlight deployment instructions, refer to `TESTFLIGHT_DEPLOYMENT_GUIDE.md`.