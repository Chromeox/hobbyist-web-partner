# Vercel Environment Variables Setup

## Required Environment Variables for Better Auth

Add these environment variables in your Vercel Dashboard:
**Settings → Environment Variables**

---

### 1. BETTER_AUTH_URL

**For Production:**
- **Variable Name:** `BETTER_AUTH_URL`
- **Value:** `https://web-partner-3xoa2rtfn-chromeoxs-projects.vercel.app` (or your custom domain when ready)
- **Environment:** ✅ Production

**For Preview & Development (Optional):**
- You can set the same variable for Preview and Development environments
- Or leave unset - it will fall back to `NEXT_PUBLIC_APP_URL`

---

### 2. BETTER_AUTH_SECRET

**For All Environments:**
- **Variable Name:** `BETTER_AUTH_SECRET`
- **Value:** Generate a secure random string (minimum 32 characters)
- **Environment:** ✅ Production, ✅ Preview, ✅ Development

**Generate a secure secret:**
```bash
openssl rand -base64 32
```

Or use: https://generate-secret.vercel.app/32

---

### 3. NEXT_PUBLIC_APP_URL (Already exists)

**Verify it's set to:**
- **Production:** `https://web-partner-3xoa2rtfn-chromeoxs-projects.vercel.app` (or your custom domain)
- **Preview:** Can use `https://$VERCEL_URL` (dynamic)
- **Development:** `http://localhost:3000`

---

## Quick Setup via Vercel Dashboard

1. Go to: https://vercel.com/chromeoxs-projects/web-partner/settings/environment-variables

2. Click "Add New"

3. Add each variable:
   - Enter name (e.g., `BETTER_AUTH_URL`)
   - Enter value
   - Select environments (Production, Preview, Development)
   - Click "Save"

4. **Redeploy** your project for changes to take effect:
   - Go to Deployments tab
   - Click "..." on latest deployment
   - Click "Redeploy"

---

## How It Works

The updated `lib/auth.ts` now supports:

✅ **Production domain** (via `BETTER_AUTH_URL`)
✅ **Vercel preview URLs** (via `VERCEL_URL` - automatically provided)
✅ **Local development** (fallback to `localhost:3000`)
✅ **Apple OAuth** (hardcoded trusted origin)

The `trustedOrigins` configuration:
```typescript
trustedOrigins: [
  process.env.BETTER_AUTH_URL || process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
  process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : undefined,
  "https://appleid.apple.com",
].filter(Boolean)
```

---

## Testing After Setup

1. Set the environment variables in Vercel Dashboard
2. Redeploy the project
3. Visit: `https://web-partner-3xoa2rtfn-chromeoxs-projects.vercel.app/internal/admin`
4. Sign in with: `admin@hobbi.com` / `$tarFox64*4455`
5. You should be redirected to the admin dashboard ✅

---

## Troubleshooting

**If you see "Invalid origin" errors:**
- Check that `BETTER_AUTH_URL` is set in Vercel
- Verify it matches the URL you're visiting
- Check browser console for specific error messages
- Ensure you redeployed after adding variables

**If redirects aren't working:**
- Clear browser cookies/cache
- Try incognito/private browsing
- Check that `BETTER_AUTH_SECRET` is set and is at least 32 characters

---

**Note:** `VERCEL_URL` is automatically provided by Vercel for all preview deployments. You don't need to set it manually.
