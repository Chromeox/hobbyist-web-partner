# OAuth Setup Guide for Studio Portal

## Current Status

### ✅ Email/Password Authentication - WORKING
- Demo account: demo@hobbyist.com / demo123456
- Admin account: admin@hobbyist.com / admin123456
- Sign up with new email works
- Password reset flow configured

### 🔧 Google OAuth - NEEDS CONFIGURATION

**Current Issue**: "Sign in with Google doesn't work"

**Fix Steps**:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project or create a new one
3. Enable Google+ API and People API
4. Go to "Credentials" → "OAuth 2.0 Client IDs"
5. Create Web Application credentials with these settings:
   ```
   Authorized JavaScript origins:
   - http://localhost:3000
   - https://your-production-domain.com
   
   Authorized redirect URIs:
   - http://localhost:3000/auth/callback
   - https://your-production-domain.com/auth/callback
   ```
6. Update your environment variables with the actual values

### 🔧 Apple OAuth - NEEDS CONFIGURATION

**Current Issue**: "invalid_request - Invalid client id or web redirect url"

**Fix Steps**:
1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to "Certificates, IDs & Profiles" → "Identifiers"
3. Find your App ID: `com.hobbyist.bookingapp`
4. Configure "Sign In with Apple":
   ```
   Primary App ID: com.hobbyist.bookingapp
   Website URLs: 
   - http://localhost:3000
   - https://your-production-domain.com
   
   Return URLs:
   - http://localhost:3000/auth/callback
   - https://your-production-domain.com/auth/callback
   ```

### Supabase OAuth Configuration

**Required**: Configure OAuth providers in Supabase Dashboard

**Steps**:
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to Authentication → Settings → Auth Providers
3. Enable Google with your client credentials
4. Enable Apple with your app credentials
5. Set redirect URL to: https://[YOUR_PROJECT].supabase.co/auth/v1/callback

## Environment Variables Template

Create a `.env.local` file with these variables (use your actual values):

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=[YOUR_SUPABASE_URL]
NEXT_PUBLIC_SUPABASE_ANON_KEY=[YOUR_SUPABASE_ANON_KEY]
SUPABASE_SERVICE_ROLE_KEY=[YOUR_SUPABASE_SERVICE_ROLE_KEY]

# Google OAuth
NEXT_PUBLIC_GOOGLE_CLIENT_ID=[YOUR_GOOGLE_CLIENT_ID]
GOOGLE_CLIENT_SECRET=[YOUR_GOOGLE_CLIENT_SECRET]

# Apple OAuth  
NEXT_PUBLIC_APPLE_CLIENT_ID=com.hobbyist.bookingapp
APPLE_CLIENT_SECRET=[YOUR_APPLE_CLIENT_SECRET]

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=[YOUR_STRIPE_PUBLISHABLE_KEY]
STRIPE_SECRET_KEY=[YOUR_STRIPE_SECRET_KEY]

# Auth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=[GENERATE_WITH: openssl rand -base64 32]
```

## Testing Checklist

### ✅ Email/Password Authentication
- [x] Demo account login
- [x] Admin account login  
- [x] Sign up flow
- [x] Password reset

### 🔧 OAuth (Needs Setup)
- [ ] Google OAuth flow
- [ ] Apple OAuth flow
- [ ] User creation in database
- [ ] Session persistence

## Production Notes

When deploying:
1. Update all redirect URLs to production domain
2. Use production environment variables
3. Test all OAuth flows on live domain
4. Ensure HTTPS for all OAuth callbacks