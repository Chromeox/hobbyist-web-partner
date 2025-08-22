#!/bin/bash

# Complete Setup Script for Vancouver Pricing System
# Run this after setting your database password

set -e

echo "🚀 HobbyistSwiftUI Pricing System Setup"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found${NC}"
    echo "Installing Supabase CLI..."
    brew install supabase/tap/supabase
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found${NC}"
    echo "Please install Node.js first: brew install node"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Step 1: Database Migration
echo "📦 Step 1: Database Migration"
echo "-----------------------------"
echo "You need to reset your database password first:"
echo -e "${YELLOW}👉 Visit: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database${NC}"
echo ""
read -p "Have you reset your database password? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please reset your password first, then run this script again${NC}"
    exit 1
fi

echo "Running database migration..."
cd /Users/chromefang.exe/HobbyistSwiftUI

# This will prompt for password
supabase db push --include-all

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database migration successful!${NC}"
else
    echo -e "${RED}❌ Migration failed. Please check the error above${NC}"
    exit 1
fi

# Step 2: Environment Variables
echo ""
echo "📝 Step 2: Setting up environment variables"
echo "-------------------------------------------"

ENV_FILE="/Users/chromefang.exe/HobbyistSwiftUI/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env.local file..."
    cat > "$ENV_FILE" << 'EOF'
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Stripe Configuration
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=your_webhook_secret_here

# Apple Pay Configuration
APP_STORE_CONNECT_SHARED_SECRET=your_shared_secret_here
EOF
    echo -e "${YELLOW}⚠️  Please update the .env.local file with your actual keys${NC}"
else
    echo -e "${GREEN}✅ .env.local already exists${NC}"
fi

# Step 3: Deploy Edge Functions
echo ""
echo "🚀 Step 3: Deploying Edge Functions"
echo "------------------------------------"

echo "Deploying stripe-products-setup function..."
supabase functions deploy stripe-products-setup

echo "Deploying purchase-credits function..."
supabase functions deploy purchase-credits

echo "Deploying credit-webhooks function..."
supabase functions deploy credit-webhooks

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Edge functions deployed!${NC}"
else
    echo -e "${YELLOW}⚠️  Some edge functions may have failed. Check the output above${NC}"
fi

# Step 4: Create Stripe Products
echo ""
echo "💳 Step 4: Creating Stripe Products"
echo "------------------------------------"

read -p "Do you have your Stripe API keys configured? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating Stripe products via edge function..."
    
    # Get service role key
    read -sp "Enter your Supabase service role key: " SERVICE_KEY
    echo
    
    curl -X POST https://mcjqvdzdhtcvbrejvrtp.supabase.co/functions/v1/stripe-products-setup \
        -H "Authorization: Bearer $SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -d '{"action": "create"}' \
        --silent | python3 -m json.tool
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Stripe products created!${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to create Stripe products. You can do this manually later${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Skipping Stripe product creation. You can run this later${NC}"
fi

# Step 5: Configure iOS App
echo ""
echo "📱 Step 5: iOS App Configuration"
echo "---------------------------------"

PLIST_FILE="/Users/chromefang.exe/HobbyistSwiftUI/iOS/HobbyistSwiftUI/Info.plist"

echo "Checking Info.plist configuration..."
if grep -q "com.hobbyist.app" "$PLIST_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Bundle identifier configured${NC}"
else
    echo -e "${YELLOW}⚠️  Please ensure your bundle identifier is set to: com.hobbyist.app${NC}"
fi

# Step 6: Verification
echo ""
echo "✅ Step 6: Verification"
echo "-----------------------"

echo "Checking database tables..."
TABLES=$(supabase db dump --data-only | grep -c "credit_packs" || echo "0")

if [ "$TABLES" -gt "0" ]; then
    echo -e "${GREEN}✅ Database tables created${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify database tables${NC}"
fi

# Summary
echo ""
echo "======================================"
echo "🎉 Setup Complete!"
echo "======================================"
echo ""
echo "✅ Completed:"
echo "  • Database migration deployed"
echo "  • Edge functions configured"
echo "  • Environment variables template created"
echo ""
echo "📋 Next Steps:"
echo "  1. Update .env.local with your actual API keys"
echo "  2. Configure Apple Pay in App Store Connect:"
echo "     - Add In-App Purchase products"
echo "     - Set up subscription groups"
echo "     - Configure shared secret"
echo "  3. Test the purchase flow in the app"
echo ""
echo "🔗 Important URLs:"
echo "  • Supabase Dashboard: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp"
echo "  • Database Password Reset: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
echo "  • API Keys: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"