# TestFlight Automation System

A comprehensive automation system for iOS TestFlight submissions, designed to streamline the entire process from build validation to tester management.

## 🎯 Overview

This automation system implements all phases of the TestFlight submission specification, providing:

- **Pre-upload validation** - Comprehensive build and environment checks
- **Automated uploads** - Enhanced Fastlane integration with retry logic
- **Status monitoring** - Real-time upload processing tracking
- **Metadata management** - Programmatic App Store Connect metadata updates
- **Version coordination** - Automated version and build number management
- **Testing group management** - Internal and external tester group automation
- **Notification system** - Slack and webhook integration
- **Comprehensive logging** - Detailed audit trails and reporting

## 📁 Project Structure

```
testflight-automation/
├── README.md                      # This documentation
├── scripts/                       # All automation scripts
│   ├── master-automation.sh       # Main orchestrator script
│   ├── pre-upload-validation.sh   # Pre-upload validation
│   ├── upload-status-monitor.sh   # Upload status monitoring  
│   ├── metadata-manager.py        # Metadata management
│   ├── version-manager.sh         # Version/build management
│   └── testing-group-manager.py   # Testing group management
├── configs/                       # Configuration files
│   └── automation-config.yml      # Main configuration
├── templates/                     # Templates and samples
│   ├── testers-template.csv       # Sample tester CSV format
│   └── metadata-template.json     # Metadata template (generated)
├── logs/                          # Log files (auto-created)
├── changelogs/                    # Generated changelogs (auto-created)
├── testers/                       # Tester management files (auto-created)
└── backups/                       # Metadata backups (auto-created)
```

## 🚀 Quick Start

### Prerequisites

1. **Xcode** with command line tools installed
2. **Fastlane** (`gem install fastlane`)
3. **Python 3** with required packages (`pip install pyyaml requests`)
4. **Git** (for changelog generation)
5. **App Store Connect credentials** configured

### Environment Setup

1. Set up required environment variables:
```bash
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"
export MATCH_PASSWORD="your-match-password"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/your-webhook-url"  # Optional
export SLACK_CHANNEL="#ios-releases"  # Optional
```

2. Configure Fastlane match for code signing (if not already done):
```bash
fastlane match init
```

### Basic Usage

1. **Run a dry run** to test the setup:
```bash
./testflight-automation/scripts/master-automation.sh --dry-run
```

2. **Full automation** with default settings:
```bash
./testflight-automation/scripts/master-automation.sh
```

3. **Custom release** with specific options:
```bash
./testflight-automation/scripts/master-automation.sh \
  --increment patch \
  --changelog "Bug fixes and UI improvements" \
  --groups "Alpha Testers,Beta Testers"
```

## 📋 Script Reference

### 1. Master Automation (`master-automation.sh`)

The main orchestrator script that runs the complete automation pipeline.

**Usage:**
```bash
./testflight-automation/scripts/master-automation.sh [options]
```

**Options:**
- `--dry-run` - Perform dry run without making changes
- `--skip-validation` - Skip pre-upload validation
- `--skip-build` - Skip building the app
- `--skip-upload` - Skip uploading to TestFlight
- `--skip-monitoring` - Skip processing status monitoring
- `--skip-groups` - Skip testing group management
- `--increment TYPE` - Version increment (major, minor, patch, build)
- `--version-source SOURCE` - Version source (xcode, git, manual)
- `--changelog TEXT` - Custom changelog text
- `--groups GROUPS` - Comma-separated list of testing groups
- `--no-notify` - Don't notify testers

**Examples:**
```bash
# Full automation with defaults
./master-automation.sh

# Dry run to test process
./master-automation.sh --dry-run

# Patch release with custom changelog
./master-automation.sh --increment patch --changelog "Critical bug fixes"

# Skip monitoring for faster execution
./master-automation.sh --skip-monitoring --groups "Internal Team"
```

### 2. Pre-upload Validation (`pre-upload-validation.sh`)

