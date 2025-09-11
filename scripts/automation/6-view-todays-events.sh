#!/bin/bash
# View Today's Scraped Events

echo "📊 Today's Instagram Scraping Activity"
echo "======================================"
echo ""

TODAY=$(date +%Y-%m-%d)
LOG_FILE=~/HobbyistSwiftUI/scraper.log

if [ -f "$LOG_FILE" ]; then
    echo "Date: $TODAY"
    echo ""
    
    # Count events
    EVENTS=$(grep "$TODAY" "$LOG_FILE" | grep -c "✅ Event sent")
    ERRORS=$(grep "$TODAY" "$LOG_FILE" | grep -c "❌")
    ACCOUNTS=$(grep "$TODAY" "$LOG_FILE" | grep -c "📸 Scraping")
    
    echo "📈 Statistics:"
    echo "• Accounts scraped: $ACCOUNTS"
    echo "• Events found: $EVENTS"
    echo "• Errors: $ERRORS"
    echo ""
    
    echo "Recent Events:"
    echo "--------------"
    grep "$TODAY" "$LOG_FILE" | grep "✅ Event sent" | tail -5
    
    if [ $ERRORS -gt 0 ]; then
        echo ""
        echo "⚠️  Recent Errors:"
        echo "-----------------"
        grep "$TODAY" "$LOG_FILE" | grep "❌" | tail -3
    fi
else
    echo "No log file found"
fi

echo ""
echo "View full logs: tail -50 ~/HobbyistSwiftUI/scraper.log"
echo "View Google Sheet: https://docs.google.com/spreadsheets/d/14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w"