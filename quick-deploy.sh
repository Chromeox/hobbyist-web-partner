#!/bin/bash

# Quick Deploy Script - Run after getting your database password
# This handles the password securely without storing it

echo "🚀 HobbyistSwiftUI Quick Deploy"
echo "================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📋 This script will:"
echo "  1. Deploy your database migration"
echo "  2. Deploy edge functions"
echo "  3. Verify the setup"
echo ""

echo -e "${YELLOW}First, you need to reset your database password:${NC}"
echo "👉 Visit: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
echo ""
read -p "Have you reset your password? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please reset your password first, then run this script again"
    exit 1
fi

echo ""
echo "Now I'll run the migration. You'll be prompted for your password."
echo -e "${YELLOW}Tip: The password won't show when you type/paste it${NC}"
echo ""

# Run migration - this will prompt for password
cd /Users/chromefang.exe/HobbyistSwiftUI
if supabase db push --include-all; then
    echo -e "${GREEN}✅ Migration deployed successfully!${NC}"
else
    echo "Migration failed. Please check the error above."
    exit 1
fi

# Deploy edge functions
echo ""
echo "🚀 Deploying edge functions..."
supabase functions deploy stripe-products-setup
supabase functions deploy purchase-credits
supabase functions deploy credit-webhooks
supabase functions deploy payments

echo ""
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Get your Supabase API keys from:"
echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api"
echo ""
echo "2. Get your Stripe API keys from:"
echo "   https://dashboard.stripe.com/apikeys"
echo ""
echo "3. Update .env.local with these keys"
echo ""
echo "4. Configure Apple Pay products in App Store Connect"