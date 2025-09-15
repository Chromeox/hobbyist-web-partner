# App Store Connect API Setup Guide

This guide walks you through setting up App Store Connect API authentication for automated code signing and distribution with Fastlane.

## Overview

The App Store Connect API provides a secure way to automate iOS app distribution without relying on Apple ID credentials and two-factor authentication prompts.

## Prerequisites

- Apple Developer Program membership
- Admin or Developer role in App Store Connect
- Access to your development team's App Store Connect account

## Step 1: Generate API Key in App Store Connect

### 1.1 Access App Store Connect API Settings
1. Sign in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **Users and Access** → **Integrations** → **App Store Connect API**
3. Click the **+** button to create a new API key

### 1.2 Configure API Key
1. **Name**: Enter a descriptive name (e.g., "HobbyistSwiftUI Fastlane Automation")
2. **Access**: Select **Developer** (recommended) or **Admin** if broader access is needed
3. **Download**: Click **Generate** and immediately download the `.p8` file
   - ⚠️ **IMPORTANT**: This file can only be downloaded once. Store it securely!

### 1.3 Record Key Information
After creating the key, record these values:
- **Key ID**: 10-character identifier (e.g., `ABC123DEFG`)
- **Issuer ID**: UUID format (e.g., `12345678-1234-1234-1234-123456789012`)
- **Key File**: The downloaded `.p8` file

## Step 2: Secure Key Storage

### 2.1 Store the P8 File Securely
```bash
# Create a secure directory for API keys
mkdir -p ~/.app-store-connect-keys
chmod 700 ~/.app-store-connect-keys

# Move and secure the P8 file (replace YOUR_KEY_ID with actual key ID)
mv ~/Downloads/AuthKey_YOUR_KEY_ID.p8 ~/.app-store-connect-keys/
chmod 600 ~/.app-store-connect-keys/AuthKey_YOUR_KEY_ID.p8
```

### 2.2 Update Environment Variables
Add these to your `fastlane/.env` file:

```bash
# App Store Connect API Configuration
APP_STORE_CONNECT_API_KEY_ID="YOUR_KEY_ID"
APP_STORE_CONNECT_API_ISSUER_ID="YOUR_ISSUER_ID"
APP_STORE_CONNECT_API_KEY_FILEPATH="/Users/$(whoami)/.app-store-connect-keys/AuthKey_YOUR_KEY_ID.p8"

# Optional: Alternative path relative to fastlane directory
# APP_STORE_CONNECT_API_KEY_FILEPATH="./AuthKey_YOUR_KEY_ID.p8"
```

## Step 3: Update Fastlane Configuration

### 3.1 Update Appfile
The API key configuration in `fastlane/Appfile`:

```ruby
# App Store Connect API Authentication (preferred method)
if ENV["APP_STORE_CONNECT_API_KEY_ID"]
  app_store_connect_api_key(
    key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
    issuer_id: ENV["APP_STORE_CONNECT_API_ISSUER_ID"],
    key_filepath: ENV["APP_STORE_CONNECT_API_KEY_FILEPATH"],
    duration: 1200, # optional (maximum 1200)
    in_house: false # optional but may be required if using Enterprise account
  )
else
  # Fallback to Apple ID authentication
  apple_id(ENV["APPLE_ID"])
  itc_team_id(ENV["APP_STORE_CONNECT_TEAM_ID"])
  team_id(ENV["DEVELOPER_TEAM_ID"])
end
```

### 3.2 Update Match Configuration
Ensure your `fastlane/Matchfile` supports API key authentication:

```ruby
# The Matchfile will automatically use App Store Connect API if configured in Appfile
# No additional changes needed, but ensure these are set:
app_identifier(["com.hobbyist.bookingapp"])
username(ENV["APPLE_ID"]) # Still needed for certificate generation
team_id(ENV["DEVELOPER_TEAM_ID"])
```

## Step 4: Testing the Setup

### 4.1 Verify API Connection
Test the API connection with a simple Fastlane command:

```bash
# Navigate to your project directory
cd /Users/chromefang.exe/HobbyistSwiftUI

# Test App Store Connect API connection
fastlane run app_store_connect_api_key \
  key_id:"YOUR_KEY_ID" \
  issuer_id:"YOUR_ISSUER_ID" \
  key_filepath:"~/.app-store-connect-keys/AuthKey_YOUR_KEY_ID.p8"
```

### 4.2 Test Certificate Management
```bash
# Test match with API authentication
fastlane match development --readonly
```

## Step 5: Security Best Practices

### 5.1 File Permissions
- P8 file: `600` (read/write for owner only)
- Directory: `700` (full access for owner only)
- `.env` file: `600` and **never commit to version control**

### 5.2 Key Rotation
- Rotate API keys every 6-12 months
- Use different keys for different environments (dev/staging/production)
- Monitor key usage in App Store Connect

### 5.3 Environment Separation
Create separate `.env` files for different environments:
- `.env.development`
- `.env.staging`
- `.env.production`

## Step 6: CI/CD Integration

### 6.1 GitHub Actions Setup
For GitHub Actions, store secrets in repository settings:

```yaml
# .github/workflows/deploy.yml
env:
  APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
  APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
  APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
```

### 6.2 Other CI Platforms
- **Xcode Cloud**: Upload P8 file in Xcode Cloud settings
- **Jenkins**: Use Jenkins credential management
- **GitLab CI**: Use protected variables

## Troubleshooting

### Common Issues

1. **"Invalid API Key"**
   - Verify Key ID and Issuer ID are correct
   - Check that P8 file path is accessible
   - Ensure key hasn't been revoked

2. **"Insufficient Permissions"**
   - Verify API key has appropriate role (Developer/Admin)
   - Check that your Apple ID has necessary permissions

3. **"File Not Found"**
   - Verify P8 file path in environment variable
   - Check file permissions (should be readable by current user)

4. **Rate Limiting**
   - App Store Connect API has rate limits
   - Implement retry logic in CI/CD pipelines

### Debug Commands
```bash
# Check environment variables
env | grep APP_STORE_CONNECT

# Test file accessibility
ls -la ~/.app-store-connect-keys/

# Validate P8 file format
openssl pkcs8 -nocrypt -in ~/.app-store-connect-keys/AuthKey_YOUR_KEY_ID.p8 -topk8
```

## Benefits of API Key Authentication

✅ **No 2FA prompts** - Fully automated workflows  
✅ **Enhanced security** - Key-based authentication  
✅ **Better CI/CD** - No interactive authentication  
✅ **Audit trail** - Track API usage in App Store Connect  
✅ **Role-based access** - Fine-grained permissions  

## Next Steps

After completing this setup:
1. Configure Fastlane Match for certificate management
2. Set up automated build and distribution workflows
3. Test the complete CI/CD pipeline

## Support

- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [Fastlane App Store Connect API Guide](https://docs.fastlane.tools/app-store-connect-api/)
- [Apple Developer Support](https://developer.apple.com/support/)