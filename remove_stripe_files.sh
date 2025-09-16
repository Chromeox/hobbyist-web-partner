#!/bin/bash

# Remove Stripe File References from Xcode Project
echo "🗑️ Removing Stripe file references from project..."

PROJECT_FILE="/Users/chromefang.exe/HobbyistSwiftUI/HobbyistSwiftUI.xcodeproj/project.pbxproj"

# Create backup
cp "$PROJECT_FILE" "$PROJECT_FILE.backup-stripe-files"

# Remove PBXBuildFile entries for Stripe files
echo "🧹 Removing build file entries..."
sed -i '' '/E2E5EFFB2E790D3200F90F24.*StripeWebhookValidator.swift in Sources/d' "$PROJECT_FILE"
sed -i '' '/E2E5EFFF2E790D3200F90F24.*StripePaymentService.swift in Sources/d' "$PROJECT_FILE"

# Remove PBXFileReference entries
echo "🧹 Removing file references..."
sed -i '' '/E2E5EFD32E790D3200F90F24.*StripePaymentService.swift/d' "$PROJECT_FILE"
sed -i '' '/E2E5EFD42E790D3200F90F24.*StripeWebhookValidator.swift/d' "$PROJECT_FILE"

# Remove from group references (Services folder)
echo "🧹 Removing from Services group..."
sed -i '' '/E2E5EFD32E790D3200F90F24.*StripePaymentService.swift/d' "$PROJECT_FILE"
sed -i '' '/E2E5EFD42E790D3200F90F24.*StripeWebhookValidator.swift/d' "$PROJECT_FILE"

# Remove from Sources build phase
echo "🧹 Removing from Sources build phase..."
sed -i '' '/E2E5EFFB2E790D3200F90F24.*StripeWebhookValidator.swift in Sources/d' "$PROJECT_FILE"
sed -i '' '/E2E5EFFF2E790D3200F90F24.*StripePaymentService.swift in Sources/d' "$PROJECT_FILE"

echo "✅ Stripe file references removed!"
echo "🚀 Project should now build successfully with Apple Pay only."