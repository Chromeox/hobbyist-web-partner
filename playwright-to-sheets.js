/**
 * Playwright to Google Sheets Scraper
 * Scrapes Instagram and websites, then sends to Google Sheets
 * 
 * Setup:
 * 1. npm install playwright @google-cloud/sheets dotenv
 * 2. Set up Google Sheets API credentials
 * 3. Run: node playwright-to-sheets.js
 */

const { chromium } = require('playwright');
const { google } = require('googleapis');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

// ============= CONFIGURATION =============

const CONFIG = {
  // Google Sheets
  SPREADSHEET_ID: process.env.SHEETS_ID || 'YOUR_SPREADSHEET_ID_HERE',
  SHEET_NAME: 'Events Staging',
  
  // Target accounts
  INSTAGRAM_ACCOUNTS: [
    '@rumbleboxingmp',
    '@claymates.studio',
    // Add more accounts here
  ],
  
  // Websites to scrape
  WEBSITES: [
    'https://www.claymatesceramicsstudio.com',
    // Add more websites here
  ],
  
  // Rate limiting
  DELAY_BETWEEN_REQUESTS: 3000, // 3 seconds
  BATCH_SIZE: 5,
};

// ============= GOOGLE SHEETS SETUP =============

class GoogleSheetsClient {
  constructor() {
    this.sheets = null;
    this.auth = null;
  }

  async initialize() {
    // Using service account (recommended)
    // Download JSON key from Google Cloud Console
    const keyFile = await fs.readFile('google-sheets-key.json', 'utf8');
    const key = JSON.parse(keyFile);
    
    this.auth = new google.auth.GoogleAuth({
      credentials: key,
      scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });
    
    this.sheets = google.sheets({ version: 'v4', auth: this.auth });
    console.log('✅ Google Sheets connected');
  }

  async appendRow(data) {
    try {
      const response = await this.sheets.spreadsheets.values.append({
        spreadsheetId: CONFIG.SPREADSHEET_ID,
        range: `${CONFIG.SHEET_NAME}!A:Y`,
        valueInputOption: 'USER_ENTERED',
        requestBody: {
          values: [data],
        },
      });
      
      console.log(`✅ Added row to Google Sheets`);
      return response.data;
    } catch (error) {
      console.error('❌ Error appending to Sheets:', error);
      throw error;
    }
  }

  async batchAppend(rows) {
    try {
      const response = await this.sheets.spreadsheets.values.append({
        spreadsheetId: CONFIG.SPREADSHEET_ID,
        range: `${CONFIG.SHEET_NAME}!A:Y`,
        valueInputOption: 'USER_ENTERED',
        requestBody: {
          values: rows,
        },
      });
      
      console.log(`✅ Added ${rows.length} rows to Google Sheets`);
      return response.data;
    } catch (error) {
      console.error('❌ Error batch appending to Sheets:', error);
      throw error;
    }
  }

  async getExistingEvents() {
    try {
      const response = await this.sheets.spreadsheets.values.get({
        spreadsheetId: CONFIG.SPREADSHEET_ID,
        range: `${CONFIG.SHEET_NAME}!B:B`, // Get all names to check duplicates
      });
      
      return response.data.values?.flat() || [];
    } catch (error) {
      console.error('❌ Error reading from Sheets:', error);
      return [];
    }
  }
}

// ============= INSTAGRAM SCRAPER =============

class InstagramScraper {
  constructor(browser) {
    this.browser = browser;
  }

