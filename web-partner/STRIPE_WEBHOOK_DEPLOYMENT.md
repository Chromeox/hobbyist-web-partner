# Stripe Webhook Integration - Deployment Guide

**Status**: ✅ Code Complete - Ready for Database Deployment
**Date**: 2025-11-11
**Estimated Deployment Time**: 5-10 minutes

---

## What Was Fixed

All 7 TODO comments in Stripe webhook handlers have been resolved:

1. ✅ **account.updated** → Saves Stripe account status to database
2. ✅ **account.application.deauthorized** → Marks account as disconnected
3. ✅ **payment_intent.succeeded** → Records payment + updates booking status
4. ✅ **payment_intent.payment_failed** → Records failure + notifies
5. ✅ **transfer.created** → Tracks platform → studio transfers
6. ✅ **payout.paid** → Marks payout completed
7. ✅ **payout.failed** → Records failure + alerts studio

---

## New Database Tables

### 1. `stripe_payment_events`
Comprehensive audit log of all payment-related webhooks.

**Purpose**: Track every payment event for compliance, debugging, and analytics.

**Key Features**:
- Idempotent inserts (duplicate events ignored)
- Full event metadata stored
- Links to bookings and users
- Error codes and messages captured

### 2. `stripe_transfers`
Track platform → studio/instructor transfers (commission payments).

**Purpose**: Reconcile all money moving from platform to connected accounts.

**Key Features**:
- Links to bookings and revenue shares
- Commission breakdown (gross, fee, payout)
- Transfer status tracking
- Failure handling

### 3. `stripe_account_statuses`
Stripe Connect account status for studios/instructors.

**Purpose**: Know real-time onboarding status and capabilities.

**Key Features**:
- Charges/payouts enabled flags
- Requirements tracking
- Deauthorization handling
- Links to studio submissions

### 4. `payout_requests` Updates
Added Stripe-specific fields to existing table.

**New Fields**:
- `stripe_payout_id`
- `stripe_transfer_id`
- `stripe_arrival_date`
- `stripe_status`
- `stripe_failure_code`
- `stripe_failure_message`

---

## Helper Functions Created

### `upsert_stripe_account_status()`
Updates or inserts Stripe account status from webhooks.

**Parameters**:
- `p_stripe_account_id` (TEXT)
- `p_charges_enabled` (BOOLEAN)
- `p_payouts_enabled` (BOOLEAN)
- `p_details_submitted` (BOOLEAN)
- `p_requirements_due` (TEXT[])
- `p_disabled_reason` (TEXT)

**Returns**: UUID of status record

**Idempotency**: Uses UPSERT (ON CONFLICT DO UPDATE)

---

### `record_stripe_payment_event()`
Records payment intent events with automatic idempotency.

**Parameters**:
- `p_stripe_event_id` (TEXT) - Unique event ID
- `p_payment_intent_id` (TEXT)
- `p_event_type` (TEXT) - 'payment_intent.succeeded', etc.
- `p_amount` (INTEGER) - Amount in cents
- `p_currency` (TEXT)
- `p_status` (TEXT) - 'succeeded', 'failed', etc.
- `p_customer_id` (TEXT) - Optional
- `p_user_id` (UUID) - Optional
- `p_error_code` (TEXT) - Optional
- `p_error_message` (TEXT) - Optional

**Returns**: UUID of event record (or NULL if duplicate)

**Idempotency**: Uses ON CONFLICT DO NOTHING

---

### `record_stripe_transfer()`
Records platform → studio transfers with idempotency.

**Parameters**:
- `p_stripe_transfer_id` (TEXT) - Unique transfer ID
- `p_destination_account` (TEXT) - Connected account ID
- `p_amount` (INTEGER) - Amount in cents
- `p_currency` (TEXT)
- `p_description` (TEXT) - Optional
- `p_studio_id` (UUID) - Optional
- `p_booking_id` (UUID) - Optional

**Returns**: UUID of transfer record (or NULL if duplicate)

**Idempotency**: Uses ON CONFLICT DO NOTHING

---

### `update_payout_status()`
Updates payout request status from webhook events.

