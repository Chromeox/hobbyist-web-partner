# 🚀 TestFlight Setup Guide - Hobbyist App

**Bundle ID**: `com.hobbyist.bookingapp`
**App Name**: Hobbyist App
**Generated**: $(date)

## ✅ Prerequisites Complete
- ✅ Bundle ID updated to `com.hobbyist.bookingapp`
- ✅ Xcode project configured correctly
- ✅ Build scripts created
- ✅ Export options configured

---

## 📋 Step-by-Step Checklist

### **Phase 1: Apple Developer Account (5-10 minutes)**

1. **🆔 Create App ID** (Browser tab should be open)
   - Go to: https://developer.apple.com/account/resources/identifiers/bundleId/add/
   - Bundle ID: `com.hobbyist.bookingapp`
   - Description: "Hobbyist App - Class Booking Platform"
   - Enable: Push Notifications, Apple Pay, In-App Purchase, Sign In with Apple

2. **📱 Create App Store Connect Record** (Browser tab should be open)
   - Go to: https://appstoreconnect.apple.com/apps
   - Click "+" to add new app
   - App Name: "Hobbyist App"
   - Bundle ID: `com.hobbyist.bookingapp`
   - SKU: `hobbyist-booking-001`

### **Phase 2: First Archive Build (15-30 minutes)**

3. **🔨 Option A: Automated Build**
   ```bash
   cd /Users/chromefang.exe/HobbyistSwiftUI
   ./build_for_testflight.sh
   ```

4. **🔨 Option B: Xcode GUI Build**
   ```bash
   # Open project
   open HobbyistSwiftUI.xcodeproj

   # Then in Xcode:
   # 1. Select "Any iOS Device" or connected device
   # 2. Product → Archive
   # 3. Wait for archive to complete
   # 4. Organizer opens → Select archive → "Distribute App"
   # 5. App Store Connect → Upload
   ```

### **Phase 3: TestFlight Configuration (10-15 minutes)**

5. **📤 Upload to App Store Connect**
   - Archive uploads automatically after build
   - Wait for "Processing" to complete (5-15 minutes)
   - Check App Store Connect for build appearance

6. **🧪 Configure TestFlight**
   - In App Store Connect → TestFlight tab
   - Select uploaded build
   - Add test information
   - Submit for beta review (if required)

---

## 🛠️ Troubleshooting

### **Common Issues & Solutions**

**"Bundle ID not found"**
- Ensure App ID created in developer.apple.com first
- Verify exact spelling: `com.hobbyist.bookingapp`

**"Code signing error"**
- Check Apple Developer account membership is active
- Verify automatic signing is enabled in Xcode

**"Archive failed"**
- Clean build folder: Product → Clean Build Folder
- Check all Stripe dependencies resolved
- Try building for Simulator first to verify code compiles

**"Upload failed"**
- Verify App Store Connect record exists
- Check bundle ID matches exactly
- Ensure latest Xcode version

---

## 📊 Success Timeline

- **Next 15 minutes**: Complete Apple Developer setup
- **Next 45 minutes**: First successful archive
- **Next 1 hour**: TestFlight upload complete
- **Next 2 hours**: Ready for alpha testers

---

## 🎯 Final Verification

Before proceeding, verify:
- [ ] Bundle ID: `com.hobbyist.bookingapp` everywhere
- [ ] App Store Connect record created
- [ ] Xcode project opens without errors
- [ ] All dependencies resolved (Stripe, Supabase)
- [ ] Build script is executable

---

## 🚀 Next Steps After Upload

1. **Add Internal Testers** (immediate)
   - Add your own Apple ID as tester
   - Test core flows: login, booking, payment

2. **Add External Testers** (after beta review)
   - Invite friends/family for feedback
   - Target 5-10 initial alpha testers

3. **Monitor Crashes & Feedback**
   - Check TestFlight feedback regularly
   - Use crash logs to fix critical issues

---

**🎉 You're about to launch your first alpha! Your 6 months of development work is about to reach real users.**