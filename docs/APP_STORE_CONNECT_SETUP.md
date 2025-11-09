# App Store Connect Setup Guide

## 📱 App Information
- **Bundle ID**: `com.hobbyist.bookingapp`
- **App Name**: HobbyApp
- **Privacy Policy**: `https://hobbyist.app/privacy`
- **Terms of Use**: `https://hobbyist.app/terms`
- **Support Email**: `support@hobbyist.app`

## 🚀 Step-by-Step App Store Connect Setup

### 1. Create New App in App Store Connect

1. **Sign in to App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Create New App**:
   - Click "My Apps" → "+" (plus icon) → "New App"
   - **Platform**: iOS
   - **Name**: HobbyApp
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.hobbyist.bookingapp`
   - **SKU**: hobbyapp-ios-2024 (unique identifier)

3. **After Creation**:
   - Note your **iPhone Store ID** (appears in app URL)
   - Example: https://appstoreconnect.apple.com/apps/123456789/appstore

### 2. Configure App Information

#### General Information
- **Name**: HobbyApp
- **Subtitle**: Discover Creative Classes in Vancouver
- **Primary Category**: Health & Fitness
- **Secondary Category**: Lifestyle

#### Privacy & URLs
- **Privacy Policy URL**: `https://hobbyist.app/privacy`
- **Terms of Use URL**: `https://hobbyist.app/terms`
- **Support URL**: `support@hobbyist.app`

#### Age Rating
- **Rating**: 4+ (No Restricted Content)
- **Frequent/Intense**: No for all categories

### 3. App Store Description

```
Discover and book creative classes across Vancouver with HobbyApp!

🎨 EXPLORE CLASSES
• Pottery, ceramics, painting, crafts, and more
• Local Vancouver studios and instructors
• Real-time availability and instant booking

💳 SMART PAYMENTS  
• Credit pack system for better value
• Secure payments with Apple Pay and Stripe
• 30% platform fee, 70% goes to studios

📱 SEAMLESS EXPERIENCE
• Face ID authentication for quick access
• Class reminders and notifications
• Follow your favorite instructors and studios

🏆 DISCOVER VANCOUVER'S CREATIVE SCENE
• Support local artists and studios
• Build your creative skills
• Connect with Vancouver's maker community

Perfect for beginners and experienced creators alike. Start your creative journey today!

Download HobbyApp and unlock Vancouver's creative potential.
```

### 4. Keywords (100 characters max)
```
pottery,ceramics,classes,vancouver,art,creative,booking,workshops,crafts,local
```

### 5. App Screenshots Requirements

#### iPhone Screenshots (6.7" display - iPhone 15 Pro Max)
1. **Hero/Landing Screen** - Show main discovery interface
2. **Class Detail** - Display class information and booking
3. **Authentication** - Face ID or login screen
4. **Booking Flow** - Payment and confirmation
5. **Profile/Credits** - User credits and profile

#### Specifications:
- **Size**: 1290 x 2796 pixels
- **Format**: PNG or JPEG
- **Color Space**: sRGB or P3

### 6. App Icon
- **Size**: 1024 x 1024 pixels
- **Format**: PNG (no transparency)
- **Design**: Already configured in Assets.xcassets

### 7. Build Upload Preparation

#### Version Information
- **Version**: 1.0
- **Build**: 1 (auto-increments)
- **Copyright**: 2024 HobbyApp Inc.

#### Export Compliance
- **Uses Encryption**: Yes (for HTTPS communications)
- **Qualifies for Exemption**: Yes (standard encryption)

### 8. TestFlight Beta Configuration

#### Beta App Information
- **Beta App Description**: 
```
Alpha testing version of HobbyApp for Vancouver creative classes.

TESTING FOCUS:
• Facebook/Google/Apple authentication
• Class discovery and booking flow  
• Credit pack purchases ($25, $50, $90)
• Payment processing with Stripe
• Studio profile viewing

KNOWN LIMITATIONS:
• Limited to Vancouver area classes
• Test payment mode enabled
• 50 alpha tester limit

Please test all authentication methods and complete at least one credit purchase. Report any issues via TestFlight feedback.
```

#### Test Information
- **Email**: support@hobbyist.app
- **First Name**: HobbyApp
- **Last Name**: Testing
- **Phone**: [Your phone number]

#### What to Test
```
ALPHA TESTING CHECKLIST:

Authentication:
□ Sign up with email/password
□ Sign in with Apple ID
□ Sign in with Google
□ Sign in with Facebook
□ Face ID authentication

Class Discovery:
□ Browse Vancouver studios
□ Filter classes by type/date
□ View class details and instructor profiles
□ Save favorite classes

Booking & Payments:
□ Purchase credit packs ($25, $50, $90)
□ Book classes using credits
□ Apple Pay functionality
□ Credit balance tracking

Profile & Settings:
□ Update user profile
□ View booking history
□ Privacy policy access
□ Terms of service acceptance

Please complete testing within 7 days and provide feedback through TestFlight.
```

## 📋 Pre-Launch Checklist

### Required Before Submission
- [ ] App Store Connect app created
- [ ] iPhone Store ID documented
- [ ] Screenshots uploaded (5 required)
- [ ] App description and keywords finalized
- [ ] Privacy policy live at URL
- [ ] Terms of service live at URL
- [ ] Support email configured
- [ ] Age rating completed
- [ ] Export compliance declared

### TestFlight Specific
- [ ] Beta app description written
- [ ] Test information provided
- [ ] Alpha tester group created (50 Vancouver users)
- [ ] TestFlight testing instructions documented
- [ ] Feedback collection method defined

## 🔍 Post-Setup Actions

1. **Document iPhone Store ID**: Add to Configuration.swift if needed
2. **Create Tester Groups**: Set up external beta testing group
3. **Prepare Marketing**: Screenshots and promotional materials
4. **Monitor Reviews**: Set up App Store Connect notifications

## 📞 Support Information

- **Technical Issues**: Report via GitHub Issues
- **App Store Questions**: Use Apple Developer Forums
- **Business Inquiries**: support@hobbyist.app

---

**Next Step**: Upload your first build using Xcode Archive → Distribute to App Store Connect