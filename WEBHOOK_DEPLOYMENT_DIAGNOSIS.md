# 🔍 Webhook Deployment Diagnosis & Fix

## What We Discovered

### The Problem
Your Vercel deployment was stuck on an **old build from 2 days ago** (ID: `dpl_GzTHsM4B6oUUrD55S7kYCj2pavSF`) that:
- Did NOT have the database integration code
- Was logging "Payment data to save" (old debug code)
- Crashed with `responseStatusCode: -1` (timeout/error)
- Never actually called the database functions

### The Evidence
From your Vercel logs (`logs_result.json`):
```json
{
  "message": "Payment data to save: {...}",
  "responseStatusCode": -1,  // Function crashed/timeout
  "deploymentId": "dpl_GzTHsM4B6oUUrD55S7kYCj2pavSF"  // OLD deployment
}
```

### Why Database Was Empty
The webhook handler was:
1. ✅ Receiving events from Stripe
2. ✅ Parsing payment intent data
3. ✅ Logging the data
4. ❌ **Crashing before database insertion**
5. ❌ Never calling `record_stripe_payment_event()` function

---

## The Fix

### What We Did
Forced a fresh Vercel deployment with the complete database integration code:

```bash
# Commit: c19cbd0
git commit --allow-empty -m "chore: force Vercel deployment rebuild - database integration"
git push origin main
```

### What This Includes
The new deployment will have:
- ✅ Complete `handlePaymentSucceeded()` with database RPC call
- ✅ All 7 webhook event handlers with database integration
- ✅ Supabase service client properly configured
- ✅ Error handling and logging
- ✅ Idempotent database helper functions

---

## Testing the New Deployment

### Step 1: Wait for Deployment (2-3 minutes)

Run the monitoring script:
```bash
cd /Users/chromefang.exe/HobbyApp
./check-deployment-ready.sh
```

This will:
- Check deployment status every 30 seconds
- Alert you when ready (returns 400 = signature verification working)
- Automatically timeout after 5 minutes

**OR** manually check Vercel:
- Go to https://vercel.com/dashboard
- Find: `hobbyist-web-partner-v3`
- Look for: Latest deployment with "Ready" status
- Verify: Commit message "force Vercel deployment rebuild"

---

### Step 2: Test Webhook with Stripe CLI

Once deployment is ready:

```bash
# Trigger a test payment event
stripe trigger payment_intent.succeeded
```

**Expected Output**:
```
Setting up fixture for: payment_intent
Running fixture for: payment_intent
Trigger succeeded! Check dashboard for event details.
```

---

### Step 3: Verify Database Insertion

Run in **Supabase SQL Editor**:

```sql
-- Should now show COUNT > 0
SELECT COUNT(*) as total_events
FROM stripe_payment_events;

-- Should show the most recent event
SELECT
  event_type,
  stripe_payment_intent_id,
  amount / 100.0 as amount_dollars,
  currency,
  status,
  created_at,
  NOW() - created_at as age
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results**:
- Total events: `1` (or more if you triggered multiple)
- Most recent event:
  - `event_type`: `payment_intent.succeeded`
  - `amount_dollars`: `20.00` (Stripe test amount)
  - `status`: `succeeded`
  - `age`: Less than 1 minute

---

### Step 4: Verify Webhook Delivery in Stripe

1. Go to: https://dashboard.stripe.com/test/webhooks
2. Click on your webhook: `we_1SStr7Rvf7VmvkGVbC5pxtpa`
3. Click: **Events & logs** tab
4. Find: Your test event (should show within last minute)
5. Verify: Response code **200 OK** (not -1 or 500)

---

## Success Criteria

All of these should be true:

- ✅ Deployment shows "Ready" in Vercel dashboard
- ✅ `curl` test returns 400 (signature verification)
- ✅ `stripe trigger` command succeeds
- ✅ Database shows `COUNT(*) > 0`
- ✅ Stripe dashboard shows 200 OK response
- ✅ Vercel function logs show "✅ Payment event recorded in database"

---

## If It Still Doesn't Work

### Check 1: Environment Variables
Verify in Vercel → Settings → Environment Variables:

| Variable | Should Be |
|----------|-----------|
| `STRIPE_WEBHOOK_SECRET` | `whsec_FRXJ8Z2mqsPjY3wg8ZyZMeCC8E0084Wp` |
| `NEXT_PUBLIC_SUPABASE_URL` | Your Supabase URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Your service role key (starts with `eyJ...`) |

If any are missing or wrong → Update → Redeploy

### Check 2: Deployment Logs
1. Vercel Dashboard → Deployments → Latest
2. Click: **View Function Logs**
3. Look for:
   - ✅ "Payment succeeded: {id: 'pi_...'}"
   - ✅ "✅ Payment event recorded in database"
   - ❌ Any error messages (database connection, RLS, etc.)

### Check 3: Database Functions Exist
Run in Supabase SQL Editor:
```sql
SELECT routine_name
FROM information_schema.routines
WHERE routine_name LIKE '%stripe%'
  AND routine_schema = 'public';
