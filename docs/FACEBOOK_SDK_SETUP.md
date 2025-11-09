# Facebook SDK Setup Guide

## Step 1: Create Facebook App

1. Go to https://developers.facebook.com/apps/
2. Click "Create App"
3. Choose "Consumer" for app type
4. App Details:
   - App Name: "HobbyApp"
   - App Contact Email: privacy@hobbyapp.ca
   - Purpose: Authentication for Vancouver creative class booking app

## Step 2: Configure iOS Platform

1. In Facebook App Dashboard → Settings → Basic
2. Add Platform → iOS
3. Bundle ID: `com.hobbyist.bookingapp`
4. iPhone Store ID: (add when available)

## Step 3: Get App Credentials

From App Dashboard → Settings → Basic:
- **App ID**: [COPY_FROM_DASHBOARD]
- **App Secret**: [COPY_FROM_DASHBOARD] (keep secure)

## Step 4: Configure App Settings

1. **App Domains**: hobbyapp.ca
2. **Privacy Policy URL**: https://hobbyapp.ca/privacy
3. **Terms of Service URL**: https://hobbyapp.ca/terms
4. **User Data Deletion**: https://hobbyapp.ca/data-deletion

## Step 5: Add Facebook Login Product

1. In App Dashboard → Products → Add Product
2. Select "Facebook Login"
3. Platform: iOS
4. Valid OAuth Redirect URIs:
   - `fb[APP_ID]://authorize/`
   - `https://hobbyapp.ca/auth/facebook/callback`

## Step 6: App Review (Before Going Live)

1. Submit for review with these permissions:
   - `email` (default)
   - `public_profile` (default)
2. Provide app screenshots and description
3. Explain use case for authentication

## Integration Notes

- SDK will be added via Swift Package Manager
- Authentication will integrate with Supabase
- User data will be stored in Supabase user_profiles table
- Facebook data is only used for authentication, not stored