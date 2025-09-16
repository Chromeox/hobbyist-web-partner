#!/bin/bash

# TestFlight Build Script for Hobbyist App
# Bundle ID: com.hobbyist.bookingapp

set -e

echo "🚀 Building Hobbyist App for TestFlight..."
echo "Bundle ID: com.hobbyist.bookingapp"

# Navigate to project directory
cd "$(dirname "$0")"

# Clean build directory
echo "🧹 Cleaning build directory..."
xcodebuild clean -project HobbyistSwiftUI.xcodeproj -scheme HobbyistSwiftUI

# Build archive
echo "📦 Creating archive..."
xcodebuild archive \
    -project HobbyistSwiftUI.xcodeproj \
    -scheme HobbyistSwiftUI \
    -destination 'generic/platform=iOS' \
    -archivePath "./build/HobbyistApp.xcarchive" \
    -configuration Release \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM_ID

# Export for TestFlight
echo "📤 Exporting for TestFlight..."
xcodebuild -exportArchive \
    -archivePath "./build/HobbyistApp.xcarchive" \
    -exportPath "./build/export" \
    -exportOptionsPlist "./ExportOptions.plist"

echo "✅ Build complete! Archive ready for TestFlight upload."
echo "📍 Location: ./build/export/HobbyistApp.ipa"
echo ""
echo "Next steps:"
echo "1. Open Xcode Organizer (Window → Organizer)"
echo "2. Select the archive and click 'Distribute App'"
echo "3. Choose 'App Store Connect' → 'Upload'"
echo "4. Wait for processing in App Store Connect"
echo "5. Add to TestFlight for alpha testing"