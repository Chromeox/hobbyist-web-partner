# App Metadata & Bundle Identifier Configuration

## Bundle Identifier Setup

### Recommended Bundle Identifier Format:
```
com.[your-company-name].hobbyistswiftui
```

### Examples:
- `com.yourcompany.hobbyistswiftui`
- `com.hobbyist.app`
- `com.classconnect.hobbyistswiftui`

### Important Rules:
1. **Must be unique** across the entire App Store
2. **Cannot contain** spaces, special characters (except dots and hyphens)
3. **Should be lowercase** by convention
4. **Must match** between Xcode project and App Store Connect
5. **Cannot be changed** after App Store submission

## App Store Connect Configuration

### Required App Information:

#### Basic App Details:
```
App Name: HobbyistSwiftUI
Subtitle: Discover Local Creative Classes
Bundle ID: com.yourcompany.hobbyistswiftui
SKU: HOBBYISTSWIFTUI_001
Language: English (U.S.)
```

#### App Description (4000 character limit):
```
Discover and book creative classes in your city with HobbyistSwiftUI. From pottery and painting to cooking and photography, find hands-on learning experiences taught by passionate local instructors.

🎨 Features:
• Browse classes by category, location, and skill level
• Book and pay securely with Apple Pay and Stripe
• Get class reminders and booking confirmations
• Follow your favorite instructors and studios
• Track your creative journey and achievements
• Discover trending classes and special offers

🏛️ Perfect for:
• Art enthusiasts exploring new mediums
• Professionals seeking creative outlets
• Date nights and friend activities
• Skill building and personal development
• Community connection through shared interests

📍 Currently serving Vancouver with plans to expand to more cities. Join thousands of creative learners building their skills and connecting with their communities through hands-on experiences.

Download HobbyistSwiftUI and turn your curiosity into creativity!
```

#### Keywords (100 character limit):
```
classes,art,pottery,cooking,creative,hobby,workshop,learn,Vancouver,book,instructor,studio
```

#### Support URL:
```
https://hobbyistswiftui.com/support
```

#### Marketing URL:
```
https://hobbyistswiftui.com
```

#### Privacy Policy URL:
```
https://hobbyistswiftui.com/privacy
```

### App Categorization:

#### Primary Category:
- **Education** (recommended for class booking apps)

#### Secondary Category:
- **Lifestyle** (for hobby and creative activities)

### Content Rating:
- **Age Rating**: 4+ (suitable for all ages)
- **Frequent/Intense Content**: None

### App Review Information:

#### Demo Account (for App Review):
```
Username: reviewer@hobbyistswiftui.com
Password: TestFlight2024!
```

#### Review Notes:
```
This app helps users discover and book creative classes in their local area. 

Key features to test:
1. Browse classes by category
2. View class details and instructor profiles
3. Test booking flow (use test Stripe cards)
4. Check notification permissions
5. Test user profile and authentication

The app integrates with Supabase for backend services and Stripe for payments. All payment processing uses test mode during review.

Location permission is used to show nearby classes and studios. Camera/photo permissions are for profile pictures and class sharing (optional features).
```

### Pricing and Availability:

#### Pricing:
- **Free** (freemium model with in-app purchases)

#### Availability:
- **Regions**: Canada (start with home market)
- **Future expansion**: United States, United Kingdom

#### In-App Purchases:
```
Credit Pack - Small: $9.99 (10 credits)
Credit Pack - Medium: $24.99 (25 credits + 5 bonus)
Credit Pack - Large: $49.99 (50 credits + 15 bonus)
Premium Membership: $14.99/month (unlimited booking + perks)
```

## Version and Build Management

### Version Numbering Strategy:
```
Marketing Version (CFBundleShortVersionString):
- 1.0.0: Initial App Store release
- 1.1.0: New features
- 1.0.1: Bug fixes

Build Version (CFBundleVersion):
- Increment for each TestFlight upload
- Format: 1, 2, 3, 4... (simple integer)
```

### Release Notes Template:
```
Version 1.0.0 - Initial Release
• Discover creative classes in Vancouver
• Book and pay securely with Apple Pay
• Get class reminders and notifications
• Follow favorite instructors and studios
• Track your creative learning journey

We're excited to help you explore your creativity! Send feedback to support@hobbyistswiftui.com
```

## TestFlight Configuration

### Beta App Information:
```
Beta App Name: HobbyistSwiftUI Beta
Beta App Description: Help us test the future of creative class discovery! Book pottery, cooking, art, and other hands-on classes with local instructors.

What to Test:
• Browse and search classes
• Complete a test booking (use test payment methods)
• Check notification settings
• Test user profile features
• Try following instructors

Your feedback helps us create the best experience for creative learners!
```

### Test Information:
```
What to Test:
1. Sign up/login flow
2. Browse classes by category
3. Filter by location and date
4. View instructor profiles
5. Complete booking with test payment
6. Check calendar integration
7. Test notification permissions
8. Upload profile picture
9. Follow/unfollow studios

Known Issues:
• Some test data may display placeholder content
• Payment processing uses Stripe test mode
• Location services require permission for full functionality

Feedback Instructions:
Use the TestFlight feedback feature or email beta@hobbyistswiftui.com with:
• Device model and iOS version
• Steps to reproduce any issues
• Screenshots if helpful
• Feature suggestions welcome!
```

## Apple Developer Account Setup

### Required Information:
```
Legal Entity Name: [Your Company Name]
D-U-N-S Number: [If applicable for business]
Address: [Your business address]
Contact Information: [Phone and email]
Banking Information: [For App Store revenue]
Tax Information: [Required for sales]
```

### App Store Connect Access:
1. **Account Holder**: Full access to everything
2. **Admin**: Manage apps, users, and agreements
3. **Developer**: Create apps and upload builds
4. **Marketing**: Manage app metadata and marketing
5. **Sales**: Access to sales reports

## Localization Planning

### Initial Launch:
- **English (Canada)**: Primary market
- **French (Canada)**: Quebec market

### Future Localization:
- **English (US)**: US market expansion
- **Spanish (US)**: Hispanic market
- **German**: European expansion
- **Mandarin Chinese**: Asian markets

### Localization Assets:
- App name and description
- Keywords and categories
- Screenshots with localized text
- App icon (if culturally relevant)
- Privacy policy and terms of service

## Trademark and Legal Considerations

### Trademark Search:
- Verify "HobbyistSwiftUI" availability
- Consider alternative names if needed
- Register trademark if planning commercial use

### Privacy Compliance:
- GDPR compliance for EU users
- CCPA compliance for California users
- Privacy policy must match app functionality
- Data collection transparency

### Terms of Service:
- User account management
- Booking and cancellation policies
- Payment and refund terms
- Instructor and studio agreements
- Liability and insurance coverage

## Marketing Assets Requirements

### App Store Screenshots (Required):
- **iPhone 6.7"**: Up to 10 screenshots
- **iPhone 6.5"**: Up to 10 screenshots  
- **iPhone 5.5"**: Up to 10 screenshots
- **iPad Pro 12.9"**: Up to 10 screenshots

### App Previews (Optional but Recommended):
- **Duration**: 15-30 seconds
- **Resolution**: Match device requirements
- **Content**: Show key app functionality
- **Audio**: Optional voiceover or music

### App Icon Requirements:
- **1024x1024**: App Store display
- **Multiple sizes**: Generated automatically
- **No transparency**: App Store requirement
- **Consistent branding**: Across all sizes

This configuration ensures your app is properly set up for a successful TestFlight beta and eventual App Store launch.