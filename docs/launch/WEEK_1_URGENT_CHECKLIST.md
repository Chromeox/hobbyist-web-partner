# Week 1 Urgent Action Checklist
**This Week's Mission: Get TestFlight Live + Print Materials + Recruit 25 Alpha Testers**

---

## 🔴 CRITICAL PATH (Must Complete This Week)

### Monday-Tuesday: Technical Foundation

#### [ ] 1. Create Xcode Archive Build (30 minutes)
**Steps:**
1. Open `/Users/chromefang.exe/HobbyApp/iOS/HobbyistSwiftUI.xcodeproj` in Xcode
2. Select "Any iOS Device" as build target (not Simulator)
3. Menu: Product → Archive
4. Wait for build to complete (5-10 minutes)
5. Archive Organizer will open automatically
6. Validate: Click "Validate App" button
7. Wait for validation (2-5 minutes)

**Success Criteria:** Archive appears in Organizer with green checkmark

**If Build Fails:**
- Check for Swift compilation errors
- Ensure all Package Dependencies resolved
- Verify Development Team is set (594BDWKT53)
- Try: Product → Clean Build Folder, then retry

---

#### [ ] 2. Upload to App Store Connect (15 minutes)
**Steps:**
1. In Archive Organizer, select your archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Select "Upload"
5. Select "Automatically manage signing"
6. Click "Upload"
7. Wait for upload (3-10 minutes depending on connection)

**Post-Upload:**
1. Go to App Store Connect: https://appstoreconnect.apple.com
2. Navigate to your app → TestFlight tab
3. Find uploaded build (may take 5-10 minutes to process)
4. Complete "What to Test" section:
   ```
   Please test the complete user journey:
   1. Sign up with email/Apple/Google
   2. Complete 6-step onboarding
   3. Browse classes in Discovery feed
   4. Book a class using credits
   5. Purchase credit pack ($25 test)
   6. Leave a review after "attending" class

   Known issues: None at this time
   Focus areas: Payment flow, authentication, class discovery
   ```
5. Complete Beta App Description:
   ```
   HobbyApp connects curious learners with Vancouver's creative studios
   through curated introductory classes. Discover pottery, cooking, dance,
   art, and wellness experiences - book with credits, attend, and explore
   your creative side.
   ```

**Success Criteria:** Build shows "Ready to Test" status in TestFlight

---

#### [ ] 3. Set Up Crash Reporting (2 hours)
**Recommended: Firebase Crashlytics**

**Steps:**
1. Go to https://console.firebase.google.com
2. Create new project: "HobbyApp Production"
3. Add iOS app with Bundle ID: `com.yourcompany.hobbyistswiftui`
4. Download GoogleService-Info.plist
5. Add to Xcode project (drag into project navigator)
6. Add Firebase SDK to Package.swift:
   ```swift
   .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.18.0")
   ```
7. Add to target dependencies: FirebaseCrashlytics
8. In AppDelegate or main app file, import and initialize:
   ```swift
   import FirebaseCore
   import FirebaseCrashlytics

   @main
   struct HobbyApp: App {
       init() {
           FirebaseApp.configure()
       }
   }
   ```
9. Enable crash collection in Xcode:
   - Build Settings → Debug Information Format → DWARF with dSYM
10. Upload symbols script (Build Phases → Add Run Script):
    ```bash
    "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
    ```
11. Test crash in debug: `fatalError("Test crash")`
12. Build and run, trigger crash, verify in Firebase Console

**Alternative: Sentry (if prefer)**
- Sign up at sentry.io
- Add Sentry SDK via Swift Package Manager
- Similar setup process

**Success Criteria:** Test crash appears in Firebase Console within 5 minutes

---

#### [ ] 4. Set Up User Analytics (2 hours)
**Recommended: Mixpanel (free tier)**

**Steps:**
1. Sign up at https://mixpanel.com (free up to 100K events/month)
2. Create project: "HobbyApp Production"
3. Get Project Token from Settings
4. Add Mixpanel SDK via Swift Package Manager:
   ```
   https://github.com/mixpanel/mixpanel-swift
   ```
5. Initialize in App:
   ```swift
   import Mixpanel

   Mixpanel.initialize(token: "YOUR_TOKEN")
   ```
6. Track key events:
   - `signup_completed`: User ID, auth method
   - `onboarding_step_completed`: Step number (1-6)
   - `class_viewed`: Class ID, category, studio
   - `booking_started`: Class ID, credits required
   - `booking_completed`: Class ID, credits used, studio
   - `credit_purchase_completed`: Pack size, amount, payment method
7. Test events in debug mode
8. Verify events appear in Mixpanel dashboard (real-time)

