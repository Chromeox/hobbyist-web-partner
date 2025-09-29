/**
 * Instagram Scraper Using Your Chrome Profile
 * No login needed - uses your existing Chrome session
 */

const { chromium } = require('playwright');
const path = require('path');
const os = require('os');

// Configuration
const CONFIG = {
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  
  // Path to your Chrome profile
  CHROME_PROFILE_PATH: path.join(os.homedir(), 'Library/Application Support/Google/Chrome/Profile 2'),
  
  // Slower rate limit for safety
  RATE_LIMIT: 5000, // 5 seconds between accounts
  POST_DELAY: 3000, // 3 seconds between posts
};

// Instagram accounts to scrape
const INSTAGRAM_ACCOUNTS = [
  '@rumbleboxingmp',
  '@claymates.studio',
  '@yyoga',
  '@harbordance',
  '@dirtykitchenvancouver',
  '@f45_vancouver',
  '@makermakervancouver',
  '@choprayogacenter',
  '@vancoeverdance',
  '@barrefitvancouver',
  '@spinco_vancouver',
  '@4cats_vancouver',
  '@paintnitevancouver',
  '@cookculture_vancouver',
  '@pottersnook'
];

// Account profiles
const ACCOUNT_PROFILES = {
  '@rumbleboxingmp': {
    name: 'Rumble Boxing',
    address: '2935 Main St, Vancouver, BC V5T 3G5',
    defaultPrice: '35'
  },
  '@claymates.studio': {
    name: 'Claymates Studio',
    address: '3071 Main St, Vancouver, BC V5V 3P1',
    defaultPrice: '45'
  },
  '@yyoga': {
    name: 'YYoga',
    address: 'Vancouver, BC',
    defaultPrice: '25'
  },
  '@harbordance': {
    name: 'Harbour Dance',
    address: '927 Granville St, Vancouver, BC',
    defaultPrice: '20'
  },
  '@dirtykitchenvancouver': {
    name: 'Dirty Kitchen',
    address: 'Vancouver, BC',
    defaultPrice: '65'
  },
  '@f45_vancouver': {
    name: 'F45 Training',
    address: 'Vancouver, BC',
    defaultPrice: '35'
  },
  '@makermakervancouver': {
    name: 'Maker Maker',
    address: 'Vancouver, BC',
    defaultPrice: '40'
  }
};

class ChromeProfileScraper {
  constructor() {
    this.browser = null;
    this.context = null;
    this.page = null;
    this.eventsFound = [];
  }

  async initialize() {
    console.log('🚀 Starting Instagram Scraper with Chrome Profile\n');
    console.log('📂 Using profile:', CONFIG.CHROME_PROFILE_PATH);
    console.log('⚠️  IMPORTANT: Make sure Chrome is CLOSED before running!\n');
    
    try {
      // Launch Chrome with your profile - NOT Chromium
      const { chromium: chrome } = require('playwright');
      this.context = await chrome.launchPersistentContext(
        CONFIG.CHROME_PROFILE_PATH,
        {
          headless: false, // Must be false to use existing profile
          executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', // Use actual Chrome
          viewport: null, // Use default viewport
          args: [
            '--disable-blink-features=AutomationControlled',
            '--no-sandbox',
            '--disable-dev-shm-usage'
          ]
        }
      );
      
      // Get the first page or create new one
      const pages = this.context.pages();
      this.page = pages.length > 0 ? pages[0] : await this.context.newPage();
      
      console.log('✅ Chrome profile loaded successfully!\n');
      
    } catch (error) {
      if (error.message.includes('already running')) {
        console.error('❌ ERROR: Chrome is already running!');
        console.error('   Please close all Chrome windows and try again.\n');
      } else {
        console.error('❌ Failed to load Chrome profile:', error.message);
      }
      throw error;
    }
  }

  async checkLogin() {
    console.log('🔍 Checking Instagram login status...\n');
    
    // Go to Instagram
    await this.page.goto('https://www.instagram.com/', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });
    
    // Wait a moment for page to load
    await this.page.waitForTimeout(3000);
    
    // Check if logged in
    const isLoggedIn = await this.page.$('svg[aria-label="Home"], a[href="/direct/inbox/"], article');
    
