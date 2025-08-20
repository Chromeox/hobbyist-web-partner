#!/bin/bash

# Fix Migration History Script
# This script helps repair the migration history after file renames

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Migration History Repair Tool${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${YELLOW}Current local migration files:${NC}"
ls -1 supabase/migrations/*.sql | xargs -n1 basename

echo ""
echo -e "${YELLOW}To fix the migration history, you need to:${NC}"
echo ""
echo "1. First, check the current migration status:"
echo -e "${GREEN}   supabase migration list${NC}"
echo ""
echo "2. If there are mismatches, repair each migration:"
echo -e "${GREEN}   supabase migration repair --status applied 20250808000001${NC}"
echo -e "${GREEN}   supabase migration repair --status applied 20250808000002${NC}"
echo -e "${GREEN}   supabase migration repair --status applied 20250813000001${NC}"
echo -e "${GREEN}   supabase migration repair --status applied 20250819000001${NC}"
echo -e "${GREEN}   supabase migration repair --status applied 20250819000002${NC}"
echo -e "${GREEN}   supabase migration repair --status applied 20250819000003${NC}"
echo ""
echo "3. Then push any pending migrations:"
echo -e "${GREEN}   supabase db push --linked${NC}"
echo ""
echo "4. Finally, verify everything is synced:"
echo -e "${GREEN}   supabase db pull${NC}"
echo ""
echo -e "${YELLOW}Note: You'll need your database password for each command.${NC}"
echo -e "${YELLOW}Get it from: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database${NC}"