**Parameters**:
- `p_stripe_payout_id` (TEXT)
- `p_status` (TEXT) - 'paid', 'failed'
- `p_arrival_date` (TIMESTAMPTZ) - Optional
- `p_failure_code` (TEXT) - Optional
- `p_failure_message` (TEXT) - Optional

**Returns**: BOOLEAN (true if updated)

---

## Deployment Steps

### Step 1: Review Migration File

```bash
cat supabase/migrations/20251111000000_stripe_webhook_tracking.sql
```

**Verify**:
- ✅ Creates 3 new tables
- ✅ Adds columns to payout_requests
- ✅ Creates 4 helper functions
- ✅ Enables RLS with appropriate policies
- ✅ Creates performance indexes

### Step 2: Apply Migration to Database

**Option A: Supabase CLI (Recommended)**

```bash
# From project root
cd /Users/chromefang.exe/HobbyApp

# Apply to remote database
supabase db push

# Or apply specific migration
supabase migration up --db-url postgresql://...
```

**Option B: Direct SQL Execution**

```bash
# Using psql
PGPASSWORD="your_password" psql \
  "postgresql://postgres.mcjqvdzdhtcvbrejvrtp:password@aws-0-us-west-1.pooler.supabase.com:6543/postgres?sslmode=require" \
  -f supabase/migrations/20251111000000_stripe_webhook_tracking.sql
```

**Option C: Supabase Dashboard**

1. Go to Supabase Dashboard → SQL Editor
2. Copy contents of migration file
3. Execute SQL
4. Verify tables created

### Step 3: Verify Migration Success

```sql
-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'stripe_payment_events',
    'stripe_transfers',
    'stripe_account_statuses'
  )
ORDER BY table_name;

-- Should return 3 rows

-- Check functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%stripe%'
ORDER BY routine_name;

-- Should return 4 functions

-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'stripe_payment_events',
    'stripe_transfers',
    'stripe_account_statuses'
  );

-- All should show rowsecurity = true
```

### Step 4: Deploy Code to Production

```bash
# Push to Vercel (or your deployment platform)
git push origin feature/codebase-cleanup

# Or deploy via Vercel dashboard
# Project Settings → Git → Deploy branch
```

### Step 5: Update Environment Variables

**Verify these are set in production**:

```env
STRIPE_SECRET_KEY=sk_live_... (or sk_test_...)
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

**Important**: `SUPABASE_SERVICE_ROLE_KEY` is required for webhook handlers to bypass RLS.

### Step 6: Configure Stripe Webhooks

**In Stripe Dashboard**:

1. Go to Developers → Webhooks
2. Add endpoint: `https://your-app.vercel.app/api/stripe/webhooks`
3. Select events to listen for:
   - ✅ `account.updated`
   - ✅ `account.application.deauthorized`
   - ✅ `payment_intent.succeeded`
   - ✅ `payment_intent.payment_failed`
   - ✅ `transfer.created`
   - ✅ `payout.paid`
   - ✅ `payout.failed`
4. Copy webhook signing secret
5. Add to environment variables as `STRIPE_WEBHOOK_SECRET`

---

## Testing the Integration

### Test 1: Account Status Webhook

**Using Stripe CLI**:

```bash
# Install Stripe CLI if not already
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local dev
stripe listen --forward-to localhost:3000/api/stripe/webhooks

# Trigger test event
stripe trigger account.updated
```

**Expected Result**:
- Console shows: "✅ Account status updated in database"
- Database shows new row in `stripe_account_statuses`

### Test 2: Payment Success Webhook

```bash
# Trigger payment success
stripe trigger payment_intent.succeeded

# Or create real test payment
stripe payment_intents create \
  --amount 2000 \
  --currency usd \
  --payment-method pm_card_visa \
  --confirm true \
  --metadata[booking_id]=test-booking-123
```

**Expected Result**:
- Console shows: "✅ Payment event recorded in database"
- Database shows new row in `stripe_payment_events`
- If booking_id provided, booking status updated to 'confirmed'

### Test 3: Transfer Webhook

```bash
# Trigger transfer (requires connected account)
stripe trigger transfer.created
```

