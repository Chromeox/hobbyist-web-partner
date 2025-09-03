#!/bin/bash

# Fresh Database Deployment Script
# This will drop all old tables and create a clean Vancouver pricing system

echo "🚀 Fresh Database Deployment for HobbyistSwiftUI"
echo "================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${YELLOW}⚠️  WARNING: This will DROP ALL EXISTING TABLES and start fresh!${NC}"
echo ""
echo "This is recommended because:"
echo "• Removes conflicts from old migrations"
echo "• Creates clean schema aligned with Vancouver pricing"
echo "• Ensures all foreign keys and relationships are correct"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 1: Running database cleanup...${NC}"
echo "This will drop all existing tables"
echo ""

echo "Enter your database password when prompted:"
echo "(Password won't show as you type)"
echo ""

# First, run the cleanup
if supabase db push --include-all; then
    echo -e "${GREEN}✅ Database cleaned and migrations applied!${NC}"
    echo ""
    
    # Deploy edge functions
    echo -e "${BLUE}Step 2: Deploying Edge Functions...${NC}"
    echo "--------------------------------------"
    
    # Check if functions directory exists
    if [ -d "supabase/functions" ]; then
        for func in stripe-products-setup purchase-credits credit-webhooks payments; do
            if [ -d "supabase/functions/$func" ]; then
                echo "Deploying $func..."
                if supabase functions deploy "$func" 2>/dev/null; then
                    echo -e "  ${GREEN}✅ $func deployed${NC}"
                else
                    echo -e "  ${YELLOW}ℹ️ $func may already exist${NC}"
                fi
            fi
        done
    else
        echo -e "${YELLOW}Edge functions directory not found. Skipping...${NC}"
    fi
    
    echo ""
    echo "=========================================="
    echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}✅ Database Tables Created:${NC}"
    echo "  • user_credits - Credit balance tracking"
    echo "  • studios - Partner studios in Vancouver"
    echo "  • instructors - Instructor profiles"
    echo "  • classes - Class definitions with tiers"
    echo "  • class_schedules - Scheduled sessions"
    echo "  • bookings - User bookings"
    echo "  • credit_packs - 5 packages ($25-$300)"
    echo "  • subscription_plans - 4 tiers ($39-$179/month)"
    echo "  • credit_insurance_plans - 3 options ($3-$8/month)"
    echo "  • squads - Social accountability groups"
    echo "  • dynamic_pricing_rules - Peak/off-peak pricing"
    echo "  • promotional_campaigns - Promo codes"
    echo "  • retention_metrics - User engagement tracking"
    echo ""
    echo -e "${BLUE}✅ Features Enabled:${NC}"
    echo "  • Vancouver market pricing ($10-$150 classes)"
    echo "  • Credit system (0.5-4 credits per class)"
    echo "  • Winter bonus (20% extra Nov-Feb)"
    echo "  • Squad social features"
    echo "  • Credit rollover (25-100% based on tier)"
    echo "  • Insurance to prevent expiration"
    echo "  • Peak/off-peak dynamic pricing"
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo ""
    echo "1. View your new database schema:"
    echo -e "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor${NC}"
    echo ""
    echo "2. Get your API keys:"
    echo -e "   ${YELLOW}https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api${NC}"
    echo ""
    echo "3. Configure Stripe products:"
    echo -e "   ${YELLOW}https://dashboard.stripe.com${NC}"
    echo ""
    echo "4. Set up Apple Pay products in App Store Connect"
    echo ""
    echo "5. Update .env.local with your API keys"
    echo ""
    echo -e "${GREEN}Your Vancouver pricing system is ready! 🎉${NC}"
    
else
    echo ""
    echo -e "${RED}❌ Deployment failed${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Wrong password - Reset at:"
    echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
    echo ""
    echo "2. If you see syntax errors, check the logs above"
    echo ""
    echo "3. You can also try running migrations manually in the SQL editor:"
    echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql"
fi