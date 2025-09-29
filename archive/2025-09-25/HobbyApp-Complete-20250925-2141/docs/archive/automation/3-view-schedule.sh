#!/bin/bash
# View Current Automation Schedule

echo "📅 Instagram Scraper Schedule"
echo "=============================="
echo ""

# Check if automation is enabled
if crontab -l 2>/dev/null | grep -q "run-scraper-with-env"; then
    echo "✅ Automation is ACTIVE"
    echo ""
    echo "Current Schedule:"
    echo "-----------------"
    echo "⏰ 10:00 AM Daily - All accounts (60 total)"
    echo ""
    
    echo "Next Scheduled Run:"
    echo "-------------------"
    HOUR=$(date +%H)
    if [ $HOUR -lt 10 ]; then
        echo "• Today at 10:00 AM (in $((10-HOUR)) hours)"
    else
        echo "• Tomorrow at 10:00 AM"
    fi
    
    echo ""
    echo "Processing Details:"
    echo "-------------------"
    echo "• Accounts: 60 total"
    echo "• Categories: Fitness, Arts, Culinary, Wellness, Photography"
    echo "• Duration: ~15-20 minutes"
    echo "• Rate limiting: Built-in delays"
else
    echo "❌ Automation is NOT active"
    echo ""
    echo "Run ./5-enable-automation.sh to start"
fi

echo ""
echo "Last run logs: tail -20 ~/HobbyistSwiftUI/scraper.log"