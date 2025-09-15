#!/bin/bash

# TestFlight Master Automation Script
# Orchestrates the complete TestFlight submission and management process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$PROJECT_ROOT/testflight-automation/logs"
AUTOMATION_LOG="$LOGS_DIR/master-automation-$(date +%Y%m%d-%H%M%S).log"

# Default options
DRY_RUN=false
SKIP_VALIDATION=false
SKIP_BUILD=false
SKIP_UPLOAD=false
SKIP_MONITORING=false
SKIP_GROUPS=false
INCREMENT_TYPE="build"
VERSION_SOURCE="xcode"
CHANGELOG=""
GROUPS="Alpha Testers,Internal Team"
NOTIFY_TESTERS=true

# Create logs directory
mkdir -p "$LOGS_DIR"

# Logging functions
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$AUTOMATION_LOG"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_info() {
    log "${BLUE}ℹ️ $1${NC}"
}

log_header() {
    log "${PURPLE}🚀 $1${NC}"
}

# Function to check if required tools are installed
check_dependencies() {
    log_header "Checking dependencies..."
    
    local missing_tools=()
    
    # Check for required tools
    local required_tools=("fastlane" "xcodebuild" "git" "python3")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    log_success "All dependencies are installed"
    return 0
}

# Function to run pre-upload validation
run_validation() {
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        log_warning "Skipping pre-upload validation"
        return 0
    fi
    
    log_header "Step 1: Pre-upload Validation"
    
    local validation_script="$SCRIPT_DIR/pre-upload-validation.sh"
    
    if [[ ! -x "$validation_script" ]]; then
        log_error "Validation script not found or not executable: $validation_script"
        return 1
    fi
    
    local validation_args=""
    if [[ "$DRY_RUN" == "true" ]]; then
        validation_args="--skip-auth"
    fi
    
    if "$validation_script" $validation_args; then
        log_success "Pre-upload validation passed"
        return 0
    else
        log_error "Pre-upload validation failed"
        return 1
    fi
}

# Function to manage version and build numbers
manage_version() {
    log_header "Step 2: Version and Build Management"
    
    local version_script="$SCRIPT_DIR/version-manager.sh"
    
    if [[ ! -x "$version_script" ]]; then
        log_error "Version manager script not found or not executable: $version_script"
        return 1
    fi
    
    local version_args="--increment $INCREMENT_TYPE --version-source $VERSION_SOURCE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        version_args="$version_args --dry-run"
    fi
    
    # Generate changelog if not provided
    if [[ -z "$CHANGELOG" ]]; then
        version_args="$version_args --generate-changelog"
    fi
    
    if "$version_script" $version_args > "$LOGS_DIR/version-info.json"; then
        log_success "Version management completed"
        
        # Extract version information
        local version_info=$(cat "$LOGS_DIR/version-info.json" 2>/dev/null | tail -n 10)
        NEW_VERSION=$(echo "$version_info" | grep '"version"' | sed 's/.*: "\(.*\)".*/\1/' | head -1)
        NEW_BUILD_NUMBER=$(echo "$version_info" | grep '"build_number"' | sed 's/.*: "\(.*\)".*/\1/' | head -1)
        
        log_info "New version: $NEW_VERSION"
        log_info "New build number: $NEW_BUILD_NUMBER"
        
        return 0
    else
        log_error "Version management failed"
        return 1
    fi
}

# Function to build and upload to TestFlight
build_and_upload() {
    if [[ "$SKIP_BUILD" == "true" && "$SKIP_UPLOAD" == "true" ]]; then
        log_warning "Skipping build and upload"
        return 0
    fi
    
    log_header "Step 3: Build and Upload to TestFlight"
    
    cd "$PROJECT_ROOT"
    
    local fastlane_args=""
    if [[ -n "$CHANGELOG" ]]; then
        fastlane_args="changelog:\"$CHANGELOG\""
    fi
    
    if [[ -n "$GROUPS" ]]; then
        # Convert comma-separated groups to array format
        local groups_array=$(echo "$GROUPS" | sed 's/,/","/g' | sed 's/^/["/' | sed 's/$/"]/')
        fastlane_args="$fastlane_args groups:$groups_array"
    fi
    
    if [[ "$NOTIFY_TESTERS" == "false" ]]; then
        fastlane_args="$fastlane_args notify_external:false"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would execute: fastlane automated_testflight_release $fastlane_args"
        return 0
    else
        if fastlane automated_testflight_release $fastlane_args; then
            log_success "Build and upload completed"
            return 0
        else
            log_error "Build and upload failed"
            return 1
        fi
    fi
}

