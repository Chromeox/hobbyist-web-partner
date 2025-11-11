#!/bin/bash

echo "🔨 Quick build check to verify files are in build target..."
echo ""

cd /Users/chromefang.exe/HobbyApp

# Quick syntax check only (faster than full build)
xcodebuild -project HobbyApp.xcodeproj \
           -scheme HobbyApp \
           -destination 'generic/platform=iOS Simulator' \
           -dry-run \
           build 2>&1 | head -30

echo ""
echo "✅ If you see 'Build settings from command line:' above, Xcode recognized the project!"
echo ""
echo "Now try pressing ⌘B in Xcode to build and check for 'Cannot find' errors."
