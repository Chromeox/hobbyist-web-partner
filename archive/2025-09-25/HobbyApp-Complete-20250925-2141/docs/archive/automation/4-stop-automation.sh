#!/bin/bash
# Stop Automation (Emergency Stop)

echo "🛑 Stopping Instagram Scraper Automation"
echo "========================================"
echo ""

# Backup current crontab
crontab -l > ~/HobbyistSwiftUI/crontab_backup_$(date +%Y%m%d_%H%M%S).txt 2>/dev/null

# Remove scraper jobs
crontab -l | grep -v 'instagram-scraper' | crontab -

echo "✅ Automation stopped"
echo ""
echo "Your crontab has been backed up to:"
echo "~/HobbyistSwiftUI/crontab_backup_*.txt"
echo ""
echo "To re-enable, run: ./5-enable-automation.sh"