#!/bin/bash

# Alternative TestFlight Build Script - Handles Package Resolution Better
# Bundle ID: com.hobbyist.bookingapp

set -e

echo "🚀 Building Hobbyist App for TestFlight (Alternative Method)..."
echo "Bundle ID: com.hobbyist.bookingapp"

# Navigate to project directory
cd "$(dirname "$0")"

# Create build directory
mkdir -p ./build

echo "📱 Opening Xcode for manual archive..."
echo ""
echo "🔧 MANUAL STEPS IN XCODE:"
echo "1. Xcode should be opening now..."
echo "2. Wait for package resolution to complete (this may take 5-10 minutes)"
echo "3. Select 'Any iOS Device' as destination"
echo "4. Go to Product → Archive"
echo "5. When Organizer opens, select 'Distribute App'"
echo "6. Choose 'App Store Connect' → Upload"
echo ""
echo "⏱️  The package resolution timeout is normal for first builds with Stripe SDK"
echo ""

# Open Xcode
open HobbyistSwiftUI.xcodeproj

echo "✅ Xcode opened! Follow the manual steps above to complete your TestFlight build."
echo ""
echo "🎯 Alternative approach if Xcode hangs:"
echo "1. Force quit Xcode (Cmd+Q)"
echo "2. Delete ~/Library/Developer/Xcode/DerivedData/HobbyistSwiftUI-* folders"
echo "3. Reopen project and try again"
echo ""
echo "📞 Once archive completes, you'll be ready for TestFlight!"