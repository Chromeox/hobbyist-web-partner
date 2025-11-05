#!/bin/bash

# Font Readability Fixes for 2025 Standards
# Minimum font sizes: text-sm (14px) for body text, text-xs (12px) only for labels/timestamps

echo "🔤 Fixing font readability across the portal..."

# Fix text-xs to text-sm for important content (keeping timestamps and labels as text-xs)
files=(
  "app/dashboard/messages/MessagesCenter.tsx"
  "app/dashboard/students/StudentManagement.tsx"
  "app/dashboard/analytics/AnalyticsDashboard.tsx"
  "app/dashboard/DashboardOverview.tsx"
  "components/auth/SignUpForm.tsx"
  "components/auth/SignInForm.tsx"
  "app/dashboard/revenue/RevenueReporting.tsx"
  "app/dashboard/pricing/PricingManagement.tsx"
  "app/dashboard/classes/ClassManagement.tsx"
  "app/dashboard/bookings/BookingManagement.tsx"
  "app/dashboard/staff/StaffManagement.tsx"
  "app/dashboard/DashboardLayout.tsx"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "  📝 Updating $file..."
    
    # Update button text from text-xs to text-sm
    sed -i '' 's/text-xs font-medium/text-sm font-medium/g' "$file"
    
    # Update general text-xs to text-sm (except for timestamps and labels)
    sed -i '' 's/text-xs text-gray-600/text-sm text-gray-600/g' "$file"
    sed -i '' 's/text-xs text-gray-900/text-sm text-gray-900/g' "$file"
    
    # Keep these as text-xs (timestamps, labels, badges)
    # text-xs text-gray-500 (timestamps)
    # text-xs text-gray-400 (subtle labels)
    # text-xs font-semibold (badges)
    
    # Fix any text-2xs or text-3xs to text-xs minimum
    sed -i '' 's/text-2xs/text-xs/g' "$file"
    sed -i '' 's/text-3xs/text-xs/g' "$file"
    
    # Increase heading sizes
    sed -i '' 's/text-lg font-bold/text-xl font-bold/g' "$file"
    sed -i '' 's/text-lg font-semibold/text-xl font-semibold/g' "$file"
    sed -i '' 's/text-base font-bold/text-lg font-bold/g' "$file"
    sed -i '' 's/text-base font-semibold/text-lg font-semibold/g' "$file"
  fi
done

# Special handling for onboarding components
onboarding_files=(
  "app/onboarding/steps/StudioProfileStep.tsx"
  "app/onboarding/steps/VerificationStep.tsx"
  "app/onboarding/components/ProgressIndicator.tsx"
)

for file in "${onboarding_files[@]}"; do
  if [ -f "$file" ]; then
    echo "  📝 Updating onboarding: $file..."
    sed -i '' 's/text-xs/text-sm/g' "$file"
    sed -i '' 's/text-2xs/text-sm/g' "$file"
  fi
done

echo "✅ Font readability improvements complete!"
echo ""
echo "📊 Changes made:"
echo "  • Minimum font size: text-sm (14px) for body text"
echo "  • Labels/timestamps: text-xs (12px) minimum"
echo "  • Headings increased by one size level"
echo "  • Removed all text-2xs and text-3xs usage"