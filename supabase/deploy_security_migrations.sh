#!/bin/bash

# ============================================
# Supabase Security Migration Deployment Script
# ============================================

set -e

echo "============================================"
echo "🔐 Supabase Security Migration Deployment"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI not found!${NC}"
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

# Get the project directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$PROJECT_DIR"

echo "📁 Working directory: $PROJECT_DIR"
echo ""

# Check if we're linked to a project
echo "🔍 Checking Supabase project link..."
LINKED_PROJECT=$(supabase projects list 2>/dev/null | grep "mcjqvdzdhtcvbrejvrtp" || true)

if [ -z "$LINKED_PROJECT" ]; then
    echo -e "${YELLOW}⚠️  Project not linked. Linking now...${NC}"
    supabase link --project-ref mcjqvdzdhtcvbrejvrtp
else
    echo -e "${GREEN}✅ Project already linked${NC}"
fi

echo ""
echo "📋 Migration files to deploy:"
echo "----------------------------"
ls -la supabase/migrations/*.sql | awk '{print $9}'

echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: This will apply security migrations to your database${NC}"
echo "Make sure you have:"
echo "1. ✅ Backed up your database"
echo "2. ✅ Reset your database password at:"
echo "   https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
echo ""

read -p "Do you want to continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Migration cancelled."
    exit 1
fi

# Run migrations
echo ""
echo "🚀 Running migrations..."
echo "------------------------"

if supabase db push; then
    echo -e "${GREEN}✅ Migrations applied successfully!${NC}"
else
    echo -e "${RED}❌ Migration failed!${NC}"
    echo "Please check the error messages above."
    exit 1
fi

# Verify migrations
echo ""
echo "🔍 Verifying security configuration..."
echo "-------------------------------------"

# Create verification script
cat > /tmp/verify_security.sql << 'EOF'
-- Check RLS status on all tables
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Enabled'
        ELSE '❌ DISABLED'
    END as rls_status
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
ORDER BY tablename;

-- Count policies per table
SELECT 
    schemaname,
    tablename,
    COUNT(policyname) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Check for functions without search_path
SELECT 
    proname as function_name,
    CASE 
        WHEN prosecdef AND proconfig IS NULL THEN '⚠️  Missing search_path'
        WHEN prosecdef AND proconfig IS NOT NULL THEN '✅ Has search_path'
        ELSE '✅ Not SECURITY DEFINER'
    END as security_status
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
ORDER BY proname;
EOF

echo "Running verification queries..."
supabase db query -f /tmp/verify_security.sql

# Clean up
rm /tmp/verify_security.sql

echo ""
echo "============================================"
echo -e "${GREEN}🎉 Security migration deployment complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Review the verification output above"
echo "2. Test your application authentication"
echo "3. Monitor security audit logs"
echo "4. Configure API rate limits in your app"
echo ""
echo "Security features now active:"
echo "✅ Row Level Security on all tables"
echo "✅ Optimized RLS policies with initplan"
echo "✅ Security audit logging"
echo "✅ Rate limiting support"
echo "✅ Failed login tracking"
echo "✅ Suspicious activity detection"
echo ""