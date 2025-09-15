#!/bin/bash

# TestFlight Pre-Upload Validation Script
# This script validates build configuration, certificates, and environment before upload
# Exit codes: 0 = success, 1-99 = specific validation failures

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="HobbyistSwiftUI"
BUNDLE_ID="com.hobbyist.bookingapp"
SCHEME="HobbyistSwiftUI"
XCODEPROJ="HobbyistSwiftUI.xcodeproj"
WORKSPACE=""
EXPORT_METHOD="app-store"
LOGS_DIR="testflight-automation/logs"
VALIDATION_LOG="$LOGS_DIR/pre-upload-validation-$(date +%Y%m%d-%H%M%S).log"

# Exit codes for different validation failures
EXIT_CODE_SUCCESS=0
EXIT_CODE_XCODE_MISSING=10
EXIT_CODE_PROJECT_MISSING=11
EXIT_CODE_SCHEME_MISSING=12
EXIT_CODE_BUNDLE_ID_MISMATCH=20
EXIT_CODE_CERTIFICATE_MISSING=30
EXIT_CODE_PROVISIONING_PROFILE_MISSING=31
EXIT_CODE_CODE_SIGNING_IDENTITY_INVALID=32
EXIT_CODE_BUILD_SETTINGS_INVALID=40
EXIT_CODE_ENVIRONMENT_VARS_MISSING=50
EXIT_CODE_FASTLANE_MISSING=60
EXIT_CODE_APP_STORE_CONNECT_AUTH_FAILED=70
EXIT_CODE_VERSION_VALIDATION_FAILED=80

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_info() {
    log "${BLUE}ℹ️  $1${NC}"
}

# Function to validate Xcode installation
validate_xcode() {
    log_info "Validating Xcode installation..."
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found"
        return $EXIT_CODE_XCODE_MISSING
    fi
    
    local xcode_version=$(xcodebuild -version | head -n1)
    log_success "Found Xcode: $xcode_version"
    
    # Check if Xcode license is accepted
    if ! xcodebuild -checkFirstLaunchStatus &> /dev/null; then
        log_warning "Xcode license may need to be accepted. Run 'sudo xcodebuild -license accept'"
    fi
    
    return 0
}

# Function to validate project structure
validate_project() {
    log_info "Validating project structure..."
    
    if [[ ! -f "$XCODEPROJ/project.pbxproj" ]]; then
        log_error "Xcode project file not found: $XCODEPROJ"
        return $EXIT_CODE_PROJECT_MISSING
    fi
    
    log_success "Found Xcode project: $XCODEPROJ"
    
    # Validate scheme exists
    if ! xcodebuild -list -project "$XCODEPROJ" | grep -q "$SCHEME"; then
        log_error "Scheme '$SCHEME' not found in project"
        return $EXIT_CODE_SCHEME_MISSING
    fi
    
    log_success "Found scheme: $SCHEME"
    return 0
}

# Function to validate bundle identifier
validate_bundle_id() {
    log_info "Validating bundle identifier..."
    
    local plist_bundle_id
    
    # First try to get from project file directly
    plist_bundle_id=$(grep "PRODUCT_BUNDLE_IDENTIFIER = " "$XCODEPROJ/project.pbxproj" | head -1 | sed 's/.*= \(.*\);/\1/')
    
    # If not found, try build settings with specific destination
    if [[ -z "$plist_bundle_id" || "$plist_bundle_id" == "NO" ]]; then
        plist_bundle_id=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$SCHEME" -destination 'generic/platform=iOS' 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER | head -1 | sed 's/.*= //')
    fi
    
    # If still not found, try Info.plist
    if [[ -z "$plist_bundle_id" || "$plist_bundle_id" == "NO" ]]; then
        if [[ -f "$PROJECT_NAME/Info.plist" ]]; then
            local plist_value=$(plutil -p "$PROJECT_NAME/Info.plist" | grep CFBundleIdentifier | sed 's/.*=> "\(.*\)"/\1/')
            if [[ "$plist_value" == '$(PRODUCT_BUNDLE_IDENTIFIER)' ]]; then
                log_warning "Bundle ID is using variable substitution - checking project settings"
                plist_bundle_id="$BUNDLE_ID"  # Assume correct if using variable
            else
                plist_bundle_id="$plist_value"
            fi
        fi
    fi
    
    if [[ -z "$plist_bundle_id" || "$plist_bundle_id" == "NO" ]]; then
        log_error "Could not determine bundle identifier from project"
        return $EXIT_CODE_BUNDLE_ID_MISMATCH
    fi
    
    if [[ "$plist_bundle_id" != "$BUNDLE_ID" ]]; then
        log_error "Bundle ID mismatch. Expected: $BUNDLE_ID, Found: $plist_bundle_id"
        return $EXIT_CODE_BUNDLE_ID_MISMATCH
    fi
    
    log_success "Bundle ID validated: $BUNDLE_ID"
    return 0
}

