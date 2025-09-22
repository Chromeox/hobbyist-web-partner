# 🎯 Hobby Directory Automation Control Center

## Quick Start
All scripts are numbered in order of common use:
1. **Run scraper now** - `./1-run-now.sh`
2. **Monitor live activity** - `./2-monitor-live.sh`
3. **View schedule** - `./3-view-schedule.sh`
4. **Stop automation** - `./4-stop-automation.sh`
5. **Enable automation** - `./5-enable-automation.sh`
6. **View today's events** - `./6-view-todays-events.sh`
7. **Clear Google Sheet** - `./7-clear-google-sheet.sh`
8. **Export to CSV** - `./8-export-to-csv.sh`

---

## 📊 Current Pipeline Status

```
Instagram (60 accounts) 
    ↓ [Automated 3x daily]
Google Sheets 
    ↓ [Manual CSV export]
Airtable 
    ↓ [WhaleSync - needs setup]
Webflow
```

### ✅ What's Working
- Instagram scraping (3x daily automated)
- Google Sheets data collection
- 60 accounts in rotation (20 per batch)

### 🔄 Next Steps
1. Configure WhaleSync connection
2. Set up Webflow CMS structure
3. Enable auto-sync

---

## 🚀 Daily Operations

### Single Daily Run (10:00 AM)
- Scraper runs automatically once per day
- Processes all 60 accounts in one batch
- Categories: Fitness, Arts, Culinary, Wellness, Photography
- Duration: ~15-20 minutes
- Check results: `./6-view-todays-events.sh`

### Why Single Daily Run?
- Events have multi-day/week lead times
- Reduces Instagram rate limiting risk by 66%
- More efficient server resource usage
- Easier to monitor and troubleshoot

### Weekly Maintenance (Fridays)
1. Clear old events: `./7-clear-google-sheet.sh`
2. Export to Airtable: `./8-export-to-csv.sh`
3. Check for issues: `tail -100 ~/HobbyistSwiftUI/scraper.log | grep "❌"`

---

## 🔧 Troubleshooting

### If scraper stops working:
```bash
# Check if it's running
./3-view-schedule.sh

# View recent errors
tail -50 ~/HobbyistSwiftUI/scraper.log | grep "❌"

# Restart automation
./4-stop-automation.sh
./5-enable-automation.sh
```

### If Instagram blocks access:
1. Clear browser session: `rm ~/HobbyistSwiftUI/.instagram-session.json`
2. Run manual test: `./1-run-now.sh`
3. Re-enter credentials when prompted

### If Google Sheets fills up:
1. Run: `./7-clear-google-sheet.sh`
2. Choose "Clear Old Events"
3. Export recent data first if needed

---

## 📈 Performance Metrics

### Expected Daily Results
- **Accounts checked**: 60 (all at once)
- **Events found**: 5-15 (varies by day)
- **Success rate**: 80-90%
- **Processing time**: 15-20 minutes total

### Rate Limits
- Instagram: 200 actions/hour (we use ~60)
- Google Sheets API: 100 requests/minute (we use ~20)
- Safe buffer maintained

---

## 🌐 Webflow Preparation

### CMS Collection Structure Needed
Create a CMS collection called "Events" with these fields:

| Field Name | Type | Required | Maps From |
|------------|------|----------|-----------|
| Name | Text | Yes | name |
| Slug | Slug | Yes | slug |
| Studio | Text | Yes | studio |
| Location | Text | Yes | location |
| Address | Text | Yes | address |
| Event Date | Date | Yes | Event Date |
| Time | Text | Yes | Time |
| Price | Text | Yes | price |
| Description | Rich Text | Yes | Description |
| Image | Image | No | Image URL |
| Book Link | Link | No | Book Link |
| Tags | Multi-reference | No | Tags |
| Featured | Switch | No | - |
| Status | Option | Yes | Webflow status |

### WhaleSync Configuration
1. **Source**: Airtable (your Events table)
2. **Destination**: Webflow (Events collection)
3. **Sync direction**: One-way (Airtable → Webflow)
4. **Sync frequency**: Every 5 minutes
5. **Field mapping**: Match names above

### Webflow Template Pages
1. **Events List** (`/events`)
   - Filter by date, category, price
   - Search functionality
   - Map view option

2. **Event Detail** (`/events/[slug]`)
   - Full description
   - Booking button
   - Related events

3. **Today's Events** (`/events/today`)
   - Auto-filter current date
   - Highlight urgent

4. **Categories** (`/events/[category]`)
   - Fitness, Arts, Culinary, etc.

---

## 📞 Support & Issues

### Logs Location
- Scraper log: `~/HobbyistSwiftUI/scraper.log`
- Cron errors: `/var/mail/$(whoami)`

### Key Files
- Config: `~/HobbyistSwiftUI/instagram-accounts-config.js`
- Scraper: `~/HobbyistSwiftUI/instagram-scraper-rotated.js`
- Credentials: `~/HobbyistSwiftUI/.env.instagram`

### Manual Controls
- Force run: `cd ~/HobbyistSwiftUI && node instagram-scraper-rotated.js`
- Test 5 accounts: `node test-5-accounts.js`
- Simple scraper: `node simple-instagram-scraper.js`

---

## 🎯 Success Metrics

Track these weekly:
- [ ] Events scraped: Target 50+/week
- [ ] Unique studios: Target 20+/week  
- [ ] Data quality: 90%+ complete fields
- [ ] Automation uptime: 95%+
- [ ] Webflow sync: All events visible

---

*Last Updated: September 2025*
*Version: 1.0*