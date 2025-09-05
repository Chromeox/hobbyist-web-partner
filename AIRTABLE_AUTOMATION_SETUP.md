# 🔄 Airtable Automation Setup for Hobby Directory

## 1. API Access Setup ✅ (Current Step)

### Personal Access Token (Recommended)
1. Go to [https://airtable.com/create/tokens](https://airtable.com/create/tokens)
2. Click "Create token"
3. Name: "Hobby Directory Automation"
4. Scopes to enable:
   - `data.records:read`
   - `data.records:write`
   - `data.recordComments:write`
   - `schema.bases:read`
   - `webhook:manage`
5. Access: Select your Hobby Directory base
6. Copy and save token to `.env`:
   ```
   AIRTABLE_API_KEY=patXXXXXXXXXXXXXX
   AIRTABLE_BASE_ID=appXXXXXXXXXXXXXX
   ```

### Finding Your Base ID
1. Open your Airtable base
2. Go to Help → API Documentation
3. Base ID is in the URL: `https://airtable.com/appXXXXXXXXXXXXXX/api/docs`

---

## 2. Airtable Automation Rules

### A. New Event Processing
**Trigger**: When record created in "Events Staging"
**Actions**:
1. **Check for duplicates**
   - Find records in "Events" where `name` contains staging record name
   - If found, update status to "Duplicate"
2. **Enrich data**
   - If Instagram handle exists, trigger webhook to Playwright scraper
   - If website exists, trigger Google Sheets IMPORTXML
3. **Move to review queue**
   - Update status to "Pending Review"
   - Set review_date to tomorrow 7:30am

### B. Daily Review Automation (7:30am)
**Trigger**: At scheduled time (7:30am daily)
**Actions**:
1. Find all records where status = "Pending Review"
2. Send digest email with:
   - Event name, date, venue
   - Original vs rewritten descriptions
   - Quick approve/reject links
3. Create Slack notification (optional)

### C. Content Rewriting
**Trigger**: When record enters "Events Staging" with status "Scraped"
**Actions**:
1. Send to Make.com/Zapier webhook with:
   - Original description
   - Event type
   - Target tone (fun, professional, casual)
2. Receive rewritten content
3. Update `description_rewritten` field
4. Set status to "Pending Review"

### D. WhaleSync Preparation
**Trigger**: When status changes to "Approved"
**Actions**:
1. Copy record to "Events Published" table
2. Generate Webflow slug from event name
3. Set publish_date to current timestamp
4. Tag for WhaleSync sync

---

## 3. WhaleSync Configuration

### Initial Setup
1. Sign up at [whalesync.com](https://whalesync.com)
2. Connect Airtable:
   - Use OAuth or API key from step 1
   - Select "Hobby Directory" base
   - Choose "Events Published" table
3. Connect Webflow:
   - Authorize Webflow access
   - Select your Hobby Directory site
   - Map to "Events" CMS collection

### Field Mapping
```
Airtable → Webflow
--------------------------------
name → Name (required)
description_rewritten → Description
date → Event Date
time → Event Time
venue → Venue
address → Address
price → Price
image_url → Main Image
instructor → Instructor Reference
category → Category (multi-ref)
booking_url → Booking Link
instagram_handle → Instagram
website_url → Website
```

### Sync Settings
- **Direction**: One-way (Airtable → Webflow)
- **Frequency**: Real-time (webhook-based)
- **Conflict resolution**: Airtable wins
- **Delete behavior**: Don't delete in Webflow

---

## 4. Google Sheets Scraping Setup

### Create Master Sheet
1. Create new Google Sheet: "Hobby Directory Scrapers"
2. Add tabs:
   - Instagram_Queue
   - Website_Queue
   - Scraped_Data
   - Error_Log

### IMPORTXML Formulas
```
// For website meta descriptions
=IMPORTXML(A2,"//meta[@name='description']/@content")

// For website titles
=IMPORTXML(A2,"//title")

// For structured data (events)
=IMPORTXML(A2,"//script[@type='application/ld+json']")

// For Open Graph images
=IMPORTXML(A2,"//meta[@property='og:image']/@content")
```

### Apps Script Automation
```javascript
function processScrapingQueue() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet();
  const queue = sheet.getSheetByName('Website_Queue');
  const data = queue.getDataRange().getValues();
  
  data.forEach((row, index) => {
    if (row[0] && !row[2]) { // Has URL, no result yet
      try {
        // Scrape data
        const result = UrlFetchApp.fetch(row[0]);
        const content = result.getContentText();
        
        // Extract data (customize as needed)
        const title = content.match(/<title>(.*?)<\/title>/)[1];
        const description = content.match(/<meta name="description" content="(.*?)"/)[1];
        
        // Write results
        queue.getRange(index + 1, 3).setValue(title);
        queue.getRange(index + 1, 4).setValue(description);
        queue.getRange(index + 1, 5).setValue(new Date());
        
        // Send to Airtable
        updateAirtableRecord(row[1], title, description);
        
      } catch(e) {
        queue.getRange(index + 1, 6).setValue('Error: ' + e.toString());
      }
    }
  });
}

function updateAirtableRecord(recordId, title, description) {
  const url = `https://api.airtable.com/v0/${BASE_ID}/Events%20Staging/${recordId}`;
  
  UrlFetchApp.fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json'
    },
    payload: JSON.stringify({
      fields: {
        'website_title': title,
        'website_description': description,
        'scrape_status': 'Completed'
      }
    })
  });
}
```

---

## 5. Playwright Scraping Scripts

### Instagram Scraper
Save as `~/HobbyistSwiftUI/scrapers/instagram-scraper.js`:

```javascript
const { chromium } = require('playwright');
const Airtable = require('airtable');

