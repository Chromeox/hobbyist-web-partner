# CI/CD Pipeline Setup Guide for HobbyistSwiftUI

## Overview
Complete guide to set up automated TestFlight deployment, security scanning, and App Store release automation for your HobbyistSwiftUI iOS app.

## Prerequisites Checklist

### Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Team ID and Team Name noted down
- [ ] App Store Connect access configured
- [ ] Two-Factor Authentication enabled

### GitHub Repository
- [ ] Repository: `https://github.com/Chromeox/HobbyistSwiftUI.git` ✅
- [ ] Admin access to repository settings ✅
- [ ] GitHub Actions enabled ✅

## Phase 1: GitHub Secrets Configuration

### Required Secrets Setup
Navigate to: `https://github.com/Chromeox/HobbyistSwiftUI/settings/secrets/actions`

#### 1. Apple Developer Credentials
**APPLE_ID**
- Description: Your Apple Developer account email
- Example: `your.email@example.com`
- Where to find: Apple Developer Portal → Account → Personal Information

**DEVELOPER_TEAM_ID**
- Description: Your Apple Developer Team ID (10-character string)
- Example: `ABC1234567`
- Where to find: Apple Developer Portal → Membership tab

**APP_STORE_CONNECT_TEAM_ID**
- Description: App Store Connect Team ID (may be same as DEVELOPER_TEAM_ID)
- Example: `ABC1234567`
- Where to find: App Store Connect → Users and Roles → Your Team

#### 2. App-Specific Password
**FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD**
- Description: App-specific password for Apple ID
- How to create:
  1. Go to `https://appleid.apple.com/account/manage`
  2. Sign in with your Apple ID
  3. In Security section → App-Specific Passwords
  4. Click "Generate Password"
  5. Enter label: "HobbyistSwiftUI CI/CD"
  6. Copy the 16-character password (format: xxxx-xxxx-xxxx-xxxx)

#### 3. Certificate Management
**MATCH_PASSWORD**
- Description: Password to encrypt certificates in private git repo
- Requirements: Strong password, store securely
- Example: Generate with: `openssl rand -base64 32`

**MATCH_GIT_URL**
- Description: Private repository URL for storing certificates
- Format: `https://github.com/Chromeox/HobbyistSwiftUI-certificates.git`
- Note: Create this private repository first (see Phase 2)

**MATCH_GIT_BASIC_AUTHORIZATION** (Optional but recommended)
- Description: Base64 encoded GitHub credentials for Match repo access
- Format: `echo -n "username:personal_access_token" | base64`

#### 4. Optional Notification Setup
**SLACK_WEBHOOK_URL** (Optional)
- Description: Slack webhook for deployment notifications
- How to get: Slack → Apps → Incoming Webhooks

**BETA_FEEDBACK_EMAIL**
- Description: Email for TestFlight beta feedback
- Example: `feedback@hobbyist.app` or your email

## Phase 2: Match Repository Setup

### Create Private Certificate Repository
1. **Create new private repository**:
   ```bash
   # GitHub web interface or CLI
   gh repo create HobbyistSwiftUI-certificates --private --description "Certificate storage for HobbyistSwiftUI CI/CD"
   ```

2. **Initialize Match**:
   ```bash
   cd /Users/chromefang.exe/HobbyApp
   fastlane match init
   ```
   
   When prompted:
   - Storage mode: `git`
   - Git URL: `https://github.com/Chromeox/HobbyistSwiftUI-certificates.git`

3. **Generate initial certificates** (local machine first):
   ```bash
   fastlane match development --app_identifier com.hobbyist.app
   fastlane match appstore --app_identifier com.hobbyist.app
   ```

## Phase 3: Test CI/CD Pipeline

### 1. Test Security Scan Pipeline
```bash
cd /Users/chromefang.exe/HobbyApp

# Trigger security scan manually
gh workflow run "Swift Dependency Security Scan"

# Check status
gh workflow list
```

### 2. Test TestFlight Deployment
```bash
# Manual TestFlight deployment test
gh workflow run "App Store Deployment Automation" \
  -f deployment_type=testflight \
  -f changelog="Initial CI/CD pipeline test build" \
  -f skip_tests=false
```

### 3. Monitor Pipeline Execution
```bash
# Watch workflow status
gh run watch

# View logs for debugging
gh run view --log
```

## Phase 4: Automated Triggers Configuration

### Current Trigger Configuration
Your pipelines are already configured with these triggers:

**Security Scan Pipeline**:
- ✅ Weekly schedule (Mondays 8:00 AM UTC)
- ✅ Package.swift changes
- ✅ Pull request validation
- ✅ Manual trigger available

