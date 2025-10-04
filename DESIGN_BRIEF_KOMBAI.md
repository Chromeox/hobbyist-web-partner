 # HobbyApp - Design Brief for Modern UI Redesign

**Project Goal:** Transform HobbyApp into a modern, smooth, rounded UI with sophisticated components that emphasize discovery, gamification, and Vancouver's creative community.

---

## 📱 App Overview

**HobbyApp** is Vancouver's premier platform for discovering and booking creative hobby classes. Think "ClassPass meets Instagram for hobbies" - combining social discovery with seamless booking and a credit-based payment system.

**Target Audience:**
- Young professionals (25-40) in Vancouver
- Creative-minded individuals looking for community experiences
- Beginners exploring new hobbies and seasoned enthusiasts

**Brand Personality:**
- Modern & approachable (not fitness-focused)
- Community-driven & welcoming
- Creative & inspiring
- Vancouver-local focus

---

## 🎨 Design Direction

### Visual Style
- **Modern rounded UI** with generous corner radiuses (16-24px)
- **Smooth animations** with spring physics and fluid transitions
- **Card-based layouts** with sophisticated shadows and depth
- **Gradient accents** (subtle, tasteful - not overwhelming)
- **Glassmorphism effects** for elevated surfaces
- **Micro-interactions** that delight (haptics, scaling, fading)

