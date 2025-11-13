# ✅ Webhook Final Setup Checklist

## Current Status

✅ **Webhook endpoint created** in Stripe (test mode)
- URL: `https://hobbyist-web-partner-v3.vercel.app/api/stripe/webhooks`
- Events: 7 configured (payments, accounts, transfers, payouts)
- Secret: `whsec_FRXJ8Z2mqsPjY3wg8ZyZMeCC8E0084Wp`

✅ **Local .env.local updated** with new secret

⏳ **Need to do**: Update Vercel and test

---

## Step 1: Update Vercel Environment Variable (2 minutes)

1. Go to: https://vercel.com/dashboard
2. Find your project: `hobbyist-web-partner-v3`
3. Click: **Settings** → **Environment Variables**
4. Find: `STRIPE_WEBHOOK_SECRET`
5. Click: **Edit** (pencil icon)
6. Replace value with:
   ```
   whsec_FRXJ8Z2mqsPjY3wg8ZyZMeCC8E0084Wp
   ```
7. Ensure selected for: **Production** + Preview + Development
8. Click: **Save**

---

## Step 2: Redeploy (1 minute)

After saving the environment variable:

1. Go to: **Deployments** tab
2. Find: Latest deployment
3. Click: **⋯** (three dots menu)
4. Click: **Redeploy**
5. **Uncheck** "Use existing Build Cache"
6. Click: **Redeploy**
7. Wait: ~2-3 minutes for deployment to complete

---

## Step 3: Test Webhook (1 minute)

Once deployment shows ✅ Ready:

### Test Command:
```bash
cd /Users/chromefang.exe/HobbyApp
stripe trigger payment_intent.succeeded
```

**Expected Output**:
```
Setting up fixture for: payment_intent
Running fixture for: payment_intent
Trigger succeeded! Check dashboard for event details.
```

---

## Step 4: Verify in Database (1 minute)

Run this in **Supabase SQL Editor**:

```sql
SELECT
  event_type,
  stripe_payment_intent_id,
  amount,
  currency,
  status,
  created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 5;
```

**Expected**: You should see the test event with:
- `event_type`: `payment_intent.succeeded`
- `amount`: Some test amount (e.g., 2000 = $20.00)
- `status`: `succeeded`
- Recent `created_at` timestamp

---

## Step 5: Test All Event Types (Optional - 2 minutes)

If first test works, verify all webhook handlers:

```bash
# Test payment events
stripe trigger payment_intent.succeeded
stripe trigger payment_intent.payment_failed

# Test transfer event
stripe trigger transfer.created

# Test payout events
stripe trigger payout.paid
stripe trigger payout.failed
```

Then check database for all event types:

```sql
SELECT event_type, COUNT(*) as count
FROM stripe_payment_events
GROUP BY event_type
ORDER BY count DESC;
```

---

## Success Criteria

All of these should be true:

- ✅ Vercel environment variable updated
- ✅ Deployment completed successfully
- ✅ `stripe trigger` commands succeed
- ✅ Events appear in `stripe_payment_events` table
- ✅ No errors in Vercel function logs
- ✅ Stripe Dashboard shows webhook delivery as "succeeded"

---

## Troubleshooting

### Issue: Events not in database

**Check**:
1. Vercel function logs (Deployments → Latest → View Function Logs)
2. Look for errors like:
   - "Webhook signature verification failed" → Secret mismatch
   - "Function not found" → Migration not applied
   - "Permission denied" → RLS policy issue

**Fix**:
- Secret mismatch → Verify secret in Vercel matches `whsec_FRXJ8Z2mqsPjY3wg8ZyZMeCC8E0084Wp`
- Function errors → Rerun migration in Supabase

### Issue: Webhook shows as "failed" in Stripe

**Check**: Stripe Dashboard → Webhooks → Your endpoint → Recent deliveries

**Common Causes**:
- 500 error → Check Vercel function logs
- 400 error with "signature" → Secret mismatch
- Timeout → Database query too slow

---

## After Everything Works

### For Friend Testing:

1. **Real bookings** will automatically create webhook events
2. **Payment tracking** happens automatically
3. **Commission splits** recorded in database
4. **Studio payouts** monitored via webhooks

### Monitoring:

**Daily**:
- Check Stripe Dashboard → Webhooks for delivery success rate
- Should be 95%+ success

**Weekly**:
```sql
-- Check webhook volume
SELECT DATE(created_at) as date, COUNT(*) as events
FROM stripe_payment_events
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## Current Webhook Details

**Webhook ID**: `we_1SStr7Rvf7VmvkGVbC5pxtpa`
**URL**: `https://hobbyist-web-partner-v3.vercel.app/api/stripe/webhooks`
**Mode**: Test mode (for testing with test API keys)
**Status**: Enabled
**Events**: 7 payment & commission events

---

**Next Step**: Update Vercel env var → Redeploy → Test!
**Estimated Time**: 5 minutes total
**Last Updated**: November 12, 2025
