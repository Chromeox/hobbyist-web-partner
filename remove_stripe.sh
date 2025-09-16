#!/bin/bash

# Force Remove Stripe Dependencies Script
echo "🗑️ Force removing Stripe from HobbyistSwiftUI project..."

PROJECT_FILE="/Users/chromefang.exe/HobbyistSwiftUI/HobbyistSwiftUI.xcodeproj/project.pbxproj"

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "✅ Created backup: project.pbxproj.backup"

# Remove all Stripe framework references
echo "🧹 Removing Stripe framework references..."
sed -i '' '/StripePaymentSheet in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/StripePayments in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/StripeApplePay in Frameworks/d' "$PROJECT_FILE"

# Remove Stripe file references
echo "🧹 Removing Stripe file references..."
sed -i '' '/StripePaymentService.swift/d' "$PROJECT_FILE"
sed -i '' '/StripeWebhookValidator.swift/d' "$PROJECT_FILE"

# Remove package references
echo "🧹 Removing package references..."
sed -i '' '/stripe-ios/d' "$PROJECT_FILE"
sed -i '' '/github.com\/stripe\/stripe-ios.git/d' "$PROJECT_FILE"

# Remove XCRemoteSwiftPackageReference entries
sed -i '' '/E2E73DED2E764B4800994857/d' "$PROJECT_FILE"

# Remove product references
sed -i '' '/E2E73DFA2E764DF500994858/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFB2E764DF500994859/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFC2E764DF500994860/d' "$PROJECT_FILE"

echo "✅ Stripe references removed from project file"

# Remove Stripe service files
echo "🗑️ Removing Stripe service files..."
rm -f "/Users/chromefang.exe/HobbyistSwiftUI/HobbyistSwiftUI/Services/StripePaymentService.swift"
rm -f "/Users/chromefang.exe/HobbyistSwiftUI/HobbyistSwiftUI/Services/StripeWebhookValidator.swift"

echo "✅ Stripe service files removed"

echo ""
echo "🎉 Stripe completely removed! Your app now uses pure Apple Pay/StoreKit."
echo "💡 Next: Test build with: xcodebuild -project HobbyistSwiftUI.xcodeproj -scheme HobbyistSwiftUI build"