# Function to monitor upload processing
monitor_processing() {
    if [[ "$SKIP_MONITORING" == "true" ]]; then
        log_warning "Skipping processing monitoring"
        return 0
    fi
    
    log_header "Step 4: Monitor Processing Status"
    
    if [[ -z "$NEW_BUILD_NUMBER" ]]; then
        log_error "Build number not available for monitoring"
        return 1
    fi
    
    local monitor_script="$SCRIPT_DIR/upload-status-monitor.sh"
    
    if [[ ! -x "$monitor_script" ]]; then
        log_error "Monitor script not found or not executable: $monitor_script"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would monitor build $NEW_BUILD_NUMBER"
        return 0
    else
        if "$monitor_script" --build-number "$NEW_BUILD_NUMBER" --timeout 1800 --interval 60; then
            log_success "Processing monitoring completed"
            return 0
        else
            log_error "Processing monitoring failed or timed out"
            return 1
        fi
    fi
}

# Function to manage testing groups
manage_testing_groups() {
    if [[ "$SKIP_GROUPS" == "true" ]]; then
        log_warning "Skipping testing group management"
        return 0
    fi
    
    log_header "Step 5: Testing Group Management"
    
    local groups_script="$SCRIPT_DIR/testing-group-manager.py"
    
    if [[ ! -x "$groups_script" ]]; then
        log_error "Testing groups script not found or not executable: $groups_script"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would manage testing groups"
        return 0
    else
        # Setup internal groups
        if "$groups_script" --action setup-internal; then
            log_success "Internal testing groups setup completed"
        else
            log_warning "Internal testing groups setup failed"
        fi
        
        # Generate report
        if "$groups_script" --action report > "$LOGS_DIR/testing-groups-report.json"; then
            log_success "Testing groups report generated"
        else
            log_warning "Testing groups report generation failed"
        fi
        
        return 0
    fi
}

# Function to send completion notifications
send_completion_notifications() {
    log_header "Step 6: Send Completion Notifications"
    
    local success_message="🎉 TestFlight automation completed successfully!"
    if [[ "$DRY_RUN" == "true" ]]; then
        success_message="🧪 TestFlight automation dry run completed successfully!"
    fi
    
    # Send Slack notification if configured
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        local slack_payload=$(cat <<EOF
{
    "channel": "${SLACK_CHANNEL:-#ios-releases}",
    "username": "TestFlight Automation",
    "icon_emoji": ":rocket:",
    "text": "$success_message",
    "attachments": [
        {
            "color": "good",
            "fields": [
                {
                    "title": "Version",
                    "value": "${NEW_VERSION:-N/A}",
                    "short": true
                },
                {
                    "title": "Build Number",
                    "value": "${NEW_BUILD_NUMBER:-N/A}",
                    "short": true
                },
                {
                    "title": "Groups",
                    "value": "$GROUPS",
                    "short": false
                },
                {
                    "title": "Log File",
                    "value": "$AUTOMATION_LOG",
                    "short": false
                }
            ]
        }
    ]
}
EOF
)
        
        curl -X POST \
            -H "Content-Type: application/json" \
            -d "$slack_payload" \
            "$SLACK_WEBHOOK_URL" \
            --silent --output /dev/null
        
        if [[ $? -eq 0 ]]; then
            log_success "Slack notification sent"
        else
            log_warning "Failed to send Slack notification"
        fi
    fi
    
    log_success "Automation completed successfully"
}

