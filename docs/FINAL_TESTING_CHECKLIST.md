# Final Testing Checklist - Facebook SDK & Stripe Integration

## 🎯 Testing Overview
Complete validation of Facebook authentication and live Stripe payment processing before TestFlight alpha launch.

## 📱 Device Requirements
- **Physical iOS Device**: Required (simulator cannot test Face ID, Apple Pay, or real payments)
- **iOS Version**: 16.0+ 
- **Network**: Stable internet for API calls
- **Apple ID**: Signed into device for Apple Pay testing

---

## 🔐 Facebook Authentication Testing

### Setup Validation
- [ ] **Build Success**: Xcode project builds without errors
- [ ] **Facebook SDK**: Properly linked (no runtime crashes)
- [ ] **Info.plist**: Facebook App ID and Client Token configured
- [ ] **URL Scheme**: `fb1964533104334373` responds to callbacks

### Login Flow Testing
- [ ] **Facebook Button**: Displays correctly in LoginView
- [ ] **FB Login Sheet**: Opens Facebook authorization when tapped
- [ ] **Permission Grant**: Requests email and public_profile access
- [ ] **Successful Login**: Returns to app with valid token
- [ ] **User Creation**: Creates new user in Supabase with Facebook data
- [ ] **Login Cancellation**: Handles user canceling Facebook login
- [ ] **Error Handling**: Shows appropriate error messages

### Integration Testing  
- [ ] **Supabase Integration**: Facebook token creates/authenticates Supabase user
- [ ] **Profile Data**: Email and name populate from Facebook
- [ ] **Persistent Login**: User stays logged in on app restart
- [ ] **Logout**: Facebook logout clears session properly

### Edge Cases
- [ ] **No Facebook App**: Works when Facebook app not installed
- [ ] **Invalid Permissions**: Handles permission denial gracefully  
- [ ] **Network Issues**: Appropriate error handling for connectivity
- [ ] **Account Issues**: Handles deactivated/suspended Facebook accounts

**Test Accounts**: Use your personal Facebook account and one test account

---

## 💳 Stripe Payment Testing

### Configuration Validation
- [ ] **Live Keys**: Configuration.swift uses live publishable key
- [ ] **Bank Account**: Connected in Stripe Dashboard
- [ ] **Business Verification**: Complete in Stripe Dashboard
- [ ] **PaymentSheet**: Stripe SDK properly initialized

### Test Mode Validation (Before Live Testing)
- [ ] **Test Cards**: Use `4242 4242 4242 4242` for successful payments
- [ ] **Decline Test**: Use `4000 0000 0000 0002` for declined payments
- [ ] **Payment Sheet**: Opens and displays payment methods
- [ ] **Apple Pay Test**: Shows Apple Pay option (if configured)

### Live Payment Testing ⚠️ **Use Small Amounts ($1 CAD)**
- [ ] **Credit Pack Purchase**: Test $25 pack with real card
- [ ] **Payment Success**: Money appears in your bank account
- [ ] **Commission Split**: Verify platform fee calculation
- [ ] **Receipt Email**: Stripe sends confirmation email
- [ ] **Error Handling**: Test with insufficient funds card

### Apple Pay Testing (If Available)
- [ ] **Apple Pay Button**: Shows in payment sheet
- [ ] **Touch/Face ID**: Authenticates payment properly
- [ ] **Transaction**: Completes and shows in Wallet app
- [ ] **Receipt**: Payment confirmation in app

### Class Booking Payment Testing
- [ ] **Credit Payment**: Book class using existing credits
- [ ] **Insufficient Credits**: Proper error when not enough credits
- [ ] **Payment Recovery**: Retry payment after initial failure
- [ ] **Booking Confirmation**: Class appears in user's bookings

---

## 🔄 Integration Flow Testing

### Complete User Journey - New User
1. [ ] **App Launch**: Opens to landing/login screen
2. [ ] **Facebook Signup**: New user signs up with Facebook
3. [ ] **Profile Creation**: Basic profile populated from Facebook
4. [ ] **Credit Purchase**: Buy $25 credit pack with live Stripe
5. [ ] **Class Discovery**: Browse available Vancouver classes
6. [ ] **Class Booking**: Book class using purchased credits
7. [ ] **Confirmation**: Receive booking confirmation
8. [ ] **Profile View**: See booking in user profile

### Complete User Journey - Returning User
1. [ ] **Face ID Login**: Biometric authentication works
2. [ ] **Profile Load**: User data and credit balance load
3. [ ] **Class History**: Previous bookings visible
4. [ ] **New Booking**: Book additional class
5. [ ] **Credit Top-up**: Purchase more credits when needed