    if (isLoggedIn) {
      console.log('✅ Already logged into Instagram!\n');
      return true;
    } else {
      console.log('❌ Not logged into Instagram');
      console.log('   Please log into Instagram manually in the browser window');
      console.log('   Then press Enter here to continue...\n');
      
      // Wait for user to log in manually
      await new Promise(resolve => {
        process.stdin.once('data', resolve);
      });
      
      return true;
    }
  }

  async scrapeAccount(username) {
    const profile = ACCOUNT_PROFILES[username] || { name: username.replace('@', '') };
    username = username.replace('@', '');
    
    console.log(`\n📸 Scraping @${username}...`);
    
    try {
      // Navigate to profile
      await this.page.goto(`https://www.instagram.com/${username}/`, {
        waitUntil: 'domcontentloaded',
        timeout: 30000
      });
      
      // Wait for content to load
      await this.page.waitForTimeout(3000);
      
      // Check for posts
      const posts = await this.page.$$('article a[href*="/p/"]');
      console.log(`  Found ${posts.length} posts`);
      
      if (posts.length === 0) {
        console.log('  No posts accessible');
        return [];
      }
      
      const events = [];
      const maxPosts = Math.min(3, posts.length); // Check first 3 posts
      
      for (let i = 0; i < maxPosts; i++) {
        console.log(`  Checking post ${i + 1}/${maxPosts}...`);
        
        // Click on post
        await posts[i].click();
        await this.page.waitForTimeout(2000);
        
        // Get caption - try multiple selectors
        let caption = '';
        const captionSelectors = [
          'article h1 + div span',
          'article div[dir="auto"] span',
          'div[role="dialog"] span[dir="auto"]',
          'h1 ~ div span'
        ];
        
        for (const selector of captionSelectors) {
          caption = await this.page.$eval(selector, el => el.textContent).catch(() => '');
          if (caption) break;
        }
        
        if (!caption) {
          console.log('    No caption found');
        } else {
          console.log(`    Caption: ${caption.substring(0, 50)}...`);
        }
        
        // Get image
        const imageUrl = await this.page.$eval(
          'article img[style*="object-fit"], div[role="dialog"] img',
          el => el.src
        ).catch(() => '');
        
        // Get post URL
        const postUrl = this.page.url();
        
        // Analyze if it's an event
        const eventData = this.analyzeCaption(caption, profile);
        
        if (eventData.isEvent) {
          const event = {
            name: eventData.name || `${profile.name} Class`,
            studio: profile.name || username,
            location: profile.name,
            address: profile.address || 'Vancouver, BC',
            date: eventData.date || this.getNextDate(),
            time: eventData.time || '7:00 PM',
            price: eventData.price || profile.defaultPrice || '30',
            description: this.cleanDescription(caption),
            original_caption: caption.substring(0, 500),
            instagram_url: postUrl,
            image_url: imageUrl,
            source: 'Instagram',
            confidence_score: eventData.confidence,
            indicators_found: eventData.indicators.join(', ')
          };
          
          events.push(event);
          console.log(`    ✅ Event detected: ${event.name}`);
        } else {
          console.log(`    ⏭️  Not an event (${eventData.confidence.toFixed(2)} confidence)`);
        }
        
        // Close post
        await this.page.keyboard.press('Escape');
        await this.page.waitForTimeout(CONFIG.POST_DELAY);
      }
      
      return events;
      
    } catch (error) {
      console.error(`  ❌ Error scraping @${username}:`, error.message);
      return [];
    }
  }

  analyzeCaption(caption, profile) {
    if (!caption) return { isEvent: false, confidence: 0, indicators: [] };
    
    const captionLower = caption.toLowerCase();
    const indicators = [];
    
    // Check for event indicators
    if (captionLower.match(/\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i)) {
      indicators.push('weekday');
    }
    if (captionLower.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}/i)) {
      indicators.push('date');
    }
    if (captionLower.match(/\d{1,2}(:\d{2})?\s*(am|pm)/i)) {
      indicators.push('time');
    }
    if (captionLower.match(/\$\d+|free/i)) {
      indicators.push('price');
    }
    if (captionLower.match(/class|workshop|session|event|bootcamp|training/i)) {
      indicators.push('event-keyword');
    }
    if (captionLower.match(/book|register|sign up|reserve|spots? available|limited/i)) {
      indicators.push('booking');
    }
    
    const confidence = indicators.length / 6;
    const isEvent = indicators.length >= 2; // At least 2 indicators
    
    // Determine event name
    let name = 'Workshop';
    if (profile.name && profile.name.includes('Boxing')) name = 'Boxing Class';
    else if (profile.name && profile.name.includes('Pottery')) name = 'Pottery Workshop';
    else if (profile.name && profile.name.includes('Yoga')) name = 'Yoga Session';
    else if (profile.name && profile.name.includes('Dance')) name = 'Dance Class';
    else if (profile.name && profile.name.includes('Kitchen')) name = 'Cooking Class';
    else if (profile.name && profile.name.includes('F45')) name = 'F45 Training Session';
    
    // Extract date if present
    const dateMatch = caption.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2})/i);
    const date = dateMatch ? this.parseDate(dateMatch[0]) : null;
    
    // Extract time if present
    const timeMatch = caption.match(/(\d{1,2})(:\d{2})?\s*(am|pm)/i);
    const time = timeMatch ? timeMatch[0].toUpperCase() : null;
    
    // Extract price if present
    const priceMatch = caption.match(/\$(\d+)/);
    const price = priceMatch ? priceMatch[1] : null;
    
    return {
      isEvent,
      confidence,
      indicators,
      name,
      date,
      time,
      price
    };
  }

  parseDate(dateStr) {
    const months = {
      jan: '01', feb: '02', mar: '03', apr: '04',
      may: '05', jun: '06', jul: '07', aug: '08',
      sep: '09', oct: '10', nov: '11', dec: '12'
    };
    
    const match = dateStr.toLowerCase().match(/(\w{3})\w*\s+(\d{1,2})/);
    if (match) {
      const month = months[match[1].substring(0, 3)];
      const day = match[2].padStart(2, '0');
      const year = new Date().getFullYear();
      return `${year}-${month}-${day}`;
    }
    return null;
  }

  getNextDate() {
    const date = new Date();
    date.setDate(date.getDate() + 7);
    return date.toISOString().split('T')[0];
  }

  cleanDescription(caption) {
    if (!caption) return '';
    return caption
      .substring(0, 200)
      .replace(/[@#]\w+/g, '')
      .replace(/\s+/g, ' ')
      .trim();
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
        console.log(`    📤 Sent to Google Sheets`);
        return true;
      } else {
        console.error(`    ❌ Failed to send:`, result.error);
        return false;
      }
    } catch (error) {
      console.error(`    ❌ Error sending:`, error.message);
      return false;
    }
  }

  async cleanup() {
    if (this.context) {
      await this.context.close();
    }
  }
}