**Deployment Pipeline**:
- ✅ Manual trigger with parameters
- ✅ Deployment type selection (TestFlight/App Store/Hotfix)
- ✅ Changelog requirement
- ✅ Test execution control

### Enhanced Automation (Optional)
Add to `.github/workflows/testflight-auto-deploy.yml`:

```yaml
name: Auto-Deploy to TestFlight

on:
  push:
    branches: [main]
    paths: [iOS/**]

jobs:
  auto-deploy:
    if: "!contains(github.event.head_commit.message, '[skip ci]')"
    uses: ./.github/workflows/app-store-deployment.yml
    with:
      deployment_type: 'testflight'
      changelog: ${{ github.event.head_commit.message }}
      skip_tests: false
    secrets: inherit
```

## Phase 5: Monitoring and Notifications

### Key Metrics to Monitor
1. **Build Success Rate**: Target >95%
2. **Build Duration**: Target <20 minutes
3. **TestFlight Processing Time**: Usually 10-60 minutes
4. **Security Scan Results**: Zero critical vulnerabilities

### Notification Setup
**Slack Integration** (if configured):
- ✅ Success notifications for deployments
- ✅ Failure alerts with error details
- ✅ Security vulnerability warnings
- ✅ Build status updates

**Email Notifications**:
- GitHub → Settings → Notifications
- Enable "Actions" notifications
- Choose email or web notifications

### Monitoring Dashboard
GitHub repository → Actions tab provides:
- ✅ Workflow run history
- ✅ Success/failure rates
- ✅ Build duration trends
- ✅ Artifact downloads

## Troubleshooting Guide

### Common Issues and Solutions

**1. Certificate Issues**
```bash
# Reset certificates if needed
fastlane match nuke development
fastlane match nuke distribution

# Regenerate
fastlane match development --force
fastlane match appstore --force
```

**2. Build Failures**
- Check Xcode version compatibility
- Verify Package.swift dependencies
- Ensure clean build environment

**3. TestFlight Upload Issues**
- Verify App Store Connect team access
- Check bundle identifier matches
- Ensure increment build number is working

**4. Security Scan Failures**
- Review vulnerable dependencies
- Update Package.swift versions
- Run local security validation

### Debug Commands
```bash
# Local fastlane testing
cd /Users/chromefang.exe/HobbyApp
fastlane test

# Certificate verification
fastlane match development --readonly

# Build verification
fastlane build_testflight --skip_build false
```

## Success Validation Checklist

### Phase 1 Complete ✅
- [ ] All 8 GitHub secrets configured
- [ ] App-specific password generated
- [ ] Team IDs confirmed and added
- [ ] Match password generated and stored

### Phase 2 Complete ✅
- [ ] Private certificates repository created
- [ ] Match initialized locally
- [ ] Development certificates generated
- [ ] App Store certificates generated
- [ ] No certificate errors in Xcode

### Phase 3 Complete ✅
- [ ] Security scan pipeline runs successfully
- [ ] TestFlight deployment pipeline completes
- [ ] First automated build uploaded to TestFlight
- [ ] No critical errors in CI logs

### Phase 4 Complete ✅
- [ ] Automated triggers tested
- [ ] Manual deployment triggers working
- [ ] Pull request validation active
- [ ] Weekly security scans scheduled

### Phase 5 Complete ✅
- [ ] Monitoring dashboard accessible
- [ ] Notifications configured (Slack/email)
- [ ] Success metrics tracked
- [ ] Troubleshooting procedures documented

## Next Steps After Setup

1. **Alpha Testing Launch**:
   ```bash
   gh workflow run "App Store Deployment Automation" \
     -f deployment_type=testflight \
     -f changelog="Alpha testing launch - complete app ready for feedback"
   ```

2. **Regular Maintenance**:
   - Weekly dependency security reviews
   - Monthly certificate renewal checks
   - Quarterly CI/CD pipeline optimization

3. **App Store Preparation**:
   ```bash
   # When ready for App Store
   gh workflow run "App Store Deployment Automation" \
     -f deployment_type=app-store \
     -f submit_for_review=true \
     -f changelog="Official App Store launch"
   ```

## Support and Resources

- **Fastlane Documentation**: https://docs.fastlane.tools
- **GitHub Actions**: https://docs.github.com/actions
- **Apple Developer**: https://developer.apple.com/documentation
- **Match Setup**: https://docs.fastlane.tools/actions/match/

Your CI/CD pipeline is now ready to accelerate your TestFlight alpha testing and App Store launch! 🚀