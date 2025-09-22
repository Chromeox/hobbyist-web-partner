/**
 * Direct Airtable Instagram Scraper
 * Replaces Google Sheets with direct Airtable API integration
 * 
 * Setup:
 * 1. npm install airtable playwright dotenv
 * 2. Get Airtable Personal Access Token from https://airtable.com/create/tokens
 * 3. Set AIRTABLE_TOKEN and AIRTABLE_BASE_ID in .env
 * 4. Run: node airtable-direct-scraper.js
 */

const { chromium } = require('playwright');
const Airtable = require('airtable');
const fs = require('fs').promises;
require('dotenv').config();

// ============= CONFIGURATION =============

const CONFIG = {
  // Airtable
  AIRTABLE_TOKEN: process.env.AIRTABLE_TOKEN,
  AIRTABLE_BASE_ID: process.env.AIRTABLE_BASE_ID,
  AIRTABLE_TABLE_NAME: 'Events', // Your table name in Airtable
  
  // Instagram accounts from your existing config
  INSTAGRAM_ACCOUNTS: [
    '@rumbleboxingmp',
    '@claymates.studio',
    '@hotpotterymaybe',
    '@vanpotterystudio',
    '@coastalclayvancouver',
    // Add more from your instagram-accounts-config.js
  ],
  
  // Rate limiting
  DELAY_BETWEEN_REQUESTS: 3000, // 3 seconds
  BATCH_SIZE: 10, // Airtable allows up to 10 records per batch
};

// ============= AIRTABLE CLIENT =============

class AirtableClient {
  constructor() {
    if (!CONFIG.AIRTABLE_TOKEN || !CONFIG.AIRTABLE_BASE_ID) {
      throw new Error('Missing AIRTABLE_TOKEN or AIRTABLE_BASE_ID in environment variables');
    }
    
    this.base = new Airtable({ apiKey: CONFIG.AIRTABLE_TOKEN })
      .base(CONFIG.AIRTABLE_BASE_ID);
    
    this.table = this.base(CONFIG.AIRTABLE_TABLE_NAME);
    console.log('✅ Airtable connected');
  }

  async createRecord(data) {
    try {
      const record = await this.table.create([
        {
          fields: data
        }
      ]);
      
      console.log(`✅ Added record to Airtable: ${data.name || 'Unnamed event'}`);
      return record[0];
    } catch (error) {
      console.error('❌ Error creating Airtable record:', error);
      throw error;
    }
  }

  async createRecords(recordsData) {
    try {
      // Split into batches of 10 (Airtable limit)
      const batches = [];
      for (let i = 0; i < recordsData.length; i += CONFIG.BATCH_SIZE) {
        batches.push(recordsData.slice(i, i + CONFIG.BATCH_SIZE));
      }

      const allRecords = [];
      for (const batch of batches) {
        const formattedBatch = batch.map(data => ({ fields: data }));
        const records = await this.table.create(formattedBatch);
        allRecords.push(...records);
        console.log(`✅ Added batch of ${records.length} records to Airtable`);
        
        // Brief pause between batches to respect rate limits
        if (batches.length > 1) {
          await this.delay(1000);
        }
      }
      
      return allRecords;
    } catch (error) {
      console.error('❌ Error creating Airtable records:', error);
      throw error;
    }
  }

