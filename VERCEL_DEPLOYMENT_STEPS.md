# Deploy Stripe Webhook Integration to Vercel

## ✅ Migration Complete - Ready to Deploy!

Your Stripe webhook integration is ready to deploy. Choose either automatic or manual deployment.

---

## Option A: Automatic Deployment via Vercel Dashboard (2 minutes)

### Step 1: Merge to Main Branch (if needed)

If your Vercel project is configured to auto-deploy from `main`:

```bash
cd /Users/chromefang.exe/HobbyApp
git checkout main
git merge feature/codebase-cleanup
git push origin main
```

**Or** if deploying from feature branch:

Vercel should auto-deploy from `feature/codebase-cleanup` if GitHub integration is enabled.

### Step 2: Monitor Deployment

1. Go to: https://vercel.com/dashboard
2. Find your project (hobbyist-web-partner or similar)
3. Check "Deployments" tab
4. Wait for latest deployment to complete (~2-3 minutes)

### Step 3: Verify Deployment

Once deployed, check:
- ✅ Build succeeded
- ✅ No TypeScript errors
- ✅ No build warnings
- ✅ Deployment URL active

---

## Option B: Manual Deployment via Vercel CLI (5 minutes)

### Install Vercel CLI (if not installed)

```bash
npm install -g vercel
```

### Login to Vercel

```bash
vercel login
```

### Deploy from web-partner directory

```bash
cd /Users/chromefang.exe/HobbyApp/web-partner

# Deploy to production
vercel --prod

# Or deploy to preview first
vercel
```

### Follow prompts:
- Set up and deploy? **Yes**
- Which scope? **Your account/team**
- Link to existing project? **Yes** (if you have one)
- Project name? **hobbyist-web-partner** (or your project name)

---

## Option C: Deploy via Git Push (Automatic)

If you have Vercel GitHub integration:

1. **Push was already done** ✅
2. Vercel detects the push automatically
3. Builds and deploys within 2-3 minutes
4. Check Vercel dashboard for deployment status

---

## Environment Variables to Verify

**Critical**: Ensure these are set in Vercel project settings:

```env
# Stripe
STRIPE_SECRET_KEY=sk_live_... (or sk_test_...)
STRIPE_WEBHOOK_SECRET=whsec_...

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...  ← CRITICAL for webhooks!
```

**To check/add**:
1. Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add missing variables
3. Redeploy if you added variables

---

## Post-Deployment Verification

### Step 1: Check Build Logs

In Vercel Dashboard:
1. Go to latest deployment
2. Click "View Function Logs"
3. Look for any errors

### Step 2: Test Webhook Endpoint

```bash
# Test webhook endpoint is accessible
curl -X POST https://your-app.vercel.app/api/stripe/webhooks \
  -H "Content-Type: application/json" \
  -d '{"type":"test"}'

# Should return: "Webhook signature verification failed"
# (This is expected - means endpoint is working)
```

### Step 3: Check Dashboard Loads

Visit your deployment URL:
- Login works
- Dashboard loads
- No console errors

---

## Next Step: Configure Stripe Webhooks

Once deployment is complete and verified:

1. **Get your deployment URL**:
   - Production: `https://your-app.vercel.app`
   - Or check Vercel dashboard for URL

2. **Configure in Stripe Dashboard**:
   - Go to: https://dashboard.stripe.com/webhooks
   - Add endpoint: `https://your-app.vercel.app/api/stripe/webhooks`
   - Select events (see STRIPE_WEBHOOK_DEPLOYMENT.md)

3. **Test with Stripe CLI**:
   ```bash
   stripe listen --forward-to https://your-app.vercel.app/api/stripe/webhooks
   stripe trigger payment_intent.succeeded
   ```

---

## Troubleshooting

### Build Fails

**Check**:
- TypeScript errors in build logs
- Missing environment variables
- Dependencies not installed

**Fix**:
```bash
# Test build locally
cd /Users/chromefang.exe/HobbyApp/web-partner
npm run build

# If it works locally, issue is with Vercel config
```

### Webhooks Don't Work

**Check**:
1. `SUPABASE_SERVICE_ROLE_KEY` is set in Vercel
2. Webhook endpoint is accessible (curl test above)
3. Stripe webhook secret matches Vercel env var
4. Check Vercel function logs for errors

### "Function not found" errors

**Cause**: Database migration functions don't exist

**Fix**: Rerun migration in Supabase Dashboard

---

## Success Criteria

✅ Vercel deployment succeeded
✅ No build errors
✅ Dashboard loads without errors
✅ Webhook endpoint responds (even with error)
✅ Environment variables all set
✅ Ready for Stripe webhook configuration

---

**Current Status**:
- ✅ Code pushed to GitHub
- ✅ Database migration applied
- ⏳ Awaiting Vercel deployment

**Next**: Configure Stripe webhooks once deployment is live!