// Main execution
async function main() {
  const scraper = new ChromeProfileScraper();
  
  try {
    // Initialize with Chrome profile
    await scraper.initialize();
    
    // Check if logged into Instagram
    const loggedIn = await scraper.checkLogin();
    
    if (!loggedIn) {
      console.log('Please log into Instagram first');
      return;
    }
    
    // Scrape accounts
    console.log('🎯 Starting to scrape accounts...');
    console.log('=====================================');
    
    let totalEvents = 0;
    let successCount = 0;
    
    for (const account of INSTAGRAM_ACCOUNTS) {
      const events = await scraper.scrapeAccount(account);
      
      // Send events to Google Sheets
      for (const event of events) {
        const sent = await scraper.sendToGoogleSheets(event);
        if (sent) successCount++;
        totalEvents++;
      }
      
      // Rate limiting between accounts
      console.log(`  Waiting ${CONFIG.RATE_LIMIT/1000} seconds before next account...`);
      await scraper.page.waitForTimeout(CONFIG.RATE_LIMIT);
    }
    
    // Summary
    console.log('\n=====================================');
    console.log('📊 SCRAPING COMPLETE');
    console.log('=====================================');
    console.log(`✅ Events found: ${totalEvents}`);
    console.log(`📤 Sent to sheets: ${successCount}`);
    console.log(`📍 View your data:`);
    console.log(`   https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
  } finally {
    console.log('\n🔚 Closing browser...');
    await scraper.cleanup();
  }
}

// Run
if (require.main === module) {
  main();
}

module.exports = { ChromeProfileScraper };