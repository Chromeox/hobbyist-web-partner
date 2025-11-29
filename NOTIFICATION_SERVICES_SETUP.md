# Notification Services Setup Guide

This guide covers setting up SendGrid (email), Twilio (SMS), and Apple Push Notifications (APNs) for the HobbiApp Partner Portal.

---

## Quick Start

1. Add environment variables to `.env.local` (see sections below)
2. Verify configuration: `GET /api/notifications/send`
3. Send test notifications using the unified API

---

## 1. SendGrid (Email)

### Get API Key
1. Go to [SendGrid Dashboard](https://app.sendgrid.com/settings/api_keys)
2. Click "Create API Key"
3. Name it "HobbiApp Production"
4. Select "Full Access" or restrict to Mail Send only
5. Copy the key (starts with `SG.`)

### Verify Sender Domain (Required for Production)
1. Go to Settings → Sender Authentication
2. Add your domain (e.g., `hobbiapp.com`)
3. Add the DNS records to your domain provider
4. Wait for verification (usually < 1 hour)

### Environment Variables
```env
SENDGRID_API_KEY=SG.your-api-key-here
SENDGRID_FROM_EMAIL=noreply@hobbiapp.com
SENDGRID_FROM_NAME=Hobbi
```

### Usage
```typescript
import emailService from '@/lib/services/email';

// Send booking confirmation
await emailService.sendBookingConfirmation(
  { email: 'user@example.com', name: 'John' },
  {
    className: 'Morning Yoga',
    instructorName: 'Sarah',
    date: 'Dec 5, 2024',
    time: '9:00 AM',
    location: '123 Main St',
    studioName: 'Zen Studio',
    creditsUsed: 3,
  }
);

// Send marketing campaign
await emailService.sendMarketingCampaign(recipients, {
  subject: '20% Off This Weekend!',
  title: 'Special Holiday Offer',
  body: '<p>Book any class this weekend...</p>',
  ctaText: 'Book Now',
  ctaUrl: 'https://app.hobbiapp.com/classes',
  studioName: 'Your Studio',
  unsubscribeUrl: 'https://app.hobbiapp.com/unsubscribe',
});
```

---

## 2. Twilio (SMS)

### Get Credentials
1. Go to [Twilio Console](https://console.twilio.com)
2. Copy your Account SID and Auth Token from the dashboard
3. Get a phone number: Phone Numbers → Manage → Buy a Number

### Environment Variables
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token-here
TWILIO_PHONE_NUMBER=+1234567890
```

### Usage
```typescript
import smsService from '@/lib/services/sms';

// Send booking confirmation
await smsService.sendBookingConfirmationSMS('+15551234567', {
  className: 'Morning Yoga',
  date: 'Dec 5, 2024',
  time: '9:00 AM',
  studioName: 'Zen Studio',
});

// Send waitlist promotion
await smsService.sendWaitlistPromotionSMS('+15551234567', {
  className: 'Advanced Pilates',
  date: 'Dec 6, 2024',
  time: '6:00 PM',
  expiresIn: '2 hours',
});

// Send bulk SMS
await smsService.sendBulkSMS(
  [{ phone: '+15551234567', name: 'John' }],
  (recipient) => `Hi ${recipient.name}, your class starts in 1 hour!`
);
```

---

## 3. Apple Push Notifications (APNs)

### Get Credentials from Apple Developer Portal
1. Go to [Apple Developer → Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Create a new key with "Apple Push Notifications service (APNs)" enabled
3. Download the `.p8` file (you can only download once!)
4. Note the Key ID shown on the key details page
5. Your Team ID is in Membership Details

### Environment Variables
```env
APNS_KEY_ID=ABC123DEFG
APNS_TEAM_ID=TEAM123456
APNS_BUNDLE_ID=com.hobbi.app
# Paste the contents of your .p8 file (with newlines as \n)
APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...\n-----END PRIVATE KEY-----"
```

### Converting .p8 File to Environment Variable
```bash
# Read .p8 file and convert newlines to \n
cat AuthKey_ABC123DEFG.p8 | awk '{printf "%s\\n", $0}'
```

### Usage
```typescript
import pushService from '@/lib/services/push-notifications';

// Send booking confirmation
await pushService.sendBookingConfirmationPush(deviceToken, {
  className: 'Morning Yoga',
  date: 'Dec 5, 2024',
  time: '9:00 AM',
  bookingId: 'booking-123',
});

// Send waitlist promotion (time-sensitive)
await pushService.sendWaitlistPromotionPush(deviceToken, {
  className: 'Advanced Pilates',
  date: 'Dec 6, 2024',
  time: '6:00 PM',
  expiresIn: '2 hours',
  waitlistId: 'waitlist-456',
});

// Send to multiple devices
await pushService.sendBulkPushNotifications(
  deviceTokens,
  {
    title: 'Class Starting Soon',
    body: 'Your yoga class starts in 30 minutes!',
    sound: 'default',
  }
);

// For development/TestFlight, use sandbox
await pushService.sendBookingConfirmationPush(deviceToken, data, true); // sandbox=true
```

---

## 4. Unified Notifications API

### Check Service Status
```bash
curl https://your-domain.com/api/notifications/send
```

Response:
```json
{
  "services": {
    "email": { "configured": true, "provider": "SendGrid" },
    "sms": { "configured": true, "phoneNumber": "+1 (xxx) xxx-xxxx" },
    "push": { "configured": true, "bundleId": "com.hobbi.app" }
  },
  "availableTemplates": [
    "booking_confirmation",
    "waitlist_promotion",
    "class_reminder",
    "payment_failed",
    "payout_confirmation",
    "new_message",
    "class_cancellation"
  ]
}
```

### Send Notifications
```bash
curl -X POST https://your-domain.com/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "type": "all",
    "template": "booking_confirmation",
    "recipients": [
      {
        "email": "user@example.com",
        "phone": "+15551234567",
        "deviceToken": "abc123...",
        "name": "John"
      }
    ],
    "data": {
      "className": "Morning Yoga",
      "date": "Dec 5, 2024",
      "time": "9:00 AM",
      "studioName": "Zen Studio",
      "location": "123 Main St",
      "instructorName": "Sarah",
      "bookingId": "booking-123"
    }
  }'
```

### Notification Types
- `email` - Send email only
- `sms` - Send SMS only
- `push` - Send push notification only
- `all` - Send to all available channels

---

## 5. Vercel Environment Setup

Add these variables in Vercel Dashboard → Settings → Environment Variables:

| Variable | Value | Environment |
|----------|-------|-------------|
| `SENDGRID_API_KEY` | `SG.xxx...` | Production, Preview |
| `SENDGRID_FROM_EMAIL` | `noreply@hobbiapp.com` | All |
| `SENDGRID_FROM_NAME` | `Hobbi` | All |
| `TWILIO_ACCOUNT_SID` | `ACxxx...` | Production, Preview |
| `TWILIO_AUTH_TOKEN` | `xxx...` | Production, Preview |
| `TWILIO_PHONE_NUMBER` | `+1xxx...` | All |
| `APNS_KEY_ID` | `ABC123...` | All |
| `APNS_TEAM_ID` | `TEAM...` | All |
| `APNS_BUNDLE_ID` | `com.hobbi.app` | All |
| `APNS_PRIVATE_KEY` | `-----BEGIN...` | Production, Preview |

---

## 6. Testing

### Test Email
```typescript
import emailService from '@/lib/services/email';

const result = await emailService.sendEmail({
  to: { email: 'test@example.com' },
  subject: 'Test Email',
  html: '<h1>Hello!</h1><p>This is a test.</p>',
});
console.log(result); // { success: true, messageId: 'xxx' }
```

### Test SMS
```typescript
import smsService from '@/lib/services/sms';

const result = await smsService.sendSMS({
  to: '+15551234567',
  message: 'Test SMS from Hobbi!',
});
console.log(result); // { success: true, messageId: 'SMxxx' }
```

### Test Push (Sandbox)
```typescript
import pushService from '@/lib/services/push-notifications';

const result = await pushService.sendPushNotification({
  deviceToken: 'device-token-from-ios-app',
  payload: {
    title: 'Test Push',
    body: 'This is a test notification!',
    sound: 'default',
  },
  sandbox: true, // Use sandbox for TestFlight/development
});
console.log(result); // { success: true, apnsId: 'xxx' }
```

---

## 7. Automatic Notifications

The following webhooks automatically send notifications:

| Event | Email | SMS | Push |
|-------|-------|-----|------|
| Payment Succeeded | ✅ | ✅ | ✅ |
| Payment Failed | ✅ | ✅ | ❌ |
| Payout Sent | ✅ | ❌ | ❌ |
| Payout Failed | ✅ | ❌ | ❌ |

---

## Troubleshooting

### Email Not Sending
1. Check `SENDGRID_API_KEY` is set
2. Verify sender domain in SendGrid
3. Check spam folder
4. View SendGrid Activity Feed for errors

### SMS Not Sending
1. Check `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN`
2. Verify phone number format (E.164: +1XXXXXXXXXX)
3. Check Twilio Console for error logs
4. Ensure phone number is SMS-capable

### Push Not Sending
1. Check all APNS variables are set
2. Verify device token is valid (64 hex chars)
3. Use `sandbox: true` for TestFlight builds
4. Check iOS app has push notification entitlement
5. Verify bundle ID matches your app

---

*Last updated: November 29, 2024*
