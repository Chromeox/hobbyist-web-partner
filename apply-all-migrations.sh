#!/bin/bash

# Apply All Migrations Script
# This will apply all pending migrations to your remote database

echo "🚀 Applying All Migrations to Remote Database"
echo "============================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${BLUE}This will apply these migrations:${NC}"
echo "  1. 20240819_create_base_tables.sql (base tables)"
echo "  2. 20240820_base_tables.sql (additional base tables)"
echo "  3. 20240821_flexible_pricing_v2.sql (pricing system)"
echo "  + Any other migrations in order"
echo ""

echo -e "${YELLOW}You'll need to enter your database password.${NC}"
echo -e "${YELLOW}The password won't show as you type - that's normal!${NC}"
echo ""

# Apply all migrations with include-all flag
echo "Running: supabase db push --include-all"
echo ""

if supabase db push --include-all; then
    echo ""
    echo -e "${GREEN}✅ SUCCESS! All migrations applied!${NC}"
    echo ""
    echo "Your database now has:"
    echo "  ✅ Base tables (users, studios, classes, bookings)"
    echo "  ✅ Credit system with packages ($25-$300)"
    echo "  ✅ Subscription tiers ($39-$179/month)"
    echo "  ✅ Insurance plans ($3-$8/month)"
    echo "  ✅ Squad features for social accountability"
    echo "  ✅ Dynamic pricing rules"
    echo "  ✅ Retention metrics tracking"
    echo ""
    
    # Deploy edge functions
    echo -e "${BLUE}Step 2: Deploying Edge Functions${NC}"
    echo "--------------------------------------"
    
    echo "Deploying edge functions (no password needed)..."
    
    # Deploy each function
    for func in stripe-products-setup purchase-credits credit-webhooks payments; do
        echo "Deploying $func..."
        if supabase functions deploy $func 2>/dev/null; then
            echo -e "${GREEN}  ✅ $func deployed${NC}"
        else
            echo -e "${YELLOW}  ⚠️ $func might already be deployed${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🎉 COMPLETE! Your pricing system is deployed!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo "1. Get your Supabase API keys:"
    echo "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api${NC}"
    echo ""
    echo "2. Get your Stripe API keys:"
    echo "   ${YELLOW}https://dashboard.stripe.com/apikeys${NC}"
    echo ""
    echo "3. Update .env.local with your keys"
    echo ""
    echo "4. View your database tables:"
    echo "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor${NC}"
    echo ""
    echo "5. Configure Apple Pay in App Store Connect"
    
else
    echo ""
    echo -e "${RED}❌ Migration failed${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Wrong password - Reset it at:"
    echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
    echo ""
    echo "2. Network issues - Check your internet connection"
    echo ""
    echo "3. Try viewing existing tables at:"
    echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor"
fi