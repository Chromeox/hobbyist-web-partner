#!/bin/bash

# HobbyistSwiftUI App Store Archive Preparation Script
# This script prepares the iOS app for archiving and App Store submission

set -e  # Exit on any error

echo "🚀 Starting HobbyistSwiftUI App Store Archive Preparation..."
echo "=================================================="

# Configuration
PROJECT_NAME="HobbyistSwiftUI"
SCHEME="HobbyistSwiftUI"
BUNDLE_ID="com.hobbyist.app"
BUILD_CONFIG="Release"

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

# Step 1: Pre-Archive Configuration Check
print_step "1. Pre-Archive Configuration Check"

# Check if we're in the correct directory
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    print_error "Not in iOS project directory. Please run from iOS/ directory."
    exit 1
fi

# Check for valid code signing identity
print_step "Checking code signing identities..."
DISTRIBUTION_IDENTITY=$(security find-identity -p codesigning | grep "Apple Distribution" | head -1 | cut -d '"' -f 2)
if [ -z "$DISTRIBUTION_IDENTITY" ]; then
    print_error "No Apple Distribution certificate found. Please install distribution certificate."
    exit 1
else
    print_success "Found distribution certificate: $DISTRIBUTION_IDENTITY"
fi

# Step 2: Update Build and Version Numbers
print_step "2. Updating Build and Version Numbers"

CURRENT_VERSION=$(xcodebuild -showBuildSettings -scheme $SCHEME -configuration $BUILD_CONFIG | grep MARKETING_VERSION | awk '{print $3}')
CURRENT_BUILD=$(xcodebuild -showBuildSettings -scheme $SCHEME -configuration $BUILD_CONFIG | grep CURRENT_PROJECT_VERSION | awk '{print $3}')

echo "Current Version: $CURRENT_VERSION"
echo "Current Build: $CURRENT_BUILD"

# Increment build number
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "New Build Number: $NEW_BUILD"

# Update build number in project
xcrun agvtool new-version -all $NEW_BUILD
print_success "Updated build number to $NEW_BUILD"

# Step 3: Configure Release Build Settings
print_step "3. Configuring Release Build Settings"

# Verify release build settings
OPTIMIZATION_LEVEL=$(xcodebuild -showBuildSettings -scheme $SCHEME -configuration $BUILD_CONFIG | grep GCC_OPTIMIZATION_LEVEL | awk '{print $3}')
SWIFT_OPTIMIZATION=$(xcodebuild -showBuildSettings -scheme $SCHEME -configuration $BUILD_CONFIG | grep SWIFT_OPTIMIZATION_LEVEL | awk '{print $3}')

echo "GCC Optimization Level: $OPTIMIZATION_LEVEL"
echo "Swift Optimization Level: $SWIFT_OPTIMIZATION"

if [ "$OPTIMIZATION_LEVEL" != "s" ] || [ "$SWIFT_OPTIMIZATION" != "\"-O\"" ]; then
    print_warning "Build settings may not be optimized for release"
fi

# Step 4: Clean and Validate Project
print_step "4. Cleaning and Validating Project"

# Clean build folder
xcodebuild clean -scheme $SCHEME -configuration $BUILD_CONFIG
print_success "Project cleaned"

# Resolve packages
xcodebuild -resolvePackageDependencies -scheme $SCHEME
print_success "Package dependencies resolved"

# Validate project
print_step "Validating project build..."
xcodebuild build -scheme $SCHEME -configuration $BUILD_CONFIG -destination generic/platform=iOS -quiet
if [ $? -eq 0 ]; then
    print_success "Project builds successfully"
else
    print_error "Project build failed. Please fix build issues before archiving."
    exit 1
fi

# Step 5: Archive Information
print_step "5. Archive Preparation Complete"

echo ""
echo "📋 Archive Summary:"
echo "==================="
echo "Project: $PROJECT_NAME"
echo "Scheme: $SCHEME" 
echo "Bundle ID: $BUNDLE_ID"
echo "Version: $CURRENT_VERSION"
echo "Build: $NEW_BUILD"
echo "Configuration: $BUILD_CONFIG"
echo "Code Signing: $DISTRIBUTION_IDENTITY"
echo ""

# Step 6: Archive Command
print_step "6. Ready to Archive"

ARCHIVE_PATH="./build/${PROJECT_NAME}_v${CURRENT_VERSION}_b${NEW_BUILD}.xcarchive"
ARCHIVE_CMD="xcodebuild archive \\
    -scheme $SCHEME \\
    -configuration $BUILD_CONFIG \\
    -destination generic/platform=iOS \\
    -archivePath \"$ARCHIVE_PATH\" \\
    CODE_SIGN_STYLE=Automatic \\
    DEVELOPMENT_TEAM=594BDWKT53 \\
    CODE_SIGN_IDENTITY=\"$DISTRIBUTION_IDENTITY\""

echo "Archive will be created at: $ARCHIVE_PATH"
echo ""
echo "To create the archive, run:"
echo "$ARCHIVE_CMD"
echo ""

# Create build directory
mkdir -p ./build

print_success "Archive preparation complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Run the archive command above"
echo "2. Once archived, export for App Store distribution"
echo "3. Upload to App Store Connect using Xcode or altool"