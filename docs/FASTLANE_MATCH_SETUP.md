# Fastlane Match Setup Guide

This guide walks you through setting up Fastlane Match for automated certificate and provisioning profile management.

## Overview

Fastlane Match creates and maintains your certificates and provisioning profiles for you and stores them in a git repository, encrypted and password-protected. This ensures all team members have access to the same certificates and profiles.

## Prerequisites

- ✅ Fastlane installed (version 2.228.0 detected)
- ✅ Apple Developer Program membership
- ✅ App Store Connect API key configured (see APP_STORE_CONNECT_API_SETUP.md)
- Git repository for storing certificates (private repository recommended)

## Step 1: Create Certificate Repository

### 1.1 Create Private Git Repository
Create a **private** git repository to store your certificates:

**Option A: GitHub**
```bash
# Using GitHub CLI (install with: brew install gh)
gh repo create certificates --private
```

**Option B: Manual Creation**
1. Go to [GitHub](https://github.com) → New Repository
2. Name: `certificates` or `ios-certificates`
3. **Important**: Set as **Private**
4. Initialize with README
5. Copy the repository URL

### 1.2 Repository Structure
Match will create this structure in your repository:
```
certificates-repo/
├── certs/
│   ├── development/
│   ├── appstore/
│   └── enterprise/ (if needed)
├── profiles/
│   ├── development/
│   ├── appstore/
│   └── enterprise/ (if needed)
└── README.md
```

## Step 2: Configure Match Environment

### 2.1 Update .env Configuration
Add these variables to your `fastlane/.env` file:

```bash
# Match (Code Signing) Configuration
MATCH_PASSWORD="your-strong-encryption-password"
MATCH_GIT_URL="https://github.com/yourusername/certificates.git"
MATCH_KEYCHAIN_NAME="fastlane_tmp_keychain"
MATCH_KEYCHAIN_PASSWORD="fastlane-keychain-password"

# Git Authentication (if using HTTPS with token)
MATCH_GIT_BASIC_AUTHORIZATION="base64-encoded-username-token"

# Optional Match Settings
MATCH_FORCE_FOR_NEW_DEVICES="false"
MATCH_READONLY_IN_CI="true"
MATCH_SHALLOW_CLONE="true"
```

### 2.2 Generate Git Basic Authorization (if needed)
For private repositories, create a Personal Access Token:

```bash
# Replace with your GitHub username and personal access token
echo -n "username:token" | base64
```

## Step 3: Initialize Match

### 3.1 Initialize Match for Your App
```bash
cd /Users/chromefang.exe/HobbyApp

# Initialize Match (this will create initial certificates)
fastlane match init
```

Follow the prompts:
- **Git URL**: Enter your certificate repository URL
- **Branch**: Use `main` (default)
- **App Identifier**: `com.hobbyist.bookingapp`

### 3.2 Generate Development Certificates
```bash
# Generate development certificates and profiles
fastlane match development
```

### 3.3 Generate App Store Certificates
```bash
# Generate App Store distribution certificates and profiles
fastlane match appstore
```

## Step 4: Update Fastlane Configuration

### 4.1 Enhanced Matchfile
Update your `fastlane/Matchfile`:

```ruby
# Git repository URL for storing certificates and provisioning profiles
git_url(ENV["MATCH_GIT_URL"])

# Storage mode (git is recommended)
storage_mode("git")

# App identifier
app_identifier(["com.hobbyist.bookingapp"])

# Apple Developer Account
username(ENV["APPLE_ID"])

# Team ID
team_id(ENV["DEVELOPER_TEAM_ID"])

# Git branch for certificates
git_branch("main")

# Git authentication for private repositories
if ENV["MATCH_GIT_BASIC_AUTHORIZATION"]
  git_basic_authorization(Base64.strict_encode64(ENV["MATCH_GIT_BASIC_AUTHORIZATION"]))
end

# Keychain configuration
keychain_name(ENV["MATCH_KEYCHAIN_NAME"] || "fastlane_tmp_keychain")
keychain_password(ENV["MATCH_KEYCHAIN_PASSWORD"])

# Performance optimizations
shallow_clone(ENV["MATCH_SHALLOW_CLONE"] == "true")

# CI/CD configuration
readonly(ENV["CI"] == "true" || ENV["MATCH_READONLY_IN_CI"] == "true")

# Force update profiles when new devices are added
force_for_new_devices(ENV["MATCH_FORCE_FOR_NEW_DEVICES"] == "true")

# For more information about the Matchfile, see:
#     https://docs.fastlane.tools/actions/match/#parameters
```

### 4.2 Update Appfile for API Key Support
Ensure your `fastlane/Appfile` includes API key configuration:

```ruby
# App identifier for the app
app_identifier("com.hobbyist.bookingapp") # Your bundle identifier

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
  apple_id(ENV["APPLE_ID"]) # Your Apple email address
  itc_team_id(ENV["APP_STORE_CONNECT_TEAM_ID"]) # App Store Connect Team ID
  team_id(ENV["DEVELOPER_TEAM_ID"]) # Developer Portal Team ID
end

# For more information about the Appfile, see:
#     https://docs.fastlane.tools/advanced/#appfile
```

## Step 5: Xcode Project Integration

### 5.1 Update Build Settings
Configure your Xcode project to use Match certificates:

```bash
# Update project provisioning profiles
fastlane run update_project_provisioning \
  xcodeproj:"HobbyistSwiftUI.xcodeproj" \
  target_filter:"HobbyistSwiftUI" \
  profile:"$(sigh_com.hobbyist.bookingapp_appstore_profile-path)" \
  code_signing_identity:"iPhone Distribution"
```

### 5.2 Automatic Code Signing vs Manual
Your project is currently using **Automatic** signing. For Match integration, you have options:

**Option A: Keep Automatic (Recommended)**
- Keep `CODE_SIGN_STYLE = Automatic`
- Match will ensure certificates are available
- Xcode handles profile selection automatically

**Option B: Switch to Manual**
- Set `CODE_SIGN_STYLE = Manual`
- Use Match to specify exact profiles
- More control but requires maintenance

## Step 6: Enhanced Fastlane Lanes

### 6.1 Certificate Management Lane
Add this enhanced lane to your `Fastfile`:

```ruby
# Enhanced certificate setup with device management
lane :setup_certificates do |options|
  desc "Setup certificates and provisioning profiles with enhanced device management"
  
  # Sync new devices if any were added
  if options[:force_for_new_devices] || ENV["MATCH_FORCE_FOR_NEW_DEVICES"] == "true"
    UI.message "🔄 Syncing certificates for new devices..."
    
    # Register any new devices from devices.txt if it exists
    if File.exist?("./fastlane/devices.txt")
      register_devices(devices_file: "./fastlane/devices.txt")
    end
    
    # Force update development profiles
    match(
      type: "development",
      app_identifier: "com.hobbyist.bookingapp",
      force_for_new_devices: true,
      readonly: ENV["CI"] == "true"
    )
  else
    # Standard certificate sync
    match(
      type: "development",
      app_identifier: "com.hobbyist.bookingapp",
      readonly: ENV["CI"] == "true"
    )
  end
  
  # App Store certificates
  match(
    type: "appstore",
    app_identifier: "com.hobbyist.bookingapp",
    readonly: ENV["CI"] == "true"
  )
  
  UI.success "✅ Certificates and provisioning profiles setup complete"
end
```

### 6.2 Device Registration Lane
```ruby
# Lane for registering new devices
lane :register_new_devices do |options|
  desc "Register new devices and update provisioning profiles"
  
  # Option 1: Register devices from file
  if options[:devices_file] || File.exist?("./fastlane/devices.txt")
    register_devices(
      devices_file: options[:devices_file] || "./fastlane/devices.txt"
    )
  end
  
  # Option 2: Register individual device
  if options[:device_name] && options[:device_udid]
    register_devices(
      devices: {
        options[:device_name] => options[:device_udid]
      }
    )
  end
  
  # Update development profiles with new devices
  match(
    type: "development",
    app_identifier: "com.hobbyist.bookingapp",
    force_for_new_devices: true
  )
  
  UI.success "✅ New devices registered and profiles updated"
end
```

### 6.3 Certificate Renewal Lane
```ruby
# Lane for certificate renewal
lane :renew_certificates do |options|
  desc "Renew expired certificates and provisioning profiles"
  
  # Force renewal of development certificates
  match(
    type: "development",
    app_identifier: "com.hobbyist.bookingapp",
    force: true
  )
  
  # Force renewal of App Store certificates
  match(
    type: "appstore",
    app_identifier: "com.hobbyist.bookingapp", 
    force: true
  )
  
  UI.success "✅ Certificates renewed successfully"
end
```

## Step 7: Team Sharing

### 7.1 Share Repository Access
Add team members to the certificate repository:
1. Go to your certificate repository on GitHub
2. Settings → Manage access → Invite a collaborator
3. Share the `MATCH_PASSWORD` securely (use password manager)

### 7.2 Team Setup Commands
New team members run:
```bash
# Clone certificates (read-only)
fastlane match development --readonly
fastlane match appstore --readonly
```

## Step 8: Testing and Validation

### 8.1 Test Certificate Installation
```bash
# Test development certificates
fastlane match development --readonly

# Test App Store certificates  
fastlane match appstore --readonly
```

### 8.2 Validate Keychain
```bash
# List certificates in keychain
security find-identity -v -p codesigning

# Check specific keychain
security find-identity -v -p codesigning fastlane_tmp_keychain
```

### 8.3 Test Build with Match
```bash
# Test build with Match certificates
fastlane setup_certificates
fastlane build_app_store
```

## Step 9: Security Best Practices

### 9.1 Password Management
- Use a strong, unique password for `MATCH_PASSWORD`
- Store passwords in a secure password manager
- Share passwords securely with team members
- Rotate passwords periodically

### 9.2 Repository Security
- Use private repositories only
- Enable two-factor authentication
- Regularly audit repository access
- Monitor repository activity

### 9.3 Keychain Management
- Use temporary keychains in CI/CD
- Clean up keychains after builds
- Don't store passwords in build logs

## Step 10: CI/CD Integration

### 10.1 GitHub Actions Example
```yaml
name: iOS Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup certificates
      env:
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }}
        APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
        APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
        APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
      run: |
        echo "$APP_STORE_CONNECT_API_KEY_CONTENT" > ./AuthKey.p8
        fastlane setup_certificates
        
    - name: Build and upload to TestFlight
      run: fastlane upload_testflight
```

## Troubleshooting

### Common Issues

1. **Certificate Conflicts**
   ```bash
   # Clean up conflicting certificates
   fastlane match nuke development
   fastlane match nuke appstore
   # Then regenerate
   fastlane match development
   fastlane match appstore
   ```

2. **Git Authentication Issues**
   - Verify `MATCH_GIT_BASIC_AUTHORIZATION` is correctly encoded
   - Check repository permissions
   - Ensure token has repository access

3. **Keychain Issues**
   ```bash
   # Reset keychain
   fastlane match --force
   ```

4. **Device Registration Problems**
   - Verify device UDID format
   - Check Apple Developer Portal for device limits
   - Ensure devices.txt format is correct

### Debug Commands
```bash
# Verbose Match output
fastlane match development --verbose

# Check Match status
fastlane match --help

# Test git repository access
git ls-remote $MATCH_GIT_URL
```

## Benefits

✅ **Automated Certificate Management** - No more manual certificate creation  
✅ **Team Synchronization** - All developers use the same certificates  
✅ **CI/CD Ready** - Seamless integration with automated workflows  
✅ **Version Control** - Track certificate changes over time  
✅ **Security** - Encrypted storage with password protection  

## Next Steps

After completing Match setup:
1. Test the complete build and signing process
2. Set up automated CI/CD pipelines
3. Configure team member access
4. Implement certificate rotation schedule

## Support

- [Fastlane Match Documentation](https://docs.fastlane.tools/actions/match/)
- [Code Signing Guide](https://docs.fastlane.tools/codesigning/getting-started/)
- [Troubleshooting Guide](https://docs.fastlane.tools/codesigning/troubleshooting/)