# Function to handle errors and cleanup
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    log_error "Automation failed at line $line_number with exit code $exit_code"
    
    # Send error notification if configured
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        local error_payload=$(cat <<EOF
{
    "channel": "${SLACK_CHANNEL:-#ios-releases}",
    "username": "TestFlight Automation",
    "icon_emoji": ":x:",
    "text": "❌ TestFlight automation failed!",
    "attachments": [
        {
            "color": "danger",
            "fields": [
                {
                    "title": "Error",
                    "value": "Automation failed at line $line_number",
                    "short": false
                },
                {
                    "title": "Log File",
                    "value": "$AUTOMATION_LOG",
                    "short": false
                }
            ]
        }
    ]
}
EOF
)
        
        curl -X POST \
            -H "Content-Type: application/json" \
            -d "$error_payload" \
            "$SLACK_WEBHOOK_URL" \
            --silent --output /dev/null
    fi
    
    exit $exit_code
}

# Function to show script usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                    Show this help message"
    echo "  --dry-run                     Perform dry run without making changes"
    echo "  --skip-validation             Skip pre-upload validation"
    echo "  --skip-build                  Skip building the app"
    echo "  --skip-upload                 Skip uploading to TestFlight"
    echo "  --skip-monitoring             Skip processing status monitoring"
    echo "  --skip-groups                 Skip testing group management"
    echo "  --increment TYPE              Version increment type (major, minor, patch, build)"
    echo "  --version-source SOURCE       Version source (xcode, git, manual)"
    echo "  --changelog TEXT              Custom changelog text"
    echo "  --groups GROUPS               Comma-separated list of testing groups"
    echo "  --no-notify                   Don't notify testers"
    echo "  --verbose                     Enable verbose logging"
    echo ""
    echo "Environment Variables:"
    echo "  SLACK_WEBHOOK_URL             Slack webhook URL for notifications"
    echo "  SLACK_CHANNEL                 Slack channel for notifications"
    echo ""
    echo "Examples:"
    echo "  $0                                      # Full automation with defaults"
    echo "  $0 --dry-run                           # Dry run to test the process"
    echo "  $0 --increment patch --changelog \"Bug fixes\""
    echo "  $0 --skip-monitoring --groups \"Beta Testers\""
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --skip-monitoring)
            SKIP_MONITORING=true
            shift
            ;;
        --skip-groups)
            SKIP_GROUPS=true
            shift
            ;;
        --increment)
            INCREMENT_TYPE="$2"
            shift 2
            ;;
        --version-source)
            VERSION_SOURCE="$2"
            shift 2
            ;;
        --changelog)
            CHANGELOG="$2"
            shift 2
            ;;
        --groups)
            GROUPS="$2"
            shift 2
            ;;
        --no-notify)
            NOTIFY_TESTERS=false
            shift
            ;;
        --verbose)
            set -x
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
log_header "TestFlight Master Automation Started"
log_info "Log file: $AUTOMATION_LOG"
log_info "Project root: $PROJECT_ROOT"
log_info "Dry run: $DRY_RUN"

# Step 0: Check dependencies
check_dependencies

# Step 1: Run validation
run_validation

# Step 2: Manage version and build numbers
manage_version

# Step 3: Build and upload
build_and_upload

# Step 4: Monitor processing
monitor_processing

# Step 5: Manage testing groups
manage_testing_groups

# Step 6: Send completion notifications
send_completion_notifications

log_success "🎉 TestFlight Master Automation completed successfully!"

# Display summary
echo ""
echo "================================"
echo "     AUTOMATION SUMMARY"
echo "================================"
if [[ -n "$NEW_VERSION" ]]; then
    echo "Version: $NEW_VERSION"
fi
if [[ -n "$NEW_BUILD_NUMBER" ]]; then
    echo "Build: $NEW_BUILD_NUMBER"
fi
echo "Groups: $GROUPS"
echo "Log: $AUTOMATION_LOG"
echo "================================"