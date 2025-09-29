/**
 * Instagram Scraper with Smart Rotation
 * Avoids rate limits by running different batches at different times
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { getCurrentBatch, SCRAPER_CONFIG } = require('./instagram-accounts-config');

// Configuration
const CONFIG = {
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  CREDENTIALS_FILE: path.join(__dirname, '.env.instagram'),
  HEADLESS: true, // Run headless in production
  LOG_FILE: path.join(__dirname, 'scraper.log'),
  SESSION_FILE: path.join(__dirname, '.instagram-session.json')
};

// Load credentials
function loadCredentials() {
  try {
    const content = fs.readFileSync(CONFIG.CREDENTIALS_FILE, 'utf8');
    const lines = content.split('\n');
    const creds = {};
    
    lines.forEach(line => {
      if (line.includes('=') && !line.startsWith('#')) {
        const [key, value] = line.split('=');
        creds[key.trim()] = value.trim();
      }
    });
    
    return creds;
  } catch (error) {
    console.error('❌ Could not read credentials file');
    process.exit(1);
  }
}

// Logging function
function log(message) {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}`;
  console.log(message);
  fs.appendFileSync(CONFIG.LOG_FILE, logMessage + '\n');
}

// Main scraper class
class RotatedInstagramScraper {
  constructor() {
    this.browser = null;
    this.context = null;
    this.page = null;
    this.actionCount = 0;
    this.startTime = Date.now();
  }

  async initialize() {
    log(`🚀 Starting Instagram Scraper - DAILY RUN`);
    log(`📊 Processing all 60 accounts in single run`);
    
    this.browser = await chromium.launch({
      headless: CONFIG.HEADLESS,
      args: ['--disable-blink-features=AutomationControlled']
    });
    
    // Create context with saved session if available
    const contextOptions = {
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    };
    
    if (fs.existsSync(CONFIG.SESSION_FILE)) {
      contextOptions.storageState = JSON.parse(fs.readFileSync(CONFIG.SESSION_FILE, 'utf8'));
    }
    
    this.context = await this.browser.newContext(contextOptions);
    this.page = await this.context.newPage();
  }

  async checkRateLimit() {
    const elapsedHours = (Date.now() - this.startTime) / (1000 * 60 * 60);
    const actionsPerHour = this.actionCount / Math.max(elapsedHours, 0.1);
    
    if (actionsPerHour > SCRAPER_CONFIG.MAX_ACTIONS_PER_HOUR) {
      const waitTime = 60 - (new Date().getMinutes());
      log(`⚠️  Rate limit approaching. Waiting ${waitTime} minutes...`);
      await this.page.waitForTimeout(waitTime * 60 * 1000);
      this.actionCount = 0;
      this.startTime = Date.now();
    }
  }

  async login() {
    const creds = loadCredentials();
    
    await this.page.goto('https://www.instagram.com/', { waitUntil: 'domcontentloaded' });
    await this.page.waitForTimeout(3000);
    
    // Check if already logged in
    const homeFeed = await this.page.$('svg[aria-label="Home"], article');
    if (homeFeed) {
      log('✅ Already logged in from saved session');
      await this.saveSession();
      return true;
    }
    
    // Login
    try {
      await this.page.waitForSelector('input[name="username"]', { timeout: 10000 });
      await this.page.fill('input[name="username"]', creds.INSTAGRAM_USERNAME);
      await this.page.fill('input[name="password"]', creds.INSTAGRAM_PASSWORD);
      await this.page.click('button[type="submit"]');
      
      await this.page.waitForTimeout(5000);
      
      // Handle popups
      const notNow = await this.page.$('button:has-text("Not Now")');
      if (notNow) await notNow.click();
      
      await this.saveSession();
      log('✅ Logged in successfully');
      return true;
      
    } catch (error) {
      log('❌ Login failed: ' + error.message);
      return false;
    }
  }

  async saveSession() {
    const state = await this.context.storageState();
    fs.writeFileSync(CONFIG.SESSION_FILE, JSON.stringify(state, null, 2));
  }

  async scrapeAccount(account) {
    const username = account.handle.replace('@', '');
    
    try {
      await this.checkRateLimit();
      
      log(`📸 Scraping ${account.handle} (${account.name})...`);
      
      // Navigate to profile
      await this.page.goto(`https://www.instagram.com/${username}/`, {
        waitUntil: 'domcontentloaded',
        timeout: 15000
      });
      
      this.actionCount++;
      await this.page.waitForTimeout(SCRAPER_CONFIG.RATE_LIMITS.BETWEEN_POSTS);
      
      // Get posts
      const posts = await this.page.$$('article a[href*="/p/"], a[href*="/p/"]');
      
      if (posts.length === 0) {
        log(`  No posts found for ${account.handle}`);
        return [];
      }
      
      const events = [];
      const maxPosts = Math.min(SCRAPER_CONFIG.POSTS_PER_ACCOUNT, posts.length);
      
      for (let i = 0; i < maxPosts; i++) {
        // Click post
        await posts[i].click();
        this.actionCount++;
        await this.page.waitForTimeout(SCRAPER_CONFIG.RATE_LIMITS.BETWEEN_POSTS);
        
        // Extract caption
        let caption = '';
        try {
          const elements = await this.page.$$('h2 + span, h3 + span');
          for (const element of elements) {
            const text = await element.textContent();
            if (text && text.length > 20 && !text.includes('followers')) {
              caption = text;
              break;
            }
          }
        } catch {}
        
        if (!caption) {
          const allSpans = await this.page.$$eval('span', 
            elements => elements.map(el => el.textContent).filter(t => t && t.length > 30)
          ).catch(() => []);
          
          caption = allSpans.find(text => 
            text && !text.includes('followers') && !text.includes('Photo shared')
          ) || '';
        }
        
        // Analyze for events
        if (this.isLikelyEvent(caption)) {
          const event = this.createEvent(caption, account, this.page.url());
          events.push(event);
          await this.sendToGoogleSheets(event);
        }
        
        // Close post
        await this.page.keyboard.press('Escape');
        await this.page.waitForTimeout(1000);
      }
      
      // Rate limit between accounts
      await this.page.waitForTimeout(SCRAPER_CONFIG.RATE_LIMITS.BETWEEN_ACCOUNTS);
      
      return events;
      
    } catch (error) {
      log(`  ❌ Error scraping ${account.handle}: ${error.message}`);
      return [];
    }
  }

  isLikelyEvent(caption) {
    if (!caption || caption.length < 20) return false;
    
    const captionLower = caption.toLowerCase();
    const indicators = [];
    
    // Check for event indicators
    if (captionLower.match(/\b(class|workshop|session|training|bootcamp|meetup)\b/)) indicators.push('event-type');
    if (captionLower.match(/\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/)) indicators.push('weekday');
    if (captionLower.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}/)) indicators.push('date');
    if (captionLower.match(/\d{1,2}(:\d{2})?\s*(am|pm)/)) indicators.push('time');
    if (captionLower.match(/\$\d+|free/i)) indicators.push('price');
    if (captionLower.match(/join|register|sign up|book|reserve|spots/)) indicators.push('booking');
    if (captionLower.match(/tonight|tomorrow|today|this week/)) indicators.push('urgency');
    
    const confidence = indicators.length / 7;
    return confidence >= SCRAPER_CONFIG.MIN_CONFIDENCE;
  }

  createEvent(caption, account, postUrl) {
    // Extract event details from caption
    const captionLower = caption.toLowerCase();
    
    // Determine event type
    let eventName = 'Workshop';
    if (account.name.includes('Boxing')) eventName = 'Boxing Class';
    else if (account.name.includes('Yoga')) eventName = 'Yoga Session';
    else if (account.name.includes('Run')) eventName = 'Group Run';
    else if (account.name.includes('Paint')) eventName = 'Painting Class';
    else if (account.name.includes('Pottery')) eventName = 'Pottery Workshop';
    else if (account.name.includes('Cook')) eventName = 'Cooking Class';
    else if (account.name.includes('Photo')) eventName = 'Photography Workshop';
    
    // Extract time
    const timeMatch = caption.match(/(\d{1,2})(:\d{2})?\s*(am|pm)/i);
    const eventTime = timeMatch ? timeMatch[0].toUpperCase() : '7:00 PM';
    
    // Extract date or use next week
    let eventDate = new Date();
    eventDate.setDate(eventDate.getDate() + 7);
    
    const dateMatch = caption.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2})/i);
    if (dateMatch) {
      const months = {jan:'01',feb:'02',mar:'03',apr:'04',may:'05',jun:'06',
                    jul:'07',aug:'08',sep:'09',oct:'10',nov:'11',dec:'12'};
      const month = months[dateMatch[1].substring(0,3).toLowerCase()];
      const day = dateMatch[2].padStart(2, '0');
      eventDate = `2025-${month}-${day}`;
    } else {
      eventDate = eventDate.toISOString().split('T')[0];
    }
    
    return {
      name: eventName,
      studio: account.name,
      location: account.name,
      address: account.address || 'Vancouver, BC',
      date: eventDate,
      time: eventTime,
      price: account.price || '30',
      description: caption.substring(0, 200).replace(/[@#]\w+/g, '').trim(),
      original_caption: caption.substring(0, 500),
      instagram_url: postUrl,
      booking_url: account.website || '',
      source: 'Instagram',
      confidence_score: 0.75,
      scraped_batch: 'DAILY'
    };
  }

  async sendToGoogleSheets(event) {
    try {
      const response = await fetch(CONFIG.WEB_APP_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(event)
      });
      
      const result = await response.json();
      if (result.success) {
        log(`  ✅ Event sent: ${event.name}`);
      } else {
        log(`  ❌ Failed to send: ${result.error}`);
      }
    } catch (error) {
      log(`  ❌ Error sending: ${error.message}`);
    }
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// Main execution
async function main() {
  const scraper = new RotatedInstagramScraper();
  const accounts = require('./instagram-accounts-config');
  
  // Combine all batches for single daily run
  const allAccounts = [
    ...accounts.MORNING,
    ...accounts.AFTERNOON,
    ...accounts.EVENING
  ];
  
  try {
    await scraper.initialize();
    
    const loginSuccess = await scraper.login();
    if (!loginSuccess) {
      log('Failed to login. Exiting.');
      return;
    }
    
    // Browse home feed first (natural behavior)
    log('📱 Browsing home feed...');
    await scraper.page.waitForTimeout(5000);
    await scraper.page.evaluate(() => window.scrollBy(0, 300));
    await scraper.page.waitForTimeout(2000);
    
    // Scrape all accounts
    let totalEvents = 0;
    let accountsProcessed = 0;
    
    for (const account of allAccounts) {
      const events = await scraper.scrapeAccount(account);
      totalEvents += events.length;
      accountsProcessed++;
      
      // Progress update every 10 accounts
      if (accountsProcessed % 10 === 0) {
        log(`📊 Progress: ${accountsProcessed}/${allAccounts.length} accounts processed`);
      }
      
      // Safety check
      if (scraper.actionCount > SCRAPER_CONFIG.MAX_ACTIONS_PER_HOUR * 0.8) {
        log('⚠️  Approaching rate limit, stopping early');
        break;
      }
    }
    
    // Summary
    log('\n=====================================');
    log(`✅ Daily scraping complete`);
    log(`📊 Events found: ${totalEvents}`);
    log(`📈 Accounts processed: ${accountsProcessed}/${allAccounts.length}`);
    log(`🔢 Actions performed: ${scraper.actionCount}`);
    log(`📍 View data: https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
  } catch (error) {
    log('❌ Fatal error: ' + error.message);
  } finally {
    await scraper.cleanup();
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { RotatedInstagramScraper };