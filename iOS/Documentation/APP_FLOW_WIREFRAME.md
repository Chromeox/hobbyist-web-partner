# HobbyistSwiftUI - Complete App Flow Wireframe

## 🎯 App Navigation Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     App Launch Flow                         │
└─────────────────────────────────────────────────────────────┘

    [App Launch]
         │
         ├─[First Launch?]─Yes─→ [OnboardingView] ──→ [HomeView]
         │                           │
         │                           ├─ Welcome
         │                           ├─ Profile Setup
         │                           ├─ Preferences
         │                           ├─ Notifications
         │                           ├─ Payment Setup
         │                           └─ Completion
         │
         └─[Authenticated?]─No──→ [AuthenticationView]
                   │                    │
                   │                    ├─→ [LoginView] ──→ [HomeView]
                   │                    │      ├─ Email/Password
                   │                    │      ├─ Social Login
                   │                    │      └─ Forgot Password
                   │                    │
                   │                    └─→ [SignUpView] ──→ [OnboardingView]
                   │                           ├─ Registration Form
                   │                           ├─ Password Strength
                   │                           └─ Terms Agreement
                   │
                   └─Yes──→ [MainTabView]
```

## 📱 Main App Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        MainTabView                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │ Home │  │Browse│  │  My  │  │ Fav  │  │Profile│       │
│  │  🏠  │  │  🔍  │  │Classes│  │  ❤️  │  │  👤  │       │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘       │
│      │         │         │         │         │            │
└──────┼─────────┼─────────┼─────────┼─────────┼────────────┘
       │         │         │         │         │
       ↓         ↓         ↓         ↓         ↓
```

## 🏠 Home Tab Flow

```
[HomeView]
    │
    ├─ Search Bar ────→ [Search Results]
    │
    ├─ Categories ────→ [Filtered Classes]
    │
    ├─ Featured Classes
    │     └─→ [ClassDetailView] ──→ [BookingFlowView]
    │
    ├─ Nearby Classes Map
    │     └─→ [FullMapView] ──→ [ClassDetailView]
    │
    ├─ Upcoming Classes
    │     └─→ [ClassDetailView]
    │
    └─ Recommended Classes
          └─→ [ClassDetailView]
```

## 🔍 Browse/Search Tab Flow

```
[ClassListView]
    │
    ├─ Search Bar
    │
    ├─ Filter Pills
    │     └─→ [FiltersView]
    │           ├─ Date Range
    │           ├─ Price Range
    │           ├─ Difficulty
    │           ├─ Class Size
    │           └─ Amenities
    │
    ├─ Sort Options
    │     ├─ Recommended
    │     ├─ Price
    │     ├─ Distance
    │     ├─ Rating
    │     └─ Start Time
    │
    ├─ List/Map Toggle
    │     └─→ [ClassMapView]
    │
    └─ Class Items
          └─→ [ClassDetailView]
```

## 📖 Class Detail Flow

```
[ClassDetailView]
    │
    ├─ Hero Image
    │     ├─ Favorite Button ──→ Updates Favorites
    │     └─ Share Button ────→ [ShareSheet]
    │
    ├─ Instructor Info ──→ [InstructorProfileView]
    │
    ├─ Tabs
    │   ├─ Overview
    │   │     ├─ Description
    │   │     ├─ Requirements
    │   │     └─ Amenities
    │   │
    │   ├─ Location
    │   │     ├─ Map View
    │   │     ├─ Address
    │   │     └─ Directions ──→ Maps App
    │   │
    │   ├─ Reviews
    │   │     ├─ Rating Summary
    │   │     └─ Review List
    │   │
    │   └─ Similar Classes ──→ [ClassDetailView]
    │
    └─ Book Now Button ──→ [BookingFlowView]
```

## 💳 Booking Flow (5 Steps)

```
[BookingFlowView]
    │
    ├─ Step 1: Participant Selection
    │     ├─ Participant Count (1-10)
    │     ├─ Participant Names (optional)
    │     └─ Price Calculation
    │
    ├─ Step 2: Booking Details
    │     ├─ Special Requests
    │     ├─ Experience Level
    │     ├─ Equipment Rental
    │     └─ Emergency Contact
    │
    ├─ Step 3: Payment Method
    │     ├─ Apple Pay
    │     ├─ Saved Cards
    │     ├─ Add New Card ──→ [Stripe Sheet]
    │     └─ Promo Code
    │
    ├─ Step 4: Review
    │     ├─ Class Details
    │     ├─ Booking Summary
    │     ├─ Payment Summary
    │     └─ Terms Agreement
    │
    └─ Step 5: Confirmation
          ├─ Success Animation
          ├─ Confirmation Code
          ├─ Calendar Integration
          ├─ Share Option
          └─ Done ──→ [HomeView]
```