  async scrapeProfile(username) {
    const page = await this.browser.newPage();
    
    try {
      console.log(`📸 Scraping Instagram: @${username}`);
      
      // Remove @ if present
      username = username.replace('@', '');
      
      // Navigate to profile
      await page.goto(`https://www.instagram.com/${username}/`, {
        waitUntil: 'networkidle',
        timeout: 30000,
      });

      // Wait for content to load
      await page.waitForTimeout(2000);

      // Extract profile data
      const profileData = await page.evaluate(() => {
        // Helper function to safely get text
        const getText = (selector) => {
          const element = document.querySelector(selector);
          return element ? element.textContent.trim() : '';
        };

        // Get bio
        const bioElement = document.querySelector('div.-vDIg > span');
        const bio = bioElement ? bioElement.textContent : '';

        // Get follower count
        const followerElement = document.querySelector('a[href*="/followers/"] span');
        const followers = followerElement ? followerElement.title || followerElement.textContent : '0';

        // Get website link
        const websiteElement = document.querySelector('a[rel="me"]');
        const website = websiteElement ? websiteElement.href : '';

        // Check if verified
        const isVerified = !!document.querySelector('[aria-label="Verified"]');

        return {
          bio,
          followers,
          website,
          isVerified,
        };
      });

      // Extract recent posts
      const posts = await this.extractRecentPosts(page);

      await page.close();

      return {
        username: `@${username}`,
        ...profileData,
        posts,
        scraped_at: new Date().toISOString(),
      };

    } catch (error) {
      console.error(`❌ Error scraping @${username}:`, error);
      await page.close();
      
      return {
        username: `@${username}`,
        error: error.message,
        scraped_at: new Date().toISOString(),
      };
    }
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

      // Process posts to extract event information
      const events = [];
      for (const post of posts) {
        const eventInfo = this.parseEventFromCaption(post.caption);
        if (eventInfo) {
          events.push({
            ...eventInfo,
            instagram_url: post.url,
            image_url: post.imageUrl,
          });
        }
      }

      return events;

    } catch (error) {
      console.error('Error extracting posts:', error);
      return [];
    }
  }

  parseEventFromCaption(caption) {
    if (!caption) return null;

    // Extract date patterns (customize based on actual caption formats)
    const datePattern = /(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})|(\w+ \d{1,2}(?:st|nd|rd|th)?(?:,? \d{4})?)/i;
    const timePattern = /(\d{1,2}(?::\d{2})?\s*(?:am|pm))/i;
    const pricePattern = /\$(\d+(?:\.\d{2})?)/;

    const dateMatch = caption.match(datePattern);
    const timeMatch = caption.match(timePattern);
    const priceMatch = caption.match(pricePattern);

    // Only create event if we found meaningful data
    if (dateMatch || timeMatch || caption.toLowerCase().includes('class') || caption.toLowerCase().includes('workshop')) {
      return {
        description_original: caption,
        date: dateMatch ? dateMatch[0] : '',
        time: timeMatch ? timeMatch[0] : '',
        price: priceMatch ? priceMatch[1] : '',
      };
    }

    return null;
  }
}

// ============= WEBSITE SCRAPER =============

class WebsiteScraper {
  constructor(browser) {
    this.browser = browser;
  }

  async scrapeWebsite(url) {
    const page = await this.browser.newPage();
    
    try {
      console.log(`🌐 Scraping website: ${url}`);
      
      await page.goto(url, {
        waitUntil: 'networkidle',
        timeout: 30000,
      });

      // Extract metadata
      const metadata = await page.evaluate(() => {
        const getMetaContent = (name) => {
          const meta = document.querySelector(`meta[name="${name}"], meta[property="${name}"]`);
          return meta ? meta.content : '';
        };

        return {
          title: document.title,
          description: getMetaContent('description'),
          ogImage: getMetaContent('og:image'),
          ogTitle: getMetaContent('og:title'),
          ogDescription: getMetaContent('og:description'),
        };
      });

      // Look for event-specific data
      const events = await this.extractEvents(page);

      await page.close();

      return {
        url,
        ...metadata,
        events,
        scraped_at: new Date().toISOString(),
      };

    } catch (error) {
      console.error(`❌ Error scraping ${url}:`, error);
      await page.close();
      
      return {
        url,
        error: error.message,
        scraped_at: new Date().toISOString(),
      };
    }
  }

  async extractEvents(page) {
    try {
      // Look for structured data
      const structuredData = await page.evaluate(() => {
        const scripts = document.querySelectorAll('script[type="application/ld+json"]');
        const events = [];

        scripts.forEach(script => {
          try {
            const data = JSON.parse(script.textContent);
            if (data['@type'] === 'Event' || data['@type'] === 'Course') {
              events.push({
                name: data.name,
                description: data.description,
                startDate: data.startDate,
                location: data.location?.name || data.location?.address,
                price: data.offers?.price,
                url: data.url,
              });
            }
          } catch (e) {
            // Invalid JSON, skip
          }
        });

        return events;
      });

      return structuredData;

    } catch (error) {
      console.error('Error extracting events:', error);
      return [];
    }
  }
}

// ============= MAIN ORCHESTRATOR =============

class HobbyDirectoryScraper {
  constructor() {
    this.browser = null;
    this.sheets = new GoogleSheetsClient();
    this.results = [];
  }

