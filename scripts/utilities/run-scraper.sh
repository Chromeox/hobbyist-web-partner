#!/bin/bash
# Hobby Directory Scraper Runner

cd ~/HobbyistSwiftUI

# Log the start time
echo "$(date): Starting Instagram scraper" >> ~/HobbyistSwiftUI/scraper.log

# Run the scraper
/usr/local/bin/node ../instagram/intelligent-instagram-scraper.js >> ~/HobbyistSwiftUI/scraper.log 2>&1

# Log completion
echo "$(date): Scraper completed" >> ~/HobbyistSwiftUI/scraper.log
echo "---" >> ~/HobbyistSwiftUI/scraper.log
