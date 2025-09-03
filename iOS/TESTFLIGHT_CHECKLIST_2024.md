# TestFlight Launch Checklist - HobbyistSwiftUI
*Updated: December 28, 2024*

## ✅ What You Already Have

### Code & Project Structure
- [x] **Complete iOS app codebase** with MVVM architecture
- [x] **Xcode project file** (`HobbyistSwiftUI.xcodeproj`) configured
- [x] **Bundle identifier set**: `com.hobbyist.app`
- [x] **Package.swift** with dependencies:
  - Supabase 2.5.1 (authentication & database)
  - Stripe 23.27.0 (payment processing)
  - Kingfisher 7.10.0 (image loading)
- [x] **Info.plist** configured with basic app settings
- [x] **App entry point** (`HobbyistSwiftUIApp.swift`) with @main
- [x] **Complete folder structure**:
  - Models, Views, ViewModels, Services
  - Assets.xcassets (structure exists, icons missing)
  - Security configurations

### Documentation & Scripts
- [x] Setup script ready: `setup-testflight.sh`
- [x] Fastlane configuration for deployment automation
- [x] Studio partner documentation in `Documentation/` folder

---

## ❌ What's Actually Missing

### 1. Development Environment
- [ ] **Xcode installation** (Command Line Tools exist, but full Xcode needed)
  - Currently only have: `/Library/Developer/CommandLineTools`
  - Need full Xcode for building iOS apps

### 2. Apple Developer Requirements
- [ ] **Apple Developer Program enrollment** ($99/year)
- [ ] **Development Team ID** (obtained after enrollment)
- [ ] **Code signing certificates**
- [ ] **Provisioning profiles**
- [ ] **App Store Connect app record**

### 3. App Assets
- [ ] **App icons** (AppIcon.appiconset folder is empty)
  - Need 1024x1024 for App Store
  - Need various sizes for iPhone (120x120, 180x180, etc.)
- [ ] **Launch screen** (currently using default)
- [ ] **App screenshots** for App Store listing

### 4. App Metadata
- [ ] **Version number** (need to set in project settings)
- [ ] **Build number** (need to set in project settings)
- [ ] **App description** for TestFlight
- [ ] **Privacy policy URL** (required for apps using Supabase/Stripe)
- [ ] **Terms of use URL**

---

## 🚀 Step-by-Step Action Plan

### Day 1: Foundation Setup
**Time: 2-3 hours**

1. **Install Xcode** (1-2 hours with download)
   ```bash
   # From Mac App Store
   # Search "Xcode" and click Install (15-20GB)
   ```

2. **Enroll in Apple Developer Program** (30 minutes)
   - Go to: https://developer.apple.com/programs/
   - Sign in with Apple ID
   - Pay $99 annual fee
   - Wait for activation (usually instant)

### Day 2: Project Configuration
**Time: 1-2 hours**

3. **Open project in Xcode**
   ```bash
   cd ~/HobbyistSwiftUI/iOS
   open HobbyistSwiftUI.xcodeproj
   ```

4. **Configure signing**
   - Select project in navigator
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your developer team
   - Xcode will create certificates automatically

5. **Set version numbers**
   - In project settings, set:
   - Marketing Version: 1.0.0
   - Current Project Version: 1

### Day 3: Assets & Metadata
**Time: 2-3 hours**

6. **Create app icons**
   - Use https://www.appicon.co/
   - Upload a 1024x1024 source image
   - Download the icon set
   - Drag into `Assets.xcassets/AppIcon.appiconset`

7. **Create privacy policy**
   - Can use generator: https://app-privacy-policy-generator.firebaseapp.com/
   - Host on GitHub Pages or simple website
   - Required because app uses:
     - Supabase (user data)
     - Stripe (payment data)

### Day 4: Build & Test
**Time: 1-2 hours**

8. **Build the app**
   ```bash
   # In Xcode:
   # 1. Select "Any iOS Device" as destination
   # 2. Product → Build (Cmd+B)
   # 3. Fix any build errors
   ```

9. **Test on simulator**
   - Select iPhone 15 Pro simulator
   - Run app (Cmd+R)
   - Test core flows:
     - Sign up/Login
     - Browse classes
     - Book a class
     - Payment flow

### Day 5: TestFlight Upload
**Time: 1-2 hours**

10. **Create App Store Connect record**
    - Go to: https://appstoreconnect.apple.com
    - My Apps → "+" → New App
    - Fill in:
      - Name: HobbyistSwiftUI
      - Bundle ID: com.hobbyist.app
      - SKU: HOBBYIST001

11. **Archive and upload**
    ```bash
    # In Xcode:
    # 1. Product → Archive
    # 2. Distribute App → App Store Connect
    # 3. Upload
    # 4. Wait for processing (5-10 minutes)
    ```

12. **Configure TestFlight**
    - In App Store Connect → TestFlight
    - Add test information
    - Add internal testers (your team)
    - Submit for external testing review

### Day 6: External Testing
**Time: 24-48 hours for review**

13. **Add external testers**
    - Create public link or add specific emails
    - Share with alpha studios
    - Monitor feedback in TestFlight

---

## 🔧 Quick Commands

### Check if ready to build:
```bash
# Check Xcode installation
xcodebuild -version

# Check code signing
security find-identity -p codesigning

# Build from command line (after Xcode setup)
cd ~/HobbyistSwiftUI/iOS
xcodebuild -scheme HobbyistSwiftUI -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Use the automated setup script:
```bash
cd ~/HobbyistSwiftUI/iOS
./setup-testflight.sh
```

---

## 📱 Testing Checklist

Before submitting to TestFlight, test these flows:

- [ ] User can sign up with email
- [ ] User can log in
- [ ] User can browse classes
- [ ] User can view class details
- [ ] User can book a class
- [ ] User can purchase credits
- [ ] Payment flow completes successfully
- [ ] User can view their bookings
- [ ] User can cancel a booking
- [ ] App handles network errors gracefully
- [ ] App works on different iPhone sizes

---

## 🎯 Success Metrics

Your app is ready for TestFlight when:
1. ✅ Builds without errors in Xcode
2. ✅ Runs on iPhone simulator
3. ✅ Has app icons
4. ✅ Has privacy policy URL
5. ✅ Uploaded to App Store Connect
6. ✅ TestFlight build is processing/ready

---

## 🆘 Common Issues & Solutions

### "No team selected"
→ Sign into Xcode with Apple ID that has developer account

### "Bundle identifier already exists"
→ Change to unique identifier like `com.yourname.hobbyist`

### Build fails with package errors
→ File → Packages → Reset Package Caches

### "Missing compliance" in TestFlight
→ Answer export compliance questions (usually "No" for standard apps)

### Archive option grayed out
→ Select "Any iOS Device (arm64)" as destination, not simulator

---

## 📞 Next Steps After TestFlight

1. **Gather feedback** from alpha testers
2. **Fix critical bugs** found during testing
3. **Iterate on UI/UX** based on feedback
4. **Add remaining features** (if any)
5. **Prepare for App Store submission**
   - Professional screenshots
   - App Store description
   - Keywords optimization
   - Category selection

---

## 💡 Pro Tips

1. **Start with internal testing** (your team) before external
2. **Use TestFlight feedback** feature for bug reports
3. **Version each build** (1.0.0, 1.0.1, etc.)
4. **Test on real devices** if possible (not just simulator)
5. **Keep build notes** updated in TestFlight

---

**Remember**: The goal is to get real user feedback quickly. Don't wait for perfection - ship at 70% and iterate based on actual usage!