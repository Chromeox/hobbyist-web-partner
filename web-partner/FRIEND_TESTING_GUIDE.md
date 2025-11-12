# Friend Testing Guide - Partner Portal

**Testing Date**: Week of 2025-11-11
**Version**: Alpha v0.9
**Purpose**: Validate UX, identify critical issues, gather feature feedback

---

## 🎯 What We're Testing

This is an **alpha test** to validate:
1. **User experience** - Is the flow intuitive?
2. **Visual design** - Does it look professional?
3. **Mobile/tablet** - Does it work on iPads (primary studio device)?
4. **Feature priorities** - What do real studios actually need?

---

## ✅ What's REAL (Actually Works)

### Authentication ✅
- **Email/password** sign up and sign in
- **Google OAuth** sign in
- **Password reset** (via email link)
- Session management and auto-login

### Dashboard Overview ✅
- **Real metrics** from your account
- **Activity feed** shows actual events
- **Navigation** to all sections works

### Classes Management ✅
- **View classes** from database
- **Edit class details** (name, description, pricing)
- **Schedule management** basic functionality
- **Instructor assignment** to classes

### Stripe Integration ✅
- **Connect account** setup flow
- **Payment tracking** (just implemented!)
- **Payout visibility** in dashboard
- **Commission calculations** (30% platform / 70% you)

### Onboarding ✅
- **Studio profile** creation
- **Business details** collection
- **Stripe Connect** onboarding
- **Account approval** workflow

---

## ⚠️ What's MOCK DATA (Not Real Yet)

### Students Section 🎭
**What you'll see**: 3 hardcoded students (Emma Thompson, Michael Chen, Sarah Johnson)

**Reality**: Student management not connected to real database yet

**For testing**: Pretend these are real students, test the UI/UX

---

### Analytics Dashboard 📊
**What you'll see**: Beautiful charts showing revenue forecasts, customer segments, predictions

**Reality**: 100% mock data with fake numbers

**For testing**: Evaluate if these analytics would be useful *if* they were real

---

### Marketing Campaigns 📧
**What you'll see**: Full campaign creation interface with email/SMS options

**Reality**: No actual email/SMS integration yet

**For testing**: Assess if you'd use this feature, what's missing

---

### Reservations Management 📅
**What you'll see**: List of bookings with refund/message buttons

**Reality**: Displays mock data, refund processing not implemented

**For testing**: Check if the workflow makes sense, what info is missing

---

### Subscriptions 💳
**What you'll see**: "Coming Soon" page with planned features

**Reality**: Not built at all

**For testing**: Read the features listed, tell us priority ranking

---

### Settings ⚙️
**What you'll see**: "Settings management coming soon..."

**Reality**: Placeholder text only

**For testing**: Think about what settings you'd expect to configure

---

## 📱 Testing Checklist

### Pre-Testing Setup