Validates build configuration, certificates, and environment before upload.

**Usage:**
```bash
./testflight-automation/scripts/pre-upload-validation.sh [options]
```

**Key Validations:**
- Xcode installation and license
- Project structure and scheme validation
- Bundle ID verification
- Code signing certificates and provisioning profiles
- Build settings validation
- Environment variables check
- Fastlane installation
- App Store Connect authentication

**Exit Codes:**
- `0` - Success
- `10-19` - Xcode/Project issues
- `20-29` - Bundle ID issues  
- `30-39` - Code signing issues
- `40-49` - Build settings issues
- `50-59` - Environment issues
- `60-69` - Fastlane issues
- `70-79` - Authentication issues
- `80-89` - Version issues

### 3. Upload Status Monitor (`upload-status-monitor.sh`)

Monitors App Store Connect processing status and sends notifications.

**Usage:**
```bash
./testflight-automation/scripts/upload-status-monitor.sh --build-number BUILD_NUMBER
```

**Options:**
- `--build-number NUMBER` - Build number to monitor (required)
- `--timeout SECONDS` - Monitoring timeout (default: 1800)
- `--interval SECONDS` - Check interval (default: 60)
- `--slack-webhook URL` - Slack webhook for notifications
- `--webhook-url URL` - Generic webhook for notifications

### 4. Metadata Manager (`metadata-manager.py`)

Manages App Store Connect metadata programmatically.

**Usage:**
```bash
./testflight-automation/scripts/metadata-manager.py --action ACTION
```

**Actions:**
- `create-template` - Create metadata template
- `update` - Update App Store metadata
- `fetch` - Fetch current metadata
- `validate` - Validate metadata file
- `backup` - Create metadata backup
- `report` - Generate metadata report

**Examples:**
```bash
# Create template
./metadata-manager.py --action create-template

# Update metadata from file
./metadata-manager.py --action update --metadata-file metadata.json

# Validate metadata
./metadata-manager.py --action validate --metadata-file metadata.json --verbose
```

### 5. Version Manager (`version-manager.sh`)

Handles automated version coordination and changelog generation.

**Usage:**
```bash
./testflight-automation/scripts/version-manager.sh [options]
```

**Options:**
- `--increment TYPE` - Increment type (major, minor, patch, build)
- `--version-source SOURCE` - Version source (xcode, git, manual)
- `--manual-version VERSION` - Manual version when using manual source
- `--generate-changelog` - Generate changelog from git commits
- `--commit-changes` - Commit version changes to git
- `--create-git-tag` - Create git tag for new version
- `--push-tags` - Push git tags to origin
- `--check-conflicts` - Check for build number conflicts

**Examples:**
```bash
# Increment patch version and create git tag
./version-manager.sh --increment patch --commit-changes --create-git-tag

# Just increment build number with changelog
./version-manager.sh --increment build --generate-changelog

# Use git version as source and increment minor
./version-manager.sh --version-source git --increment minor
```

### 6. Testing Group Manager (`testing-group-manager.py`)

Manages TestFlight testing groups and tester invitations.

**Usage:**
```bash
./testflight-automation/scripts/testing-group-manager.py --action ACTION
```

**Actions:**
- `setup-internal` - Setup internal testing groups
- `setup-external` - Setup external testing groups  
- `create-group` - Create individual testing group
- `add-testers` - Add testers to group
- `distribute-build` - Distribute build to groups
- `generate-link` - Generate public link for external group
- `send-invitations` - Send custom invitation emails
- `list-groups` - List all testing groups
- `report` - Generate testing groups report

**Examples:**
```bash
# Setup all internal groups from config
./testing-group-manager.py --action setup-internal

# Create new external group
./testing-group-manager.py --action create-group --group-name "Beta Users" --group-type external

# Add testers from CSV
./testing-group-manager.py --action add-testers --group-name "Alpha Testers" --testers-file testers.csv

# Distribute build to specific groups
./testing-group-manager.py --action distribute-build --build-number 123 --groups "Alpha Testers,Beta Testers"
```