```

**Expected**: Should show 4 functions:
- `record_stripe_payment_event`
- `record_stripe_transfer`
- `upsert_stripe_account_status`
- `update_payout_status`

If missing → Rerun migration: `supabase/migrations/20251111000000_stripe_webhook_tracking.sql`

---

## What's Different in New Deployment

### Old Code (Causing Crashes)
```typescript
// Was just logging, no database call
console.log("Payment data to save:", data);
// Then crashed due to missing code
```

### New Code (Database Integration)
```typescript
async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent) {
  const supabase = getSupabaseServiceClient();

  // Record payment event using helper function (with idempotency)
  const { data, error } = await supabase.rpc('record_stripe_payment_event', {
    p_stripe_event_id: `pi_succeeded_${paymentIntent.id}`,
    p_payment_intent_id: paymentIntent.id,
    p_event_type: 'payment_intent.succeeded',
    p_amount: paymentIntent.amount,
    p_currency: paymentIntent.currency,
    p_status: 'succeeded',
    p_customer_id: typeof paymentIntent.customer === 'string' ? paymentIntent.customer : null,
    p_user_id: userId
  });

  if (error) {
    console.error('Failed to record payment event:', error);
    throw error;
  }

  console.log('✅ Payment event recorded in database');

  // Also update booking status if applicable
  // ...
}
```

---

## Timeline

| Time | Event |
|------|-------|
| 2 days ago | Old deployment created (without database code) |
| Today 6:30 AM | You triggered webhook events |
| Today 6:30 AM | Old deployment logged data but crashed |
| Today 6:40 AM | Analyzed logs, discovered old deployment issue |
| **Today NOW** | **Pushed new deployment with database integration** |
| **Next 3 min** | **New deployment will be ready** |

---

## Next Steps After Success

Once webhooks are working and database is recording events:

1. **Test All Event Types**:
   ```bash
   stripe trigger payment_intent.succeeded
   stripe trigger payment_intent.payment_failed
   stripe trigger transfer.created
   stripe trigger payout.paid
   ```

2. **Verify Each Event in Database**:
   ```sql
   SELECT event_type, COUNT(*)
   FROM stripe_payment_events
   GROUP BY event_type;
   ```

3. **Enable for Friend Testing**:
   - Webhooks will automatically track all real payments
   - Commission splits recorded automatically
   - Studio payouts monitored in real-time

4. **Production Deployment** (when ready):
   - Switch to live mode keys in Vercel
   - Use live webhook secret: `whsec_57A8IEo6PwxkJfOC7CMY5fjdr2hK7vkZ`
   - Monitor Stripe Dashboard for delivery success rate

---

## Files Modified

- `/web-partner/app/api/stripe/webhooks/route.ts` (database integration)
- `/supabase/migrations/20251111000000_stripe_webhook_tracking.sql` (database schema)
- `check-deployment-ready.sh` (monitoring script)
- This diagnosis document

---

**Status**: ⏳ Deployment in progress (commit `c19cbd0`)
**Next Step**: Wait 2-3 minutes, then test with Stripe CLI
**Expected**: Database records events successfully
**If Issues**: Check deployment logs and environment variables

---

*Last Updated: November 13, 2025 06:45 UTC*
*Deployment Commit: c19cbd0*
