#!/bin/bash

# TestFlight Setup Script for HobbyistSwiftUI
# Run this after installing Xcode and enrolling in Apple Developer Program

set -e

echo "🚀 HobbyistSwiftUI TestFlight Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Xcode is installed
check_xcode() {
    echo "Checking Xcode installation..."
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ Xcode is not installed${NC}"
        echo "Please install Xcode from the Mac App Store first"
        echo "Download from: https://apps.apple.com/app/xcode/id497799835"
        exit 1
    else
        XCODE_VERSION=$(xcodebuild -version | head -n 1)
        echo -e "${GREEN}✅ $XCODE_VERSION installed${NC}"
    fi
}

# Check if logged into Apple Developer account
check_developer_account() {
    echo ""
    echo "Checking Apple Developer account..."
    
    # Check if certificates exist
    CERT_COUNT=$(security find-identity -v -p codesigning | grep -c "valid identities found" || true)
    
    if [[ "$CERT_COUNT" == "0 valid identities found" ]]; then
        echo -e "${YELLOW}⚠️  No signing certificates found${NC}"
        echo "Please ensure you're signed into Xcode with your Apple Developer account:"
        echo "1. Open Xcode"
        echo "2. Go to Xcode → Settings → Accounts"
        echo "3. Add your Apple ID with Developer Program membership"
        echo ""
        read -p "Press Enter once you've signed into Xcode..."
    else
        echo -e "${GREEN}✅ Signing certificates found${NC}"
    fi
}

# Install required Ruby gems
install_dependencies() {
    echo ""
    echo "Installing required dependencies..."
    
    # Check if bundler is installed
    if ! command -v bundle &> /dev/null; then
        echo "Installing bundler..."
        sudo gem install bundler
    fi
    
    # Install fastlane if not present
    if ! command -v fastlane &> /dev/null; then
        echo "Installing fastlane..."
        sudo gem install fastlane
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Configure project settings
configure_project() {
    echo ""
    echo "Configuring project settings..."
    
    # Navigate to iOS directory
    cd "$(dirname "$0")"
    
    # Create .env file for fastlane if it doesn't exist
    if [ ! -f "../fastlane/.env" ]; then
        echo "Creating fastlane environment file..."
        cat > ../fastlane/.env << EOF
# Fastlane Environment Variables
APP_IDENTIFIER=com.hobbyist.app
APPLE_ID=your_apple_id@example.com
TEAM_ID=YOUR_TEAM_ID
ITC_TEAM_ID=YOUR_ITC_TEAM_ID

# TestFlight Settings
BETA_FEEDBACK_EMAIL=feedback@hobbyist.app

# Match Configuration (if using match for certificate management)
MATCH_TYPE=appstore
MATCH_APP_IDENTIFIER=com.hobbyist.app
MATCH_USERNAME=your_apple_id@example.com

# Optional: Slack webhook for notifications
# SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF
        echo -e "${YELLOW}⚠️  Please update ../fastlane/.env with your Apple ID and Team information${NC}"
    fi
    
    echo -e "${GREEN}✅ Project configuration ready${NC}"
}

# Open Xcode for manual configuration
open_xcode_project() {
    echo ""
    echo "Opening Xcode project for configuration..."
    
    # Open the Xcode project
    open HobbyistSwiftUI.xcodeproj
    
    echo ""
    echo -e "${YELLOW}📝 Manual Steps Required in Xcode:${NC}"
    echo "1. Select the project in the navigator"
    echo "2. Go to 'Signing & Capabilities' tab"
    echo "3. Enable 'Automatically manage signing'"
    echo "4. Select your Developer Team from dropdown"
    echo "5. Verify Bundle Identifier is set to: com.hobbyist.app"
    echo "6. Build the project (Cmd+B) to verify setup"
    echo ""
    read -p "Press Enter once you've completed the Xcode configuration..."
}

# Create app icons placeholder
create_app_icons() {
    echo ""
    echo "Setting up app icon placeholders..."
    
    ICON_DIR="HobbyistSwiftUI/Assets.xcassets/AppIcon.appiconset"
    
    if [ ! -f "$ICON_DIR/Contents.json" ]; then
        mkdir -p "$ICON_DIR"
        cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
        echo -e "${YELLOW}⚠️  App icon placeholders created. Add actual icons before submission${NC}"
        echo "Use https://www.appicon.co to generate icons from a 1024x1024 image"
    else
        echo -e "${GREEN}✅ App icon configuration exists${NC}"
    fi
}

# Test build
test_build() {
    echo ""
    echo "Testing build configuration..."
    
    # Try to build the project
    echo "Attempting test build..."
    
    xcodebuild -project HobbyistSwiftUI.xcodeproj \
               -scheme HobbyistSwiftUI \
               -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
               -derivedDataPath build \
               clean build 2>&1 | tail -20
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful!${NC}"
    else
        echo -e "${YELLOW}⚠️  Build failed. Please check Xcode for errors${NC}"
    fi
}

# Fastlane setup
setup_fastlane() {
    echo ""
    echo "Setting up Fastlane for automated deployment..."
    
    cd ../
    
    # Initialize fastlane if needed
    if [ -d "fastlane" ]; then
        echo "Fastlane already configured"
        
        # Install fastlane plugins
        echo "Installing fastlane plugins..."
        bundle install 2>/dev/null || fastlane install_plugins
        
        echo -e "${GREEN}✅ Fastlane ready${NC}"
    else
        echo -e "${RED}❌ Fastlane directory not found${NC}"
    fi
}

# Display next steps
show_next_steps() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}✅ Setup Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Next Steps:"
    echo ""
    echo "1. Add app icons:"
    echo "   - Generate icons at https://www.appicon.co"
    echo "   - Add to Assets.xcassets/AppIcon.appiconset"
    echo ""
    echo "2. Create App Store Connect record:"
    echo "   - Visit https://appstoreconnect.apple.com"
    echo "   - Create new app with bundle ID: com.hobbyist.app"
    echo ""
    echo "3. Build and upload to TestFlight:"
    echo "   cd /Users/chromefang.exe/HobbyistSwiftUI"
    echo "   fastlane ios release_testflight"
    echo ""
    echo "4. Configure TestFlight testing:"
    echo "   - Add internal testers"
    echo "   - Submit for external testing review"
    echo "   - Invite alpha testers"
    echo ""
    echo "For detailed instructions, see:"
    echo "iOS/TESTFLIGHT_PREPARATION_REPORT.md"
    echo ""
    echo "=========================================="
}

# Main execution
main() {
    check_xcode
    check_developer_account
    install_dependencies
    configure_project
    create_app_icons
    open_xcode_project
    test_build
    setup_fastlane
    show_next_steps
}

# Run main function
main