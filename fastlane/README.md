# HobbyistSwiftUI Fastlane Configuration

This directory contains the Fastlane configuration for automating the build, test, and deployment processes for HobbyistSwiftUI.

## 📋 Prerequisites

1. **Install Fastlane**: `gem install fastlane` or use Bundler
2. **Xcode Command Line Tools**: `xcode-select --install`
3. **Apple Developer Account**: With appropriate permissions
4. **Environment Variables**: Copy `.env.example` to `.env` and configure

## 🚀 Available Lanes

### 📱 Main Release Lanes

#### TestFlight Release
```bash
# Complete TestFlight release (recommended)
fastlane release_testflight

# Upload to TestFlight with custom changelog
fastlane upload_testflight changelog:"Bug fixes and new features"

# Build only for TestFlight
fastlane build_testflight
```

#### App Store Release
```bash
# Complete App Store release
fastlane release_app_store

# Upload to App Store with options
fastlane upload_app_store submit_for_review:true automatic_release:false

# Build only for App Store
fastlane build_app_store
```

### 🔧 Utility Lanes

#### Code Signing
```bash
# Setup certificates and provisioning profiles
fastlane setup_certificates

# Complete code signing setup
fastlane setup_code_signing
```

#### Testing
```bash
# Run all tests
fastlane test

# Generate screenshots
fastlane generate_screenshots

# Upload screenshots only
fastlane upload_screenshots
```

#### Metadata Management
```bash
# Update App Store metadata only
fastlane update_metadata

# Update metadata without screenshots
fastlane update_metadata skip_screenshots:true
```

#### Hotfix and Emergency
```bash
# Create hotfix release
fastlane hotfix_release version:"1.0.1" changelog:"Critical bug fix"
```

#### Maintenance
```bash
# Clean up build artifacts
fastlane cleanup

# Register new devices for development
fastlane register_devices
```

## 📝 Configuration Files

### Core Configuration
- **`Fastfile`**: Main lane definitions and automation logic
- **`Appfile`**: App identifier and team information
- **`.env`**: Environment variables (create from `.env.example`)

### Specialized Configuration
- **`Matchfile`**: Code signing certificate management
- **`Deliverfile`**: App Store Connect upload settings
- **`Gymfile`**: Build configuration and export options
- **`Scanfile`**: Test execution configuration
- **`Snapshotfile`**: Screenshot generation settings

## 🔐 Environment Setup

### Required Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Apple Developer Account
APPLE_ID="your-apple-id@example.com"
DEVELOPER_TEAM_ID="YOUR_DEVELOPER_TEAM_ID"
APP_STORE_CONNECT_TEAM_ID="YOUR_APP_STORE_CONNECT_TEAM_ID"

# Authentication
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"

# Code Signing
MATCH_PASSWORD="your-match-repository-password"
MATCH_GIT_URL="https://github.com/yourorg/certificates-repo.git"
```

### Apple Developer Account Setup

1. **App-Specific Password**: Generate at [appleid.apple.com](https://appleid.apple.com)
2. **Team IDs**: Find in Apple Developer Portal
3. **Match Repository**: Private Git repository for certificates

## 📊 CI/CD Integration

### GitHub Actions Integration

The Fastlane configuration integrates with GitHub Actions:

```yaml
# Example workflow usage
- name: Deploy to TestFlight
  run: fastlane release_testflight
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
    FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD }}
```

### Required Secrets

Configure these secrets in your CI/CD system:
- `MATCH_PASSWORD`
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`
- `APPLE_ID`
- `DEVELOPER_TEAM_ID`
- `APP_STORE_CONNECT_TEAM_ID`

## 🔄 Typical Workflows

### Alpha Release Process
1. **Prepare Release**:
   ```bash
   fastlane test                    # Run tests
   fastlane generate_screenshots    # Update screenshots
   ```

2. **Deploy to TestFlight**:
   ```bash
   fastlane release_testflight
   ```

3. **Monitor and Iterate**: Use TestFlight feedback for improvements

### App Store Submission Process
1. **Final Testing**:
   ```bash
   fastlane test
   fastlane build_app_store
   ```

2. **Submit for Review**:
   ```bash
   fastlane release_app_store submit_for_review:true
   ```

3. **Metadata Updates** (if needed):
   ```bash
   fastlane update_metadata
   ```

### Emergency Hotfix Process
1. **Create Hotfix Build**:
   ```bash
   fastlane hotfix_release version:"1.0.1" changelog:"Critical security fix"
   ```

2. **Fast-track Review**: Contact Apple for expedited review if critical

## 📱 Device and Screenshot Management

### Supported Devices
- iPhone 15 Pro Max
- iPhone 15 Pro
- iPhone SE (3rd generation)
- iPad Pro (12.9-inch) (6th generation)
- iPad Pro (11-inch) (4th generation)

### Screenshot Generation
```bash
# Generate all screenshots
fastlane generate_screenshots

# Upload to App Store Connect
fastlane upload_screenshots
```

## 🛠 Troubleshooting

### Common Issues

#### Code Signing Issues
```bash
# Reset and recreate certificates
fastlane match nuke development
fastlane match nuke appstore
fastlane setup_code_signing
```

#### Build Failures
```bash
# Clean and retry
fastlane cleanup
fastlane test
fastlane build_testflight
```

#### Authentication Problems
1. Verify App-Specific Password is current
2. Check team IDs are correct
3. Ensure Apple ID has appropriate permissions

### Debug Mode
```bash
# Run with verbose output
fastlane release_testflight --verbose

# Capture logs
fastlane release_testflight 2>&1 | tee fastlane.log
```

## 📊 Monitoring and Notifications

### Slack Integration
Configure `SLACK_WEBHOOK_URL` for deployment notifications:
- Build success/failure alerts
- Release status updates
- Error notifications with context

### Build Metrics
Fastlane automatically tracks:
- Build times and success rates
- Test coverage and results
- Deployment success metrics

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Update certificates with `fastlane setup_code_signing`
- **Monthly**: Review and clean up old builds with `fastlane cleanup`
- **Before Major Releases**: Generate fresh screenshots

### Updates
- **Fastlane**: `gem update fastlane`
- **Plugins**: `fastlane update_plugins`
- **Dependencies**: `bundle update`

## 🎯 Best Practices

1. **Always test before releasing**: `fastlane test`
2. **Use descriptive changelogs**: Help testers understand changes
3. **Monitor phased releases**: Watch crash rates and user feedback
4. **Keep certificates updated**: Use Match for team synchronization
5. **Version control configuration**: Track changes to Fastlane files

## 📞 Support

For issues with this Fastlane configuration:
1. Check the troubleshooting section above
2. Review Fastlane documentation: [docs.fastlane.tools](https://docs.fastlane.tools)
3. Contact the development team

---

**Last Updated**: December 2024  
**Fastlane Version**: 2.217.0  
**Configuration Version**: 1.0.0