// Configure Airtable
const base = new Airtable({ apiKey: process.env.AIRTABLE_API_KEY })
  .base(process.env.AIRTABLE_BASE_ID);

async function scrapeInstagram(username, recordId) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  try {
    // Navigate to Instagram profile
    await page.goto(`https://www.instagram.com/${username}/`);
    await page.waitForLoadState('networkidle');
    
    // Extract profile data
    const profileData = await page.evaluate(() => {
      const getTextContent = (selector) => {
        const element = document.querySelector(selector);
        return element ? element.textContent.trim() : null;
      };
      
      return {
        followerCount: getTextContent('[title*="followers"]'),
        bio: getTextContent('div.-vDIg > span'),
        websiteUrl: document.querySelector('a[rel="me"]')?.href,
        isVerified: !!document.querySelector('[aria-label="Verified"]'),
        postCount: getTextContent('span.g47SY')
      };
    });
    
    // Extract recent posts
    const recentPosts = await page.evaluate(() => {
      const posts = [];
      const postElements = document.querySelectorAll('article a[href*="/p/"]');
      
      for (let i = 0; i < Math.min(3, postElements.length); i++) {
        const post = postElements[i];
        posts.push({
          url: post.href,
          imageUrl: post.querySelector('img')?.src,
          altText: post.querySelector('img')?.alt
        });
      }
      
      return posts;
    });
    
    // Update Airtable record
    await base('Events Staging').update(recordId, {
      'instagram_bio': profileData.bio,
      'instagram_followers': profileData.followerCount,
      'instagram_verified': profileData.isVerified,
      'instagram_website': profileData.websiteUrl,
      'recent_posts': JSON.stringify(recentPosts),
      'scrape_status': 'Completed',
      'scraped_at': new Date().toISOString()
    });
    
    console.log(`✅ Scraped @${username} successfully`);
    
  } catch (error) {
    console.error(`❌ Error scraping @${username}:`, error);
    
    // Update error status
    await base('Events Staging').update(recordId, {
      'scrape_status': 'Error',
      'scrape_error': error.message,
      'scraped_at': new Date().toISOString()
    });
    
  } finally {
    await browser.close();
  }
}

// Queue processor
async function processQueue() {
  const records = await base('Events Staging')
    .select({
      filterByFormula: 'AND({instagram_handle}, {scrape_status} = "Pending")',
      maxRecords: 10
    })
    .firstPage();
  
  for (const record of records) {
    const username = record.get('instagram_handle').replace('@', '');
    await scrapeInstagram(username, record.id);
    
    // Rate limiting - wait 2-5 seconds between requests
    await new Promise(resolve => setTimeout(resolve, 2000 + Math.random() * 3000));
  }
}

// Run every 30 minutes
if (require.main === module) {
  processQueue()
    .then(() => console.log('Queue processing complete'))
    .catch(console.error);
}

