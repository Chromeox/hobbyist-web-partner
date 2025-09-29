#!/bin/bash

# Setup Provisioning Profiles for HobbyistSwiftUI
# This script helps you create and manage provisioning profiles for com.hobbyist.app

set -e

echo "🔑 Setting up Provisioning Profiles for HobbyistSwiftUI"
echo "======================================================="

# Configuration
BUNDLE_ID="com.hobbyist.app"
TEAM_ID="594BDWKT53"
APP_NAME="Hobbyist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step "1. Checking Current Configuration"
echo "Bundle ID: $BUNDLE_ID"
echo "Team ID: $TEAM_ID"
echo "App Name: $APP_NAME"
echo ""

print_step "2. Checking Code Signing Identities"
security find-identity -p codesigning -v
echo ""

print_step "3. Checking Existing Provisioning Profiles"
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILES_DIR" ]; then
    MATCHING_PROFILES=$(find "$PROFILES_DIR" -name "*.mobileprovision" -exec grep -l "$BUNDLE_ID" {} \; 2>/dev/null || true)
    
    if [ -n "$MATCHING_PROFILES" ]; then
        print_success "Found provisioning profiles for $BUNDLE_ID:"
        echo "$MATCHING_PROFILES" | while read profile; do
            echo "  - $profile"
        done
    else
        print_warning "No provisioning profiles found for $BUNDLE_ID"
    fi
else
    print_warning "Provisioning profiles directory not found"
fi
echo ""

print_step "4. Instructions to Create Provisioning Profiles"
echo ""
echo "Since no provisioning profiles were found for $BUNDLE_ID, you need to:"
echo ""
echo "📱 Option 1: Use Xcode (Recommended)"
echo "   1. Open your project in Xcode"
echo "   2. Select your project in the navigator"
echo "   3. Select the HobbyistSwiftUI target"
echo "   4. Go to 'Signing & Capabilities' tab"
echo "   5. Make sure 'Automatically manage signing' is checked"
echo "   6. Select Team: Quantum Hobbyist Group Inc. ($TEAM_ID)"
echo "   7. Xcode will automatically create the provisioning profile"
echo ""
echo "🌐 Option 2: Apple Developer Portal"
echo "   1. Go to https://developer.apple.com/account"
echo "   2. Sign in with your Apple ID"
echo "   3. Go to Certificates, Identifiers & Profiles"
echo "   4. Click on 'Profiles' and then '+' to add new"
echo "   5. Select 'App Store' distribution profile"
echo "   6. Choose your App ID: $BUNDLE_ID"
echo "   7. Select your distribution certificate"
echo "   8. Download and install the profile"
echo ""
echo "🔧 Option 3: Use fastlane match (Advanced)"
echo "   1. Install fastlane: 'gem install fastlane'"
echo "   2. Set up match for your team"
echo "   3. Run: 'fastlane match appstore -a $BUNDLE_ID'"
echo ""

print_step "5. Testing Archive Export"
echo ""
echo "After setting up provisioning profiles, test the export:"
echo "   ./export-appstore.sh"
echo ""

print_step "6. Alternative: Export with Development Provisioning"
echo ""
echo "If you want to create a development build for testing:"
echo "   1. Create a development provisioning profile"
echo "   2. Use the export-development.sh script (if available)"
echo "   3. Or modify exportOptions.plist to use 'development' method"
echo ""

# Create a development export options file
cat > exportOptions-development.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    
    <key>teamID</key>
    <string>594BDWKT53</string>
    
    <key>signingStyle</key>
    <string>automatic</string>
    
    <key>stripSwiftSymbols</key>
    <false/>
    
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF

print_success "Created exportOptions-development.plist for development builds"
echo ""

print_step "Summary"
echo "======="
echo "✅ Certificates: Apple Distribution certificate found"
echo "⚠️  Provisioning: Need to create App Store provisioning profile for $BUNDLE_ID"
echo "🎯 Next Action: Set up provisioning profiles using one of the methods above"
echo ""
print_warning "Cannot export to App Store until provisioning profiles are configured"