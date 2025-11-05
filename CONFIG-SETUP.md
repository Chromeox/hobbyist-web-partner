# HobbyApp Configuration Setup Guide

## Overview

The HobbyApp uses a secure configuration system with multiple fallback options:

1. **Keychain** (most secure, production)
2. **Config-Dev.plist** (development)
3. **Environment variables** (CI/CD)
4. **Fallback defaults** (development only)

## Development Configuration

### Config-Dev.plist Structure

The development configuration file contains all necessary keys for local development:

#### Core Services
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Public anonymous key for client-side auth
- `SUPABASE_SERVICE_ROLE_KEY` - Admin key for server operations

#### Payment Integration  
- `STRIPE_PUBLISHABLE_KEY` - Test key for client-side Stripe integration
- `STRIPE_SECRET_KEY` - Test key for server-side payment processing

#### OAuth & Authentication
- `GOOGLE_CLIENT_ID` - Google Sign-In configuration
- `APPLE_TEAM_ID` - Apple Developer Team ID (594BDWKT53)
- `APPLE_CLIENT_ID` - Bundle ID for Apple Sign-In

#### Analytics & Monitoring
- `SENTRY_DSN` - Error tracking and monitoring
- `AMPLITUDE_API_KEY` - User analytics and behavior tracking

#### Development Features
- `ENABLE_LOGGING` - Detailed console logging
- `ENABLE_DEBUG_MENU` - In-app debug options
- `MOCK_DATA_ENABLED` - Use mock data when APIs unavailable
- `SIMULATE_SLOW_NETWORK` - Test loading states

#### Feature Flags
- `ENABLE_APPLE_PAY` - Apple Pay integration
- `ENABLE_PUSH_NOTIFICATIONS` - Push notification support
- `ENABLE_LOCATION_SERVICES` - Location-based features
- `ENABLE_BIOMETRIC_AUTH` - Touch/Face ID authentication

## Security Notes

### Development Environment
- Certificate pinning is **disabled** for development
- Mock data is **enabled** for offline testing
- Logging is **enabled** for debugging
- Rate limiting is **disabled** for easier testing

### Placeholder Values
Some keys contain placeholder values that should be replaced with real values when available:

- `SENTRY_DSN` - Replace with actual Sentry project DSN
- `AMPLITUDE_API_KEY` - Replace with actual Amplitude API key
- `APP_STORE_CONNECT_SHARED_SECRET` - Replace with actual shared secret
- `WEBHOOK_BASE_URL` - Replace with ngrok or actual webhook URL

### Real API Keys Included
The following keys are **real** and functional:
- ✅ Supabase URL and keys (production-ready)
- ✅ Stripe test keys (working for development)
- ✅ Google Client ID (configured for this bundle)
- ✅ Apple Team and Client IDs (verified)

## Configuration Loading Process

1. **App Launch**: `AppConfiguration.shared` loads configuration
2. **Environment Detection**: Automatically detects development/staging/production
3. **Source Priority**: Keychain → Plist → Environment → Fallbacks
4. **Validation**: Checks for required fields and valid formats
5. **Security**: Saves valid config to Keychain for future use

## Production Setup

For production deployment:

1. **Remove** Config-Dev.plist from production builds
2. **Use** Keychain storage for sensitive values
3. **Enable** certificate pinning
4. **Disable** debug features and mock data
5. **Configure** production API endpoints

## Troubleshooting

### Configuration Not Loading
- Check file exists: `HobbyApp/Config-Dev.plist`
- Verify required keys are present
- Look for placeholder values that need replacement
- Check console for configuration error messages

### Common Issues
- **"No configuration found"**: File missing or malformed
- **"Contains placeholder values"**: Replace placeholder strings
- **"Invalid URL format"**: Check SUPABASE_URL is https://
- **"Keychain access failed"**: Reset iOS Simulator or check permissions

### Debug Commands
```swift
// Check current configuration
print(AppConfiguration.shared.current)

// Validate configuration
print(AppConfiguration.shared.validateConfiguration())

// Check environment
print(AppConfiguration.Environment.current)
```

## Next Steps

1. Replace placeholder values with real API keys when available
2. Test configuration loading in iOS Simulator
3. Verify all services connect properly
4. Set up production configuration for App Store build

---

*Last Updated: November 5, 2024*
*Configuration Version: v2.0*