# Stripe Webhook Setup Guide

## ✅ Prerequisites Complete
- ✅ Code pushed to main branch (commit d8808cb)
- ✅ Database migration applied to Supabase
- ✅ Vercel deployment triggered automatically
- ✅ All webhook handlers implemented with database integration

## Production Deployment URL

Based on your test-password-reset.md, your production URL is:
```
https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app
```

**Webhook Endpoint**:
```
https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/api/stripe/webhooks
```

---

## Step 1: Configure Webhook in Stripe Dashboard (5 minutes)

### 1.1 Go to Stripe Dashboard
- Login at: https://dashboard.stripe.com
- Navigate to: **Developers → Webhooks**
- Click: **Add endpoint**

### 1.2 Add Endpoint URL
```
https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/api/stripe/webhooks
```

### 1.3 Select Events to Listen To

Your webhook handlers are configured for these 7 events:

#### Payment Events
- ✅ `payment_intent.succeeded` - When customer payment succeeds
- ✅ `payment_intent.payment_failed` - When payment fails

#### Connect Account Events
- ✅ `account.updated` - When studio Stripe account details change
- ✅ `account.application.deauthorized` - When studio disconnects

#### Transfer Events
- ✅ `transfer.created` - When platform transfers commission to studio

#### Payout Events
- ✅ `payout.paid` - When studio receives payout
- ✅ `payout.failed` - When payout to studio fails

### 1.4 Click "Add endpoint"

Stripe will create the endpoint and generate a **webhook signing secret**.

### 1.5 Copy Webhook Signing Secret

After creating the endpoint, you'll see a signing secret like:
```
whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**SAVE THIS** - you'll need it for Step 2.

---

## Step 2: Add Environment Variable to Vercel (3 minutes)

### 2.1 Go to Vercel Dashboard
- Login at: https://vercel.com/dashboard
- Find project: **hobbyist-web-partner** (or similar name)
- Go to: **Settings → Environment Variables**

### 2.2 Add STRIPE_WEBHOOK_SECRET

**Variable name**: `STRIPE_WEBHOOK_SECRET`
**Value**: `whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (from Step 1.5)
**Environment**: Select all (Production, Preview, Development)

### 2.3 Click "Save"

### 2.4 Trigger Redeploy

**IMPORTANT**: Environment variable changes require a redeploy.

**Option A - Vercel Dashboard**:
1. Go to **Deployments** tab
2. Find latest deployment
3. Click ⋯ (three dots)
4. Click **Redeploy**

**Option B - Git Push** (faster):
```bash
cd /Users/chromefang.exe/HobbyApp
git commit --allow-empty -m "chore: trigger redeploy for webhook secret"
git push origin main
```

Wait 2-3 minutes for deployment to complete.

---

## Step 3: Verify Webhook Endpoint (2 minutes)

### 3.1 Test Endpoint Accessibility

```bash
curl -X POST https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/api/stripe/webhooks \
  -H "Content-Type: application/json" \
  -d '{"type":"test"}'
```

**Expected Response**:
```json
{"error":"Webhook signature verification failed"}
```

This is GOOD! It means:
- ✅ Endpoint is accessible
- ✅ Signature verification is working
- ✅ Ready to receive real Stripe webhooks

**If you get 404 or 500 error**, check Vercel function logs.

### 3.2 Send Test Event from Stripe

In Stripe Dashboard → Webhooks → Your Endpoint:
1. Click **Send test webhook**
2. Select event: `payment_intent.succeeded`
3. Click **Send test webhook**

**Check Result**:
- Stripe shows: ✅ Response: 200 OK
- If 200 OK = SUCCESS! Webhook is working

---

## Step 4: Test with Stripe CLI (5 minutes)

### 4.1 Install Stripe CLI

**macOS**:
```bash
brew install stripe/stripe-cli/stripe
```

**Or download from**: https://docs.stripe.com/stripe-cli

### 4.2 Login to Stripe

```bash
stripe login
```

This opens your browser to authenticate.

### 4.3 Test Webhook Locally (Optional)

If you want to test before going live:

```bash
# Forward webhooks to local dev server
stripe listen --forward-to localhost:3000/api/stripe/webhooks

# In another terminal, trigger test events
stripe trigger payment_intent.succeeded
stripe trigger transfer.created
stripe trigger payout.paid
```

### 4.4 Test Production Webhook

