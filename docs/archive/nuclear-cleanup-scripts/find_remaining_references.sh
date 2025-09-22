#!/bin/bash

echo "=== REMAINING FAILING SERVICE REFERENCES ==="
echo "These files are causing build failures and need removal from Xcode project:"
echo ""

failing_files=(
    "APIRateLimiter.swift"
    "PaymentServiceProtocol.swift"
    "NotificationServiceProtocol.swift"
    "ApplePayProducts.swift"
    "LocationService.swift"
    "BookingService.swift"
    "FollowingService.swift"
)

echo "Files that need reference removal from Xcode project navigator:"
for file in "${failing_files[@]}"; do
    if grep -q "$file" HobbyistSwiftUI.xcodeproj/project.pbxproj; then
        echo "❌ $file (still referenced in project - REMOVE)"
    else
        echo "✅ $file (already removed)"
    fi
done

echo ""
echo "=== MANUAL CLEANUP REQUIRED ==="
echo "1. In Xcode Project Navigator, look for RED files"
echo "2. Right-click each red file → Delete → Remove Reference"
echo "3. Focus on Services folder - remove all red/missing files"
echo "4. After cleanup, build should succeed"
echo ""