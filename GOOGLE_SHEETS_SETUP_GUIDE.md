# 📊 Google Sheets Data Hub Setup Guide

## Quick Start (10 minutes)

### Step 1: Create Your Google Sheet
1. Go to [sheets.google.com](https://sheets.google.com)
2. Create new spreadsheet: **"Hobby Directory Data Hub"**
3. Copy the spreadsheet ID from the URL:
   - URL: `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID_HERE/edit`
   - Copy the ID between `/d/` and `/edit`

### Step 2: Install the Apps Script
1. In your sheet, go to **Extensions → Apps Script**
2. Delete the default code
3. Copy ALL content from `sheets-setup.js`
4. Paste into Apps Script editor
5. Click **Save** (💾 icon)
6. Click **Run** → Select `setupHobbyDirectory`
7. Grant permissions when prompted
8. You'll see "✅ Hobby Directory setup complete!"

### Step 3: Verify Setup
Your sheet should now have these tabs:
- ✅ Events Staging (main data)
- ✅ Instagram Queue
- ✅ Website Queue
- ✅ Review Queue
- ✅ Published
- ✅ Settings
- ✅ Error Log

Plus a custom menu: **🎯 Hobby Directory**

---

## 🔌 Connect Playwright Scraper

### Option A: Simple Web Apps Script (No API Key Needed!)
1. In Apps Script, click **Deploy** → **New Deployment**
2. Type: **Web app**
3. Execute as: **Me**
4. Who has access: **Anyone** (or "Anyone with Google Account")
5. Click **Deploy**
6. Copy the Web App URL (save this!)

Now Playwright can POST data directly to this URL:

```javascript
// In your Playwright script
const response = await fetch('YOUR_WEB_APP_URL', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'Pottery Class',
    date: '2024-01-15',
    venue: 'Claymates Studio',
    // ... other fields
  })
});
```

### Option B: Google Sheets API (More Complex)
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project or select existing
3. Enable Google Sheets API
4. Create Service Account credentials
5. Download JSON key file
6. Share your sheet with the service account email

---

## 📝 Using the Sheet

### Daily Workflow

#### Morning (Automated)
- 7:30 AM: Review email sent automatically
- Contains all pending events
- Click links to approve/reject

#### Manual Actions via Menu
- **📥 Import Instagram Data**: Add Instagram handles to scrape
- **🌐 Scrape Websites**: Run IMPORTXML formulas
- **🤖 Rewrite Descriptions**: Process with AI (mock function included)
- **✅ Approve Selected**: Mark events as approved
- **📤 Export to CSV**: Generate CSV for Airtable import

### IMPORTXML Magic (Built-in Web Scraping!)
The Website Queue sheet includes these formulas:
```
=IMPORTXML(B2,"//title")                                    # Page title
=IMPORTXML(B2,"//meta[@name='description']/@content")       # Meta description  
=IMPORTXML(B2,"//meta[@property='og:image']/@content")      # Social image
```

These run automatically when you add URLs!

---

## 🚀 Test the System

### 1. Test Manual Entry
1. Go to **Events Staging** sheet
2. Add a test row:
   - Name: "Test Pottery Class"
   - Date: "2024-01-20"
   - Venue: "Claymates Studio"
   - Status: "Scraped"
3. Run **🎯 Hobby Directory → Rewrite Descriptions**
4. Check that Description_Rewritten was filled

### 2. Test Web Scraping
1. Go to **Website Queue** sheet
2. Add a URL in column B: `https://www.claymatesceramicsstudio.com`
3. Wait 5 seconds for IMPORTXML
4. Run **🎯 Hobby Directory → Scrape Websites**
5. Check columns D-F for scraped data

### 3. Test Review Email
1. Add a few test events with status "Pending Review"
2. Run **🎯 Hobby Directory → Send Review Email**
3. Check your email for the review digest

---

## 🔧 Configuration (Settings Sheet)

Customize these values:
- **Review_Time**: When to send daily email (24hr format)
- **Review_Email**: Where to send reviews
- **Target_Accounts**: Instagram accounts to scrape
- **Webhook_URL**: Your AI rewriting endpoint (optional)

---

## 📊 Data Flow

```
Instagram/Websites
       ↓
Playwright Scraper
       ↓
Google Sheets (via Web App or API)
       ↓
AI Rewriting (Apps Script)
       ↓
Daily Review Email (7:30 AM)
       ↓
Manual Approval
       ↓
Export CSV
       ↓
Import to Airtable
       ↓
WhaleSync → Webflow
```

---

## 🎯 Next Steps

1. **Set up Playwright scraper**:
   ```bash
   cd ~/HobbyistSwiftUI
   npm install playwright googleapis dotenv
   node playwright-to-sheets.js
   ```

2. **Schedule daily runs**:
   - Use cron (Mac/Linux) or Task Scheduler (Windows)
   - Or deploy to cloud (Heroku, Google Cloud Functions)

3. **Connect to Airtable**:
   - Export approved events as CSV
   - Import to Airtable (can be automated with Playwright!)
   - WhaleSync picks up from there

---

## 💡 Pro Tips

1. **Bulk Operations**: Select multiple rows and use menu actions
2. **Filters**: Create filter views for different statuses
3. **Conditional Formatting**: Already set up for visual status tracking
4. **Version History**: Sheets auto-saves all changes with history
5. **Collaboration**: Share with team for review/approval
6. **Mobile**: Use Google Sheets app for on-the-go reviews

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| "You do not have permission" | Re-run setup and grant all permissions |
| IMPORTXML returns error | Check if website blocks scrapers, try different formula |
| Email not sending | Check Settings sheet for correct email |
| Triggers not working | Go to Apps Script → Triggers → Add manually |
| Web App returns 404 | Redeploy and get new URL |

---

*This setup gives you 90% of Airtable's functionality for FREE, plus built-in web scraping!*