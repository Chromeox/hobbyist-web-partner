#!/bin/bash
# Enable/Re-enable Automation

echo "✅ Enabling Instagram Scraper Automation"
echo "========================================"
echo ""

# Check if already enabled
if crontab -l 2>/dev/null | grep -q "run-scraper-with-env"; then
    echo "⚠️  Automation is already active!"
    echo ""
    ./3-view-schedule.sh
    exit 0
fi

# Add automation
CRON_JOBS="# Hobby Directory Instagram Scraping - Daily at 10 AM
0 10 * * * /Users/chromefang.exe/HobbyistSwiftUI/run-scraper-with-env.sh"

(crontab -l 2>/dev/null; echo "$CRON_JOBS") | crontab -

echo "✅ Automation enabled!"
echo ""
echo "Schedule: Daily at 10:00 AM"
echo "Processing: All 60 accounts in single run"
echo ""
./3-view-schedule.sh