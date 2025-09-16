#!/bin/bash

# 🚀 HobbyistSwiftUI TestFlight Build Script
# This script creates an archive and exports it for App Store submission

set -e  # Exit on any error

echo "🏗️  Building HobbyistSwiftUI for TestFlight..."
echo "📱 Bundle ID: com.hobbyist.app"
echo "👥 Team: Quantum Hobbyist Group Inc. (594BDWKT53)"
echo ""

# Create build directory
mkdir -p build

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project HobbyistSwiftUI.xcodeproj -scheme HobbyistSwiftUI -configuration Release
rm -rf build/*

echo "📦 Creating archive..."
xcodebuild archive \
  -project HobbyistSwiftUI.xcodeproj \
  -scheme HobbyistSwiftUI \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "./build/HobbyistSwiftUI.xcarchive" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=594BDWKT53 \
  PRODUCT_BUNDLE_IDENTIFIER=com.hobbyist.app

echo "📤 Exporting for App Store..."
xcodebuild -exportArchive \
  -archivePath "./build/HobbyistSwiftUI.xcarchive" \
  -exportPath "./build/" \
  -exportOptionsPlist "./ExportOptions.plist" \
  -allowProvisioningUpdates

echo ""
echo "✅ Build complete!"
echo "📁 Archive location: ./build/HobbyistSwiftUI.xcarchive"
echo "📦 IPA location: ./build/HobbyistSwiftUI.ipa"
echo ""
echo "🚀 Next steps:"
echo "1. Open Xcode Organizer to upload to App Store Connect"
echo "2. Or use Application Loader to upload the IPA"
echo "3. Configure TestFlight in App Store Connect"
echo ""
echo "🌐 App Store Connect: https://appstoreconnect.apple.com"