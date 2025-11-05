#!/bin/bash

# Deploy Messaging Tables Migration to Supabase
# This script deploys the messaging tables and sets up real-time subscriptions

set -e

echo "🚀 Deploying Messaging Tables Migration to Supabase..."
echo "Project: mcjqvdzdhtcvbrejvrtp.supabase.co"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if migration file exists
if [ ! -f "migrations/messaging_tables.sql" ]; then
    echo -e "${RED}❌ Migration file not found: migrations/messaging_tables.sql${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Migration file found: migrations/messaging_tables.sql${NC}"

# Instructions for manual deployment
echo -e "${YELLOW}🔧 To deploy this migration:${NC}"
echo ""
echo "1. Open your Supabase dashboard:"
echo "   👉 https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp"
echo ""
echo "2. Navigate to: SQL Editor → New Query"
echo ""
echo "3. Copy and paste the SQL from: migrations/messaging_tables.sql"
echo ""
echo "4. Click 'Run' to execute the migration"
echo ""
echo -e "${GREEN}✅ Migration includes:${NC}"
echo "   • conversations table with RLS policies"
echo "   • messages table with real-time support"
echo "   • Database triggers for auto-updates"
echo "   • Index optimization for performance"
echo "   • Sample data for testing"
echo ""

# Display first few lines of the migration
echo -e "${BLUE}📄 Migration preview:${NC}"
echo "----------------------------------------"
head -n 10 migrations/messaging_tables.sql
echo "..."
echo "----------------------------------------"

echo ""
echo -e "${YELLOW}⚠️  Important notes:${NC}"
echo "   • This will enable realtime for messaging tables"
echo "   • RLS policies ensure secure access control"
echo "   • Sample conversation will be created for testing"
echo ""

# Offer to open the migration file
echo -e "${BLUE}📖 Would you like to view the complete migration file?${NC}"
echo "Run: cat migrations/messaging_tables.sql"
echo ""

# Success message
echo -e "${GREEN}🎯 After deployment, your messaging system will be ready!${NC}"
echo "   • Test at: http://localhost:3001/dashboard/messages"
echo "   • Real-time updates will work immediately"
echo "   • Instructor conversations can be created via the + button"

exit 0