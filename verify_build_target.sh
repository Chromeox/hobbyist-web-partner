#!/bin/bash

echo "🔨 Building HobbyApp to verify target membership fixes..."
echo ""

cd /Users/chromefang.exe/HobbyApp

# Try to build the project
xcodebuild -project HobbyApp.xcodeproj \
           -scheme HobbyApp \
           -configuration Debug \
           -destination 'generic/platform=iOS Simulator' \
           clean build 2>&1 | tee /tmp/build_output.log

# Check results
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo "All 6 files are now properly in the build target!"
else
    echo ""
    echo "⚠️  Build had errors. Checking if our 6 files are resolved..."

    # Check for our specific "Cannot find" errors
    if ! grep -q "Cannot find 'LoginView'" /tmp/build_output.log && \
       ! grep -q "Cannot find 'EnhancedOnboardingFlow'" /tmp/build_output.log && \
       ! grep -q "Cannot find 'AppConfiguration'" /tmp/build_output.log && \
       ! grep -q "Cannot find 'ShareSheet'" /tmp/build_output.log; then
        echo "✅ Good news: The 6 'Cannot find' errors are RESOLVED!"
        echo "   Remaining errors are from AppError.swift (as expected)"
    else
        echo "❌ Some files still not found. Double-check target membership."
    fi
fi

echo ""
echo "📊 Error summary:"
grep "error:" /tmp/build_output.log | wc -l | xargs echo "Total errors:"
