#!/bin/bash
# Wrapper script for cron to run with proper environment

# Set up Node.js environment
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export NODE_PATH="/usr/local/lib/node_modules"

# Set Playwright browser path
export PLAYWRIGHT_BROWSERS_PATH="/Users/chromefang.exe/Library/Caches/ms-playwright"

# Navigate to project directory
cd /Users/chromefang.exe/HobbyistSwiftUI

# Run the scraper with full node path
/usr/local/bin/node scripts/instagram/instagram-scraper-rotated.js >> scraper.log 2>&1
