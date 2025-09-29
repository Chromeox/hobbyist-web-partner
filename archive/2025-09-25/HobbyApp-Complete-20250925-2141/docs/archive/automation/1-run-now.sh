#!/bin/bash
# Run Instagram Scraper Immediately

echo "🚀 Running Instagram Scraper NOW"
echo "================================"
cd ~/HobbyistSwiftUI

# Show current batch
HOUR=$(date +%H)
if [ $HOUR -ge 6 ] && [ $HOUR -lt 14 ]; then
    echo "Running MORNING batch (run clubs & fitness)"
elif [ $HOUR -ge 14 ] && [ $HOUR -lt 18 ]; then
    echo "Running AFTERNOON batch (arts & crafts)"
else
    echo "Running EVENING batch (culinary & wellness)"
fi

echo ""
node ../instagram/instagram-scraper-rotated.js

echo ""
echo "✅ Scraping complete!"
echo "View results: https://docs.google.com/spreadsheets/d/14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w"