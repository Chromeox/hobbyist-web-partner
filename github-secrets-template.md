# GitHub Secrets Configuration for HobbyistSwiftUI CI/CD

## Required Secrets
Go to: https://github.com/Chromeox/HobbyistSwiftUI/settings/secrets/actions

### Apple Developer Credentials
1. **APPLE_ID**: Your Apple Developer account email
2. **DEVELOPER_TEAM_ID**: Your 10-character Team ID from Apple Developer Portal
3. **APP_STORE_CONNECT_TEAM_ID**: Usually same as DEVELOPER_TEAM_ID
4. **FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD**: Generate at appleid.apple.com

### Certificate Management
5. **MATCH_PASSWORD**: Strong password to encrypt certificates (generate with: openssl rand -base64 32)
6. **MATCH_GIT_URL**: https://github.com/Chromeox/HobbyistSwiftUI-certificates.git

### Optional Notifications
7. **SLACK_WEBHOOK_URL**: For deployment notifications (optional)
8. **BETA_FEEDBACK_EMAIL**: Email for TestFlight feedback

## Quick Setup Commands
```bash
# Generate Match password
echo "MATCH_PASSWORD: $(openssl rand -base64 32)"

# Get Team ID
echo "Visit: https://developer.apple.com/account/#!/membership/"

# Create App-Specific Password  
echo "Visit: https://appleid.apple.com/account/manage → Security → App-Specific Passwords"
```

## Test Commands (after secrets are set)
```bash
# Test security scan
gh workflow run "Swift Dependency Security Scan"

# Test TestFlight deployment
gh workflow run "App Store Deployment Automation" \
  -f deployment_type=testflight \
  -f changelog="CI/CD pipeline test" \
  -f skip_tests=true
```