1. **Create account**:
   - Go to: https://your-deployment-url.vercel.app/auth/signup
   - Use real email (you'll get password reset emails)
   - Choose studio/instructor role

2. **Complete onboarding**:
   - Fill out studio profile
   - Add business details
   - Connect Stripe (test mode is fine)
   - Wait for approval (may be instant for testing)

3. **Access dashboard**:
   - Should redirect automatically after approval
   - See dashboard overview with your studio name

### Core Flows to Test

#### Flow 1: Authentication Journey (5 min)
- [ ] Sign up with email/password
- [ ] Log out
- [ ] Sign in again
- [ ] Test "Forgot Password" flow
- [ ] Try Google sign-in (if you have Gmail)

**Feedback**: Was this smooth? Any confusing steps?

---

#### Flow 2: Dashboard Navigation (5 min)
- [ ] Click through all sidebar menu items
- [ ] Check if pages load without errors
- [ ] Note which sections have "Coming Soon"
- [ ] Try mobile/tablet view (resize browser or use device)

**Feedback**: Easy to find things? Any broken links?

---

#### Flow 3: Class Management (10 min)
- [ ] View list of classes (should see Vancouver demo data)
- [ ] Click "Edit" on a class
- [ ] Change class details
- [ ] Save changes
- [ ] Verify changes persisted

**Feedback**: Is editing intuitive? What's missing?

---

#### Flow 4: Stripe Onboarding (10 min)
- [ ] If not done, click "Connect Stripe"
- [ ] Complete Stripe Express onboarding
- [ ] Return to dashboard
- [ ] Check if "Stripe Connected" status shows

**Feedback**: Was Stripe setup clear? Any roadblocks?

---

#### Flow 5: Mobile/Tablet Experience (10 min)
**Critical** - Studios primarily use iPads

- [ ] Open on iPad or tablet
- [ ] Navigate dashboard
- [ ] Try editing a class
- [ ] Check if modals display properly
- [ ] Test scrolling and touch interactions

**Feedback**: Does it feel native? Any broken layouts?

---

#### Flow 6: Analytics Exploration (5 min)
**Remember**: All data is fake

- [ ] Click "Analytics" in sidebar
- [ ] Review charts and metrics
- [ ] Look at customer segments
- [ ] Check revenue forecasts

**Feedback**: IF this data were real, would it be useful? What's missing?

---

#### Flow 7: Feature Discovery (10 min)
Click through all menu items:

- [ ] Dashboard
- [ ] Classes
- [ ] Reservations (mock data)
- [ ] Students (3 fake students)
- [ ] Instructors
- [ ] Analytics (fake charts)
- [ ] Marketing (no backend)
- [ ] Revenue
- [ ] Reviews
- [ ] Payouts
- [ ] Settings (placeholder)
- [ ] Subscriptions (coming soon)

**Feedback**: Which features seem most valuable? Anything surprising?

---

## 🗣️ Feedback Collection

### Critical Questions

**1. First Impressions (30 seconds)**:
- Professional or amateur?
- Trustworthy enough to enter payment info?
- Clear what the platform does?

**2. Navigation & UX**:
- Could you find everything you needed?
- Any confusing terminology?
- Where did you get stuck or lost?

**3. Visual Design**:
- Does it look modern and polished?
- Any ugly pages or broken layouts?
- Color scheme appropriate for studios?

**4. Mobile/Tablet Experience**:
- Would you use this on an iPad at the studio?
- Any dealbreaker issues on mobile?
- Touch targets too small?

**5. Feature Priorities** (Rank 1-5):
- Real student management
- Real analytics dashboard
- Marketing/email campaigns
- Subscription management
- Advanced scheduling tools

**6. Missing Features**:
- What's the #1 thing you expected but didn't see?
- What would make you switch from your current system?
- Any features that seem unnecessary?

**7. Pain Points**:
- Anything that would prevent you from using this?
- Features that seem half-baked?
- Critical bugs encountered?

**8. Pricing Expectations**:
- 30% commission (70% to you) - Fair or too high?
- Would you pay this vs Mindbody/ClassPass?
- At what price point would you definitely use this?

---

## 🐛 Bug Reporting

**If something breaks**:

1. **Take a screenshot**
2. **Note exact steps** to reproduce
3. **Check browser console** (F12 → Console tab)
4. **Copy any error messages**
5. **Note your device/browser** (iPad Safari, Chrome Desktop, etc.)

**Send to**:
- Email: [your-email]
- Share screenshots: [method]
- Or just text me!

---

## 📊 Known Limitations

### Don't Report These (We Know!)

- ❌ Only 3 students show (Emma, Michael, Sarah) → *Feature not built yet*
- ❌ Analytics show fake data → *Not connected to real data*
- ❌ Marketing campaigns don't send → *No email provider yet*
- ❌ Reservations don't process refunds → *Backend incomplete*
- ❌ Subscriptions page is "Coming Soon" → *Not started*
- ❌ Settings page is empty → *Not implemented*
- ❌ Some pages say "Q2 2024" → *Timeline placeholder*

### DO Report These

- ✅ Anything that prevents core workflows
- ✅ Broken authentication or login issues
- ✅ Can't connect Stripe
- ✅ Pages that won't load
- ✅ Mobile layout completely broken
- ✅ Data that disappears after refresh
- ✅ Error messages that block progress

---

## 🎁 Thank You Gifts

For completing testing:

- **Early access** to platform when it launches
- **Discounted commission** (25% instead of 30%) for first 6 months
- **Priority support** during launch
- **Free feature requests** (within reason!)
- **Your name in credits** (if you want)

---

## 📅 Timeline

### This Week (Friend Testing)
- Test current alpha with mock data
- Collect UX feedback
- Identify critical issues
- Prioritize feature requests

### Next 2-3 Weeks
- Fix critical bugs from testing
- Implement top 3 requested features
- Connect real student management
- Polish mobile experience

### 1-2 Months
- Build out analytics with real data
- Add marketing integrations (email/SMS)
- Implement subscription system
- Prepare for beta launch

---

## 💬 Feedback Submission

**Option 1: Structured Form**
[Google Form Link] - Preferred, easiest to organize

**Option 2: Email**
Send detailed feedback to: [your-email]

**Option 3: Call/Video**
Schedule 30-min session: [Calendly link]

**Option 4: Text/DM**
Quick thoughts: [phone/social]

---

## 🙏 Thank You!

Your feedback is invaluable. We're building this FOR studios, not just for them. Your input directly shapes what gets built next.

**Remember**:
- No feedback is too harsh
- Be honest about what sucks
- Tell us what you love too!
- This is raw/unpolished on purpose
- Your time testing means everything

---

## 📞 Emergency Contact

If you're totally blocked or find a critical bug:

**Call/Text**: [phone]
**Email**: [your-email]
**Available**: 9am-9pm PST daily

---

**Happy Testing!** 🚀

Let us know what you think. And remember - we WANT critical feedback. That's the whole point!
