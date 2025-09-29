#!/bin/bash

echo "=== MISSING FILE REFERENCES IN XCODE PROJECT ==="
echo "These files are referenced in project.pbxproj but don't exist:"
echo ""

# List of service files we deleted
deleted_files=(
    "PaymentService.swift"
    "SecurityMonitor.swift"
    "ServiceContainer.swift"
    "CreditService.swift"
    "PushNotificationService.swift"
    "VenueService.swift"
    "PricingService.swift"
    "RealtimeService.swift"
    "IAPService.swift"
    "InstructorService.swift"
    "GamificationService.swift"
    "RateLimitingService.swift"
    "FeedbackService.swift"
    "GamificationServiceProtocol.swift"
    "DataService.swift"
)

echo "Files to remove from Xcode project navigator:"
for file in "${deleted_files[@]}"; do
    # Check if file is still referenced in project.pbxproj
    if grep -q "$file" HobbyistSwiftUI.xcodeproj/project.pbxproj; then
        echo "❌ $file (still referenced in project)"
        # Show the specific lines
        grep -n "$file" HobbyistSwiftUI.xcodeproj/project.pbxproj | head -3
        echo ""
    else
        echo "✅ $file (already removed)"
    fi
done

echo ""
echo "=== MANUAL CLEANUP STEPS ==="
echo "1. In Xcode Project Navigator (left panel)"
echo "2. Look for red files (missing references)"
echo "3. Right-click each red file → 'Delete' → 'Remove Reference'"
echo "4. DO NOT choose 'Move to Trash' - just 'Remove Reference'"
echo ""
echo "After cleanup, build with: Cmd+B"