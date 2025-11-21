# Web Partner Portal - Testing Checklist

**Date**: 2025-11-21
**Commits Synced**: 4 commits pushed to main
**Testing Environment**: Production (https://hobbyist-partner-portal.vercel.app)

---

## 📋 Task 1.4: End-to-End Testing (Web Partner)

### ✅ Pre-Testing Setup
- [x] Commits synced to GitHub (4 commits including gitignore fix)
- [x] Removed sensitive `.env.vercel.pulled` from git history
- [ ] Verify Vercel deployment is live
- [ ] Check environment variables are set in Vercel
- [ ] Confirm Supabase connection is working

---

## 🎯 Test 1: New Studio Onboarding

### Test Objectives
- Verify complete onboarding flow from start to finish
- Test all form validations
- Ensure data persistence between steps
- Verify file uploads (verification documents & studio photos)
- Confirm Stripe Connect integration
- Test submission and account creation

### Test Steps

#### Step 1: Access Onboarding
- [ ] Navigate to `/onboarding` route
- [ ] Verify onboarding wizard loads
- [ ] Check progress indicator displays correctly
- [ ] Confirm all 7 steps are visible

#### Step 2: Business Information
- [ ] Fill in business name
- [ ] Enter legal business name
- [ ] Add business email
- [ ] Add phone number
- [ ] Select business type (dropdown)
- [ ] Test form validation (required fields)
- [ ] Click "Next" to proceed
- [ ] Verify data persists if navigating back

#### Step 3: Address & Location
- [ ] Enter street address
- [ ] Enter city
- [ ] Select state/province
- [ ] Enter postal code
- [ ] Select country
- [ ] Test address validation
- [ ] Verify geolocation (if implemented)
- [ ] Click "Next"

#### Step 4: Verification (File Upload)
- [ ] Upload verification document (PDF/Image)
- [ ] Verify file size validation
- [ ] Verify file type validation
- [ ] Check upload progress indicator
- [ ] Confirm file preview displays
- [ ] Test file removal/replacement
- [ ] Verify Supabase Storage upload
- [ ] Check database URL persistence
- [ ] Click "Next"

#### Step 5: Studio Profile
- [ ] Enter studio name
- [ ] Write studio description
- [ ] Upload studio photos (multiple)
- [ ] Verify photo upload to Supabase Storage
- [ ] Test photo preview gallery
- [ ] Add amenities/features
- [ ] Set operating hours
- [ ] Click "Next"

#### Step 6: Payment Setup (Optional Path)
- [ ] **Option A: Skip Payment Setup**
  - [ ] Click "Skip for now" button
  - [ ] Verify can proceed without Stripe
  - [ ] Confirm account created without payment method
- [ ] **Option B: Complete Stripe Connect**
  - [ ] Click "Connect with Stripe"
  - [ ] Verify redirect to Stripe Connect
  - [ ] Complete Stripe onboarding
  - [ ] Verify return to portal
  - [ ] Confirm Stripe account linked
  - [ ] Check database for Stripe account ID

#### Step 7: Review & Submit
- [ ] Review all entered information
- [ ] Verify all data displays correctly
- [ ] Check file uploads are shown
- [ ] Click "Submit Application"
- [ ] Verify loading state
- [ ] Confirm success message
- [ ] Check redirect to dashboard
- [ ] Verify account created in database

### Expected Results
- ✅ All form validations work correctly
- ✅ File uploads succeed to Supabase Storage
- ✅ Data persists between steps
- ✅ Can skip payment setup
- ✅ Can complete payment setup
- ✅ Account created successfully
- ✅ Redirected to dashboard after submission

### Known Issues
- Document any issues found during testing

---

## 🎯 Test 2: Payment Setup (Optional Path)

### Test Objectives
- Verify Stripe Connect integration
- Test optional vs required payment setup
- Confirm account linking
- Verify webhook handling

### Test Scenarios

#### Scenario A: Skip Payment During Onboarding
- [ ] Start new onboarding flow
- [ ] Complete all steps except payment
- [ ] Click "Skip for now" on payment step
- [ ] Verify account created without Stripe
- [ ] Check dashboard access granted
- [ ] Verify payment setup can be completed later

#### Scenario B: Complete Payment During Onboarding
- [ ] Start new onboarding flow
- [ ] Reach payment setup step
- [ ] Click "Connect with Stripe"
- [ ] Complete Stripe Connect flow
- [ ] Verify return URL works
- [ ] Check Stripe account ID saved
- [ ] Confirm payment features enabled

#### Scenario C: Add Payment After Onboarding
- [ ] Login to account without payment setup
- [ ] Navigate to Settings > Payment
- [ ] Click "Connect Stripe Account"
- [ ] Complete Stripe Connect
- [ ] Verify account linked
- [ ] Check payment features now available

### Expected Results
- ✅ Can skip payment setup during onboarding
- ✅ Can complete payment setup during onboarding
- ✅ Can add payment method later
- ✅ Stripe Connect flow works correctly
- ✅ Account IDs saved properly
- ✅ Features enabled/disabled based on payment status

---

## 🎯 Test 3: Dashboard Navigation

### Test Objectives
- Verify all dashboard routes work
- Test navigation between pages
- Confirm data loads correctly
- Check responsive design
- Test quick actions

### Dashboard Pages to Test

#### 1. Dashboard Overview
- [ ] Navigate to `/dashboard`
- [ ] Verify all metric cards display
- [ ] Check revenue charts load
- [ ] Test quick action cards
- [ ] Verify navigation from quick actions
- [ ] Check responsive layout (mobile/tablet/desktop)

#### 2. Reservations Management
- [ ] Navigate to `/dashboard/reservations`
- [ ] Verify reservation list loads
- [ ] Test filtering options
- [ ] Check status updates
- [ ] Test student communication
- [ ] Verify export functionality

#### 3. Class Management
- [ ] Navigate to `/dashboard/classes`
- [ ] Verify class list displays
- [ ] Test "New Class" button
- [ ] Check class editing
- [ ] Test class deletion
- [ ] Verify schedule view

#### 4. Staff Management
- [ ] Navigate to `/dashboard/staff`
- [ ] Verify staff list loads
- [ ] Test "Invite Staff" button
- [ ] Check staff details modal
- [ ] Test permission management
- [ ] Verify performance metrics

#### 5. Students
- [ ] Navigate to `/dashboard/students`
- [ ] Verify student list loads
- [ ] Test search functionality
- [ ] Check student profiles
- [ ] Verify credit balances
- [ ] Test communication tools

#### 6. Revenue
- [ ] Navigate to `/dashboard/revenue`
- [ ] Verify revenue charts load
- [ ] Test date range filters
- [ ] Check export reports
- [ ] Verify payment breakdown
- [ ] Test commission calculations

#### 7. Locations
- [ ] Navigate to `/dashboard/locations`
- [ ] Verify location list
- [ ] Test add location
- [ ] Check location editing
- [ ] Verify map integration (if implemented)

#### 8. Reviews
- [ ] Navigate to `/dashboard/reviews`
- [ ] Verify review list loads
- [ ] Test filtering by rating
- [ ] Check response functionality
- [ ] Verify review analytics

#### 9. Payouts
- [ ] Navigate to `/dashboard/payouts`
- [ ] Verify payout history
- [ ] Check pending payouts
- [ ] Test payout details
- [ ] Verify Stripe integration

#### 10. Waitlist
- [ ] Navigate to `/dashboard/waitlist`
- [ ] Verify waitlist queue
- [ ] Test auto-promotion
- [ ] Check notification settings
- [ ] Verify analytics

#### 11. Marketing
- [ ] Navigate to `/dashboard/marketing`
- [ ] Verify campaign list
- [ ] Test create campaign
- [ ] Check email templates
- [ ] Verify analytics

#### 12. Settings
- [ ] Navigate to `/dashboard/settings`
- [ ] Verify all settings tabs
- [ ] Test profile updates
- [ ] Check payment settings
- [ ] Verify notification preferences

### Navigation Tests
- [ ] Test sidebar navigation
- [ ] Verify breadcrumbs
- [ ] Check back button behavior
- [ ] Test deep linking (direct URL access)
- [ ] Verify session persistence

### Expected Results
- ✅ All routes load without errors
- ✅ Navigation works smoothly
- ✅ Data displays correctly
- ✅ No console errors
- ✅ Responsive design works
- ✅ Session maintained during navigation

---

## 🎯 Test 4: Password Reset

### Test Objectives
- Verify password reset flow
- Test email delivery
- Confirm token validation
- Test password update

### Test Steps

#### Step 1: Request Password Reset
- [ ] Navigate to login page
- [ ] Click "Forgot Password?"
- [ ] Enter email address
- [ ] Click "Send Reset Link"
- [ ] Verify success message
- [ ] Check email delivery

#### Step 2: Email Verification
- [ ] Open password reset email
- [ ] Verify email formatting
- [ ] Check reset link is present
- [ ] Verify link is clickable
- [ ] Check email sender details

#### Step 3: Reset Password
- [ ] Click reset link in email
- [ ] Verify redirect to reset page
- [ ] Check token validation
- [ ] Enter new password
- [ ] Confirm new password
- [ ] Test password strength validation
- [ ] Click "Reset Password"
- [ ] Verify success message

#### Step 4: Login with New Password
- [ ] Navigate to login page
- [ ] Enter email
- [ ] Enter new password
- [ ] Click "Sign In"
- [ ] Verify successful login
- [ ] Check redirect to dashboard

### Edge Cases
- [ ] Test expired reset token
- [ ] Test invalid reset token
- [ ] Test password requirements
- [ ] Test rate limiting (multiple requests)
- [ ] Test with non-existent email

### Expected Results
- ✅ Reset email sent successfully
- ✅ Email contains valid reset link
- ✅ Token validation works
- ✅ Password updated successfully
- ✅ Can login with new password
- ✅ Old password no longer works
- ✅ Edge cases handled gracefully

---

## 🔐 Authentication Tests

### Better Auth Integration
- [ ] Test email/password signup
- [ ] Test email/password login
- [ ] Test Google OAuth login
- [ ] Test Apple OAuth login
- [ ] Verify session creation
- [ ] Test session persistence
- [ ] Test logout functionality
- [ ] Verify protected routes

### Session Management
- [ ] Test session timeout
- [ ] Verify session refresh
- [ ] Test concurrent sessions
- [ ] Check session invalidation on logout

---

## 📱 Cross-Browser Testing

### Desktop Browsers
- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

### Mobile Browsers
- [ ] iOS Safari
- [ ] Android Chrome
- [ ] Mobile responsive design

---

## 🐛 Bug Tracking

### Issues Found During Testing

| Issue # | Description | Severity | Status | Notes |
|---------|-------------|----------|--------|-------|
| | | | | |

---

## 📊 Test Results Summary

### Overall Status
- [ ] All tests passed
- [ ] Some tests failed (see issues above)
- [ ] Testing in progress

### Test Coverage
- Onboarding Flow: ____%
- Payment Setup: ____%
- Dashboard Navigation: ____%
- Password Reset: ____%
- Authentication: ____%

### Next Steps
1. Fix any critical issues found
2. Retest failed scenarios
3. Document any workarounds
4. Update user documentation
5. Prepare for iOS testing

---

## 🔗 Related Documentation
- [BUGS.md](./BUGS.md) - Known issues and fixes
- [FEATURE_SUMMARY.md](./FEATURE_SUMMARY.md) - Feature overview
- [FILE_UPLOAD_IMPLEMENTATION.md](./FILE_UPLOAD_IMPLEMENTATION.md) - Upload details
- [PHOTO_UPLOAD_UI_UPDATE.md](./PHOTO_UPLOAD_UI_UPDATE.md) - Photo upload UI
- [test-password-reset.md](./test-password-reset.md) - Password reset details

---

**Testing Notes:**
- Use production environment: https://hobbyist-partner-portal.vercel.app
- Document all issues with screenshots
- Test with real data when possible
- Verify database changes in Supabase
- Check Stripe dashboard for payment events
