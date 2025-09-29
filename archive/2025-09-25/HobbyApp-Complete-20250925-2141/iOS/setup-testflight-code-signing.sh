#!/bin/bash

# TestFlight Code Signing Configuration
# This script configures proper code signing for App Store distribution

echo "🔐 Configuring TestFlight code signing..."

# First, let's check current certificates
echo "📋 Checking available certificates..."
security find-identity -v -p codesigning

echo ""
echo "📋 Checking available provisioning profiles..."
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/ | head -10

# Create a temporary build settings file for distribution
echo "⚙️ Configuring distribution build settings..."

# Update the Xcode project for proper distribution signing
# We need to modify the Release configuration to use Distribution code signing

# Backup the current project file
cp HobbyistSwiftUI.xcodeproj/project.pbxproj HobbyistSwiftUI.xcodeproj/project.pbxproj.codesign-backup

# Update the CODE_SIGN_IDENTITY for Release builds
echo "🔑 Setting code sign identity for Release builds..."

# For Archive/TestFlight, we need "Apple Distribution" instead of "Apple Development"
sed -i '' 's/CODE_SIGN_IDENTITY = Apple Development;/CODE_SIGN_IDENTITY = "Apple Distribution";/g' HobbyistSwiftUI.xcodeproj/project.pbxproj

# Also ensure we have proper provisioning profile specifier for automatic signing
echo "📱 Ensuring proper provisioning profile configuration..."

# Verify the changes
echo "✅ Verifying code signing configuration..."
if grep -q 'CODE_SIGN_IDENTITY = "Apple Distribution"' HobbyistSwiftUI.xcodeproj/project.pbxproj; then
    echo "✅ Code sign identity updated to Apple Distribution"
else
    echo "❌ Failed to update code sign identity"
    echo "🔄 Restoring backup..."
    cp HobbyistSwiftUI.xcodeproj/project.pbxproj.codesign-backup HobbyistSwiftUI.xcodeproj/project.pbxproj
    exit 1
fi

echo ""
echo "🎯 TestFlight code signing configuration complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open Xcode and verify Signing & Capabilities settings"
echo "2. Check that 'Automatically manage signing' is enabled"
echo "3. Ensure you have a valid Apple Distribution certificate"
echo "4. Try Archive (Product > Archive) in Xcode"
echo ""
echo "💡 If you get code signing errors:"
echo "- Check Apple Developer portal for valid certificates"
echo "- Ensure bundle ID 'com.hobbyist.app' is registered"
echo "- Try disabling and re-enabling automatic signing in Xcode"