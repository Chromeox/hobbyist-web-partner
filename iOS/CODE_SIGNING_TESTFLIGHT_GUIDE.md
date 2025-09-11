# Code Signing Setup for TestFlight Deployment

## Overview
This guide walks you through setting up proper code signing certificates and provisioning profiles for HobbyistSwiftUI iOS app TestFlight deployment.

## Prerequisites
- Active Apple Developer Program membership ($99/year)
- Xcode installed (full version, not just Command Line Tools)
- Valid Apple ID with Developer Program access

## Step-by-Step Code Signing Setup

### Step 1: Apple Developer Portal Configuration

#### 1.1 Create App Identifier
1. Visit [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **App IDs**
4. Click the **+** button to create new App ID

**App ID Configuration:**
```
Description: HobbyistSwiftUI iOS App
Bundle ID: com.hobbyist.app (Explicit)
Platform: iOS, tvOS, watchOS
```

**Required Capabilities:**
- ✅ App Groups
- ✅ Push Notifications  
- ✅ In-App Purchase
- ✅ Apple Pay Payment Processing
- ✅ Associated Domains
- ✅ Sign In with Apple (if using)

#### 1.2 Create Development Certificate
1. Navigate to **Certificates** → **Development**
2. Click **+** to create new certificate
3. Select **iOS App Development**
4. Follow CSR generation instructions:

```bash
# Generate Certificate Signing Request (CSR)
1. Open Keychain Access
2. Keychain Access → Certificate Assistant → Request Certificate from CA
3. Enter your Apple Developer email
4. Leave CA Email blank
5. Select "Saved to disk"
6. Save as "HobbyistDevelopment.certSigningRequest"
```

5. Upload the CSR file
6. Download and install the certificate

#### 1.3 Create Distribution Certificate
1. Navigate to **Certificates** → **Production**
2. Click **+** to create new certificate
3. Select **App Store and Ad Hoc**
4. Generate new CSR (similar process as development)
5. Upload CSR and download certificate

### Step 2: Provisioning Profile Creation

#### 2.1 Development Provisioning Profile
1. Navigate to **Profiles** → **Development**
2. Click **+** to create new profile
3. Select **iOS App Development**

**Configuration:**
```
App ID: com.hobbyist.app (select your App ID)
Certificates: Select your development certificate
Devices: Select test devices (iPhone, iPad for testing)
Profile Name: HobbyistSwiftUI Development
```

#### 2.2 Distribution Provisioning Profile  
1. Navigate to **Profiles** → **Distribution**
2. Click **+** to create new profile
3. Select **App Store**

**Configuration:**
```
App ID: com.hobbyist.app
Certificates: Select your distribution certificate
Profile Name: HobbyistSwiftUI App Store Distribution
```

### Step 3: Xcode Code Signing Configuration

#### 3.1 Automatic Signing (Recommended)
1. Open `HobbyistSwiftUI.xcodeproj` in Xcode
2. Select project → Target → **Signing & Capabilities**
3. **Automatically manage signing**: ✅ Checked
4. **Team**: Select your Apple Developer Team
5. **Bundle Identifier**: `com.hobbyist.app`

#### 3.2 Verify Signing Configuration
Check that Xcode shows:
```
✅ Signing Certificate: Apple Development (for Debug)
✅ Signing Certificate: Apple Distribution (for Release)  
✅ Provisioning Profile: Managed by Xcode
✅ Bundle Identifier: com.hobbyist.app
```

#### 3.3 Manual Signing (Advanced Users)
If automatic signing fails:
1. **Automatically manage signing**: ❌ Unchecked
2. **Provisioning Profile**: 
   - Debug: Select development profile
   - Release: Select distribution profile
3. **Signing Certificate**: 
   - Debug: Apple Development
   - Release: Apple Distribution

### Step 4: Keychain Certificate Management

#### 4.1 Verify Certificates in Keychain
1. Open **Keychain Access**
2. Navigate to **My Certificates**
3. Verify you have:
   ```
   ✅ Apple Development: [Your Name] ([Team ID])
   ✅ Apple Distribution: [Your Name] ([Team ID])
   ```

#### 4.2 Certificate Trust Settings
1. Double-click each certificate
2. Expand **Trust** section
3. Set to **Use System Defaults** or **Always Trust**

### Step 5: TestFlight Specific Configuration

#### 5.1 App Store Connect Setup
1. Visit [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **+** → **New App**

**App Information:**
```
Platform: iOS
Name: Hobbyist
Primary Language: English (U.S.)
Bundle ID: com.hobbyist.app (must match exactly)
SKU: hobbyist-ios-app-001
User Access: Full Access
```

#### 5.2 App Information Configuration
**Categories:**
- Primary: Health & Fitness
- Secondary: Lifestyle

**Content Rights:**
```
Age Rating: 4+ (No objectionable content)
Content Rights: Does not use third-party content
```

**App Privacy:**
- Privacy Policy URL: `https://hobbyist.app/privacy`
- Support URL: `https://hobbyist.app/support`

### Step 6: Build Archive Creation

#### 6.1 Pre-Archive Preparation
1. Clean Build Folder: `⌘+Shift+K`
2. Reset Package Caches: File → Packages → Reset Package Caches
3. Select **Any iOS Device** (not simulator)
4. Verify **Release** scheme is selected

#### 6.2 Create Archive
1. **Product** → **Archive** (`⌘+Shift+⇧+A`)
2. Wait for archive completion (5-15 minutes)
3. **Organizer** opens with your archive

#### 6.3 Archive Validation
1. Select your archive in **Organizer**
2. Click **Validate App**
3. **Distribution Method**: App Store Connect
4. **Signing Options**: Automatically manage signing
5. **App Store Connect Options**:
   - Include bitcode: **NO** (required for Stripe)
   - Upload symbols: **YES** (for crash reporting)
   - Manage version and build number: **NO**

#### 6.4 Upload to App Store Connect
1. Click **Distribute App** 
2. Same settings as validation
3. Upload process: 10-30 minutes
4. Monitor progress in **Organizer**

### Step 7: TestFlight Configuration

#### 7.1 Build Processing
After upload, monitor in App Store Connect:
1. **App Store Connect** → **My Apps** → **Hobbyist**
2. **TestFlight** tab → **iOS Builds**
3. Status: Processing → Ready to Submit

#### 7.2 Test Information
**What to Test:**
```markdown
# Hobbyist iOS App - TestFlight Beta v1.0.0

## Key Features to Test
- User registration and authentication  
- Browse classes by category and location
- View detailed class information
- Complete booking flow with test payments
- Push notifications for reminders
- Profile management and photo upload
- Following instructors and studios

## Test Payment Information
Use Stripe test card: 4242 4242 4242 4242
Expiry: Any future date
CVC: Any 3 digits
ZIP: Any valid postal code

## Known Limitations
- Limited Vancouver-area class data
- Payment processing in test mode only
- Some placeholder content in development

## Feedback Focus Areas
- App crashes or errors
- UI/UX issues and suggestions  
- Performance problems
- Feature requests and improvements

Please provide detailed feedback through TestFlight's built-in feedback tools.
```

#### 7.3 Internal Testing Setup
1. **Internal Testing** → **Add Build**
2. Select your processed build
3. **Automatic Distribution**: Enable
4. Add team members as internal testers

### Step 8: Common Code Signing Issues

#### Issue: "No signing certificate found"
**Cause**: Missing or expired certificates
**Solution**: 
1. Check certificate expiration in Keychain Access
2. Renew certificates in Apple Developer Portal
3. Re-download and install in Keychain

#### Issue: "Profile doesn't include signing certificate"
**Cause**: Certificate not included in provisioning profile
**Solution**:
1. Edit provisioning profile in Developer Portal
2. Include the correct certificate
3. Re-download and install profile

#### Issue: "Bundle identifier mismatch"
**Cause**: Bundle ID doesn't match App ID
**Solution**:
1. Verify Bundle ID exactly matches: `com.hobbyist.app`
2. Check for typos or extra characters
3. Ensure App ID exists in Developer Portal

#### Issue: "Capabilities not enabled"
**Cause**: Required capabilities missing from App ID
**Solution**:
1. Edit App ID in Developer Portal
2. Enable required capabilities
3. Regenerate provisioning profiles

#### Issue: "Archive validation failed"
**Cause**: Various validation issues
**Solution**:
1. Check Info.plist configuration
2. Verify all required privacy descriptions
3. Ensure app icons are properly configured
4. Test app functionality before archiving

### Step 9: Certificate Lifecycle Management

#### Certificate Expiration Monitoring
- **Development Certificates**: Expire after 1 year
- **Distribution Certificates**: Expire after 1 year
- **Provisioning Profiles**: Expire after 1 year

#### Renewal Process
1. **30 days before expiration**: Renew certificates
2. **Update provisioning profiles** with new certificates
3. **Test builds** with updated certificates
4. **Update team members** with new certificates

#### Best Practices
- Export certificates for backup
- Share certificates securely with team
- Document certificate management process
- Set calendar reminders for renewals

### Step 10: Success Validation

#### Code Signing Success Indicators
- [ ] Certificates installed in Keychain
- [ ] App ID created with all required capabilities
- [ ] Provisioning profiles generated and valid
- [ ] Xcode shows valid signing configuration
- [ ] Archive builds without signing errors
- [ ] Validation passes in Organizer
- [ ] Upload to App Store Connect succeeds
- [ ] Build processes successfully in TestFlight

#### Ready for TestFlight Distribution
- [ ] Build appears in App Store Connect
- [ ] Status shows "Ready to Submit" 
- [ ] Test information configured
- [ ] Internal testers added
- [ ] TestFlight invitations sent successfully

This comprehensive code signing setup ensures your HobbyistSwiftUI app is properly configured for TestFlight beta testing and eventual App Store distribution.