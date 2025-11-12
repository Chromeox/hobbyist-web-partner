# Vercel Environment Variables Checklist

## 🚨 Action Required: Verify Environment Variables

Your webhook is returning a 500 error, which typically means a required environment variable is missing or not accessible to the deployment.

---

## Critical Environment Variables Needed

Go to: **Vercel Dashboard → Your Project → Settings → Environment Variables**

### Required for Webhooks to Work:

| Variable Name | Where to Get It | Status |
|---------------|-----------------|--------|
| `STRIPE_WEBHOOK_SECRET` | Stripe Dashboard → Webhooks | ✅ You added this |
| `STRIPE_SECRET_KEY` | Stripe Dashboard → API Keys | ❓ Check this |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard → Settings | ❓ Check this |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase Dashboard → Settings | ❓ Check this |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase Dashboard → Settings | ❓ Check this |

---

## Step-by-Step Verification

### Step 1: Check All Environment Variables Are Set

1. Go to: https://vercel.com/dashboard
2. Find your project (likely named `hobbyist-web-partner` or similar)
3. Click: **Settings** tab
4. Click: **Environment Variables** in sidebar
5. Verify ALL 5 variables above exist

### Step 2: Check Variable Scope

For each variable, verify it's available in:
- ✅ **Production** ← Most important for your live webhook
- ✅ **Preview**
- ✅ **Development**

### Step 3: Copy Missing Variables

If any are missing, here are the values (from your .env.local):

#### Stripe Keys
**Get these from**: Your local `.env.local` file at `/Users/chromefang.exe/HobbyApp/web-partner/.env.local`

```
STRIPE_SECRET_KEY=[Copy from .env.local]
STRIPE_WEBHOOK_SECRET=[Copy from .env.local]
```

#### Supabase Keys
**Get these from**: Your local `.env.local` file at `/Users/chromefang.exe/HobbyApp/web-partner/.env.local`

```
NEXT_PUBLIC_SUPABASE_URL=[Copy from .env.local]
NEXT_PUBLIC_SUPABASE_ANON_KEY=[Copy from .env.local]
SUPABASE_SERVICE_ROLE_KEY=[Copy from .env.local]
```

### Step 4: Redeploy After Adding Variables

**CRITICAL**: After adding/updating environment variables, you MUST redeploy.

**Option A - Vercel Dashboard**:
1. Go to **Deployments** tab
2. Find latest deployment
3. Click ⋯ (three dots menu)
4. Click **Redeploy**
5. Confirm redeploy

**Option B - Manual Trigger** (already done):
```bash
# Already pushed these commits:
# e42f2ca - "chore: trigger Vercel deployment for webhook secret"
# 23d11bf - "feat: add webhook testing script and deployment status guide"
```

### Step 5: Wait for Deployment

- ⏰ **Wait**: 2-3 minutes after redeploy
- 📊 **Monitor**: Vercel Dashboard → Deployments
- ✅ **Look for**: Green checkmark = deployment complete

---

## 🧪 Test After Fixing

Once all variables are set and deployment is complete:

```bash
cd /Users/chromefang.exe/HobbyApp
./test-webhook-endpoint.sh
```

**Expected output**:
```
✅ PASS - Endpoint accessible (returned 400 as expected)
✅ PASS - Signature verification is active
```

---

## 🐛 Common Issues

### Issue 1: "Team" Variables vs "Project" Variables

**Problem**: You added to Team environment variables, but project needs them explicitly.

**Solution**:
1. In Vercel, go to specific project settings
2. Add variables directly to the project
3. Don't rely only on Team-level variables

### Issue 2: Wrong Environment Scope

**Problem**: Variable set for "Development" but not "Production"

**Solution**: Select all three scopes when adding variable

### Issue 3: Variable Name Typo

**Problem**: Typed `STRIPE_WEBHOOK_SECRETE` instead of `STRIPE_WEBHOOK_SECRET`

**Solution**: Double-check exact spelling matches code

---

## 📸 What to Check in Vercel

### Screenshot Your Settings
Take a screenshot showing:
- ✅ All 5 environment variables listed
- ✅ Production scope checked for each
- ✅ Last deployment shows green checkmark

### Check Function Logs
1. Go to: Deployments → Latest deployment
2. Click: **View Function Logs**
3. Look for errors like:
   - "STRIPE_WEBHOOK_SECRET is not defined"
   - "Cannot connect to Supabase"
   - "Environment variable missing"

---

## 🎯 Quick Fix Steps

1. **Verify all 5 variables** are in Vercel project settings
2. **Ensure Production scope** is selected
3. **Redeploy** from Vercel dashboard
4. **Wait 2-3 minutes**
5. **Test again**: `./test-webhook-endpoint.sh`

---

## ❓ Still Not Working?

If after verifying all variables and redeploying, webhook still returns 500:

### Check Vercel Function Logs
```
Vercel Dashboard → Your Project → Deployments → Latest → View Function Logs
```

Look for specific error message, then:
1. Share the error message
2. I can help debug the specific issue

### Verify Database Migration
```sql
-- In Supabase SQL Editor, check functions exist:
SELECT routine_name
FROM information_schema.routines
WHERE routine_name LIKE '%stripe%'
  AND routine_schema = 'public';
```

**Expected**: Should see 4 functions:
- `record_stripe_payment_event`
- `record_stripe_transfer`
- `upsert_stripe_account_status`
- `update_payout_status`

If missing, rerun migration:
```sql
-- In Supabase SQL Editor
-- Run: supabase/migrations/20251111000000_stripe_webhook_tracking.sql
```

---

**Current Status**: Webhook configured, waiting for Vercel env vars verification
**Next Step**: Verify all 5 environment variables in Vercel project settings
**Then**: Redeploy and test again
