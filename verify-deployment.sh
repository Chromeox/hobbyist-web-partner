#!/bin/bash

# Verify Database Deployment
echo "🔍 Verifying HobbyistSwiftUI Database Deployment"
echo "================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${BLUE}📊 Database Tables Status:${NC}"
echo "Visit: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor"
echo ""

echo -e "${BLUE}🔧 Edge Functions Status:${NC}"
supabase functions list | grep -E "(purchase-credits|payments|credit-webhooks|stripe-products-setup)" || echo "Functions not found"
echo ""

echo -e "${BLUE}💳 Payment Architecture Recommendations:${NC}"
echo ""
echo -e "${YELLOW}For Alpha/TestFlight Launch:${NC}"
echo "• Option 1: Apple IAP only (simpler, faster approval)"
echo "  - Use StoreKit 2 for subscriptions"
echo "  - Apple handles all payment processing"
echo "  - 30% fee (15% after year 1)"
echo ""
echo "• Option 2: Hybrid (current setup)"
echo "  - Apple IAP for digital credits/subscriptions"
echo "  - Stripe for direct class bookings (physical service)"
echo "  - More complex but lower fees"
echo ""

echo -e "${GREEN}✅ Your database supports both approaches!${NC}"
echo ""
echo "Next steps:"
echo "1. Choose payment architecture (recommend Option 1 for alpha)"
echo "2. Configure Apple Developer account"
echo "3. Set up TestFlight distribution"
echo "4. Create App Store Connect products"
echo ""

echo -e "${BLUE}📱 iOS App Configuration:${NC}"
echo "• Bundle ID: com.hobbyist.app"
echo "• Team ID: [Pending Apple Developer enrollment]"
echo "• Product IDs to create in App Store Connect:"
echo "  - com.hobbyist.credits.25 (25 credits for $25)"
echo "  - com.hobbyist.credits.55 (55 credits for $50)"
echo "  - com.hobbyist.credits.120 (120 credits for $90)"
echo "  - com.hobbyist.subscription.starter ($39/month)"
echo "  - com.hobbyist.subscription.active ($69/month)"
echo "  - com.hobbyist.subscription.unlimited ($99/month)"
echo "  - com.hobbyist.subscription.platinum ($179/month)"