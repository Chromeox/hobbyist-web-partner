#!/bin/bash

# Remove Stripe Framework References from Xcode Project
echo "🗑️ Removing Stripe framework references from target..."

PROJECT_FILE="/Users/chromefang.exe/HobbyistSwiftUI/HobbyistSwiftUI.xcodeproj/project.pbxproj"

# Remove PBXBuildFile entries for Stripe frameworks
echo "🧹 Removing PBXBuildFile entries..."
sed -i '' '/E2E73DFB2E764DF500994858.*StripePaymentSheet in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFC2E764DF500994859.*StripePayments in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFD2E764DF500994860.*StripeApplePay in Frameworks/d' "$PROJECT_FILE"

# Remove framework references from Frameworks build phase
echo "🧹 Removing from Frameworks build phase..."
sed -i '' '/E2E73DFB2E764DF500994858.*StripePaymentSheet in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFC2E764DF500994859.*StripePayments in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/E2E73DFD2E764DF500994860.*StripeApplePay in Frameworks/d' "$PROJECT_FILE"

# Remove XCSwiftPackageProductDependency entries
echo "🧹 Removing XCSwiftPackageProductDependency entries..."
sed -i '' '/E2E73DFA2E764DF500994858.*StripePaymentSheet/,+3d' "$PROJECT_FILE"
sed -i '' '/E2E73DFB2E764DF500994859.*StripePayments/,+3d' "$PROJECT_FILE"
sed -i '' '/E2E73DFC2E764DF500994860.*StripeApplePay/,+3d' "$PROJECT_FILE"

echo "✅ Stripe framework references removed!"
echo "🚀 Ready to test build without Stripe frameworks."