### Color Palette
**Primary Colors:**
- Deep Blue (#2563EB) - Trust & creativity
- Teal/Cyan (#06B6D4) - Energy & discovery
- Warm Coral (#FB7185) - Community & warmth

**Category Colors:**
- Ceramics: Earthy Brown (#92400E)
- Cooking: Fresh Green (#16A34A)
- Arts & Crafts: Royal Blue (#1D4ED8)
- Photography: Deep Purple (#7C3AED)
- Music: Vibrant Indigo (#4F46E5)
- Dance: Playful Pink (#DB2777)
- Writing: Rich Brown (#78350F)
- Jewelry: Luxe Cyan (#0891B2)
- Woodworking: Natural Orange (#EA580C)

**Neutral Palette:**
- Background: #FAFAF9 (light mode), #18181B (dark mode)
- Cards: Pure white (#FFFFFF) with subtle shadows
- Text Primary: #18181B / #FAFAF9
- Text Secondary: #71717A / #A1A1AA

### Typography
- **Headlines:** SF Pro Display - Bold, 28-34pt
- **Subheads:** SF Pro Display - Semibold, 20-24pt
- **Body:** SF Pro Text - Regular, 16pt
- **Captions:** SF Pro Text - Medium, 13-14pt
- **Dynamic Type:** Full iOS support for accessibility

---

## 🎮 Core Features & User Flows

### 1. **Enhanced Onboarding (6 Steps)**
A personalized, Vancouver-focused introduction:

**Step 1: Welcome**
- Large hero icon (figure.yoga) with gradient circle background
- Headline: "Welcome to HobbyApp!"
- Subtitle: "Discover Vancouver's most creative hobby classes..."
- Smooth fade-in animation

**Step 2: Profile Setup**
- Full name input with floating labels
- Neighborhood picker (Vancouver-specific: Gastown, Yaletown, Kits, etc.)
- Clean, minimal form design

**Step 3: Class Preferences**
- Time preferences grid (Morning/Afternoon/Evening/Weekend)
- Toggle buttons with smooth active states
- Visual feedback on selection

**Step 4: Interest Selection**
- 2-column grid of creative categories
- Circle icons with category colors
- Multi-select with scale animations
- Categories: Pottery, Cooking, Arts & Crafts, Photography, Music, Dance

**Step 5: Notifications**
- Permission request with benefits
- Toggle switches with detailed descriptions
- "Class Reminders" and "New Classes" options

**Step 6: Completion**
- Checkmark animation with success feedback
- Preference summary display
- "Welcome to Vancouver's Creative Community!"

**Design Notes:**
- Progress bar at top (0-100%)
- Back/Skip/Next navigation
- Smooth step transitions
- Save preferences to Supabase backend

---

### 2. **Discovery & Home Experience**

#### Main Tab Navigation (Bottom)
**4 Core Tabs:**
1. **Home** (house icon) - Personalized feed & recommendations
2. **Search** (magnifying glass) - Explore all classes
3. **Bookings** (calendar) - Upcoming & past classes
4. **Profile** (person) - User stats, credits, settings

**Tab Animation:**
- Morph between outline and filled icons
- Subtle bounce on selection
- Background circle indicator
- Label weight changes (regular → semibold)

#### Home Tab Content

**Hero Section:**
- "Welcome back, [Name]"
- Personalized greeting based on time of day

**Stats Cards (2 columns):**
- **Classes Completed:** Trophy icon, yellow accent
- **Points Earned:** Star icon, purple accent
- Glassmorphic card design with depth

**Content Sections:**
1. **Upcoming Classes**
   - Horizontal scrolling cards
   - Class image with gradient overlay
   - Time, instructor, location
   - Quick access to class details

2. **Recommended for You**
   - Personalized based on onboarding preferences
   - Category-based recommendations
   - Instructor popularity algorithm
   - Location proximity

3. **Trending in Vancouver**
   - Popular classes this week
   - Social proof (attendees count)
   - High-rated classes (4.5+ stars)

4. **New Classes**
   - Recently added classes
   - "New" badge with pulse animation

5. **Your Followed Instructors**
   - Classes from instructors you follow
   - Avatar + name + specialty

**Card Design:**
- Large rounded corners (20px)
- Subtle shadows with depth
- Hover/tap states with scale
- Image overlays with gradients

---

### 3. **Search & Discovery**

**Search Interface:**
- Large search bar with pill shape
- Real-time search with debounce
- Recent searches chip display
- Voice search option (iOS 16+)

**Filter Panel:**
- Slide-up modal with glassmorphism
- Category chips (horizontal scroll)
- Price range slider (visual, colorful)
- Difficulty level toggle (Beginner/Intermediate/Advanced)
- Date picker (calendar view)
- Location radius slider
- "Apply Filters" button with count badge

**Results Display:**
- Grid or list view toggle
- Sort options: Date, Price, Popularity, Distance
- Infinite scroll with shimmer loading
- Empty states with helpful suggestions

**Class Card (Compact):**
- Class image (16:9 ratio)
- Category badge (top left)
- Price tag or credit cost (top right)
- Class name, instructor
- Rating stars + review count
- Duration, difficulty, spots available
- Save/favorite heart icon

---

### 4. **Class Detail Page**

**Hero Section:**
- Full-width image carousel (swipeable)
- Back button (glassmorphic)
- Share & favorite buttons

**Content Sections:**
1. **Class Overview**
   - Title (large, bold)
   - Instructor name with avatar (tappable)
   - Category badge
   - Rating (stars + count)
   - Price or credit cost

2. **Quick Info Pills:**
   - Duration (clock icon)
   - Difficulty level (chart icon)
   - Spots available (person icon)
   - Location (pin icon)

3. **Description:**
   - Expandable text with "Read more"
   - Well-formatted paragraphs

4. **What You'll Learn:**
   - Bulleted list with checkmark icons
   - Gradient checkmarks

5. **Requirements:**
   - List with warning/info icons
   - What to bring, what's provided

6. **Amenities:**
   - Icon grid (parking, tools, refreshments)
   - Clean icon design

7. **Equipment (Optional Add-ons):**
   - Selectable items with price
   - Checkbox selection
   - Running total update

8. **Reviews:**
   - Star distribution chart
   - Recent reviews with avatars
   - "See all reviews" button

9. **Instructor Profile Preview:**
   - Name, bio snippet, specialties
   - Rating + classes taught
   - "View full profile" link

10. **Similar Classes:**
    - Horizontal scroll of related classes

**Sticky Bottom:**
- Price/credit display
- "Book Now" button (prominent, gradient)
- Date/time selector (if applicable)

---

### 5. **Booking Flow**

**Step 1: Select Date & Time**
- Calendar view with availability
- Time slot grid
- Spots remaining indicator

**Step 2: Add Equipment (Optional)**
- Checkboxes for add-ons
- Visual product cards
- Running total

**Step 3: Payment Method**
- Use credits (if available)
- Pay with card (Stripe)
- Apple Pay integration
- Credit balance display

**Step 4: Confirmation**
- Booking summary card
- QR code for check-in
- Add to calendar button
- Share booking option

**Design Notes:**
- Progress stepper at top
- Smooth transitions between steps
- Form validation with helpful errors
- Success animation on completion

---

### 6. **Credits System**

**Credit Packs (3 Tiers):**

1. **Starter Pack** - $25
   - 5 credits
   - "Try it out" badge
   - Best for: Single class trial

2. **Popular Pack** - $50 ⭐
   - 15 credits (12 + 3 bonus)
   - "Most Popular" badge
   - Highlight with border glow
   - Best for: Regular learners

3. **Premium Pack** - $90
   - 35 credits (25 + 10 bonus)
   - "Best Value" badge
   - Best for: Dedicated hobbyists

**Visual Design:**
- Card layout with gradient backgrounds
- Bonus credits highlighted with sparkle icon
- Price per credit calculation
- Comparison chart
- Purchase button with loading state

**Credits Dashboard:**
- Current balance (large, prominent)
- Credit history (transactions)
- Expiration dates (if applicable)
- Purchase more button

---

### 7. **Gamification Features**

**Achievement System:**

**Categories:**
1. **Attendance Achievements**
   - "First Class" - Attend 1 class
   - "Getting Started" - Attend 5 classes
   - "Consistent Learner" - Attend 10 classes
   - "Dedicated Hobbyist" - Attend 25 classes
   - "Master Student" - Attend 50 classes

2. **Exploration Achievements**
   - "Curious Mind" - Try 3 different categories
   - "Renaissance Person" - Try all 9 categories
   - "Neighborhood Explorer" - Classes in 5 venues

3. **Social Achievements**
   - "Friendly Face" - Leave 5 reviews
   - "Supporter" - Follow 10 instructors
   - "Community Member" - Attend 3 group classes

4. **Milestone Achievements**
   - "Weekend Warrior" - 5 Saturday classes
   - "Early Bird" - 5 morning classes
   - "Night Owl" - 5 evening classes

**Achievement Display:**
- Badge grid (locked/unlocked states)
- Progress bars for in-progress achievements
- Pop-up animation on unlock
- Share achievement to social

**Points System:**
- Earn points for attending classes
- Bonus points for reviews, referrals
- Leaderboard (optional, weekly reset)
- Points visualization with animations

---

### 8. **Social Features**

**Activity Feed:**
- Friend activity (classes they booked/attended)
- Instructor updates (new classes, stories)
- Popular classes in your network

**Following:**
- Follow instructors
- Follow friends
- Class recommendations from people you follow

**Reviews & Ratings:**
- Star rating (5-point scale)
- Written review with photos
- Helpful votes on reviews
- Reply from instructors

**Sharing:**
- Share classes to social media
- Invite friends to classes
- Referral system (get credits)

---

### 9. **Profile & Settings**

**Profile Section:**
- Avatar (editable, upload photo)
- Name, bio, location
- Stats overview:
  - Classes attended
  - Favorite categories
  - Points earned
  - Achievement badges

**My Activity:**
- Upcoming bookings
- Past classes (with review prompts)
- Followed instructors
- Saved/favorited classes

**Credits & Payments:**
- Current credit balance
- Transaction history
- Payment methods
- Purchase credit packs

**Settings:**
- Notifications preferences
- Account details
- Privacy settings
- Support & help
- App version
- Logout

---

## 🎯 User Journey Flows

### **New User Flow:**
1. Download app from App Store
2. Open app → Onboarding welcome screen
3. Complete 6-step personalized onboarding
4. Land on personalized Home feed
5. Browse "Recommended for You"
6. Tap class → View details
7. Book class → Payment/credits
8. Confirmation → Add to calendar
9. Attend class → Check-in
10. Post-class → Leave review
11. Earn achievement → Share to social

### **Returning User Flow:**
1. Open app → Home feed
2. Check "Upcoming Classes" section
3. Browse new recommendations
4. Search for specific category
5. Filter by preferences
6. Book additional class
7. Check credit balance
8. View profile stats & achievements

### **Discovery Flow:**
1. Open Search tab
2. Browse by category
3. Apply filters (location, price, time)
4. View class details
5. Read reviews
6. Check instructor profile
7. Book or save for later
8. Follow instructor

### **Social Flow:**
1. Open Home/Profile
2. View activity feed
3. See friend's recent booking
4. Tap to view class details
5. Book same class to join friend
6. Share booking on social media
7. Attend together
8. Both leave reviews
9. Earn "Community Member" achievement

---

## 🎨 Component Library Needs

### Navigation Components:
- Custom tab bar with animations
- Navigation bar with glassmorphism
- Back button with blur effect
- Progress stepper for multi-step flows

### Cards:
- Class card (compact grid view)
- Class card (full detail)
- Stat card (profile, home)
- Credit pack card (purchase flow)
- Achievement badge card
- Instructor card
- Review card

### Buttons:
- Primary CTA (gradient, large)
- Secondary action (outline)
- Tertiary/ghost button
- Icon-only buttons
- Floating action button
- Chip/tag buttons (categories, filters)

### Forms:
- Text input with floating labels
- Dropdown/picker with custom styling
- Toggle switches
- Checkboxes with animations
- Radio buttons (rare)
- Date/time pickers
- Slider (price range, distance)

### Media:
- Image carousel (swipeable)
- Avatar (round, with status indicator)
- Icon backgrounds (circles, gradients)
- Video player (if tutorials)

### Feedback:
- Toast notifications
- Success animations (Lottie or SF Symbols)
- Loading states (shimmer, skeleton)
- Empty states (friendly illustrations)
- Error states (helpful messaging)
- Pull-to-refresh

### Lists:
- Horizontal scrolling (class cards)
- Vertical infinite scroll
- Grid layouts (2-3 columns)
- Section headers with sticky behavior

### Modals & Sheets:
- Bottom sheets (filters, booking flow)
- Full-screen modals (onboarding)
- Alert dialogs (confirmation)
- Action sheets (share, report)

---

## 🌟 Key Differentiators

### What Makes HobbyApp Unique:
1. **Vancouver-Focused:** Hyper-local discovery, neighborhood preferences
2. **Creative Classes Only:** No fitness/boxing - purely creative hobbies
3. **Credit System:** Better value with bonus credits
4. **Gamification:** Achievements and points for engagement
5. **Social Discovery:** Follow instructors, see friend activity
6. **Personalized Onboarding:** Tailored recommendations from day 1

### Design Philosophy:
- **Less is more:** Clean, uncluttered interfaces
- **Delight in details:** Micro-animations, haptics, smooth transitions
- **Accessibility first:** VoiceOver, Dynamic Type, color contrast
- **Performance:** 60fps animations, lazy loading, efficient caching
- **Vancouver personality:** Warm, welcoming, creative community feel

---

## 📐 Technical Specifications

### Tech Stack:
- **Framework:** Next.js 15 (App Router)
- **Styling:** Tailwind CSS v3
- **Components:** Radix UI (headless, accessible)
- **Icons:** Lucide icons
- **State:** React built-ins (Context for global state)
- **Backend:** Supabase (already integrated)
- **Payments:** Stripe (already integrated)

### Design Tokens:
```css
/* Spacing Scale */
--space-xs: 4px
--space-sm: 8px
--space-md: 16px
--space-lg: 24px
--space-xl: 32px
--space-2xl: 48px

/* Border Radius */
--radius-sm: 8px
--radius-md: 12px
--radius-lg: 20px
--radius-xl: 24px
--radius-full: 9999px

/* Shadows */
--shadow-sm: 0 1px 2px rgba(0,0,0,0.05)
--shadow-md: 0 4px 12px rgba(0,0,0,0.08)
--shadow-lg: 0 12px 24px rgba(0,0,0,0.12)
--shadow-xl: 0 20px 40px rgba(0,0,0,0.15)
```

### Animation Specs:
- **Duration:** 150ms (fast), 300ms (standard), 500ms (slow)
- **Easing:** ease-in-out (default), spring (bouncy)
- **Transitions:** opacity, transform (avoid layout shifts)

---

## 🎯 Success Metrics

**User Engagement:**
- Onboarding completion rate > 80%
- Average session duration > 5 minutes
- Repeat bookings within 30 days > 40%

**Discovery:**
- Classes viewed per session > 5
- Search → booking conversion > 15%
- Category exploration (different categories tried) > 3

**Gamification:**
- Achievement unlocks per user > 2
- Review submission rate > 30%
- Instructor follows per user > 3

**Monetization:**
- Credit pack purchase rate > 25%
- Average credit pack size (starter < popular < premium)
- Repeat credit purchases > 40%

---

## 🚀 Next Steps with Kombai

**Phase 1: Core UI Components**
1. Design tab bar navigation with animations
2. Create class card variations (grid, detail)
3. Build onboarding flow screens
4. Design home feed layout

**Phase 2: Discovery & Booking**
1. Search interface with filters
2. Class detail page template
3. Booking flow screens
4. Payment/credits interface

**Phase 3: Profile & Gamification**
1. Profile page layout
2. Achievement badge system
3. Stats dashboard
4. Activity feed design

**Phase 4: Polish & Refinement**
1. Micro-interactions
2. Loading states
3. Empty states
4. Error handling
5. Dark mode variations

---

## 📝 Questions for ChatGPT Workshop

1. **Visual Direction:** Should we lean more towards soft pastels or bold vibrant colors?
2. **Card Density:** Compact Instagram-style grid vs. spacious Pinterest-style cards?
3. **Gamification:** Subtle achievements vs. prominent points/leaderboards?
4. **Social Features:** Feed-first like Instagram or utility-first like ClassPass?
5. **Credit Visualization:** How to make credits feel valuable and engaging?
6. **Category Expression:** Should each category have strong visual identity or unified brand?

---

**End of Design Brief**

*This document serves as the foundation for redesigning HobbyApp into a modern, engaging platform for Vancouver's creative community. Use this with ChatGPT and Kombai to generate UI mockups and component designs.*