## 📅 My Classes Tab Flow

```
[MyClassesView]
    │
    ├─ Upcoming Classes
    │     ├─ Class Cards ──→ [ClassDetailView]
    │     ├─ Cancel Option ──→ [CancelConfirmation]
    │     └─ Reschedule ──→ [RescheduleFlow]
    │
    ├─ Past Classes
    │     ├─ Class History
    │     ├─ Leave Review ──→ [ReviewFormView]
    │     └─ Book Again ──→ [BookingFlowView]
    │
    └─ Calendar View
          └─ Date Selection ──→ Filtered Classes
```

## 👤 Profile Tab Flow

```
[ProfileView]
    │
    ├─ Profile Header
    │     ├─ Edit Profile ──→ [EditProfileView]
    │     └─ Settings ──→ [SettingsView]
    │
    ├─ Stats Dashboard
    │     ├─ Classes Attended
    │     ├─ Favorite Categories
    │     └─ Achievement Badges
    │
    ├─ Payment Methods ──→ [PaymentMethodsView]
    │
    ├─ Notifications ──→ [NotificationSettingsView]
    │
    ├─ Help & Support ──→ [SupportView]
    │
    └─ Sign Out ──→ [AuthenticationView]
```

## 🔔 Push Notification Triggers

```
Notification Flow:
    │
    ├─ Booking Confirmation
    │     └─ Immediate after successful payment
    │
    ├─ Class Reminder
    │     ├─ 24 hours before
    │     └─ 1 hour before
    │
    ├─ Cancellation Alert
    │     └─ If instructor cancels
    │
    ├─ New Class Alert
    │     └─ Based on preferences
    │
    └─ Promotional Offers
          └─ Based on user behavior
```

## 💰 Stripe Payment Flow

```
[Payment Processing]
    │
    ├─ Payment Method Selection
    │     ├─ Apple Pay ──→ Apple Pay Sheet
    │     └─ Card ──→ Stripe Payment Sheet
    │
    ├─ Processing
    │     ├─ Create Payment Intent (Backend)
    │     ├─ Confirm Payment (Frontend)
    │     └─ Handle Result
    │
    └─ Result Handling
          ├─ Success ──→ Booking Confirmation
          ├─ Failure ──→ Error Message
          └─ Requires Action ──→ 3D Secure
```

## 🔄 Supabase Data Flow

```
[Data Synchronization]
    │
    ├─ Real-time Subscriptions
    │     ├─ Class Updates
    │     ├─ Booking Status
    │     └─ Spot Availability
    │
    ├─ Data Fetching
    │     ├─ Classes (paginated)
    │     ├─ User Profile
    │     ├─ Bookings
    │     └─ Reviews
    │
    └─ Data Mutations
          ├─ Create Booking
          ├─ Update Profile
          ├─ Add Review
          └─ Toggle Favorite
```

## 🎯 User Journey Examples

### New User Journey:
```
Launch App → Sign Up → Onboarding → Home → Browse Classes 
→ Class Detail → Book Class → Payment → Confirmation 
→ Receive Notification → Attend Class → Leave Review
```

### Returning User Journey:
```
Launch App → Auto Login → Home → Quick Book from Favorites 
→ Apple Pay → Confirmation → Calendar Sync
```

### Power User Journey:
```
Launch App → My Classes → Upcoming → Class Detail 
→ Similar Classes → Multi-Book → Apply Discount 
→ Payment → Share Achievement
```

## 📊 Screen Count Summary

- **Authentication**: 3 screens
- **Onboarding**: 6 steps
- **Main Navigation**: 5 tabs
- **Class Discovery**: 8+ screens
- **Booking Flow**: 5 steps
- **Profile/Settings**: 6+ screens
- **Total Unique Screens**: ~30 screens

## 🔗 Deep Linking Structure

```
hobbyist://
    ├─ class/{id} → ClassDetailView
    ├─ booking/{id} → BookingConfirmation
    ├─ profile/{userId} → ProfileView
    ├─ instructor/{id} → InstructorView
    └─ promo/{code} → Applied at checkout
```

## 🎨 Navigation Patterns

1. **Tab Navigation**: Primary app structure
2. **Stack Navigation**: Within each tab
3. **Modal Presentation**: Booking flow, filters
4. **Sheet Presentation**: Payment, share, reviews
5. **Full Screen Cover**: Onboarding, auth