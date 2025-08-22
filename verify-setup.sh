#!/bin/bash

# Verification Script for Pricing System Setup

echo "🔍 HobbyistSwiftUI Pricing System Verification"
echo "=============================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Supabase CLI
echo "1️⃣  Checking Supabase CLI..."
if command -v supabase &> /dev/null; then
    VERSION=$(supabase --version | cut -d' ' -f3)
    echo -e "${GREEN}✅ Supabase CLI installed (version: $VERSION)${NC}"
else
    echo -e "${RED}❌ Supabase CLI not found${NC}"
fi

# Check project link
echo ""
echo "2️⃣  Checking Supabase project link..."
if supabase projects list 2>/dev/null | grep -q "mcjqvdzdhtcvbrejvrtp"; then
    echo -e "${GREEN}✅ Hobbyist project linked${NC}"
    echo "   Project ID: mcjqvdzdhtcvbrejvrtp"
    echo "   Region: West US (North California)"
else
    echo -e "${RED}❌ Project not linked${NC}"
fi

# Check migration files
echo ""
echo "3️⃣  Checking migration files..."
MIGRATION_DIR="/Users/chromefang.exe/HobbyistSwiftUI/supabase/migrations"
if [ -d "$MIGRATION_DIR" ]; then
    MIGRATION_COUNT=$(ls -1 "$MIGRATION_DIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✅ Found $MIGRATION_COUNT migration files${NC}"
    
    if [ -f "$MIGRATION_DIR/20240821_flexible_pricing_v2.sql" ]; then
        echo -e "${GREEN}✅ Flexible pricing migration found${NC}"
    else
        echo -e "${YELLOW}⚠️  Flexible pricing migration not found${NC}"
    fi
else
    echo -e "${RED}❌ Migration directory not found${NC}"
fi

# Check edge functions
echo ""
echo "4️⃣  Checking edge functions..."
FUNCTIONS_DIR="/Users/chromefang.exe/HobbyistSwiftUI/supabase/functions"
if [ -d "$FUNCTIONS_DIR" ]; then
    echo "   Found edge functions:"
    for func in stripe-products-setup purchase-credits credit-webhooks payments; do
        if [ -d "$FUNCTIONS_DIR/$func" ]; then
            echo -e "   ${GREEN}✅ $func${NC}"
        else
            echo -e "   ${YELLOW}⚠️  $func (missing)${NC}"
        fi
    done
else
    echo -e "${RED}❌ Functions directory not found${NC}"
fi

# Check iOS files
echo ""
echo "5️⃣  Checking iOS implementation..."
IOS_DIR="/Users/chromefang.exe/HobbyistSwiftUI/iOS/HobbyistSwiftUI"
if [ -d "$IOS_DIR" ]; then
    FILES=(
        "Services/ApplePayProducts.swift"
        "Services/IAPService.swift"
        "Services/PricingService.swift"
        "Views/Pricing/PricingView.swift"
        "Views/Pricing/PurchaseConfirmationView.swift"
        "Views/Pricing/PurchaseSuccessView.swift"
    )
    
    for file in "${FILES[@]}"; do
        if [ -f "$IOS_DIR/$file" ]; then
            echo -e "   ${GREEN}✅ $file${NC}"
        else
            echo -e "   ${YELLOW}⚠️  $file (missing)${NC}"
        fi
    done
else
    echo -e "${RED}❌ iOS directory not found${NC}"
fi

# Check environment file
echo ""
echo "6️⃣  Checking environment configuration..."
ENV_FILE="/Users/chromefang.exe/HobbyistSwiftUI/.env.local"
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}✅ .env.local exists${NC}"
    
    # Check for placeholder values
    if grep -q "your_.*_here" "$ENV_FILE"; then
        echo -e "${YELLOW}⚠️  Contains placeholder values - needs configuration${NC}"
    else
        echo -e "${GREEN}✅ Environment variables configured${NC}"
    fi
else
    echo -e "${RED}❌ .env.local not found${NC}"
fi

# Summary
echo ""
echo "=============================================="
echo "📊 Summary"
echo "=============================================="

echo ""
echo "To complete setup:"
echo ""
echo -e "${BLUE}1. Reset your database password:${NC}"
echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
echo ""
echo -e "${BLUE}2. Get your API keys:${NC}"
echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api"
echo ""
echo -e "${BLUE}3. Run the setup script:${NC}"
echo "   ./setup-pricing-system.sh"
echo ""
echo -e "${BLUE}4. Configure Stripe:${NC}"
echo "   - Get API keys from https://dashboard.stripe.com/apikeys"
echo "   - Update .env.local with keys"
echo ""
echo -e "${BLUE}5. Configure Apple Pay:${NC}"
echo "   - Add products in App Store Connect"
echo "   - Set up subscription groups"
echo "   - Configure shared secret"
echo ""