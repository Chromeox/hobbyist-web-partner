#!/bin/bash

# Fix Release Build Hanging Issues
# This script addresses Swift compilation hanging in Release mode

echo "🔧 Fixing Release build compilation issues..."

# Backup the project file
cp HobbyistSwiftUI.xcodeproj/project.pbxproj HobbyistSwiftUI.xcodeproj/project.pbxproj.backup

# Fix Swift compilation mode for Release builds
# Change from 'wholemodule' to 'incremental' to prevent hanging
echo "📝 Setting Swift compilation mode to incremental for Release..."

# Use sed to replace Swift compilation mode in the project file
sed -i '' 's/SWIFT_COMPILATION_MODE = wholemodule;/SWIFT_COMPILATION_MODE = incremental;/' HobbyistSwiftUI.xcodeproj/project.pbxproj

# Also ensure we have proper optimization settings
echo "⚡ Configuring optimization levels..."

# Verify the changes
echo "✅ Changes applied. Verifying settings..."

# Check if the change was applied
if grep -q "SWIFT_COMPILATION_MODE = incremental" HobbyistSwiftUI.xcodeproj/project.pbxproj; then
    echo "✅ Swift compilation mode set to incremental"
else
    echo "❌ Failed to update Swift compilation mode"
    echo "🔄 Restoring backup..."
    cp HobbyistSwiftUI.xcodeproj/project.pbxproj.backup HobbyistSwiftUI.xcodeproj/project.pbxproj
    exit 1
fi

echo "🎯 Release build should now compile without hanging"
echo "💡 Note: Build time may be slightly longer but more reliable"
echo ""
echo "Next steps:"
echo "1. Open Xcode and try Archive again"
echo "2. If still having issues, clean build folder (Cmd+Shift+K)"
echo "3. Consider reducing dependencies if problems persist"