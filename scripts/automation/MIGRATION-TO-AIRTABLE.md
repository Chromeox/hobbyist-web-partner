# 🚀 Migration Guide: Google Sheets → Direct Airtable

This guide helps you eliminate Google Sheets complexity and implement the recommended architecture from your directory documentation.

## Current vs. New Architecture

### ❌ Current (Complex)
```
Instagram Scraper
    ↓
Google Sheets (staging)
    ↓ [MANUAL CSV EXPORT]
Airtable
    ↓ [WhaleSync]
Webflow
```

### ✅ New (Simplified)
```
Instagram Scraper
    ↓ [Direct API]
Airtable
    ↓ [WhaleSync - unchanged]
Webflow
```

## Benefits

- **Eliminates Google Sheets** - One less tool to manage
- **No manual CSV exports** - Fully automated pipeline
- **Faster processing** - Direct API calls vs. file exports
- **Better reliability** - Fewer failure points
- **Matches documentation** - Aligns with your directory guide
- **Cost savings** - No Google Sheets subscription needed

## Migration Steps

### 1. Setup Airtable API Access

1. **Get Personal Access Token:**
   - Go to https://airtable.com/create/tokens
   - Create new token with permissions:
     - `data.records:read`
     - `data.records:write`
   - Select your Events base as scope

2. **Get Base ID:**
   - Go to https://airtable.com/api
   - Select your base
   - Copy Base ID (starts with `app`)

### 2. Install and Configure

```bash
# Run the setup script
./scripts/automation/setup-airtable-integration.sh

# Configure environment
cp scripts/automation/env.airtable.template scripts/automation/.env.airtable

# Edit with your credentials
nano scripts/automation/.env.airtable
```

### 3. Test Integration

```bash
cd scripts/automation
node airtable-direct-scraper.js
```

Expected output:
```
✅ Airtable connected
📸 Scraping Instagram: @rumbleboxingmp
✅ Added batch of 3 records to Airtable
📊 Total events added: 5
```

### 4. Update Automation

#### Replace in Cron Jobs
```bash
# Old cron job
0 10 * * * cd ~/HobbyistSwiftUI && node instagram-scraper-rotated.js

# New cron job  
0 10 * * * cd ~/HobbyistSwiftUI/scripts/automation && node airtable-direct-scraper.js
```

#### Update Your Scripts
```bash
# Edit your automation scripts to use:
scripts/automation/airtable-direct-scraper.js

# Instead of:
scripts/automation/playwright-to-sheets.js
```

### 5. Verify WhaleSync

1. Check that WhaleSync continues syncing from Airtable to Webflow
2. Verify new events appear on your website
3. Test field mappings are working correctly

## Field Mapping

The new scraper creates these Airtable fields:

| Field | Type | Description |
|-------|------|-------------|
| `name` | Text | Event title |
| `Event Date` | Date | Event date |
| `Time` | Text | Event time |
| `price` | Text | Event price |
| `Description` | Long Text | Event description |
| `location` | Text | Venue name |
| `address` | Text | Venue address |
| `studio` | Text | Studio/organizer name |
| `instagram_url` | URL | Instagram post URL |
| `Image_URL` | URL | Event image |
| `Instagram_Handle` | Text | Account handle |
| `Status` | Text | Processing status |
| `Scraped_At` | Date | When scraped |

## Troubleshooting

### Rate Limits
- Airtable: 5 requests/second per base
- Script automatically handles rate limiting
- Uses batch operations (10 records max)

### Authentication Errors
```
❌ Error: Missing AIRTABLE_TOKEN
```
**Solution:** Check your `.env.airtable` file has correct token

### Field Mapping Issues
```
❌ Error: Field 'Event Date' not found
```
**Solution:** Ensure your Airtable table has matching field names

### Duplicate Detection
The script prevents duplicates by checking:
- Event name + date + studio combination
- Configurable in `isDuplicate()` method

## Cleanup (After Testing)

Once you verify everything works:

1. **Remove Google Sheets integration:**
   ```bash
   # Archive old scripts
   mkdir scripts/automation/archive
   mv scripts/automation/playwright-to-sheets.js scripts/automation/archive/
   mv scripts/automation/sheet-management.js scripts/automation/archive/
   ```

2. **Update documentation:**
   - Update README.md with new process
   - Remove Google Sheets references

3. **Cancel subscriptions:**
   - Google Workspace (if only used for Sheets)
   - Any Google Sheets-specific tools

## Support

If you encounter issues:

1. Check the log files: `airtable_results_*.json`
2. Verify Airtable permissions and base access
3. Test with a small batch first
4. Ensure WhaleSync field mappings match new structure

## Next Steps

After successful migration, consider:

1. **Enhanced automation:** Add more Instagram accounts
2. **Data enrichment:** Use Airtable formulas for categories
3. **Monitoring:** Set up alerts for failed scrapes
4. **Optimization:** Fine-tune event detection keywords

---

**Result:** You'll have a simpler, more reliable automation pipeline that matches industry best practices! 🎉