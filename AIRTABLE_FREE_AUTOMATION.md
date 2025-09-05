# 🆓 Airtable Automation WITHOUT API (Free Plan Workaround)

## The Challenge
Airtable's free plan doesn't include API access, but we can still automate using:
- Airtable Forms (unlimited on free plan)
- Email notifications (native automations)
- CSV imports (manual or automated via Playwright)
- Zapier free tier (100 tasks/month)
- Make.com free tier (1000 operations/month)

---

## 🎯 Solution 1: Playwright + CSV Upload Automation

### How it Works
1. Playwright scrapes data from Instagram/websites
2. Generates CSV file with all event data
3. Playwright automates the Airtable CSV import process
4. Native Airtable automations handle the rest

### Playwright Airtable Uploader
Save as `~/HobbyistSwiftUI/scrapers/airtable-csv-uploader.js`:

```javascript
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

class AirtableAutomation {
  constructor() {
    this.browser = null;
    this.page = null;
  }

  async init() {
    this.browser = await chromium.launch({ 
      headless: false, // Must be false for file uploads
      slowMo: 100 // Slow down for stability
    });
    this.page = await this.browser.newPage();
  }

  async login(email, password) {
    await this.page.goto('https://airtable.com/login');
    await this.page.fill('input[name="email"]', email);
    await this.page.click('button:text("Continue")');
    await this.page.fill('input[name="password"]', password);
    await this.page.click('button:text("Sign in")');
    await this.page.waitForURL('**/workspace/**');
    console.log('✅ Logged into Airtable');
  }

  async uploadCSV(baseId, tableName, csvPath) {
    // Navigate to your base
    await this.page.goto(`https://airtable.com/${baseId}`);
    
    // Click on the target table
    await this.page.click(`text="${tableName}"`);
    await this.page.waitForTimeout(1000);
    
    // Open import menu
    await this.page.click('button:has-text("Add records")');
    await this.page.click('text="Import CSV"');
    
    // Upload file
    const fileInput = await this.page.locator('input[type="file"]');
    await fileInput.setInputFiles(csvPath);
    
    // Configure import settings
    await this.page.click('button:text("Next")');
    
    // Map fields (customize based on your schema)
    // Airtable usually auto-maps if column names match
    await this.page.click('button:text("Import")');
    
    // Wait for import to complete
    await this.page.waitForSelector('text="Import complete"', { timeout: 30000 });
    console.log('✅ CSV imported successfully');
  }

  async createFormSubmission(formUrl, data) {
    // Alternative: Submit via Airtable form
    await this.page.goto(formUrl);
    
    // Fill form fields
    for (const [field, value] of Object.entries(data)) {
      const input = await this.page.locator(`[aria-label*="${field}"]`);
      await input.fill(value);
    }
    
    await this.page.click('button:text("Submit")');
    await this.page.waitForSelector('text="Success"');
    console.log('✅ Form submitted');
  }

  async close() {
    await this.browser.close();
  }
}

// Instagram Scraper + CSV Generator
async function scrapeAndGenerateCSV() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  const events = [];
  const accounts = ['@rumbleboxingmp', '@claymates.studio'];
  
  for (const account of accounts) {
    const username = account.replace('@', '');
    await page.goto(`https://www.instagram.com/${username}/`);
    await page.waitForLoadState('networkidle');
    
    // Extract posts
    const posts = await page.evaluate(() => {
      const postElements = document.querySelectorAll('article a[href*="/p/"]');
      return Array.from(postElements).slice(0, 3).map(post => ({
        url: post.href,
        imageUrl: post.querySelector('img')?.src,
        caption: post.querySelector('img')?.alt
      }));
    });
    
    // Parse event details from captions (customize this logic)
    posts.forEach(post => {
      events.push({
        name: `Event from ${username}`,
        description_original: post.caption,
        instagram_handle: account,
        instagram_url: post.url,
        image_url: post.imageUrl,
        status: 'Scraped',
        scraped_at: new Date().toISOString()
      });
    });
  }
  
  await browser.close();
  
  // Generate CSV
  const csv = [
    Object.keys(events[0]).join(','),
    ...events.map(e => Object.values(e).map(v => `"${v}"`).join(','))
  ].join('\n');
  
  const csvPath = path.join(__dirname, `events_${Date.now()}.csv`);
  fs.writeFileSync(csvPath, csv);
  
  console.log(`✅ Generated CSV with ${events.length} events`);
  return csvPath;
}

// Main automation flow
async function runDailyAutomation() {
  // 1. Scrape and generate CSV
  const csvPath = await scrapeAndGenerateCSV();
  
  // 2. Upload to Airtable
  const automation = new AirtableAutomation();
  await automation.init();
  
  await automation.login(
    process.env.AIRTABLE_EMAIL,
    process.env.AIRTABLE_PASSWORD
  );
  
  await automation.uploadCSV(
    'appXXXXXXXXXXXXXX', // Your base ID
    'Events Staging',     // Your table name
    csvPath
  );
  
  await automation.close();
  
  // 3. Clean up
  fs.unlinkSync(csvPath);
  console.log('✅ Daily automation complete');
}

// Run the automation
if (require.main === module) {
  runDailyAutomation().catch(console.error);
}

module.exports = { runDailyAutomation, scrapeAndGenerateCSV };
```

---

## 🎯 Solution 2: Google Sheets as Data Hub

### Architecture
```
Instagram/Web → Playwright → Google Sheets → Manual CSV Export → Airtable
                     ↓
              Google Forms → Direct to Airtable (via Zapier free)
