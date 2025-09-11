#!/bin/bash
# Monitor Scraper Activity in Real-Time

echo "📊 Live Instagram Scraper Monitor"
echo "================================="
echo "Press Ctrl+C to exit"
echo ""
echo "Watching for activity..."
echo ""

# Color-coded monitoring
tail -f ~/HobbyistSwiftUI/scraper.log | while read line; do
    if [[ $line == *"✅"* ]]; then
        echo -e "\033[0;32m$line\033[0m"  # Green for success
    elif [[ $line == *"❌"* ]]; then
        echo -e "\033[0;31m$line\033[0m"  # Red for errors
    elif [[ $line == *"📊"* ]] || [[ $line == *"📸"* ]]; then
        echo -e "\033[0;34m$line\033[0m"  # Blue for info
    elif [[ $line == *"⚠️"* ]]; then
        echo -e "\033[1;33m$line\033[0m"  # Yellow for warnings
    else
        echo "$line"
    fi
done