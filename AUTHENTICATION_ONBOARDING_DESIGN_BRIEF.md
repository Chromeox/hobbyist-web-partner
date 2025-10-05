# Authentication & Onboarding Design Brief

## Overview
Modernize the authentication and onboarding screens to match the new brand design system established in the landing page.

---

## Current State Analysis

### LoginView.swift (260+ lines)
- Basic gradients but inconsistent with new brand
- Generic blue/purple colors instead of BrandPrimary/Teal/Coral
- System gray backgrounds instead of glassmorphic cards
- Standard iOS form styling
- **Existing Features to Preserve:**
  - Apple Sign In integration
  - Face ID/Touch ID authentication
  - Email/password authentication
  - Password reset functionality
  - Form validation with inline feedback

### EnhancedOnboardingFlow (Currently in ContentView.swift, ~400 lines)
- 6-step flow: Welcome → Profile → Interests → Neighborhood → Payment → Completion
- Basic navigation with progress bar
- Vancouver-focused but not branded
- Inline implementation in ContentView.swift (needs extraction)

---

## Brand Design System Reference

### Colors
- **Primary**: Deep Blue (#2563EB) - Main actions, primary buttons
- **Teal**: Vibrant Teal (#06B6D4) - Secondary accents, highlights
- **Coral**: Warm Coral (#FB7185) - Tertiary accents, progress indicators
- **Gradient**: Purple to Pink gradient for backgrounds

### Typography
- **Hero Title**: 34pt Bold Rounded
- **Large Title**: 28pt Bold Rounded
- **Title**: 22pt Semibold Rounded
- **Headline**: 18pt Semibold
- **Body**: 16pt Regular
- **Subheadline**: 15pt Medium
- **Caption**: 13pt Medium

### Spacing
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- xxl: 48px

### Corner Radius
- sm: 8px (small chips, tags)
- md: 12px (input fields)
- lg: 20px (cards, content containers)
- xl: 24px (modal sheets)
- full: 9999px (circular elements)

### Animations
- **Spring**: response 0.4, damping 0.7 - For button presses, transitions
- **Fast**: 0.15s ease-in-out - Quick micro-interactions
- **Standard**: 0.3s ease-in-out - General transitions
- **Slow**: 0.5s ease-in-out - Large view changes

---

## Design Specifications

### 1. Login/Signup Screen Redesign

#### Layout Structure
```
┌─────────────────────────────────────┐
│  Gradient Background (full screen)  │
│  ┌───────────────────────────────┐  │
│  │  Floating Hero Icon/Logo      │  │
│  │  (with gentle animation)      │  │
│  └───────────────────────────────┘  │
│                                     │
│  "Welcome Back!" / "Get Started"    │
│  Subtitle with Vancouver reference  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │  Glassmorphic Content Card      ││
│  │  ┌───────────────────────────┐  ││
│  │  │ Name Field (signup only)  │  ││
│  │  └───────────────────────────┘  ││
│  │  ┌───────────────────────────┐  ││
│  │  │ Email Field               │  ││
│  │  └───────────────────────────┘  ││
│  │  ┌───────────────────────────┐  ││
│  │  │ Password Field            │  ││
│  │  └───────────────────────────┘  ││
│  │                                 ││
│  │  Forgot Password? (signin only) ││
│  │                                 ││
│  │  [Primary Gradient Button]      ││
│  │  Sign In / Create Account       ││
│  │                                 ││
│  │  [Outline Button]               ││
│  │  Sign in with Face ID           ││
│  │                                 ││
│  │  [Outline Button]               ││
│  │  Sign in with Apple             ││
│  │                                 ││
│  │  [Text Button]                  ││
│  │  Sign Up / Already have account?││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

#### Component Specifications

**Hero Section:**
- Circular gradient background (140x140)
- Yoga figure icon, size 60pt
- Floating animation: gentle 8px up/down movement over 2.5s
- Gradient: Blue to Green

**Title Section:**
- Large Title typography (28pt Bold Rounded)
- Dynamic text:
  - Sign Up: "Create your account to discover Vancouver's best hobby classes"
  - Sign In: "Welcome back! Let's find your next creative adventure"
- Secondary color

**Form Fields:**
- Corner radius: md (12px)
- Padding: 16px
- Background: White with 95% opacity (glassmorphic)
- Icon on left (24px width fixed)
- Icons: person.circle.fill, envelope.fill, lock.fill
- Icon color: BrandPrimary

**Primary Button (Sign In/Create Account):**
- Full width with 16px horizontal padding
- Height: 54px minimum
- Background: BrandPrimary gradient
- Text: White, Semibold
- Corner radius: lg (20px)
- Shadow: Primary color at 30% opacity, 8px radius
- Icon: arrow.right.circle.fill (trailing)
- Disabled state: Gray gradient

**Secondary Buttons (Face ID, Apple Sign In):**
- Full width with 16px horizontal padding
- Height: 54px minimum
- Background: White with 95% opacity
- Border: 2px BrandPrimary
- Text: BrandPrimary, Semibold
- Corner radius: lg (20px)
- Icons: faceid, apple.logo

**Toggle Button (Switch Sign Up/Sign In):**
- Text button style
- Underline decoration
- Teal color
- Caption typography

**Validation Messages:**
- Small inline indicators
- Orange color for warnings
- Icon: exclamationmark.triangle.fill
- Caption typography
- Appear with fade-in animation

---

### 2. Onboarding Flow Redesign (6 Steps)

#### Step 0: Welcome
```
┌─────────────────────────────────────┐
│  Gradient Background                │
│  ┌───────────────────────────────┐  │
│  │  Progress Dots (1/6 filled)   │  │
│  │  ● ○ ○ ○ ○ ○                  │  │
│  └───────────────────────────────┘  │
│                                     │
│  Large Floating Icon                │
│  (Vancouver landmark illustration)  │
│                                     │
│  "Welcome to HobbyApp!"             │
│  (Hero Title typography)            │
│                                     │
│  "Discover Vancouver's most         │
│  creative hobby classes..."         │
│  (Body typography, secondary)       │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Speech Bubble               │   │
│  │ "Let's personalize your     │   │
│  │  Vancouver experience!"     │   │
│  └─────────────────────────────┘   │
│                                     │
│  [Primary Gradient Button]          │
│  Get Started                        │
└─────────────────────────────────────┘
```

#### Step 1: Profile Setup
```
┌─────────────────────────────────────┐
│  Progress: ● ● ○ ○ ○ ○              │
│                                     │
│  "Tell us about yourself"           │
│  (Title typography)                 │
│                                     │
│  "Help us personalize your          │
│   Vancouver creative class..."      │
│  (Subheadline, secondary)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Glassmorphic Card            │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ Avatar Upload Circle    │  │  │
│  │  │ (with camera icon)      │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  │  [Input: Full Name]           │  │
│  │  [Input: Preferred Name]      │  │
│  │  [Picker: Pronouns]           │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Back] [Next →]                    │
└─────────────────────────────────────┘
```

#### Step 2: Interests Selection
```
┌─────────────────────────────────────┐
│  Progress: ● ● ● ○ ○ ○              │
│                                     │
│  "What interests you?"              │
│  (Title typography)                 │
│                                     │
│  "Select all that apply"            │
│  (Subheadline, secondary)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Glassmorphic Card            │  │
│  │                               │  │
│  │  Tag Grid (multi-select):     │  │
│  │  ┌────────┐ ┌────────┐       │  │
│  │  │Pottery │ │Painting│       │  │
│  │  └────────┘ └────────┘       │  │
│  │  ┌────────┐ ┌────────┐       │  │
│  │  │Cooking │ │  Yoga  │       │  │
│  │  └────────┘ └────────┘       │  │
│  │  ┌────────┐ ┌────────┐       │  │
│  │  │  Dance │ │Woodwork│       │  │
│  │  └────────┘ └────────┘       │  │
│  │                               │  │
│  │  Selected: BrandCoral bg      │  │
│  │  Unselected: White outline    │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Back] [Skip] [Next →]             │
└─────────────────────────────────────┘
```

#### Step 3: Neighborhood Selection
```
┌─────────────────────────────────────┐
│  Progress: ● ● ● ● ○ ○              │
│                                     │
│  "Where in Vancouver are you?"      │
│  (Title typography)                 │
│                                     │
│  "Find classes near you"            │
│  (Subheadline, secondary)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Glassmorphic Card            │  │
│  │                               │  │
│  │  📍 Current Location Button   │  │
│  │  (BrandTeal accent)           │  │
│  │                               │  │
│  │  Or choose neighborhood:      │  │
│  │                               │  │
│  │  [ ] Downtown                 │  │
│  │  [ ] Kitsilano                │  │
│  │  [ ] Gastown                  │  │
│  │  [ ] Mount Pleasant           │  │
│  │  [ ] Commercial Drive         │  │
│  │  [ ] West End                 │  │
│  │                               │  │
│  │  Selected: BrandTeal bg       │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Back] [Skip] [Next →]             │
└─────────────────────────────────────┘
```

#### Step 4: Class Preferences
```
┌─────────────────────────────────────┐
│  Progress: ● ● ● ● ● ○              │
│                                     │
│  "What's your learning style?"      │
│  (Title typography)                 │
│                                     │
│  "Help us recommend the right       │
│   classes for you"                  │
│  (Subheadline, secondary)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Glassmorphic Card            │  │
│  │                               │  │
│  │  Experience Level:            │  │
│  │  ◉ Beginner                   │  │
│  │  ○ Intermediate               │  │
│  │  ○ Advanced                   │  │
│  │                               │  │
│  │  Class Size Preference:       │  │
│  │  ◉ Small groups (≤8)          │  │
│  │  ○ Medium (9-15)              │  │
│  │  ○ Large (16+)                │  │
│  │                               │  │
│  │  Time Preference:             │  │
│  │  ☐ Weekday mornings           │  │
│  │  ☐ Weekday evenings           │  │
│  │  ☑ Weekends                   │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Back] [Skip] [Next →]             │
└─────────────────────────────────────┘
```

#### Step 5: Payment Setup (Optional)
```
┌─────────────────────────────────────┐
│  Progress: ● ● ● ● ● ●              │
│                                     │
│  "Get your first credits!"          │
│  (Title typography)                 │
│                                     │
│  "Book classes with credit packs"   │
│  (Subheadline, secondary)           │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Glassmorphic Card            │  │
│  │                               │  │
│  │  Credit Pack Options:         │  │
│  │                               │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ Starter Pack            │  │  │
│  │  │ 15 credits - $25        │  │  │
│  │  │ Perfect for trying out  │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ Popular Pack  ⭐        │  │  │
│  │  │ 35 credits - $50        │  │  │
│  │  │ Best value - save 20%   │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ Enthusiast Pack         │  │  │
│  │  │ 75 credits - $90        │  │  │
│  │  │ For the committed       │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  │   Pay Button                │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Back] [Skip for now] [Purchase]   │
└─────────────────────────────────────┘
```

#### Step 6: Completion
```
┌─────────────────────────────────────┐
│  Gradient Background                │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Success Animation          │   │
│  │  (checkmark with confetti)  │   │
│  └─────────────────────────────┘   │
│                                     │
│  "You're all set!"                  │
│  (Hero Title typography)            │
│                                     │
│  "Start exploring Vancouver's       │
│   creative community"               │
│  (Body typography, secondary)       │
│                                     │
│  Summary Card:                      │
│  ┌───────────────────────────────┐  │
│  │  ✓ Profile created            │  │
│  │  ✓ 3 interests selected       │  │
│  │  ✓ Kitsilano neighborhood    │  │
│  │  ✓ 35 credits purchased      │  │
│  └───────────────────────────────┘  │
│                                     │
│  [Primary Gradient Button]          │
│  Start Exploring →                  │
└─────────────────────────────────────┘
```

---

## Component Library Needed

### 1. Category Tag Component
```swift
struct CategoryTag {
    - Text label
    - Selected state
    - Colors:
      - Selected: BrandCoral background, White text
      - Unselected: White background, Primary text, Primary border
    - Corner radius: full (pill shape)
    - Padding: 12px horizontal, 8px vertical
    - Tap animation: scale 0.95 on press
}
```

### 2. Progress Indicator
```swift
struct OnboardingProgressDots {
    - 6 dots horizontal
    - Active: BrandCoral, scale 1.2
    - Inactive: Gray opacity 0.3, scale 1.0
    - Spacing: 8px
    - Spring animation on step change
}
```

### 3. Glassmorphic Input Field
```swift
struct BrandedTextField {
    - Icon (optional, left aligned)
    - Placeholder text
    - Background: White 95% opacity
    - Corner radius: md (12px)
    - Padding: 16px
    - Border: None or subtle Primary on focus
    - Shadow: Subtle depth effect
}
```

### 4. Navigation Controls
```swift
struct OnboardingNavigation {
    - Back button: Text button, Secondary color
    - Skip button: Text button, Teal color
    - Next button: Primary gradient button with arrow
    - Layout: [Back] [Spacer] [Skip] [Next →]
}
```

---

## Interaction & Animation Patterns

### Screen Transitions
- Page changes: Horizontal slide with 0.3s ease
- Step forward: Slide from right
- Step backward: Slide from left
- Spring animation for all transitions

### Button States
- Default: Full opacity
- Pressed: Scale 0.95, spring animation
- Disabled: 50% opacity, gray colors
- Loading: Spinner replaces icon

### Input Focus
- Unfocused: Subtle shadow
- Focused: Primary color border appears
- Transition: 0.15s ease

### Tag Selection
- Tap: Scale 0.95 → 1.0
- Color change: 0.2s ease
- Multiple selection: Stagger animation by 50ms

---

## Technical Requirements

### Files to Modify/Create
1. **LoginView.swift** - Apply brand design system
2. **Views/Onboarding/EnhancedOnboardingFlow.swift** - Extract and modernize
3. **Views/Components/CategoryTag.swift** - New reusable component
4. **Views/Components/OnboardingCard.swift** - New glassmorphic wrapper
5. **Views/Components/BrandedTextField.swift** - Branded input field

### Preserve Existing Functionality
- ✅ Supabase authentication integration
- ✅ Apple Sign In
- ✅ Face ID/Touch ID biometric auth
- ✅ Email/password auth
- ✅ Password reset flow
- ✅ Form validation
- ✅ Onboarding preferences saved to Supabase
- ✅ Skip functionality for optional steps
- ✅ Progress tracking

### Success Criteria
- [ ] Visual consistency with WelcomeLandingView
- [ ] All authentication methods working
- [ ] Smooth transitions between all screens
- [ ] Glassmorphic effects applied throughout
- [ ] Brand colors used consistently
- [ ] Animations match design system
- [ ] No functionality regressions
- [ ] Vancouver-focused copy maintained

---

## Implementation Priority
1. **Phase 1**: Extract EnhancedOnboardingFlow to separate file
2. **Phase 2**: Modernize LoginView with brand system
3. **Phase 3**: Apply branding to onboarding steps 0-3
4. **Phase 4**: Apply branding to onboarding steps 4-6
5. **Phase 5**: Polish animations and transitions
6. **Phase 6**: End-to-end testing of complete flow

---

*This design brief is ready for implementation with Kombai or manual SwiftUI development.*