```

### Google Sheets Script
```javascript
// Google Apps Script (paste in Extensions → Apps Script)
function setupHobbyDirectory() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  // Create sheets if they don't exist
  const sheets = ['Events', 'Instagram_Data', 'Review_Queue', 'Published'];
  sheets.forEach(name => {
    if (!ss.getSheetByName(name)) {
      ss.insertSheet(name);
    }
  });
  
  // Set up headers
  const eventsSheet = ss.getSheetByName('Events');
  eventsSheet.getRange('A1:L1').setValues([[
    'Name', 'Date', 'Time', 'Venue', 'Description_Original',
    'Description_Rewritten', 'Instagram', 'Website', 'Image',
    'Status', 'Scraped_At', 'Notes'
  ]]);
  
  // Create import formulas for web scraping
  const formulas = eventsSheet.getRange('M2:P2');
  formulas.setFormulas([[
    '=IFERROR(IMPORTXML(H2,"//title"),"N/A")',
    '=IFERROR(IMPORTXML(H2,"//meta[@name=\'description\']/@content"),"N/A")',
    '=IFERROR(IMPORTXML(H2,"//meta[@property=\'og:image\']/@content"),"N/A")',
    '=IFERROR(LEN(E2),0)'
  ]]);
}

// Auto-process new events every hour
function processEvents() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events');
  const data = sheet.getDataRange().getValues();
  
  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const status = row[9]; // Status column
    
    if (status === 'Scraped') {
      // Send to OpenAI for rewriting (via webhook)
      const rewritten = rewriteWithAI(row[4]); // Description_Original
      sheet.getRange(i + 1, 6).setValue(rewritten);
      sheet.getRange(i + 1, 10).setValue('Pending Review');
    }
  }
}

function rewriteWithAI(text) {
  // Call your webhook or API
  const response = UrlFetchApp.fetch('YOUR_WEBHOOK_URL', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    payload: JSON.stringify({ text: text })
  });
  
  return JSON.parse(response.getContentText()).rewritten;
}

// Export ready events as CSV
function exportToCSV() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Events');
  const data = sheet.getDataRange().getValues();
  
  // Filter approved events
  const approved = data.filter(row => row[9] === 'Approved');
  
  // Create CSV
  const csv = approved.map(row => row.join(',')).join('\n');
  
  // Save to Drive
  const blob = Utilities.newBlob(csv, 'text/csv', `events_${new Date().toISOString()}.csv`);
  DriveApp.createFile(blob);
  
  // Email notification
  MailApp.sendEmail({
    to: Session.getActiveUser().getEmail(),
    subject: 'Events ready for Airtable import',
    body: `${approved.length} events ready. CSV attached.`,
    attachments: [blob]
  });
}
```

---

## 🎯 Solution 3: Airtable Forms + Email Automation

### Setup
1. Create Airtable form for your "Events Staging" table
2. Get the form URL (Share → Create form)
3. Use Playwright to submit data via form

### Form Submitter Script
```javascript
async function submitToAirtableForm(eventData) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Your Airtable form URL
  const formUrl = 'https://airtable.com/shrXXXXXXXXXXXXXX';
  
  await page.goto(formUrl);
  
  // Fill form fields (inspect form to get exact selectors)
  await page.fill('[name="fldXXXXXX"]', eventData.name);
  await page.fill('[name="fldYYYYYY"]', eventData.description);
  await page.fill('[name="fldZZZZZZ"]', eventData.venue);
  
  // Submit
  await page.click('button[type="submit"]');
  await page.waitForSelector('text="Success"');
  
  await browser.close();
  console.log('✅ Submitted to Airtable form');
}
```

---

## 🎯 Solution 4: Zapier/Make.com Free Tier

### Zapier Setup (100 tasks/month free)
1. **Trigger**: New row in Google Sheets
2. **Action**: Create record in Airtable
3. **Filter**: Only if status = "Approved"

### Make.com Setup (1000 ops/month free)
1. **Webhook trigger**: Receive scraped data
2. **OpenAI module**: Rewrite description
3. **Airtable module**: Create record
4. **Email module**: Daily digest at 7:30am

---

## 🚀 Recommended Free Stack

### Best Approach for Free Plan:
```
1. Playwright scrapes → Google Sheets (unlimited, free)
2. Google Sheets IMPORTXML for additional data
3. Apps Script processes and rewrites content
4. Manual CSV export → Import to Airtable (weekly)
5. Native Airtable automations for internal workflows
6. WhaleSync free tier (100 syncs/month) → Webflow
```

### Daily Workflow:
- **Morning**: Run Playwright scraper → Google Sheets
- **Midday**: Review in Sheets, mark approved
- **Evening**: Export CSV, import to Airtable
- **Automatic**: WhaleSync pushes to Webflow

---

## 📊 Comparison Table

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| CSV Upload | Full control, unlimited | Manual step required | Daily batch updates |
| Google Sheets Hub | Free, powerful formulas | Extra step to Airtable | Data processing |
| Form Submission | Real-time, simple | One record at a time | Live events |
| Zapier/Make | Automated, reliable | Limited free tasks | Critical automations |

---

## 🎬 Quick Start (Recommended)

1. **Set up Google Sheets** as your data hub
2. **Run this Playwright script** to populate it:
   ```bash
   node ~/HobbyistSwiftUI/scrapers/sheets-scraper.js
   ```
3. **Review data** in Sheets (share with team)
4. **Weekly export** to Airtable via CSV
5. **WhaleSync** pushes approved events to Webflow

This gives you 90% automation without paying for Airtable's API!

---

*Note: When you upgrade to Airtable paid plan ($20/month), you can switch to full API automation.*