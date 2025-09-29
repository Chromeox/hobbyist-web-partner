#!/bin/bash

# TestFlight Automation Environment Setup Script
# Helps configure the development environment for TestFlight automation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUNDLE_ID="com.hobbyist.bookingapp"
TEAM_ID="594BDWKT53"

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_header() {
    echo -e "${BLUE}🔧 $1${NC}"
}

echo "=================================="
echo "TestFlight Automation Setup"
echo "=================================="

# Step 1: Check and fix project configuration
log_header "Step 1: Checking Project Configuration"

# Verify bundle ID
current_bundle_id=$(grep "PRODUCT_BUNDLE_IDENTIFIER = " HobbyistSwiftUI.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/')
if [[ "$current_bundle_id" == "$BUNDLE_ID" ]]; then
    log_success "Bundle ID is correct: $BUNDLE_ID"
else
    log_error "Bundle ID mismatch. Expected: $BUNDLE_ID, Found: $current_bundle_id"
fi

# Check version format
current_version=$(grep "MARKETING_VERSION = " HobbyistSwiftUI.xcodeproj/project.pbxproj | head -1 | sed 's/.*= \(.*\);/\1/')
if [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_success "Version format is correct: $current_version"
else
    log_warning "Version format should be semantic (X.Y.Z): $current_version"
    log_info "Run: xcrun agvtool new-marketing-version 1.0.0"
fi

# Step 2: Check certificates
log_header "Step 2: Checking Code Signing Certificates"

dev_certs=$(security find-identity -v -p codesigning | grep "Apple Development" | wc -l | tr -d ' ')
dist_certs=$(security find-identity -v -p codesigning | grep "Apple Distribution" | wc -l | tr -d ' ')

if [[ $dev_certs -gt 0 ]]; then
    log_success "Found $dev_certs development certificate(s)"
else
    log_error "No development certificates found"
fi

if [[ $dist_certs -gt 0 ]]; then
    log_success "Found $dist_certs distribution certificate(s)"
else
    log_error "No distribution certificates found - needed for TestFlight"
fi

# Step 3: Check provisioning profiles
log_header "Step 3: Checking Provisioning Profiles"

profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
if [[ -d "$profiles_dir" ]]; then
    profile_count=$(ls "$profiles_dir"/*.mobileprovision 2>/dev/null | wc -l | tr -d ' ')
    if [[ $profile_count -gt 0 ]]; then
        log_success "Found $profile_count provisioning profile(s)"
        
        # Check for App Store profiles
        appstore_profiles=0
        for profile in "$profiles_dir"/*.mobileprovision; do
            if [[ -f "$profile" ]]; then
                profile_info=$(security cms -D -i "$profile" 2>/dev/null || true)
                if echo "$profile_info" | grep -q "$BUNDLE_ID" && echo "$profile_info" | grep -q "<key>get-task-allow</key>\s*<false/>"; then
                    ((appstore_profiles++))
                fi
            fi
        done
        
        if [[ $appstore_profiles -gt 0 ]]; then
            log_success "Found $appstore_profiles App Store provisioning profile(s) for $BUNDLE_ID"
        else
            log_error "No App Store provisioning profiles found for $BUNDLE_ID"
        fi
    else
        log_error "No provisioning profiles found"
    fi
else
    log_error "Provisioning profiles directory not found"
fi

# Step 4: Environment variables
log_header "Step 4: Checking Environment Variables"

required_vars=(
    "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD"
    "MATCH_PASSWORD"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    else
        log_success "$var is set"
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Missing environment variables: ${missing_vars[*]}"
else
    log_success "All required environment variables are set"
fi

# Step 5: Fastlane configuration
log_header "Step 5: Checking Fastlane Configuration"

if command -v fastlane &> /dev/null; then
    log_success "Fastlane is installed"
    
    if [[ -f "fastlane/Fastfile" ]]; then
        log_success "Fastfile exists"
        
        # Check if match is configured
        if [[ -f "fastlane/Matchfile" ]]; then
            log_success "Fastlane Match is configured"
        else
            log_warning "Fastlane Match is not configured"
        fi
    else
        log_error "Fastfile not found"
    fi
else
    log_error "Fastlane is not installed"
fi

echo ""
echo "=================================="
echo "RECOMMENDATIONS"
echo "=================================="

# Provide setup recommendations
if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "1. SET UP ENVIRONMENT VARIABLES:"
    echo "   export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=\"your-app-specific-password\""
    echo "   export MATCH_PASSWORD=\"your-match-password\""
    echo ""
fi

if [[ $dist_certs -eq 0 ]] || [[ $appstore_profiles -eq 0 ]]; then
    echo "2. CONFIGURE CODE SIGNING:"
    echo "   Option A - Use Fastlane Match (Recommended):"
    echo "     fastlane match init"
    echo "     fastlane match development"
    echo "     fastlane match appstore"
    echo ""
    echo "   Option B - Manual Setup:"
    echo "     1. Log into Apple Developer Portal"
    echo "     2. Create/download App Store Distribution certificate"
    echo "     3. Create/download App Store provisioning profile for $BUNDLE_ID"
    echo "     4. Install certificate and profile"
    echo ""
fi

if ! command -v fastlane &> /dev/null; then
    echo "3. INSTALL FASTLANE:"
    echo "   gem install fastlane"
    echo ""
fi

echo "4. UPDATE XCODE PROJECT SETTINGS:"
echo "   - Set Code Signing Identity to 'iPhone Distribution' for Release"
echo "   - Set Provisioning Profile to match your App Store profile"
echo "   - Ensure Team ID is set to: $TEAM_ID"
echo ""

echo "5. TEST CONFIGURATION:"
echo "   ./testflight-automation/scripts/pre-upload-validation.sh --skip-auth"
echo ""

echo "=================================="
echo "QUICK SETUP (if you have Apple Developer access):"
echo "=================================="
echo "# 1. Set environment variables"
echo "export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=\"your-password\""
echo "export MATCH_PASSWORD=\"your-match-password\""
echo ""
echo "# 2. Setup Fastlane Match"
echo "fastlane match init"
echo "fastlane match appstore"
echo ""
echo "# 3. Test automation"
echo "./testflight-automation/scripts/master-automation.sh --dry-run"
echo "=================================="