**Success Criteria:** Test events visible in Mixpanel Live View

---

### Wednesday: Physical Materials

#### [ ] 5. Design Business Cards (30 minutes)
**Specs:**
- Size: 3.5" × 2" (standard)
- Orientation: Horizontal
- Finish: Matte (premium feel)

**Front Design:**
```
┌─────────────────────────────┐
│                             │
│      [HOBBYAPP LOGO]        │
│                             │
│  Vancouver's Creative Class │
│      Discovery Platform     │
│                             │
└─────────────────────────────┘
```

**Back Design:**
```
┌─────────────────────────────┐
│                             │
│     [QR CODE - Large]       │
│                             │
│   Scan to join alpha test   │
│   hobbyistapp.com/alpha     │
│                             │
│   [Your Name] - Founder     │
│   [Your Email/Phone]        │
└─────────────────────────────┘
```

**Tools:**
- Canva (free): canva.com
- Use template: "Business Card" → 3.5 x 2"
- Export as PDF (print-ready, 300 DPI)

**Action:** Save design as `business-card-design.pdf` in this folder

---

#### [ ] 6. Design One-Pager (1 hour)
**Specs:**
- Size: 4" × 6" (postcard)
- Orientation: Vertical
- Finish: Glossy (eye-catching)

**Front Design:**
```
┌─────────────────────┐
│   HOBBYAPP          │
│                     │
│   Studios Keep      │
│   70% Revenue       │
│                     │
│   vs ClassPass 45%  │
│   = $250 more per   │
│   $1,000 bookings   │
│                     │
│   [Studio Photo]    │
└─────────────────────┘
```

**Back Design:**
```
┌─────────────────────┐
│ FOUNDING PARTNER    │
│ BENEFITS:           │
│                     │
│ ✓ Free 6 months     │
│   ($900 value)      │
│ ✓ 50% off forever   │
│ ✓ Direct input on   │
│   features          │
│                     │
│ How It Works:       │
│ 1. List classes     │
│ 2. We send students │
│ 3. Get paid weekly  │
│                     │
│ [QR CODE]           │
│ Learn more          │
└─────────────────────┘
```

**Action:** Save design as `one-pager-design.pdf` in this folder

---

#### [ ] 7. Order Printing ($200 budget)
**Option 1: Vistaprint (Recommended - Fast)**
- Website: vistaprint.com
- Business cards: 100 qty, matte, standard size
  - Cost: ~$25 + rush shipping $20 = $45
  - Delivery: 2-3 business days
- Postcards: 50 qty, 4x6, glossy, full color both sides
  - Cost: ~$30 + rush shipping $20 = $50
  - Delivery: 2-3 business days
- **Total: ~$95**

**Option 2: Local Vancouver Printer (Same-Day)**
- Staples (multiple locations)
  - Business cards: $50-70 for 100
  - Postcards: $80-100 for 50
  - Same-day pickup available
- **Total: ~$130-170**

**Option 3: Hybrid (Cost-Effective)**
- Business cards at Staples (same-day): $70
- Postcards via Vistaprint (better quality): $50
- **Total: $120**

**Action:**
1. Upload PDFs to chosen printer
2. Select rush/same-day if needed
3. Order and note delivery date
4. Budget remaining: ~$100 for contingencies

---

### Thursday-Sunday: Alpha Tester Recruitment

#### [ ] 8. Create WhatsApp Alpha Group (10 minutes)
**Steps:**
1. Open WhatsApp
2. New Group: "HobbyApp Alpha Testers 🎨"
3. Description:
   ```
   Welcome alpha testers! This is your direct line to the founder.

   - Ask questions anytime
   - Report bugs (with screenshots please!)
   - Share feedback
   - Support each other

   Bug bounty: $25 for critical bugs, $10 for minor bugs

   Let's build something awesome together! 🚀
   ```
4. Group Icon: HobbyApp logo
5. Admin settings: Only admins can edit group info

**Success Criteria:** Group created with description and icon

---

#### [ ] 9. Recruit 25 Alpha Testers (Target: 5-7 per day)
**Recruitment Message Template:**
```
Hey [Name]!

Quick question: Would you be interested in trying new creative
classes in Vancouver? (Pottery, cooking, dance, art, etc.)

I'm launching HobbyApp - a discovery platform for intro classes -
and looking for 25 alpha testers.

You'd get:
• $25 in free credits (try any class)
• VIP early access before public launch
• Direct line to me for support
• Shape the product with your feedback

Takes 2 minutes to install via TestFlight. Interested?
```