  async getExistingEvents() {
    try {
      const records = await this.table.select({
        fields: ['name', 'Event Date', 'studio'],
        maxRecords: 1000 // Adjust as needed
      }).all();
      
      return records.map(record => ({
        name: record.get('name') || '',
        date: record.get('Event Date') || '',
        studio: record.get('studio') || ''
      }));
    } catch (error) {
      console.error('❌ Error reading from Airtable:', error);
      return [];
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// ============= INSTAGRAM SCRAPER (REUSED FROM EXISTING) =============

class InstagramScraper {
  constructor(browser) {
    this.browser = browser;
  }

  async scrapeProfile(username) {
    const page = await this.browser.newPage();
    
    try {
      console.log(`📸 Scraping Instagram: ${username}`);
      
      // Remove @ if present
      username = username.replace('@', '');
      
      // Navigate to profile
      await page.goto(`https://www.instagram.com/${username}/`, {
        waitUntil: 'networkidle',
        timeout: 30000,
      });

      // Wait for content to load
      await page.waitForTimeout(2000);

      // Extract profile data and recent posts
      const profileData = await this.extractProfileData(page);
      const posts = await this.extractRecentPosts(page);

      await page.close();

      // Convert posts to events using your existing logic
      const events = [];
      for (const post of posts) {
        const eventInfo = this.parseEventFromCaption(post.caption, username, profileData);
        if (eventInfo) {
          events.push({
            ...eventInfo,
            instagram_url: post.url,
            Image_URL: post.imageUrl,
            Instagram_Handle: `@${username}`,
            studio: profileData.displayName || `@${username}`,
            Status: 'Scraped',
            Scraped_At: new Date().toISOString(),
          });
        }
      }

      return events;

    } catch (error) {
      console.error(`❌ Error scraping @${username}:`, error);
      await page.close();
      return [];
    }
  }

  async extractProfileData(page) {
    return await page.evaluate(() => {
      const getText = (selector) => {
        const element = document.querySelector(selector);
        return element ? element.textContent.trim() : '';
      };

      // Get bio and profile info
      const bioElement = document.querySelector('div.-vDIg > span');
      const bio = bioElement ? bioElement.textContent : '';
      
      // Get display name
      const nameElement = document.querySelector('section h2');
      const displayName = nameElement ? nameElement.textContent : '';

      return {
        bio,
        displayName,
      };
    });
  }

  async extractRecentPosts(page) {
    try {
      const posts = await page.evaluate(() => {
        const postElements = document.querySelectorAll('article a[href*="/p/"]');
        const postsData = [];

        for (let i = 0; i < Math.min(6, postElements.length); i++) {
          const post = postElements[i];
          const img = post.querySelector('img');
          
          postsData.push({
            url: post.href,
            imageUrl: img ? img.src : '',
            caption: img ? img.alt : '',
          });
        }

        return postsData;
      });

      return posts;
    } catch (error) {
      console.error('Error extracting posts:', error);
      return [];
    }
  }

  parseEventFromCaption(caption, username, profileData) {
    if (!caption) return null;

    // Your existing event detection logic
    const eventKeywords = [
      'class', 'workshop', 'session', 'event', 'join us', 'book now',
      'pottery', 'ceramics', 'clay', 'wheel throwing', 'hand building',
      'boxing', 'fitness', 'training', 'workout'
    ];

    const hasEventKeyword = eventKeywords.some(keyword => 
      caption.toLowerCase().includes(keyword)
    );

    if (!hasEventKeyword) return null;

    // Extract date patterns
    const datePattern = /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})|(\w+ \d{1,2}(?:st|nd|rd|th)?(?:,? \d{4})?)/i;
    const timePattern = /(\d{1,2}(?::\d{2})?\s*(?:am|pm))/i;
    const pricePattern = /\$(\d+(?:\.\d{2})?)/;

    const dateMatch = caption.match(datePattern);
    const timeMatch = caption.match(timePattern);
    const priceMatch = caption.match(pricePattern);

    // Generate event name from caption or use default
    const eventName = this.extractEventName(caption) || 
                     `${profileData.displayName || username} Event`;

    return {
      name: eventName,
      'Event Date': dateMatch ? dateMatch[0] : '',
      Time: timeMatch ? timeMatch[0] : '',
      price: priceMatch ? `$${priceMatch[1]}` : '',
      Description: caption,
      location: this.extractLocation(caption, profileData.bio),
      address: this.extractAddress(caption, profileData.bio),
    };
  }

  extractEventName(caption) {
    // Extract event name from caption
    const lines = caption.split('\n');
    const firstLine = lines[0];
    
    // If first line is short and descriptive, use it
    if (firstLine.length < 60 && firstLine.length > 5) {
      return firstLine.replace(/[🎨🏺💪🥊⭐]/g, '').trim();
    }
    
    return null;
  }

  extractLocation(caption, bio) {
    // Try to extract studio/venue name from bio or caption
    const locationKeywords = ['studio', 'gym', 'center', 'space'];
    const text = `${caption} ${bio}`.toLowerCase();
    
    for (const keyword of locationKeywords) {
      const regex = new RegExp(`([\w\s]+${keyword}[\w\s]*)`, 'i');
      const match = text.match(regex);
      if (match) {
        return match[1].trim();
      }
    }
    
    return '';
  }

  extractAddress(caption, bio) {
    // Look for Vancouver addresses
    const addressPattern = /(?:vancouver|burnaby|richmond|north van|west van|coquitlam)[\w\s,]*(?:bc|canada)?/i;
    const text = `${caption} ${bio}`;
    const match = text.match(addressPattern);
    
    return match ? match[0].trim() : '';
  }
}

// ============= MAIN ORCHESTRATOR =============

class DirectAirtableScraper {
  constructor() {
    this.browser = null;
    this.airtable = new AirtableClient();
  }

