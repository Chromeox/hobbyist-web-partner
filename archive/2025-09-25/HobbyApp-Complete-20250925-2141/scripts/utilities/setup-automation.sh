#!/bin/bash

# Instagram Scraper Automation Setup
# Sets up cron jobs for automatic scraping 3x daily

echo "🤖 Instagram Scraper Automation Setup"
echo "====================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get current directory
SCRIPT_DIR="$HOME/HobbyistSwiftUI"

echo -e "${BLUE}Current Configuration:${NC}"
echo "• Directory: $SCRIPT_DIR"
echo "• Schedule: 6 AM, 2 PM, 6 PM daily"
echo "• Rotation: 20 accounts per batch (60 total)"
echo "• Log file: $SCRIPT_DIR/scraper.log"
echo ""

# Create log file if it doesn't exist
touch "$SCRIPT_DIR/scraper.log"

# Backup existing crontab
echo -e "${YELLOW}Backing up existing crontab...${NC}"
crontab -l > "$SCRIPT_DIR/crontab_backup_$(date +%Y%m%d_%H%M%S).txt" 2>/dev/null

# Check if cron jobs already exist
if crontab -l 2>/dev/null | grep -q "instagram-scraper-rotated.js"; then
    echo -e "${YELLOW}⚠️  Automation already exists!${NC}"
    echo ""
    echo "Current schedule:"
    crontab -l | grep "instagram-scraper"
    echo ""
    read -p "Do you want to update the schedule? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing schedule."
        exit 0
    fi
    # Remove old entries
    crontab -l | grep -v "instagram-scraper" | crontab -
fi

# Add new cron jobs
echo -e "${GREEN}Adding automation schedule...${NC}"

# Create the cron entries
CRON_JOBS="# Instagram Scraper Automation (added $(date))
# Morning batch (6 AM) - Run clubs & fitness
0 6 * * * cd $SCRIPT_DIR && /usr/local/bin/node instagram-scraper-rotated.js >> scraper.log 2>&1

# Afternoon batch (2 PM) - Arts & crafts
0 14 * * * cd $SCRIPT_DIR && /usr/local/bin/node instagram-scraper-rotated.js >> scraper.log 2>&1

# Evening batch (6 PM) - Culinary & wellness
0 18 * * * cd $SCRIPT_DIR && /usr/local/bin/node instagram-scraper-rotated.js >> scraper.log 2>&1

# Daily summary email (optional - uncomment to enable)
# 0 20 * * * cd $SCRIPT_DIR && /usr/local/bin/node send-daily-summary.js >> scraper.log 2>&1"

# Add to crontab
(crontab -l 2>/dev/null; echo "$CRON_JOBS") | crontab -

echo -e "${GREEN}✅ Automation successfully configured!${NC}"
echo ""
echo -e "${BLUE}📅 Schedule Summary:${NC}"
echo "• 6:00 AM - Morning batch (run clubs, fitness)"
echo "• 2:00 PM - Afternoon batch (arts, crafts, photography)"
echo "• 6:00 PM - Evening batch (culinary, wellness)"
echo ""
echo -e "${BLUE}📊 Next runs:${NC}"

# Calculate next run times
CURRENT_HOUR=$(date +%H)
if [ $CURRENT_HOUR -lt 6 ]; then
    echo "• Next: 6:00 AM today (Morning batch)"
elif [ $CURRENT_HOUR -lt 14 ]; then
    echo "• Next: 2:00 PM today (Afternoon batch)"
elif [ $CURRENT_HOUR -lt 18 ]; then
    echo "• Next: 6:00 PM today (Evening batch)"
else
    echo "• Next: 6:00 AM tomorrow (Morning batch)"
fi

echo ""
echo -e "${BLUE}📝 Useful Commands:${NC}"
echo "• View schedule:     crontab -l"
echo "• Edit schedule:     crontab -e"
echo "• View logs:         tail -f $SCRIPT_DIR/scraper.log"
echo "• Stop automation:   crontab -l | grep -v 'instagram-scraper' | crontab -"
echo "• Test now:          cd $SCRIPT_DIR && node instagram-scraper-rotated.js"
echo ""

# Create monitoring script
cat > "$SCRIPT_DIR/monitor-scraper.sh" << 'EOF'
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
EOF

chmod +x "$SCRIPT_DIR/monitor-scraper.sh"

echo -e "${GREEN}✅ Monitor script created: ./monitor-scraper.sh${NC}"
echo ""

# Test notification
echo -e "${YELLOW}Testing setup...${NC}"
echo "[$(date)] Automation setup completed" >> "$SCRIPT_DIR/scraper.log"

if [ -f "$SCRIPT_DIR/scraper.log" ]; then
    echo -e "${GREEN}✅ Log file working${NC}"
else
    echo -e "${RED}❌ Log file creation failed${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Your Instagram scraper will now run automatically 3 times daily."
echo "Events will be sent to your Google Sheet and ready for Airtable sync."
echo ""
echo "To monitor in real-time: ./monitor-scraper.sh"