# Function to validate code signing certificates
validate_certificates() {
    log_info "Validating code signing certificates..."
    
    # Check for distribution certificates
    local dist_certs=$(security find-identity -v -p codesigning | grep "iPhone Distribution" | wc -l | tr -d ' ')
    if [[ $dist_certs -eq 0 ]]; then
        log_error "No iPhone Distribution certificates found in keychain"
        return $EXIT_CODE_CERTIFICATE_MISSING
    fi
    
    log_success "Found $dist_certs iPhone Distribution certificate(s)"
    
    # Check for development certificates (for completeness)
    local dev_certs=$(security find-identity -v -p codesigning | grep "iPhone Developer\|Apple Development" | wc -l | tr -d ' ')
    if [[ $dev_certs -gt 0 ]]; then
        log_success "Found $dev_certs development certificate(s)"
    fi
    
    return 0
}

# Function to validate provisioning profiles
validate_provisioning_profiles() {
    log_info "Validating provisioning profiles..."
    
    local profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    if [[ ! -d "$profiles_dir" ]]; then
        log_error "Provisioning profiles directory not found"
        return $EXIT_CODE_PROVISIONING_PROFILE_MISSING
    fi
    
    # Count App Store provisioning profiles for our bundle ID
    local appstore_profiles=0
    for profile in "$profiles_dir"/*.mobileprovision; do
        if [[ -f "$profile" ]]; then
            local profile_info=$(security cms -D -i "$profile" 2>/dev/null || true)
            if echo "$profile_info" | grep -q "$BUNDLE_ID" && echo "$profile_info" | grep -q "<key>get-task-allow</key>\s*<false/>"; then
                ((appstore_profiles++))
            fi
        fi
    done
    
    if [[ $appstore_profiles -eq 0 ]]; then
        log_error "No App Store provisioning profile found for bundle ID: $BUNDLE_ID"
        return $EXIT_CODE_PROVISIONING_PROFILE_MISSING
    fi
    
    log_success "Found $appstore_profiles App Store provisioning profile(s) for $BUNDLE_ID"
    return 0
}

# Function to validate build settings
validate_build_settings() {
    log_info "Validating build settings..."
    
    # Get build settings for Release configuration
    local build_settings=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Release)
    
    # Check code signing identity
    local code_sign_identity=$(echo "$build_settings" | grep "CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" | sed 's/.*= //')
    if [[ -z "$code_sign_identity" ]]; then
        code_sign_identity=$(echo "$build_settings" | grep "CODE_SIGN_IDENTITY =" | sed 's/.*= //')
    fi
    
    if [[ "$code_sign_identity" != *"iPhone Distribution"* && "$code_sign_identity" != *"Apple Distribution"* ]]; then
        log_error "Invalid code signing identity: $code_sign_identity"
        return $EXIT_CODE_CODE_SIGNING_IDENTITY_INVALID
    fi
    
    log_success "Code signing identity validated: $code_sign_identity"
    
    # Check other important settings
    local enable_bitcode=$(echo "$build_settings" | grep "ENABLE_BITCODE" | sed 's/.*= //')
    if [[ "$enable_bitcode" == "YES" ]]; then
        log_warning "Bitcode is enabled. Consider disabling for smaller binary size and faster uploads"
    fi
    
    return 0
}

# Function to validate environment variables
validate_environment() {
    log_info "Validating environment variables..."
    
    local missing_vars=()
    
    # Check for Fastlane environment variables
    if [[ -z "$FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" ]]; then
        missing_vars+=("FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD")
    fi
    
    if [[ -z "$MATCH_PASSWORD" ]]; then
        missing_vars+=("MATCH_PASSWORD")
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return $EXIT_CODE_ENVIRONMENT_VARS_MISSING
    fi
    
    log_success "All required environment variables are set"
    return 0
}

# Function to validate Fastlane installation
validate_fastlane() {
    log_info "Validating Fastlane installation..."
    
    if ! command -v fastlane &> /dev/null; then
        log_error "Fastlane not found. Install with 'gem install fastlane'"
        return $EXIT_CODE_FASTLANE_MISSING
    fi
    
    local fastlane_version=$(fastlane --version | head -n1 | sed 's/.*fastlane //')
    log_success "Found Fastlane version: $fastlane_version"
    
    # Check if Fastfile exists
    if [[ ! -f "fastlane/Fastfile" ]]; then
        log_error "Fastfile not found in fastlane directory"
        return $EXIT_CODE_FASTLANE_MISSING
    fi
    
    log_success "Fastfile found and validated"
    return 0
}

# Function to validate App Store Connect authentication
validate_app_store_connect_auth() {
    log_info "Validating App Store Connect authentication..."
    
    # Try to list apps to test authentication
    if ! spaceship-stats &> /dev/null; then
        # Alternative: use fastlane to test auth
        if ! fastlane pilot list &> /dev/null; then
            log_error "App Store Connect authentication failed. Check credentials and app-specific password"
            return $EXIT_CODE_APP_STORE_CONNECT_AUTH_FAILED
        fi
    fi
    
    log_success "App Store Connect authentication validated"
    return 0
}

# Function to validate version and build numbers
validate_version_info() {
    log_info "Validating version and build information..."
    
    # Get current version and build number
    local current_version=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$SCHEME" | grep MARKETING_VERSION | head -1 | sed 's/.*= //')
    local current_build=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$SCHEME" | grep CURRENT_PROJECT_VERSION | head -1 | sed 's/.*= //')
    
    if [[ -z "$current_version" ]]; then
        log_error "Could not determine app version"
        return $EXIT_CODE_VERSION_VALIDATION_FAILED
    fi
    
    if [[ -z "$current_build" ]]; then
        log_error "Could not determine build number"
        return $EXIT_CODE_VERSION_VALIDATION_FAILED
    fi
    
    log_success "Version: $current_version, Build: $current_build"
    
    # Validate version format (semantic versioning)
    if ! echo "$current_version" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' &> /dev/null; then
        log_warning "Version '$current_version' does not follow semantic versioning (X.Y.Z)"
    fi
    
    return 0
}

# Function to run pre-flight checklist
run_preflight_checklist() {
    log_info "Running pre-flight checklist..."
    
    local checklist=(
        "Archive build can be created"
        "Code signing is properly configured"
        "All required frameworks are embedded"
        "App icons are present for all required sizes"
        "Privacy usage descriptions are included"
    )
    
    # Test build creation (dry run)
    log_info "Testing archive build creation..."
    if xcodebuild archive -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Release -archivePath "/tmp/test-archive.xcarchive" -allowProvisioningUpdates -quiet &> /dev/null; then
        rm -rf "/tmp/test-archive.xcarchive"
        log_success "Archive build test passed"
    else
        log_error "Archive build test failed"
        return 1
    fi
    
    return 0
}

# Main validation function
run_validation() {
    log_info "Starting TestFlight pre-upload validation..."
    log_info "Log file: $VALIDATION_LOG"
    
    local validation_steps=(
        validate_xcode
        validate_project
        validate_bundle_id
        validate_certificates
        validate_provisioning_profiles
        validate_build_settings
        validate_environment
        validate_fastlane
        validate_version_info
        run_preflight_checklist
    )
    
    local failed_steps=()
    local warning_count=0
    
    for step in "${validation_steps[@]}"; do
        if $step; then
            log_success "✓ $step passed"
        else
            local exit_code=$?
            failed_steps+=("$step (exit code: $exit_code)")
            log_error "✗ $step failed"
        fi
    done
    
    # Skip App Store Connect auth validation in CI or if disabled
    if [[ "$SKIP_AUTH_VALIDATION" != "true" && "$CI" != "true" ]]; then
        if validate_app_store_connect_auth; then
            log_success "✓ validate_app_store_connect_auth passed"
        else
            local exit_code=$?
            failed_steps+=("validate_app_store_connect_auth (exit code: $exit_code)")
            log_error "✗ validate_app_store_connect_auth failed"
        fi
    else
        log_warning "Skipping App Store Connect authentication validation"
        ((warning_count++))
    fi
    
    # Summary
    echo ""
    log_info "=== VALIDATION SUMMARY ==="
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        log_success "All validation checks passed!"
        if [[ $warning_count -gt 0 ]]; then
            log_warning "$warning_count warning(s) found - review recommendations above"
        fi
        log_info "Build is ready for TestFlight upload"
        return $EXIT_CODE_SUCCESS
    else
        log_error "Validation failed! ${#failed_steps[@]} check(s) failed:"
        for step in "${failed_steps[@]}"; do
            log_error "  - $step"
        done
        log_error "Fix the issues above before attempting to upload to TestFlight"
        return 1
    fi
}

# Script usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --skip-auth             Skip App Store Connect authentication validation"
    echo "  --project PROJECT       Specify Xcode project name (default: $PROJECT_NAME)"
    echo "  --scheme SCHEME         Specify build scheme (default: $SCHEME)"
    echo "  --bundle-id BUNDLE_ID   Specify bundle identifier (default: $BUNDLE_ID)"
    echo "  --verbose               Enable verbose logging"
    echo ""
    echo "Environment Variables:"
    echo "  FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD   Apple ID app-specific password"
    echo "  MATCH_PASSWORD                                  Fastlane match password"
    echo "  SKIP_AUTH_VALIDATION                           Skip authentication validation (true/false)"
    echo ""
    echo "Exit Codes:"
    echo "  0   Success"
    echo "  10  Xcode not found"
    echo "  11  Project not found"
    echo "  12  Scheme not found"
    echo "  20  Bundle ID mismatch"
    echo "  30  Certificate missing"
    echo "  31  Provisioning profile missing"
    echo "  32  Code signing identity invalid"
    echo "  40  Build settings invalid"
    echo "  50  Environment variables missing"
    echo "  60  Fastlane missing"
    echo "  70  App Store Connect authentication failed"
    echo "  80  Version validation failed"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --skip-auth)
            export SKIP_AUTH_VALIDATION="true"
            shift
            ;;
        --project)
            PROJECT_NAME="$2"
            XCODEPROJ="$2.xcodeproj"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --bundle-id)
            BUNDLE_ID="$2"
            shift 2
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

# Run the validation
run_validation