# Stripe Webhook Quick Reference Card

## Your Webhook URL (✅ WORKING)
```
https://hobbyist-web-partner-v3.vercel.app/api/stripe/webhooks
```

## Events to Select in Stripe Dashboard

1. `payment_intent.succeeded`
2. `payment_intent.payment_failed`
3. `account.updated`
4. `account.application.deauthorized`
5. `transfer.created`
6. `payout.paid`
7. `payout.failed`

## Environment Variable to Add in Vercel

**Name**: `STRIPE_WEBHOOK_SECRET`
**Value**: `whsec_xxxxxxxxxxxxx` (get from Stripe after creating webhook)
**Environments**: Production, Preview, Development

## Quick Test Commands

### Test endpoint accessibility:
```bash
curl -X POST https://hobbyist-web-partner-v3.vercel.app/api/stripe/webhooks \
  -H "Content-Type: application/json" \
  -d '{"type":"test"}'
```

Expected: `{"error":"Webhook signature verification failed"}` ← This is GOOD!

### Test with Stripe CLI:
```bash
# Install (if needed)
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Test production webhook
stripe trigger payment_intent.succeeded
```

## Database Verification Queries

### Check events were recorded:
```sql
SELECT event_type, amount, created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 5;
```

### Check transfers:
```sql
SELECT stripe_transfer_id, amount, created_at
FROM stripe_transfers
ORDER BY created_at DESC;
```

---

**Full Guide**: `/Users/chromefang.exe/HobbyApp/STRIPE_WEBHOOK_SETUP_GUIDE.md`
