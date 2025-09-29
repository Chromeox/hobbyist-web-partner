#!/bin/bash

# Export HobbyistSwiftUI Archive for App Store Distribution
# This script exports the archive and prepares it for App Store Connect upload

set -e  # Exit on any error

echo "📦 Exporting HobbyistSwiftUI Archive for App Store Distribution"
echo "=============================================================="

# Configuration
ARCHIVE_PATH="./build/HobbyistSwiftUI_v1.0_b2.xcarchive"
EXPORT_PATH="./build/HobbyistSwiftUI_AppStore_Export"
BUNDLE_ID="com.hobbyist.app"

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

# Step 1: Verify Archive Exists
print_step "1. Verifying Archive"
if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive not found at $ARCHIVE_PATH"
    print_error "Please run ./prepare-archive.sh first to create the archive"
    exit 1
else
    print_success "Archive found: $ARCHIVE_PATH"
fi

# Step 2: Create Export Options Plist
print_step "2. Creating Export Options"
cat > exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Distribution method for App Store -->
    <key>method</key>
    <string>app-store</string>
    
    <!-- Development team -->
    <key>teamID</key>
    <string>594BDWKT53</string>
    
    <!-- Upload to App Store Connect -->
    <key>uploadBitcode</key>
    <false/>
    
    <key>uploadSymbols</key>
    <true/>
    
    <!-- Code signing settings -->
    <key>signingStyle</key>
    <string>automatic</string>
    
    <!-- Distribution signing certificate -->
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    
    <!-- Provisioning profile mapping -->
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>match AppStore $BUNDLE_ID</string>
    </dict>
    
    <!-- App Store destination -->
    <key>destination</key>
    <string>export</string>
    
    <!-- Strip Swift symbols -->
    <key>stripSwiftSymbols</key>
    <true/>
    
    <!-- Thin for device -->
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    
    <!-- Compilation mode -->
    <key>compileBitcode</key>
    <false/>
    
    <!-- Include manifest for enterprise -->
    <key>manifest</key>
    <dict>
        <key>appURL</key>
        <string>https://hobbyist.app</string>
    </dict>
</dict>
</plist>
EOF

print_success "Export options plist created"

# Step 3: Export Archive
print_step "3. Exporting Archive for App Store"

# Remove existing export directory
if [ -d "$EXPORT_PATH" ]; then
    rm -rf "$EXPORT_PATH"
fi

echo "Starting export process..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist exportOptions.plist \
    -verbose

if [ $? -eq 0 ]; then
    print_success "Archive exported successfully!"
else
    print_error "Export failed. Check the error messages above."
    exit 1
fi

# Step 4: Verify Export
print_step "4. Verifying Export"

if [ -d "$EXPORT_PATH" ]; then
    ls -la "$EXPORT_PATH"
    
    # Find the .ipa file
    IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
    
    if [ -n "$IPA_FILE" ]; then
        print_success "IPA file created: $IPA_FILE"
        
        # Get file size
        IPA_SIZE=$(ls -lah "$IPA_FILE" | awk '{print $5}')
        echo "File size: $IPA_SIZE"
        
    else
        print_error "No IPA file found in export directory"
        exit 1
    fi
else
    print_error "Export directory not created"
    exit 1
fi

# Step 5: Upload Instructions
print_step "5. App Store Connect Upload Instructions"

echo ""
echo "🚀 Export Complete! Next Steps:"
echo "================================"
echo ""
echo "Your app is ready for App Store Connect. You can upload using:"
echo ""
echo "Option 1: Using Transporter App (Recommended)"
echo "   1. Open Transporter from the Mac App Store"
echo "   2. Sign in with your Apple ID"
echo "   3. Click '+' or drag your IPA file to upload"
echo "   4. Wait for processing and validation"
echo ""
echo "Option 2: Using Xcode Organizer"
echo "   1. Open Xcode"
echo "   2. Go to Window > Organizer"
echo "   3. Select your archive from the list"
echo "   4. Click 'Distribute App'"
echo "   5. Choose 'App Store Connect' and follow prompts"
echo ""
echo "Option 3: Using altool command line (Advanced)"
echo "   xcrun altool --upload-app --type ios \\"
echo "     --file \"$IPA_FILE\" \\"
echo "     --username YOUR_APPLE_ID \\"
echo "     --password YOUR_APP_SPECIFIC_PASSWORD \\"
echo "     --asc-provider YOUR_TEAM_ID"
echo ""
echo "📋 Export Summary:"
echo "==================="
echo "Archive: $ARCHIVE_PATH"
echo "Export: $EXPORT_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Team ID: 594BDWKT53"
echo "IPA File: $IPA_FILE"
echo "File Size: $IPA_SIZE"
echo ""

# Cleanup
rm -f exportOptions.plist

print_success "Export process complete! 🎉"
print_warning "Remember to test your app in TestFlight before releasing to the App Store"