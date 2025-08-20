#!/bin/bash

# Complete Migration Sync Script
# Fixes the mismatch between local and remote migration history

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Complete Migration Sync Tool${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

cd /Users/chromefang.exe/HobbyistSwiftUI

echo -e "${YELLOW}This script will fix the migration sync issue.${NC}"
echo -e "${YELLOW}You'll need to enter your database password for each command.${NC}"
echo ""
echo -e "${RED}Important: Run each command one at a time!${NC}"
echo ""

echo -e "${GREEN}Step 1: Mark the remote-only migration as reverted${NC}"
echo "This removes the phantom migration from June 2nd that doesn't exist locally:"
echo ""
echo -e "${BLUE}supabase migration repair --status reverted 20250602234749${NC}"
echo ""
echo "Run this command now, then press Enter when done..."
read -p ""

echo -e "${GREEN}Step 2: Mark all local migrations as applied${NC}"
echo "This tells Supabase that your local migrations have been executed:"
echo ""
echo -e "${BLUE}supabase migration repair --status applied 20250808000001${NC}"
echo -e "${BLUE}supabase migration repair --status applied 20250808000002${NC}"
echo -e "${BLUE}supabase migration repair --status applied 20250813000001${NC}"
echo ""
echo "Run these commands now, then press Enter when done..."
read -p ""

echo -e "${GREEN}Step 3: Check the migration status${NC}"
echo "Verify all migrations are now aligned:"
echo ""
echo -e "${BLUE}supabase migration list${NC}"
echo ""
echo "Run this command and verify both Local and Remote columns show the same migrations."
echo "Press Enter when done..."
read -p ""

echo -e "${GREEN}Step 4: Final sync${NC}"
echo "Now try to pull the database schema:"
echo ""
echo -e "${BLUE}supabase db pull${NC}"
echo ""
echo "This should now show: 'Local and remote migrations are in sync'"
echo ""

echo -e "${GREEN}✅ Migration sync process complete!${NC}"
echo ""
echo "If you still see errors, it means the August 19 migrations weren't marked properly."
echo "In that case, also run:"
echo -e "${BLUE}supabase migration repair --status applied 20250819000001${NC}"
echo -e "${BLUE}supabase migration repair --status applied 20250819000002${NC}"
echo -e "${BLUE}supabase migration repair --status applied 20250819000003${NC}"