## ⚙️ Configuration

### Main Configuration (`automation-config.yml`)

The main configuration file controls all aspects of the automation system:

```yaml
project:
  name: "HobbyistSwiftUI"
  bundle_id: "com.hobbyist.bookingapp"
  scheme: "HobbyistSwiftUI"
  xcodeproj: "HobbyistSwiftUI.xcodeproj"

testflight:
  skip_waiting_for_build_processing: true
  skip_submission: false
  distribute_external: false
  beta_app_description: "HobbyistSwiftUI alpha version for testing"

testing_groups:
  internal:
    - name: "Alpha Testers"
      description: "Internal team alpha testing group"
      auto_add_builds: true
    - name: "Internal Team"
      description: "Core development team"
      auto_add_builds: true
      
  external:
    - name: "Beta Testers"
      description: "External beta testing group"
      auto_add_builds: false
      requires_beta_review: true

notifications:
  enabled: true
  channels:
    slack:
      enabled: true
      webhook_url: ""  # Set via environment variable
      channel: "#ios-releases"
```

### Environment Variables

Required environment variables:

```bash
# Required for App Store Connect access
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="your-app-specific-password"
MATCH_PASSWORD="your-match-password-for-certificates"

# Optional for notifications
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
SLACK_CHANNEL="#ios-releases"
WEBHOOK_URL="https://your-custom-webhook.com/endpoint"

# Optional for email notifications
BETA_FEEDBACK_EMAIL="feedback@yourapp.com"
```

## 📝 Tester Management

### CSV Format

Testers should be provided in CSV format with the following columns:

```csv
email,first_name,last_name
john.doe@example.com,John,Doe
jane.smith@example.com,Jane,Smith
beta.user@example.com,Beta,User
```

### Adding Testers

1. **Create CSV file** with tester information
2. **Add to internal group:**
```bash
./testing-group-manager.py --action add-testers --group-name "Alpha Testers" --testers-file testers.csv
```

3. **Add to external group with notifications:**
```bash
./testing-group-manager.py --action add-testers --group-name "Beta Testers" --testers-file testers.csv --notify
```

### Public Links

For external testing groups, generate public links:

```bash
./testing-group-manager.py --action generate-link --group-name "Beta Testers"
```

## 📊 Monitoring and Logging

### Log Files

All scripts generate detailed logs in `testflight-automation/logs/`:

- `master-automation-YYYYMMDD-HHMMSS.log` - Main automation log
- `pre-upload-validation-YYYYMMDD-HHMMSS.log` - Validation log
- `upload-status-monitor-YYYYMMDD-HHMMSS.log` - Upload monitoring log
- `version-manager-YYYYMMDD-HHMMSS.log` - Version management log
- `testing-group-manager.log` - Testing group operations log
- `metadata-manager.log` - Metadata operations log

### Status Files

Real-time status information is saved in JSON format:

- `current-build-status.json` - Current build processing status
- `version-info.json` - Latest version information
- `testing-groups-report.json` - Testing groups status

### Reports

Generate comprehensive reports:

```bash
# Metadata report
./metadata-manager.py --action report

# Testing groups report  
./testing-group-manager.py --action report
```

## 🔔 Notifications

### Slack Integration

