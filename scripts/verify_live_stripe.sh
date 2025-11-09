#!/bin/bash

# Verify Live Stripe Integration
# Run this after completing bank account setup

echo "🔵 Verifying Live Stripe Setup..."
echo ""

# Check if we have live keys
if grep -q "pk_live_" HobbyApp/Configuration.swift; then
    echo "✅ Live publishable key configured"
    STRIPE_KEY=$(grep "pk_live_" HobbyApp/Configuration.swift | sed 's/.*\(pk_live_[^"]*\).*/\1/')
    echo "   Key: ${STRIPE_KEY:0:20}..."
else
    echo "❌ No live publishable key found"
    exit 1
fi

echo ""
echo "🏦 Bank Account Verification Steps:"
echo ""
echo "1. Log into Stripe Dashboard: https://dashboard.stripe.com"
echo "2. Switch to Live Mode"
echo "3. Go to Settings → Payouts"
echo "4. Verify your bank account shows as 'Active'"
echo "5. Check payout schedule is set to 'Daily'"
echo ""

echo "💳 Test Payment Checklist:"
echo ""
echo "□ Open HobbyApp on physical device (not simulator)"
echo "□ Navigate to credit pack purchase"
echo "□ Use test card: 4242 4242 4242 4242"
echo "□ Complete purchase flow"
echo "□ Check Stripe Dashboard for successful payment"
echo "□ Verify payout scheduled to your bank account"
echo ""

echo "🚨 Important Security Notes:"
echo ""
echo "• Test with small amounts first ($1-5 CAD)"
echo "• Monitor all live transactions"
echo "• Never share secret keys (sk_live_)"
echo "• Set up fraud monitoring in Stripe"
echo ""

echo "📊 Expected Commission Flow:"
echo ""
echo "Customer pays \$30 for class:"
echo "├── Platform revenue: \$9.00 (30%)"
echo "├── Studio payout: \$21.00 (70%)"
echo "└── Stripe fee: ~\$1.17 (3.9% + 30¢)"
echo ""

echo "✅ Live Stripe verification guide complete!"
echo ""
echo "Next: Test a \$1 CAD payment to verify everything works"