**Target Contacts (Personal Network):**
- [ ] Friends who took pottery/art classes
- [ ] Tech worker friends seeking evening hobbies
- [ ] Emily Carr students/alumni
- [ ] Previous workout class attendees
- [ ] Creative professionals (designers, writers, photographers)
- [ ] Gift experience purchasers you know
- [ ] Social butterflies (for squad feature testing)

**Recruitment Channels:**
1. Personal texts/DMs (most effective)
2. Facebook/Instagram story: "Looking for alpha testers!"
3. Vancouver creative Facebook groups (with permission)
4. Coffee shop conversations (if you're out and about)
5. Colleagues/coworkers who fit demographic

**Daily Target:**
- Thursday: 5 recruits
- Friday: 7 recruits
- Saturday: 7 recruits
- Sunday: 6 recruits
- **Total: 25 testers by end of week**

**Tracking:**
Keep simple list:
- [ ] Name, phone/email, date invited, status (invited/installed/onboarded)

---

#### [ ] 10. Send TestFlight Invitations (As recruits agree)
**Steps for Each Tester:**
1. Go to App Store Connect → TestFlight
2. Click "Internal Testing" or "External Testing" group
3. Add tester email
4. They'll receive email with TestFlight install link
5. After they install TestFlight app, they can install HobbyApp
6. Add them to WhatsApp group
7. Send welcome email (see `alpha-tester-welcome-email.md`)

**Important:**
- External testing requires TestFlight review (24-48 hours)
- Internal testing is instant (up to 100 testers)
- Start with internal testing for speed

---

#### [ ] 11. Allocate Alpha Testing Budget ($875)
**Budget Breakdown:**
- 50 testers × $25 credits each = $1,250 face value
- Studios receive 70% = $875 actual cost to you
- Platform keeps 30% = $375 (offsets cost)
- **Net cost: $875**

**Action Items:**
1. Set aside $875 in separate account/envelope
2. Create promo code in Stripe Dashboard:
   - Code: `ALPHA25`
   - Value: $25 credit pack for $0
   - Usage limit: 50 redemptions
   - Expiry: 30 days from now
3. Or manually add credits via Supabase:
   - Insert into `user_credits` table
   - Set `amount = 25, source = 'alpha_testing_gift'`

**Success Criteria:** Budget allocated, credits ready to distribute

---

## 📊 Week 1 Success Metrics

At end of week, you should have:
- ✅ TestFlight live and installable
- ✅ 25 alpha testers installed app (100% of target)
- ✅ Business cards printed and ready (100 qty)
- ✅ One-pagers printed and ready (50 qty)
- ✅ Crash reporting operational (Firebase/Sentry)
- ✅ Analytics operational (Mixpanel/Amplitude)
- ✅ WhatsApp alpha group created with 25 members
- ✅ Alpha testing budget allocated ($875)

**Red Flags (Address Immediately):**
- 🚨 TestFlight build rejected: Fix issues, resubmit ASAP
- 🚨 <15 testers recruited: Expand outreach channels, offer more incentives
- 🚨 Crash rate >5% in early testing: Halt onboarding, debug crashes
- 🚨 Zero analytics events: Fix integration before continuing

---

## 💡 Quick Wins (If You Have Extra Time)

- [ ] Create Google Form for structured feedback
- [ ] Set up automated welcome email sequence
- [ ] Design Instagram story graphics for tester recruitment
- [ ] Create QR code landing page (hobbyistapp.com/alpha)
- [ ] Record quick video demo of app (30 seconds)
- [ ] Take professional founder headshot
- [ ] Draft first blog post or press release
- [ ] Reach out to 2-3 studios informally (soft launch conversations)

---

## 🆘 Emergency Contacts & Resources

**If TestFlight Build Fails:**
- Apple Developer Support: https://developer.apple.com/support/
- Check build logs in Xcode Organizer
- Search error messages in Stack Overflow

**If Payment Testing Issues:**
- Stripe Dashboard: https://dashboard.stripe.com
- Stripe Support: https://support.stripe.com (live chat available)
- Test card: 4242 4242 4242 4242

**If Supabase Issues:**
- Supabase Dashboard: https://app.supabase.com
- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com

**Founder Mental Health:**
- This is a big week. Take breaks.
- Celebrate small wins (TestFlight live = huge milestone!)
- Reach out to mentor/friend if feeling overwhelmed
- Remember: Progress > Perfection

---

## ✅ Daily Check-In (End of Each Day)

Before bed, ask yourself:
1. What did I accomplish today?
2. What's blocking me?
3. What's my #1 priority tomorrow?
4. Did I take care of myself today?

**Log daily progress in this document or separate journal**

---

**This checklist is your North Star for Week 1. You've got this! 🚀**

*Last Updated: November 2025*
