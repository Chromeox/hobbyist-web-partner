#!/bin/bash
# Monitor scraper logs in real-time
echo "📊 Instagram Scraper Monitor"
echo "============================"
echo "Press Ctrl+C to exit"
echo ""
tail -f ~/HobbyistSwiftUI/scraper.log | while read line; do
    if [[ $line == *"✅"* ]]; then
        echo -e "\033[0;32m$line\033[0m"
    elif [[ $line == *"❌"* ]]; then
        echo -e "\033[0;31m$line\033[0m"
    elif [[ $line == *"📊"* ]]; then
        echo -e "\033[0;34m$line\033[0m"
    else
        echo "$line"
    fi
done
