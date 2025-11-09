# Vercel Deployment Guide for Studio Portal

## Current Status
- ✅ Local build succeeds
- ✅ All dependencies fixed
- ✅ TypeScript errors resolved
- ✅ React 19 compatibility achieved
- ❌ Vercel deployment showing 404

## Manual Deployment Steps

### Option 1: Via Vercel Dashboard (Recommended)

1. **Go to Vercel Dashboard**
   - Visit: https://vercel.com/dashboard
   - Click "New Project"

2. **Import Git Repository**
   - Click "Import Git Repository"
   - If not connected, authorize GitHub access
   - Search for: `hobbyist-web-partner-v2`
   - Click "Import"

3. **Configure Project**
   ```
   Project Name: hobbyist-partner-portal
   Framework Preset: Next.js
   Root Directory: ./ (or web-partner if monorepo)
   Build Command: npm run build
   Output Directory: .next
   Install Command: npm ci
   ```

4. **Add Environment Variables**
   Click "Add" for each variable and use your actual values:
   ```
   NEXT_PUBLIC_SUPABASE_URL=[YOUR_SUPABASE_URL]
   NEXT_PUBLIC_SUPABASE_ANON_KEY=[YOUR_SUPABASE_ANON_KEY]
   SUPABASE_SERVICE_ROLE_KEY=[YOUR_SUPABASE_SERVICE_ROLE_KEY]
   NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=[YOUR_STRIPE_PUBLISHABLE_KEY]
   STRIPE_SECRET_KEY=[YOUR_STRIPE_SECRET_KEY]
   NEXTAUTH_URL=[YOUR_PRODUCTION_URL]
   NEXTAUTH_SECRET=[GENERATE_WITH: openssl rand -base64 32]
   ```

5. **Deploy**
   - Click "Deploy"
   - Wait for deployment to complete

### Option 2: Via Terminal (If Logged In)

```bash
npx vercel login
npx vercel link
npx vercel --prod
```

## Troubleshooting

### Build Errors
- Check Next.js compatibility (currently using 16.0.1)
- Verify all environment variables are set
- Check for missing dependencies

### 404 Errors
- Verify root directory is set correctly
- Check build output directory (.next)
- Ensure all API routes are properly configured