```bash
# Forward to production endpoint
stripe listen --forward-to https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/api/stripe/webhooks

# Trigger events
stripe trigger payment_intent.succeeded
stripe trigger account.updated
stripe trigger transfer.created
```

**Watch for**:
```
✓ payment_intent.succeeded [200]
✓ account.updated [200]
✓ transfer.created [200]
```

---

## Step 5: Verify Database Integration (3 minutes)

### 5.1 Check Stripe Events Table

After triggering test events, verify they were recorded:

```sql
-- In Supabase SQL Editor
SELECT
  event_type,
  payment_intent_id,
  amount,
  currency,
  status,
  created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 10;
```

**Expected**: You should see test events recorded.

### 5.2 Check Transfers Table

```sql
SELECT
  stripe_transfer_id,
  amount,
  currency,
  destination_account,
  created_at
FROM stripe_transfers
ORDER BY created_at DESC
LIMIT 5;
```

### 5.3 Check Account Statuses

```sql
SELECT
  stripe_account_id,
  charges_enabled,
  payouts_enabled,
  details_submitted,
  is_active,
  updated_at
FROM stripe_account_statuses
ORDER BY updated_at DESC;
```

---

## What Your Webhooks Do

### Payment Intent Succeeded
1. ✅ Records event in `stripe_payment_events`
2. ✅ Updates `bookings` status to 'confirmed'
3. ✅ Sets payment method and amount paid

### Transfer Created
1. ✅ Records transfer in `stripe_transfers`
2. ✅ Updates `revenue_shares` with transfer details
3. ✅ Tracks commission payouts to studios

### Account Updated
1. ✅ Updates `stripe_account_statuses`
2. ✅ Syncs capabilities (charges_enabled, payouts_enabled)
3. ✅ Updates `studio_onboarding_submissions`

### Payout Events
1. ✅ Updates payout status and arrival date
2. ✅ Records any failure codes/messages
3. ✅ Tracks when studios receive money

---

## Troubleshooting

### Webhook Returns 500 Error

**Check**:
1. Vercel function logs (Dashboard → Functions → webhook route)
2. `SUPABASE_SERVICE_ROLE_KEY` is set in Vercel
3. Database functions exist (run migration again if needed)

**Fix**:
```bash
# Verify env vars are set
# In Vercel Dashboard → Settings → Environment Variables
# Must have:
- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET
- SUPABASE_SERVICE_ROLE_KEY
```

### Events Not Appearing in Database

**Check**:
1. Webhook returned 200 OK in Stripe dashboard
2. Check Vercel function logs for error messages
3. Verify migration was applied:

```sql
-- Should return tables
SELECT table_name
FROM information_schema.tables
WHERE table_name IN ('stripe_payment_events', 'stripe_transfers', 'stripe_account_statuses');

-- Should return functions
SELECT routine_name
FROM information_schema.routines
WHERE routine_name LIKE '%stripe%';
```

### Signature Verification Fails

**Check**:
1. `STRIPE_WEBHOOK_SECRET` matches Stripe Dashboard
2. Redeploy after adding environment variable
3. Using the correct endpoint URL in Stripe

---

## Success Checklist

- ✅ Webhook endpoint added in Stripe Dashboard
- ✅ 7 events selected and configured
- ✅ Webhook signing secret copied
- ✅ `STRIPE_WEBHOOK_SECRET` added to Vercel
- ✅ Redeployed after adding env var
- ✅ Test event returns 200 OK
- ✅ Events appear in database tables
- ✅ Stripe CLI test succeeds
- ✅ Function logs show no errors

---

## Next Steps for Friend Testing

Once webhooks are configured:

1. ✅ **Test complete booking flow**
   - User books class
   - Payment succeeds
   - Booking confirmed
   - Revenue split recorded

2. ✅ **Test studio onboarding**
   - Studio connects Stripe
   - Account status updates
   - Charges enabled confirmed

3. ✅ **Monitor webhook activity**
   - Check Stripe Dashboard → Webhooks → Recent deliveries
   - Review Vercel function logs
   - Query database for event records

---

## Production Monitoring

### Daily Checks
- Stripe Dashboard → Webhooks → Check delivery success rate
- Should be 95%+ success rate
- Investigate any 4xx or 5xx errors

### Weekly Checks
- Query `stripe_payment_events` for volume trends
- Verify `stripe_transfers` match expected revenue splits
- Check `stripe_account_statuses` for any disabled accounts

---

**Status**: Ready to configure webhooks!
**Estimated Time**: 15-20 minutes total
**Last Updated**: November 12, 2025