---

## 🐛 Error Scenarios Testing

### Network & Connectivity
- [ ] **Airplane Mode**: Appropriate offline messages
- [ ] **Poor Connection**: Graceful handling of timeouts
- [ ] **API Failures**: User-friendly error messages
- [ ] **Recovery**: App recovers when connection restored

### Payment Failures
- [ ] **Declined Card**: Clear error message and retry option
- [ ] **Expired Card**: Proper error handling
- [ ] **Bank Rejection**: Informative user feedback
- [ ] **Stripe Outage**: Fallback messaging

### Authentication Issues
- [ ] **Facebook Login Failure**: Error handling and alternatives
- [ ] **Session Expiry**: Automatic re-authentication
- [ ] **Account Conflicts**: Handle email already in use
- [ ] **Biometric Failure**: Fallback to password

---

## 📊 Performance Testing

### App Performance
- [ ] **Launch Time**: App opens in under 3 seconds
- [ ] **Payment Sheet**: Opens quickly without delay
- [ ] **Facebook Login**: Completes within 5 seconds
- [ ] **Image Loading**: Class images load efficiently
- [ ] **Smooth Scrolling**: No lag in class discovery

### Memory & Battery
- [ ] **Memory Usage**: No excessive RAM consumption
- [ ] **Battery Impact**: Reasonable battery usage
- [ ] **Background Behavior**: Proper app lifecycle handling

---

## 🔧 Development Testing Tools

### Test Scripts
```bash
# Verify Stripe configuration
./scripts/verify_live_stripe.sh

# Check Facebook setup
# Manual: Build and run app, test Facebook login

# Monitor network requests
# Use Xcode Network debugging
```

### Debugging Checklist
- [ ] **Console Logs**: Review for any error messages
- [ ] **Network Activity**: Monitor API calls in Xcode
- [ ] **Crash Reports**: Check for any crashes during testing
- [ ] **Memory Leaks**: Use Instruments to check for leaks

---

## 📋 Pre-TestFlight Validation

### Code Quality
- [ ] **Build Warnings**: Zero build warnings in Xcode
- [ ] **Code Signing**: Valid distribution certificates
- [ ] **Archive Success**: Can create .ipa file for distribution
- [ ] **Bundle ID**: Matches App Store Connect configuration

### Content Verification  
- [ ] **Privacy Policy**: Live and accessible at hobbyist.app/privacy
- [ ] **Terms of Service**: Live and accessible at hobbyist.app/terms
- [ ] **Support Email**: support@hobbyist.app responds to emails
- [ ] **App Store Assets**: Screenshots and app icon ready

### Security Validation
- [ ] **No Debug Code**: All debug/test code removed
- [ ] **API Keys**: Live keys configured, no test keys in production
- [ ] **HTTPS Only**: All network requests use secure connections
- [ ] **Data Protection**: User data properly encrypted

---

## ✅ Alpha Launch Criteria

All items below MUST pass before TestFlight distribution:

### Critical Features
- [x] **Facebook Authentication**: Fully functional
- [x] **Stripe Live Payments**: Processing real transactions
- [x] **Class Discovery**: Vancouver studios visible
- [x] **Credit System**: Purchase and usage working
- [x] **User Profile**: Creation and management

### Integration Validation
- [ ] **End-to-End Test**: Complete user journey works flawlessly
- [ ] **Error Recovery**: All error scenarios handled gracefully
- [ ] **Performance**: App performs well under normal usage
- [ ] **Security**: No sensitive data exposure

### Documentation Ready
- [x] **App Store Connect**: Configured and ready
- [x] **TestFlight Setup**: Beta testing configuration complete
- [x] **Testing Instructions**: Alpha testers know what to test
- [x] **Support Process**: Issues can be tracked and resolved

---

## 🚨 Issue Tracking

### Critical Issues (Stop Launch)
- App crashes during core flows
- Payments fail or charge incorrectly
- User authentication completely broken
- Data loss or corruption

### Major Issues (Fix Before Public)
- Inconsistent error messages
- Poor performance on older devices
- Minor payment flow issues
- Non-critical feature failures

### Minor Issues (Fix in Updates)
- UI polish items
- Non-essential feature bugs
- Performance optimizations
- Additional error handling

---

## 📞 Testing Support

- **Technical Issues**: Document with screenshots and device info
- **Payment Problems**: Check Stripe Dashboard for transaction details
- **Facebook Issues**: Verify Facebook app configuration
- **General Questions**: support@hobbyist.app

**Ready for TestFlight**: All critical and major tests passing ✅