Configure Slack notifications by setting the webhook URL:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_CHANNEL="#ios-releases"
```

Notifications are sent for:
- Build upload success/failure
- Processing status updates
- Automation completion
- Error conditions

### Custom Webhooks

Set `WEBHOOK_URL` environment variable to receive JSON payloads for automation events.

Example webhook payload:
```json
{
  "event": "testflight_upload_success",
  "app_name": "HobbyistSwiftUI",
  "bundle_id": "com.hobbyist.bookingapp",
  "version": "1.2.0",
  "build_number": "123",
  "changelog": "Bug fixes and improvements",
  "timestamp": "2024-01-15T10:30:00Z",
  "groups": ["Alpha Testers", "Internal Team"]
}
```

## 🛠️ Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify App Store Connect credentials
   - Check app-specific password
   - Ensure Fastlane match is configured

2. **Build Number Conflicts**
   - The system automatically detects and resolves conflicts
   - Use `--check-conflicts` flag for manual verification

3. **Code Signing Issues**
   - Run `fastlane match development` and `fastlane match appstore`
   - Verify bundle ID matches provisioning profiles

4. **Upload Timeouts**
   - Increase timeout in monitoring script
   - Check network connectivity
   - Verify build processing isn't stuck

### Debug Mode

Enable verbose logging for any script:

```bash
./script-name.sh --verbose
# or
./script-name.py --verbose
```

### Manual Steps

If automation fails, you can run individual steps:

1. **Validate only:**
```bash
./pre-upload-validation.sh
```

2. **Version bump only:**
```bash
./version-manager.sh --increment build
```

3. **Upload only:**
```bash
fastlane upload_testflight skip_build:true
```

## 🔧 Customization

### Adding New Validation Checks

Edit `pre-upload-validation.sh` and add new validation functions:

```bash
validate_custom_check() {
    log_info "Running custom validation..."
    # Your validation logic here
    return 0
}
```

Add to the validation steps array:
```bash
local validation_steps=(
    # ... existing steps ...
    validate_custom_check
)
```

### Custom Notification Channels

Extend notification functions in `master-automation.sh`:

```bash
send_custom_notification() {
    # Your custom notification logic
    curl -X POST "your-endpoint" -d "notification-data"
}
```

### Additional Metadata Fields

Extend `metadata-manager.py` to handle custom metadata fields by modifying the `create_metadata_template()` function.

## 📈 Advanced Features

### CI/CD Integration

The automation system is designed for CI/CD integration:

```yaml
# GitHub Actions example
- name: TestFlight Release
  run: |
    export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="${{ secrets.APPLE_PASSWORD }}"
    export MATCH_PASSWORD="${{ secrets.MATCH_PASSWORD }}"
    export SLACK_WEBHOOK_URL="${{ secrets.SLACK_WEBHOOK }}"
    ./testflight-automation/scripts/master-automation.sh --increment build
```

### Quality Gates

Configure quality gates in `automation-config.yml`:

```yaml
quality_gates:
  enabled: true
  crash_rate_max: 3.0
  rating_min: 4.2
  performance_regression: true
```

### Automated Rollbacks

The system can detect failures and automatically rollback:

- Version number restoration
- Metadata reversion from backups
- Testing group state restoration

## 🤝 Contributing

To extend the automation system:

1. Follow existing script patterns
2. Add comprehensive logging
3. Include error handling
4. Update this documentation
5. Test with dry-run mode first

## 📄 License

This TestFlight automation system is part of the HobbyistSwiftUI project.

---

## 🎯 Implementation Status

✅ **Completed Tasks:**
- [x] Pre-upload validation scripts (Task 1)
- [x] Fastlane configuration for automated uploads (Task 2.1) 
- [x] Upload status monitoring system (Task 2.2)
- [x] App Store Connect metadata management (Task 3.1)
- [x] Version and build management automation (Task 3.2)
- [x] Internal testing configuration scripts (Task 4.1)
- [x] External testing group management (Task 4.2)

📋 **Next Phases:**
- Beta review submission automation (Task 5)
- Feedback collection and analysis (Task 6)
- Build iteration management (Task 7)
- Error handling and recovery (Task 8)
- Success criteria validation (Task 9)
- Monitoring and notification infrastructure (Task 10)
- Pipeline integration and testing (Task 11)

The current implementation provides a solid foundation covering the first 4 major phases of the TestFlight automation specification, with a complete end-to-end workflow for build validation, upload, monitoring, and testing group management.