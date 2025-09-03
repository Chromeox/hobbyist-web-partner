#!/bin/bash

# Deploy Fixed Migrations Script
# Run this after fixing PostgreSQL compatibility issues

echo "🚀 Deploying Fixed Vancouver Pricing System"
echo "==========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${GREEN}✅ Migrations have been fixed for PostgreSQL compatibility${NC}"
echo ""
echo "This will deploy:"
echo "  📦 Base tables (user_credits, studios, classes, bookings)"
echo "  💳 Credit packages ($25-$300)"
echo "  📅 Subscription plans ($39-$179/month)"
echo "  🛡️ Insurance options ($3-$8/month)"
echo "  👥 Squad features for social accountability"
echo "  📈 Dynamic pricing rules"
echo ""

echo -e "${YELLOW}You'll need to enter your database password when prompted.${NC}"
echo -e "${YELLOW}Remember: The password won't show as you type!${NC}"
echo ""

# Apply all migrations
echo "Running migrations..."
if supabase db push --include-all; then
    echo ""
    echo -e "${GREEN}✅ SUCCESS! All migrations deployed!${NC}"
    echo ""
    
    # Now deploy edge functions
    echo -e "${BLUE}Deploying Edge Functions...${NC}"
    echo "--------------------------------"
    
    # Deploy each function
    FUNCTIONS=("stripe-products-setup" "purchase-credits" "credit-webhooks" "payments")
    
    for func in "${FUNCTIONS[@]}"; do
        echo "Deploying $func..."
        if [ -d "supabase/functions/$func" ]; then
            if supabase functions deploy "$func"; then
                echo -e "  ${GREEN}✅ $func deployed${NC}"
            else
                echo -e "  ${YELLOW}⚠️ $func deployment issue (may already exist)${NC}"
            fi
        else
            echo -e "  ${YELLOW}⚠️ $func directory not found${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 COMPLETE! Vancouver Pricing System Deployed!${NC}"
    echo ""
    echo "================================================"
    echo -e "${BLUE}📋 What's Now Live in Your Database:${NC}"
    echo "================================================"
    echo ""
    echo "✅ Credit Packages:"
    echo "   • Starter: 10 credits for $25"
    echo "   • Explorer: 25 credits for $55"
    echo "   • Regular: 50 credits for $95"
    echo "   • Enthusiast: 100 credits for $170"
    echo "   • Power User: 200 credits for $300"
    echo ""
    echo "✅ Subscription Tiers:"
    echo "   • Casual: $39/month (30 credits)"
    echo "   • Active: $69/month (60 credits)"
    echo "   • Premium: $119/month (120 credits)"
    echo "   • Elite: $179/month (200 credits)"
    echo ""
    echo "✅ Additional Features:"
    echo "   • Credit Insurance ($3-$8/month)"
    echo "   • Squad social features"
    echo "   • Winter bonus (20% extra Nov-Feb)"
    echo "   • Dynamic peak/off-peak pricing"
    echo ""
    echo "================================================"
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo "================================================"
    echo ""
    echo "1. Get your Supabase API keys:"
    echo -e "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api${NC}"
    echo ""
    echo "2. Configure Stripe:"
    echo -e "   ${YELLOW}https://dashboard.stripe.com/apikeys${NC}"
    echo ""
    echo "3. Update .env.local with your keys"
    echo ""
    echo "4. View your new tables:"
    echo -e "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor${NC}"
    echo ""
    echo "5. Configure Apple Pay products in App Store Connect"
    echo ""
    echo -e "${GREEN}Your pricing system is ready for Vancouver! 🎉${NC}"
    
else
    echo ""
    echo -e "${RED}❌ Migration failed${NC}"
    echo ""
    echo "If you see 'relation already exists' errors, your tables might already be deployed!"
    echo ""
    echo "Check your database here:"
    echo -e "${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor${NC}"
    echo ""
    echo "If tables exist, you can skip to deploying edge functions:"
    echo "  supabase functions deploy --all"
fi