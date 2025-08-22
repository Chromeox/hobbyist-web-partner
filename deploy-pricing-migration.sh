#!/bin/bash

# Deploy Flexible Pricing V2 Migration to Supabase
# This script deploys the new Vancouver-based pricing system

set -e

echo "🚀 Deploying Flexible Pricing V2 Migration to Supabase..."
echo "=================================================="

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Installing..."
    brew install supabase/tap/supabase
fi

# Project configuration
PROJECT_ID="mcjqvdzdhtcvbrejvrtp"
MIGRATION_FILE="supabase/migrations/20240821_flexible_pricing_v2.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📋 Migration file found: $MIGRATION_FILE"
echo ""
echo "This migration will create:"
echo "  ✅ Credit packages (5 tiers: $25-$300)"
echo "  ✅ Subscription plans (4 tiers: $39-$179/month)"
echo "  ✅ Class tiers with credit requirements"
echo "  ✅ Credit insurance plans ($3-$8/month)"
echo "  ✅ Squad features for social accountability"
echo "  ✅ Retention metrics tracking"
echo "  ✅ Promotional campaigns system"
echo ""

# Confirm before proceeding
read -p "⚠️  This will modify your production database. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled"
    exit 1
fi

# Link to project if not already linked
echo "🔗 Linking to Supabase project..."
supabase link --project-ref $PROJECT_ID 2>/dev/null || true

# Run the migration
echo "🔄 Running migration..."
if supabase db push --include-all; then
    echo "✅ Migration deployed successfully!"
    
    # Show migration status
    echo ""
    echo "📊 Checking migration status..."
    supabase migration list
    
    echo ""
    echo "✅ Flexible Pricing V2 is now live!"
    echo ""
    echo "Next steps:"
    echo "1. Run ./setup-stripe-products.sh to create Stripe products"
    echo "2. Configure Apple Pay products in App Store Connect"
    echo "3. Test credit package purchases in the app"
else
    echo "❌ Migration failed. Please check the error above."
    exit 1
fi

echo ""
echo "🎉 Vancouver-based pricing system deployed successfully!"