  async initialize() {
    // Initialize browser
    this.browser = await chromium.launch({
      headless: true, // Set to false for debugging
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    // Initialize Google Sheets
    await this.sheets.initialize();

    console.log('✅ Scraper initialized');
  }

  async scrapeAll() {
    const instagramScraper = new InstagramScraper(this.browser);
    const websiteScraper = new WebsiteScraper(this.browser);

    // Get existing events to avoid duplicates
    const existingEvents = await this.sheets.getExistingEvents();
    console.log(`Found ${existingEvents.length} existing events`);

    const allEvents = [];

    // Scrape Instagram accounts
    for (const account of CONFIG.INSTAGRAM_ACCOUNTS) {
      const data = await instagramScraper.scrapeProfile(account);
      
      // Process each post as a potential event
      if (data.posts) {
        for (const post of data.posts) {
          const eventRow = this.formatEventRow({
            name: `Event from ${account}`,
            ...post,
            instagram_handle: account,
            instagram_bio: data.bio,
            instagram_followers: data.followers,
          });

          // Check for duplicates
          if (!this.isDuplicate(eventRow[1], existingEvents)) {
            allEvents.push(eventRow);
          }
        }
      }

      // Rate limiting
      await this.delay(CONFIG.DELAY_BETWEEN_REQUESTS);
    }

    // Scrape websites
    for (const url of CONFIG.WEBSITES) {
      const data = await websiteScraper.scrapeWebsite(url);
      
      if (data.events && data.events.length > 0) {
        for (const event of data.events) {
          const eventRow = this.formatEventRow({
            ...event,
            website_url: url,
            website_title: data.title,
            website_meta: data.description,
          });

          if (!this.isDuplicate(eventRow[1], existingEvents)) {
            allEvents.push(eventRow);
          }
        }
      } else {
        // Add as single event if no structured data found
        const eventRow = this.formatEventRow({
          name: data.title || `Event from ${new URL(url).hostname}`,
          description_original: data.description,
          website_url: url,
          website_title: data.title,
          website_meta: data.description,
          image_url: data.ogImage,
        });

        if (!this.isDuplicate(eventRow[1], existingEvents)) {
          allEvents.push(eventRow);
        }
      }

      await this.delay(CONFIG.DELAY_BETWEEN_REQUESTS);
    }

    // Batch append to Google Sheets
    if (allEvents.length > 0) {
      console.log(`📝 Adding ${allEvents.length} new events to Google Sheets`);
      await this.sheets.batchAppend(allEvents);
    } else {
      console.log('ℹ️ No new events found');
    }

    return allEvents;
  }

  formatEventRow(data) {
    // Format data for Google Sheets columns
    return [
      this.generateId(),                    // ID
      data.name || '',                      // Name
      data.date || data.startDate || '',    // Date
      data.time || '',                      // Time
      data.venue || data.location || '',    // Venue
      data.address || '',                   // Address
      data.description_original || data.description || '', // Description_Original
      '',                                    // Description_Rewritten (empty, will be filled by Apps Script)
      data.price || '',                     // Price
      data.instagram_handle || '',          // Instagram_Handle
      data.instagram_url || '',             // Instagram_URL
      data.website_url || data.url || '',   // Website_URL
      data.image_url || '',                 // Image_URL
      data.instructor || '',                // Instructor
      data.category || '',                  // Category
      data.booking_url || '',               // Booking_URL
      'Scraped',                            // Status
      new Date().toISOString(),            // Scraped_At
      '',                                   // Reviewed_At
      '',                                   // Quality_Score
      data.instagram_bio || '',            // Instagram_Bio
      data.instagram_followers || '',      // Instagram_Followers
      data.website_title || '',            // Website_Title
      data.website_meta || '',             // Website_Meta
      '',                                   // Error_Notes
    ];
  }

  generateId() {
    return `EVT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  isDuplicate(name, existingNames) {
    if (!name) return false;
    
    const normalizedName = name.toLowerCase().trim();
    return existingNames.some(existing => 
      existing && existing.toLowerCase().trim() === normalizedName
    );
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
  const scraper = new HobbyDirectoryScraper();
  
  try {
    console.log('🚀 Starting Hobby Directory Scraper');
    console.log(`📍 Target accounts: ${CONFIG.INSTAGRAM_ACCOUNTS.join(', ')}`);
    console.log(`🌐 Target websites: ${CONFIG.WEBSITES.join(', ')}`);
    
    await scraper.initialize();
    const results = await scraper.scrapeAll();
    
    console.log('✅ Scraping complete!');
    console.log(`📊 Total events added: ${results.length}`);
    
    // Save results to local file as backup
    const timestamp = new Date().toISOString().replace(/:/g, '-');
    const filename = `scrape_results_${timestamp}.json`;
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

module.exports = { HobbyDirectoryScraper, InstagramScraper, WebsiteScraper };