**Expected Result**:
- Console shows: "✅ Transfer recorded in database"
- Database shows new row in `stripe_transfers`

### Test 4: Payout Webhook

```bash
# Trigger payout paid
stripe trigger payout.paid

# Trigger payout failed
stripe trigger payout.failed
```

**Expected Result**:
- Console shows: "✅ Payout marked as paid/failed in database"
- Database shows `payout_requests` updated with status

---

## Monitoring & Debugging

### View Webhook Logs

**In Vercel**:
1. Go to project → Deployments → Latest
2. Click "View Function Logs"
3. Filter for `/api/stripe/webhooks`

**Look for**:
- ✅ Success messages with emoji checkmarks
- ❌ Error messages from database operations
- Event IDs for idempotency tracking

### Query Database for Events

```sql
-- Recent payment events
SELECT
    stripe_event_id,
    event_type,
    status,
    amount / 100 as amount_dollars,
    created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 10;

-- Recent transfers
SELECT
    stripe_transfer_id,
    amount / 100 as amount_dollars,
    stripe_destination_account,
    status,
    created_at
FROM stripe_transfers
ORDER BY created_at DESC
LIMIT 10;

-- Account statuses
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

### Check Webhook Delivery in Stripe

1. Stripe Dashboard → Developers → Webhooks
2. Click on your endpoint
3. View "Recent deliveries"
4. Check for failures or retries

---

## Rollback Plan

If something goes wrong:

### Rollback Code

```bash
# Revert to previous commit
git revert HEAD
git push origin feature/codebase-cleanup
```

### Drop Tables (if needed)

```sql
-- CAUTION: This deletes all webhook data
DROP TABLE IF EXISTS public.stripe_payment_events CASCADE;
DROP TABLE IF EXISTS public.stripe_transfers CASCADE;
DROP TABLE IF EXISTS public.stripe_account_statuses CASCADE;

-- Remove added columns
ALTER TABLE public.payout_requests
DROP COLUMN IF EXISTS stripe_payout_id,
DROP COLUMN IF EXISTS stripe_transfer_id,
DROP COLUMN IF EXISTS stripe_arrival_date,
DROP COLUMN IF EXISTS stripe_status,
DROP COLUMN IF EXISTS stripe_failure_code,
DROP COLUMN IF EXISTS stripe_failure_message,
DROP COLUMN IF EXISTS stripe_metadata;

-- Drop functions
DROP FUNCTION IF EXISTS public.upsert_stripe_account_status CASCADE;
DROP FUNCTION IF EXISTS public.record_stripe_payment_event CASCADE;
DROP FUNCTION IF EXISTS public.record_stripe_transfer CASCADE;
DROP FUNCTION IF EXISTS public.update_payout_status CASCADE;
```

---

## Success Criteria

✅ Migration applied without errors
✅ All 4 helper functions created
✅ RLS enabled on new tables
✅ Stripe webhooks configured in dashboard
✅ Test events successfully recorded in database
✅ Production webhooks processing correctly
✅ No errors in Vercel logs
✅ Booking statuses updating automatically

---

## Next Steps

After successful deployment:

1. **Monitor for 24-48 hours**: Watch for any errors or failures
2. **Check payment reconciliation**: Verify all payments tracked
3. **Review transfer accuracy**: Ensure commission calculations correct
4. **Test payout flow end-to-end**: Request payout → verify tracking
5. **Add notification system**: Email/SMS for failed payments/payouts

---

## Support

**If you encounter issues**:

1. Check Vercel function logs for errors
2. Query database tables to see what's being recorded
3. Review Stripe webhook delivery logs
4. Verify environment variables are set correctly
5. Test with Stripe CLI for immediate feedback

**Common Issues**:

- **"Function not found"**: Migration didn't apply → Rerun migration
- **"RLS policy error"**: Service role key not set → Add to env vars
- **"Webhook signature failed"**: Wrong webhook secret → Update from Stripe
- **"No rows affected"**: Event already processed → Idempotency working correctly

---

**Deployment Time**: ~5-10 minutes
**Risk Level**: Low (additive changes, no breaking changes)
**Rollback Time**: ~2 minutes if needed