  async initialize() {
    this.browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    console.log('✅ Scraper initialized');
  }

  async scrapeAll() {
    const instagramScraper = new InstagramScraper(this.browser);

    // Get existing events to avoid duplicates
    const existingEvents = await this.airtable.getExistingEvents();
    console.log(`Found ${existingEvents.length} existing events in Airtable`);

    const allNewEvents = [];

    // Scrape Instagram accounts
    for (const account of CONFIG.INSTAGRAM_ACCOUNTS) {
      const events = await instagramScraper.scrapeProfile(account);
      
      // Filter out duplicates
      for (const event of events) {
        if (!this.isDuplicate(event, existingEvents)) {
          allNewEvents.push(event);
        }
      }

      // Rate limiting
      await this.delay(CONFIG.DELAY_BETWEEN_REQUESTS);
    }

    // Send to Airtable in batches
    if (allNewEvents.length > 0) {
      console.log(`📝 Adding ${allNewEvents.length} new events to Airtable`);
      await this.airtable.createRecords(allNewEvents);
    } else {
      console.log('ℹ️ No new events found');
    }

    return allNewEvents;
  }

  isDuplicate(newEvent, existingEvents) {
    const normalizedName = newEvent.name?.toLowerCase().trim();
    const normalizedDate = newEvent['Event Date'];
    const normalizedStudio = newEvent.studio?.toLowerCase().trim();

    return existingEvents.some(existing => {
      const existingName = existing.name?.toLowerCase().trim();
      const existingDate = existing.date;
      const existingStudio = existing.studio?.toLowerCase().trim();
      
      return existingName === normalizedName && 
             existingDate === normalizedDate &&
             existingStudio === normalizedStudio;
    });
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
    }
    console.log('✅ Cleanup complete');
  }
}

// ============= EXECUTION =============

async function main() {
  const scraper = new DirectAirtableScraper();
  
  try {
    console.log('🚀 Starting Direct Airtable Scraper');
    console.log(`📍 Target accounts: ${CONFIG.INSTAGRAM_ACCOUNTS.join(', ')}`);
    
    await scraper.initialize();
    const results = await scraper.scrapeAll();
    
    console.log('✅ Scraping complete!');
    console.log(`📊 Total events added: ${results.length}`);
    
    // Save results to local file as backup
    const timestamp = new Date().toISOString().replace(/:/g, '-');
    const filename = `airtable_results_${timestamp}.json`;
    await fs.writeFile(filename, JSON.stringify(results, null, 2));
    console.log(`💾 Results saved to ${filename}`);
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// Run the scraper
if (require.main === module) {
  main();
}

module.exports = { DirectAirtableScraper, InstagramScraper, AirtableClient };