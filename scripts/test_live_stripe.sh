#!/bin/bash

# Test Live Stripe Integration Script
# This script helps verify your live Stripe setup

echo "🔵 Testing Live Stripe Integration..."
echo ""

# Check if we're in the right directory
if [ ! -f "HobbyApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the HobbyApp root directory"
    exit 1
fi

echo "📋 Pre-flight Checklist:"
echo ""

# Check Configuration.swift for live key
if grep -q "pk_live_" HobbyApp/Configuration.swift; then
    echo "✅ Live publishable key found in Configuration.swift"
else
    echo "⚠️  Live publishable key not found. Update Configuration.swift with your pk_live_ key"
fi

# Check if Stripe is properly configured in Info.plist
if grep -q "stripe.com" HobbyApp/Info.plist; then
    echo "✅ Stripe domain exception found in Info.plist"
else
    echo "⚠️  Stripe domain exception missing from Info.plist"
fi

# Check for URL schemes
if grep -q "stripe" HobbyApp/Info.plist; then
    echo "✅ Stripe URL scheme found in Info.plist"
else
    echo "⚠️  Stripe URL scheme missing from Info.plist"
fi

echo ""
echo "🏦 Stripe Dashboard Checklist:"
echo ""
echo "□ Switch to Live Mode in Stripe Dashboard"
echo "□ Copy live publishable key (pk_live_...)"
echo "□ Add Canadian bank account for payouts"
echo "□ Complete business verification"
echo "□ Upload required identity documents"
echo "□ Set payout schedule (recommend: daily)"
echo "□ Configure webhook endpoints (optional)"
echo ""

echo "💳 Test Payment Scenarios:"
echo ""
echo "□ Test successful payment with valid card"
echo "□ Test declined payment with test card"
echo "□ Test Apple Pay integration"
echo "□ Test credit pack purchase flow"
echo "□ Verify studio commission calculations (30% platform, 70% studio)"
echo ""

echo "🚨 Security Reminders:"
echo ""
echo "• Never commit sk_live_ keys to git"
echo "• Use environment variables for secret keys"
echo "• Monitor live transactions regularly"
echo "• Set up fraud detection rules"
echo ""

echo "📱 Next Steps:"
echo ""
echo "1. Update Configuration.swift with your live pk_live_ key"
echo "2. Complete Stripe account verification"
echo "3. Test a small live payment (e.g., $1 CAD)"
echo "4. Verify payout appears in your bank account"
echo "5. Deploy to TestFlight for alpha testing"
echo ""

echo "✅ Live Stripe setup guide complete!"
echo ""
echo "For detailed instructions, see: docs/STRIPE_LIVE_SETUP_GUIDE.md"