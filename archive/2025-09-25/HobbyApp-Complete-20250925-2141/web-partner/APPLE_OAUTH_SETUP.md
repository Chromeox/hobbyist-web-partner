# 🍎 Apple OAuth Setup Guide

Complete guide for setting up Sign In with Apple for the Hobbyist Partner Portal.

## Prerequisites
- Apple Developer Account
- Access to Apple Developer Console
- Supabase project access

## Step-by-Step Setup

### 1. Apple Developer Console - Create App ID

1. Visit [Apple Developer Console](https://developer.apple.com/account/)
2. Go to "Certificates, Identifiers & Profiles"
3. Click "Identifiers" → "+"
4. Select "App IDs" → Continue
5. Choose "App" → Continue
6. Fill out:
   - **Description**: "Hobbyist Partner Portal"
   - **Bundle ID**: `com.hobbyist.partner-portal` (explicit)
   - **Capabilities**: ✅ Enable "Sign In with Apple"
7. Click "Continue" → "Register"

### 2. Apple Developer Console - Create Services ID

1. Go back to "Identifiers" → "+"
2. Select "Services IDs" → Continue
3. Fill out:
   - **Description**: "Hobbyist Partner Portal Web"
   - **Identifier**: `com.hobbyist.partner-portal.web`
4. Click "Continue" → "Register"
5. Click on your new Services ID to configure
6. Check "Sign In with Apple" → "Configure"
7. Set:
   - **Primary App ID**: Select the App ID from step 1
   - **Website URLs**:
     - **Domains**: `localhost`, `your-production-domain.com`
     - **Return URLs**:
       - `http://localhost:3002/auth/callback`
       - `https://mcjqvdzdhtcvbrejvrtp.supabase.co/auth/v1/callback`
8. Click "Next" → "Done" → "Continue" → "Save"

### 3. Apple Developer Console - Create Private Key

1. Navigate to "Keys" → "+"
2. Fill out:
   - **Key Name**: "Hobbyist Partner Portal Sign In Key"
   - **Enable**: ✅ "Sign In with Apple"
3. Click "Configure" → Select your Primary App ID → "Save"
4. Click "Continue" → "Register"
5. **⚠️ IMPORTANT**: Download the `.p8` file immediately!
6. Note the **Key ID** (10 characters, e.g., `ABC123DEF4`)

### 4. Get Your Team ID

1. Go to Apple Developer Console main page
2. Your **Team ID** is in the top right (10 characters, e.g., `XYZ789ABC1`)

### 5. Generate Apple Client Secret (JWT)

1. Place your downloaded `.p8` file in the `web-partner` directory
2. Edit `scripts/generate-apple-jwt.js` with your values:
   ```javascript
   const config = {
     teamId: 'YOUR_TEAM_ID_HERE',        // From step 4
     clientId: 'com.hobbyist.partner-portal.web', // From step 2
     keyId: 'YOUR_KEY_ID_HERE',          // From step 3
     privateKeyPath: './AuthKey_YOUR_KEY_ID_HERE.p8' // Your downloaded file
   };
   ```
3. Run the script:
   ```bash
   node scripts/generate-apple-jwt.js
   ```
4. Copy the generated JWT token

### 6. Update Environment Variables

Add these to your `.env.local`:

```env
# Apple OAuth Configuration
NEXT_PUBLIC_APPLE_CLIENT_ID=com.hobbyist.partner-portal.web
APPLE_CLIENT_SECRET=eyJhbGciOiJFUzI1NiIsImtpZCI6IkFCQzEyM0RFRjQiLCJ0eXAiOiJKV1QifQ...
APPLE_TEAM_ID=XYZ789ABC1
APPLE_KEY_ID=ABC123DEF4
```

### 7. Configure Supabase

1. Visit [Supabase Dashboard](https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp)
2. Go to "Authentication" → "Providers"
3. Find "Apple" and click "Configure"
4. Fill out:
   - **Enabled**: ✅ Toggle ON
   - **Client ID**: `com.hobbyist.partner-portal.web`
   - **Client Secret**: The JWT token from step 5
   - **Redirect URL**: Copy the provided URL

### 8. Test the Integration

1. Visit `http://localhost:3002/auth/signin`
2. Click the Apple Sign In button
3. Should redirect to Apple's authentication
4. After successful auth, should redirect back to your dashboard

## Important Notes

- **JWT Token Expiry**: Apple JWT tokens expire in 180 days maximum
- **Private Key Security**: Never commit your `.p8` file to version control
- **Team ID**: Required for JWT signing and must match your Apple Developer account
- **Bundle ID**: Must be unique and match across App ID and Services ID

## Troubleshooting

### Common Issues

1. **"invalid_client" error**: Check your Client ID matches your Services ID exactly
2. **"invalid_request" error**: Verify your redirect URLs are configured correctly
3. **JWT signature errors**: Ensure your private key, team ID, and key ID are correct
4. **Redirect loops**: Check that your Supabase redirect URL is properly configured

### Regenerating JWT Token

When your JWT token expires (every 180 days):

1. Run the JWT generation script again: `node scripts/generate-apple-jwt.js`
2. Update your `.env.local` with the new token
3. Update the Client Secret in Supabase Dashboard

## Security Best Practices

- Store your `.p8` private key securely and never commit to version control
- Regenerate JWT tokens regularly (don't wait for expiry)
- Use environment variables for all sensitive configuration
- Regularly audit your Apple Developer Console for unused keys and services

---

✅ **Setup Complete!** Your Apple Sign In should now work alongside Google OAuth.