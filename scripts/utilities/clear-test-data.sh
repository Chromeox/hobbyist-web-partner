#!/bin/bash

# Clear Test Data Script
# Run this before testing or starting automated runs

echo "🧹 Google Sheets Test Data Cleaner"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ask for confirmation
echo -e "${YELLOW}This will clear all test data from your Google Sheet${NC}"
echo "Sheet ID: 14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w"
echo ""
read -p "Are you sure you want to clear all test data? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo -e "${GREEN}Opening Google Sheets...${NC}"
    open "https://docs.google.com/spreadsheets/d/14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w/edit"
    
    echo ""
    echo -e "${YELLOW}📋 Manual Steps:${NC}"
    echo "1. Click menu: '🧹 Data Management'"
    echo "2. Select: '🗑️ Clear All Test Data'"
    echo "3. Confirm the clearing"
    echo ""
    echo "Or to keep some data:"
    echo "- '🔄 Remove Duplicates' - Keep unique events only"
    echo "- '📅 Clear Old Events' - Remove past events"
    echo ""
    
    read -p "Press Enter when you've cleared the data..."
    
    echo ""
    echo -e "${GREEN}✅ Ready for testing!${NC}"
    echo ""
    echo "Run test with current batch:"
    echo "  node instagram-scraper-rotated.js"
    echo ""
    echo "Or test specific batch:"
    echo "  node test-5-accounts.js"
    
else
    echo -e "${RED}Cancelled - no data was cleared${NC}"
fi