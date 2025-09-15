# App Store Connect Setup for Hobbyist iOS App

## Overview
Complete guide for creating and configuring your Hobbyist app in App Store Connect for TestFlight deployment and eventual App Store release.

## Step 1: Initial App Creation

### 1.1 Create New App Record
1. Visit [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Navigate to **My Apps**
4. Click **+** button → **New App**

### 1.2 App Information Configuration
**Required Information:**
```
Platforms: iOS
Name: Hobbyist
Primary Language: English (U.S.)
Bundle ID: com.hobbyist.bookingapp
SKU: HOBBYIST-IOS-2024
User Access: Full Access
```

**Bundle ID Selection:**
- Must exactly match your Xcode project bundle identifier
- Select from existing App IDs (created in Apple Developer Portal)
- Cannot be changed after app creation

### 1.3 App Categories
**Primary Category:** Health & Fitness
**Secondary Category:** Lifestyle

**Rationale:**
- Primary aligns with fitness/wellness classes
- Secondary captures creative hobbies and lifestyle activities

## Step 2: App Information Setup

### 2.1 General App Information
Navigate to **App Information** section:

**App Name:** Hobbyist
**Subtitle:** Discover Local Creative Classes
**Category:** Health & Fitness, Lifestyle

### 2.2 Age Rating Configuration
Click **Edit** next to Age Rating:

**Content Descriptions:**
- Cartoon or Fantasy Violence: None
- Realistic Violence: None  
- Sexual Content or Nudity: None
- Profanity or Crude Humor: None
- Alcohol, Tobacco, or Drug Use: None
- Simulated Gambling: None
- Horror/Fear Themes: None
- Medical/Treatment Information: None
- Unrestricted Web Access: No
- Gambling and Contests: None

**Final Rating:** 4+ (Ages 4 and up)

### 2.3 App Privacy Configuration
**Privacy Policy URL:** `https://hobbyist.app/privacy`
**Support URL:** `https://hobbyist.app/support`

**Data Collection Practices:**
```
Contact Info:
✅ Email Address - Used for account creation and communication
✅ Name - Used for profile and booking identification
✅ Phone Number - Used for booking confirmations (optional)

Location:
✅ Precise Location - Used to show nearby classes and studios

Financial Info:
✅ Payment Info - Used for class bookings and payments
✅ Credit and Debit Card Number - Processed securely through Stripe

Usage Data:
✅ Product Interaction - Used to improve app experience
✅ Advertising Data - Not collected
✅ Analytics - Used for app performance monitoring

Identifiers:
✅ User ID - Used for account management
✅ Device ID - Used for push notifications
```

### 2.4 Content Rights
**Third-Party Content:** No
**Copyright:** Hobbyist Technologies Inc., 2024

## Step 3: Pricing and Availability

### 3.1 Pricing Configuration
1. Navigate to **Pricing and Availability**
2. **Price:** Free (the app itself is free)
3. **Availability:** All countries and regions
4. **App Distribution:** Available on the App Store

### 3.2 In-App Purchase Configuration
Since your app includes credit pack purchases:
1. Navigate to **Features** → **In-App Purchases**
2. Create purchase items for credit packs:

**Credit Pack Examples:**
```
Product ID: com.hobbyist.bookingapp.credits.5pack
Reference Name: 5 Class Credits
Type: Consumable
Price: $49.99
```

```
Product ID: com.hobbyist.bookingapp.credits.10pack  
Reference Name: 10 Class Credits
Type: Consumable
Price: $89.99
```

```
Product ID: com.hobbyist.bookingapp.credits.20pack
Reference Name: 20 Class Credits  
Type: Consumable
Price: $159.99
```

## Step 4: App Store Listing Content

### 4.1 App Description
**Primary Description:**
```
Discover and book creative classes in Vancouver. From pottery and painting to dance and fitness, Hobbyist connects you with local studios offering unique experiences.

🎨 DISCOVER CLASSES
Browse hundreds of creative classes and workshops near you. Filter by category, date, location, and skill level to find your perfect match.

📅 EASY BOOKING  
Book classes instantly with secure payments. Get confirmations, reminders, and class updates right in the app.

⭐ FOLLOW FAVORITES
Follow your favorite instructors and studios to stay updated on new classes and special offers.

💳 FLEXIBLE CREDITS
Purchase credit packs for multiple classes and use them anytime. No expiration dates or booking fees.

🔔 SMART REMINDERS
Never miss a class with personalized reminders and real-time updates about changes or cancellations.

📍 LOCAL COMMUNITY
Connect with Vancouver's creative community. Share experiences, leave reviews, and discover new hobbies.

Perfect for beginners and experts alike - start your creative journey today!
```

### 4.2 Keywords
```
pottery, painting, dance, fitness, yoga, classes, workshops, vancouver, creative, art, wellness, booking, local, community, hobbies, learning, experiences, studios, instructors
```

### 4.3 Promotional Text
```
New classes added weekly! Discover pottery, painting, dance, and more. Download now and get started with local creative experiences.
```

### 4.4 Support Information
**Support URL:** `https://hobbyist.app/support`
**Marketing URL:** `https://hobbyist.app`
**Privacy Policy URL:** `https://hobbyist.app/privacy`

## Step 5: App Preview and Screenshots

### 5.1 Screenshot Requirements
**iPhone 6.7" Display (Required):**
- 1290 x 2796 pixels
- .jpg or .png format
- RGB color space
- 3-5 screenshots required

**iPhone 6.5" Display (Required):**
- 1242 x 2688 pixels
- 3-5 screenshots required

**iPad Pro 12.9" Display (Optional but recommended):**
- 2048 x 2732 pixels
- 3-5 screenshots

### 5.2 Screenshot Content Strategy
**Screenshot 1:** Home screen with class discovery
**Screenshot 2:** Class details and booking flow
**Screenshot 3:** User profile and following
**Screenshot 4:** Search and filtering features  
**Screenshot 5:** Payment and confirmation

### 5.3 App Preview Video (Optional)
- 30 seconds maximum
- Same device sizes as screenshots
- Showcase key app features
- No spoken words (music/sound effects only)

## Step 6: TestFlight Configuration

### 6.1 TestFlight Information
Navigate to **TestFlight** tab after app creation:

**Test Information:**
```markdown
# What to Test - Hobbyist iOS v1.0.0

## Core Features
- User registration and login flow
- Browse classes by category (pottery, painting, fitness, etc.)  
- View class details and instructor profiles
- Complete booking process with test payments
- Receive push notifications for reminders
- Upload profile photos and manage account
- Follow/unfollow instructors and studios

## Payment Testing
Use Stripe test card numbers:
- Card: 4242 4242 4242 4242
- Expiry: Any future date
- CVC: Any 3 digits
- Postal Code: Any valid code

## Known Issues
- Limited class data (Vancouver focus)
- Test payment mode only
- Some placeholder content

## Feedback Needed
- Report crashes or app errors
- UI/UX feedback and suggestions
- Performance issues
- Missing features or improvements
- General usability concerns

Thank you for helping test Hobbyist!
```

### 6.2 Beta App Review Information
**Beta App Review Information:**
```
Sign-In Requirements: Yes
Username: test@hobbyist.app  
Password: TestFlight2024!

Demo Account Notes:
- Pre-loaded with sample class data
- Test payments enabled
- All features accessible
- No real charges will occur

Additional Information:
This app helps users discover and book creative classes in Vancouver. The TestFlight version includes test data and Stripe test mode for safe payment testing.
```

### 6.3 External Testing Groups
Create testing groups for organized feedback:

**Group 1: Core Team (5-10 testers)**
- Internal team members
- Full access to all builds
- Daily usage and feedback

**Group 2: Design Reviewers (10-20 testers)**  
- UI/UX focused testing
- Focus on user experience
- Visual design feedback

**Group 3: Beta Users (50-100 testers)**
- General public testing
- Broad compatibility testing  
- Real-world usage scenarios

## Step 7: Build Upload and Processing

### 7.1 Upload Process
After creating archive in Xcode:
1. **Organizer** → **Distribute App**
2. **App Store Connect** distribution
3. **Automatic Signing** (recommended)
4. **Upload Options:**
   - Include bitcode: NO
   - Upload symbols: YES
   - Manage version: NO

### 7.2 Build Processing Timeline
**Typical Timeline:**
- Upload: 10-30 minutes
- Processing: 10-60 minutes  
- Available for TestFlight: Immediately after processing
- External testing review: 24-48 hours (if required)

### 7.3 Build Status Monitoring
Monitor build status in App Store Connect:
1. **My Apps** → **Hobbyist** → **TestFlight**
2. **iOS Builds** section
3. Status progression:
   - Upload Received
   - Processing  
   - Ready to Submit
   - Ready for Testing

## Step 8: Legal and Compliance

### 8.1 Export Compliance
**ITSAppUsesNonExemptEncryption:** No
(Already configured in Info.plist)

### 8.2 Content Rating Compliance
Ensure app content matches declared 4+ rating:
- No inappropriate content
- Family-friendly interface
- Safe community features

### 8.3 Privacy Compliance  
**COPPA Compliance:** Yes (4+ rating)
**Privacy Policy:** Must be accessible from app
**Data Collection:** Transparently disclosed

## Step 9: Marketing and Metadata

### 9.1 App Store Optimization (ASO)
**Title:** Hobbyist - Creative Classes
**Subtitle:** Discover Local Art & Fitness
**Keywords:** Focus on local, creative, classes, Vancouver

### 9.2 Localization
**Primary Language:** English (U.S.)
**Additional Languages:** None initially
**Future Consideration:** French (Canadian market)

### 9.3 Editorial Content
**What's New in Version 1.0:**
```
🎉 Welcome to Hobbyist!

Discover and book amazing creative classes in Vancouver:

✨ Browse pottery, painting, dance, and fitness classes
📱 Easy booking with secure payments  
👥 Follow your favorite instructors
💳 Flexible credit packs with no expiry
🔔 Smart class reminders

Download now and start your creative journey!
```

## Step 10: Launch Strategy

### 10.1 Soft Launch Plan
1. **Internal TestFlight** (1 week)
2. **Limited External Beta** (2 weeks)
3. **Expanded Beta Testing** (2 weeks)
4. **Final Testing & Polish** (1 week)
5. **App Store Submission** (1 week review)
6. **Public Launch**

### 10.2 Success Metrics
**TestFlight Goals:**
- <1% crash rate
- >4.0 average rating
- >80% positive feedback
- All core flows functional

**App Store Goals:**
- Successful review approval
- Featured consideration
- Organic discovery optimization
- User acquisition targets

### 10.3 Post-Launch Support
**Support Infrastructure:**
- Help center documentation
- In-app feedback system
- Email support: support@hobbyist.app
- Community guidelines
- Regular updates and improvements

This comprehensive App Store Connect setup ensures your Hobbyist app is properly configured for successful TestFlight deployment and App Store launch.