module.exports = { scrapeInstagram, processQueue };
```

---

## 6. LLM Rewriting Automation

### Option A: OpenAI API Direct Integration
```javascript
const OpenAI = require('openai');
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function rewriteDescription(originalText, eventType) {
  const prompt = `
    Rewrite this event description to be engaging and fun for Vancouver locals.
    Keep it under 150 words. Include a call to action.
    Event type: ${eventType}
    Original: ${originalText}
  `;
  
  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      { role: "system", content: "You are a creative copywriter for a Vancouver events platform." },
      { role: "user", content: prompt }
    ],
    temperature: 0.7,
    max_tokens: 200
  });
  
  return completion.choices[0].message.content;
}
```

### Option B: Make.com Webhook Flow
1. Create new scenario in Make.com
2. Add webhook trigger
3. Add OpenAI module:
   - Prompt: Use template with variables
   - Model: GPT-4 or Claude
4. Add Airtable module:
   - Update record with rewritten content
5. Set up error handling and retry logic

---

## 7. Daily Review System

### Email Template
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    .event-card {
      border: 1px solid #ddd;
      padding: 20px;
      margin: 20px 0;
      border-radius: 8px;
    }
    .original { background: #f5f5f5; }
    .rewritten { background: #e8f5e9; }
    .actions { margin-top: 20px; }
    .btn {
      padding: 10px 20px;
      margin: 0 10px;
      border-radius: 4px;
      text-decoration: none;
      display: inline-block;
    }
    .approve { background: #4CAF50; color: white; }
    .reject { background: #f44336; color: white; }
  </style>
</head>
<body>
  <h2>🌟 Daily Event Review - {{date}}</h2>
  <p>Good morning! Here are today's events to review:</p>
  
  {{#each events}}
  <div class="event-card">
    <h3>{{name}}</h3>
    <p><strong>Date:</strong> {{date}} at {{time}}</p>
    <p><strong>Venue:</strong> {{venue}}</p>
    
    <div class="original">
      <strong>Original Description:</strong>
      <p>{{description_original}}</p>
    </div>
    
    <div class="rewritten">
      <strong>Rewritten Description:</strong>
      <p>{{description_rewritten}}</p>
    </div>
    
    <div class="actions">
      <a href="{{approve_url}}" class="btn approve">✓ Approve</a>
      <a href="{{reject_url}}" class="btn reject">✗ Reject</a>
      <a href="{{edit_url}}" class="btn">✏️ Edit</a>
    </div>
  </div>
  {{/each}}
</body>
</html>
```

---

## 8. Error Handling & Monitoring

### Airtable Formula Fields
```
// Scraping Health Check
IF(
  AND(
    {scrape_status} = "Pending",
    DATETIME_DIFF(NOW(), {created_at}, 'hours') > 24
  ),
  "⚠️ Stale",
  {scrape_status}
)

// Data Completeness Score
(
  IF({name}, 20, 0) +
  IF({description_rewritten}, 20, 0) +
  IF({date}, 20, 0) +
  IF({venue}, 20, 0) +
  IF({image_url}, 20, 0)
) & "%"
```

### Monitoring Dashboard Views
1. **Pending Review**: `{status} = "Pending Review"`
2. **Failed Scrapes**: `{scrape_status} = "Error"`
3. **Ready to Publish**: `{status} = "Approved"`
4. **Incomplete Data**: `{completeness_score} < 80`

---

## 9. Testing Checklist

- [ ] API key can read/write to all tables
- [ ] Test Instagram scraper with @rumbleboxingmp
- [ ] Test website scraper with claymates.studio
- [ ] Verify LLM rewriting improves descriptions
- [ ] Confirm WhaleSync updates Webflow in real-time
- [ ] Test 7:30am review email arrives
- [ ] Check error handling for failed scrapes
- [ ] Verify duplicate detection works
- [ ] Test approval/rejection workflow
- [ ] Monitor API rate limits

---

## 10. Go-Live Sequence

1. **Week 1**: Manual scraping + rewriting
2. **Week 2**: Automated scraping, manual review
3. **Week 3**: Full automation with daily reviews
4. **Week 4**: Performance optimization and scaling

---

*Next Step: Let's configure your Airtable API access and test the connection!*