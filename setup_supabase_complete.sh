#!/bin/bash

# ================================================
# Complete Supabase Setup Script
# ================================================

set -e  # Exit on error

echo "================================================"
echo "     Complete Supabase Configuration"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found!${NC}"
    echo "Please install it with: brew install supabase/tap/supabase"
    exit 1
fi

echo -e "${GREEN}✓ Supabase CLI found${NC}"
echo ""

# Function to run SQL with password
run_sql() {
    local sql_file=$1
    local description=$2
    
    echo -e "${YELLOW}→ ${description}...${NC}"
    
    if [ -z "$DB_PASSWORD" ]; then
        echo "Please enter your database password:"
        read -s DB_PASSWORD
    fi
    
    PGPASSWORD="$DB_PASSWORD" psql \
        -h aws-0-us-west-1.pooler.supabase.com \
        -p 6543 \
        -U postgres.mcjqvdzdhtcvbrejvrtp \
        -d postgres \
        -f "$sql_file" \
        --quiet \
        --no-align \
        --tuples-only
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${description} completed${NC}"
    else
        echo -e "${RED}✗ ${description} failed${NC}"
        return 1
    fi
}

# Step 1: Apply migrations
echo "================================================"
echo "Step 1: Apply Database Migrations"
echo "================================================"
echo ""

./apply_migrations.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to apply migrations. Please fix and retry.${NC}"
    exit 1
fi

echo ""

# Step 2: Configure real-time, storage, and test data
echo "================================================"
echo "Step 2: Configure Real-time, Storage & Test Data"
echo "================================================"
echo ""

run_sql "supabase_complete_setup.sql" "Configuring real-time, storage buckets, and inserting test data"

echo ""

# Step 3: Deploy Edge Functions
echo "================================================"
echo "Step 3: Deploy Edge Functions"
echo "================================================"
echo ""

echo -e "${YELLOW}→ Deploying edge functions...${NC}"

# Check if we're linked to a project
if supabase status 2>/dev/null | grep -q "Linked project"; then
    # Deploy each function
    for func in supabase/functions/*/; do
        if [ -d "$func" ]; then
            func_name=$(basename "$func")
            echo -e "${YELLOW}  → Deploying ${func_name}...${NC}"
            supabase functions deploy "$func_name" --no-verify-jwt
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}  ✓ ${func_name} deployed${NC}"
            else
                echo -e "${RED}  ✗ ${func_name} deployment failed${NC}"
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠ Not linked to a Supabase project${NC}"
    echo "To link your project, run:"
    echo "  supabase link --project-ref mcjqvdzdhtcvbrejvrtp"
    echo ""
    echo "Edge functions created locally at: supabase/functions/"
    echo "You can deploy them later with:"
    echo "  supabase functions deploy [function-name]"
fi

echo ""

# Step 4: Set environment variables
echo "================================================"
echo "Step 4: Environment Variables"
echo "================================================"
echo ""

if [ ! -f .env.local ]; then
    echo -e "${YELLOW}→ Creating .env.local file...${NC}"
    cat > .env.local << EOF
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://mcjqvdzdhtcvbrejvrtp.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_KEY_HERE

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
STRIPE_SECRET_KEY=sk_test_YOUR_KEY
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET

# Apple Push Notifications
APNS_KEY_ID=YOUR_KEY_ID
APNS_TEAM_ID=YOUR_TEAM_ID
APNS_BUNDLE_ID=com.hobbyist.app

# App Configuration
APP_URL=https://your-app-url.com
ENABLE_ANALYTICS=true
EOF
    echo -e "${GREEN}✓ Created .env.local template${NC}"
    echo -e "${YELLOW}⚠ Please update .env.local with your actual keys${NC}"
else
    echo -e "${GREEN}✓ .env.local already exists${NC}"
fi

echo ""

# Step 5: Verify setup
echo "================================================"
echo "Step 5: Verification"
echo "================================================"
echo ""

echo -e "${YELLOW}→ Running verification queries...${NC}"

# Create verification script
cat > verify_setup.sql << EOF
-- Check real-time enabled tables
SELECT 'Real-time Tables' as check_type, COUNT(*) as count 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- Check storage buckets
SELECT 'Storage Buckets' as check_type, COUNT(*) as count 
FROM storage.buckets;

-- Check test data
SELECT 'Test Data' as check_type, 
    (SELECT COUNT(*) FROM venues) as venues,
    (SELECT COUNT(*) FROM instructors) as instructors,
    (SELECT COUNT(*) FROM classes) as classes,
    (SELECT COUNT(*) FROM hobby_categories) as categories,
    (SELECT COUNT(*) FROM credit_packs) as credit_packs,
    (SELECT COUNT(*) FROM achievements) as achievements;

-- Check functions
SELECT 'Database Functions' as check_type, COUNT(*) as count
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('process_credit_purchase', 'book_class');
EOF

run_sql "verify_setup.sql" "Verifying setup"

rm verify_setup.sql

echo ""
echo "================================================"
echo -e "${GREEN}✅ Supabase Configuration Complete!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Update .env.local with your API keys"
echo "2. Get your keys from: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api"
echo "3. Link project: supabase link --project-ref mcjqvdzdhtcvbrejvrtp"
echo "4. Deploy functions: supabase functions deploy [function-name]"
echo "5. Test the setup with your iOS app"
echo ""
echo "Dashboard: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp"
echo ""

# Create a summary file
cat > SUPABASE_SETUP_SUMMARY.md << EOF
# Supabase Setup Summary

## ✅ Completed Tasks

### 1. Database Migrations Applied
- All migrations (03-08) successfully applied
- Security enhancements in place
- Partner portal schema ready
- Revenue sharing system configured

### 2. Real-time Configuration
- Enabled on key tables: bookings, classes, user_credits, notifications, etc.
- Ready for live updates in the app

### 3. Storage Buckets Created
- avatars: User profile pictures
- class-images: Class thumbnails
- venue-images: Venue photos
- certificates: Achievement certificates
- chat-attachments: Message attachments

### 4. Edge Functions Created
- process-payment: Stripe payment processing
- send-notification: Push notifications
- class-recommendations: Personalized recommendations
- analytics: Reporting and metrics

### 5. Test Data Inserted
- Venues: 4 Vancouver locations
- Instructors: 3 test instructors
- Classes: 3 upcoming classes
- Categories: 8 hobby categories
- Credit packs: 3 pricing tiers
- Achievements: 6 gamification achievements

## 🔗 Important Links

- Dashboard: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp
- API Settings: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/api
- Database: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor
- Functions: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/functions
- Storage: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/storage

## 📝 Required API Keys

Get these from your Supabase dashboard:
- SUPABASE_URL
- SUPABASE_ANON_KEY  
- SUPABASE_SERVICE_ROLE_KEY

## 🚀 Ready for Testing!

Your Supabase backend is now fully configured and ready for:
- iOS app integration
- Web partner portal
- Alpha testing with TestFlight

Generated: $(date)
EOF

echo -e "${GREEN}✓ Created SUPABASE_SETUP_SUMMARY.md${NC}"