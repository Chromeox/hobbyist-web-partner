/**
 * Instagram Scraper with Login
 * Secure version that logs in first, then scrapes
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// ============= CONFIGURATION =============

const CONFIG = {
  // Your Google Sheets Web App URL
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  
  // Browser settings
  HEADLESS: false,  // Keep false to see what's happening
  RATE_LIMIT: 3000, // 3 seconds between actions (safe for Instagram)
  
  // Session storage
  SESSION_FILE: path.join(__dirname, '.instagram-session.json'),
  
  // Event detection
  MIN_CONFIDENCE_SCORE: 0.6,
};

// Instagram accounts to scrape
const INSTAGRAM_ACCOUNTS = [
  '@rumbleboxingmp',
  '@claymates.studio',
  '@yyoga',
  '@harbordance',
  '@dirtykitchenvancouver'
];

// Account profiles for better extraction
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
  }
};

class InstagramLoginScraper {
  constructor() {
    this.browser = null;
    this.context = null;
    this.page = null;
  }

  async initialize() {
    console.log('🚀 Starting Instagram Scraper with Login\n');
    
    this.browser = await chromium.launch({
      headless: CONFIG.HEADLESS,
      slowMo: CONFIG.HEADLESS ? 0 : 100,
    });
    
    // Create context with saved session if available
    const sessionExists = fs.existsSync(CONFIG.SESSION_FILE);
    
    if (sessionExists) {
      console.log('📂 Loading saved session...');
      const sessionData = JSON.parse(fs.readFileSync(CONFIG.SESSION_FILE, 'utf8'));
      this.context = await this.browser.newContext({
        storageState: sessionData
      });
    } else {
      this.context = await this.browser.newContext();
    }
    
    this.page = await this.context.newPage();
  }

  async login(username, password) {
    console.log('🔐 Logging into Instagram...\n');
    
    // Go to Instagram
    await this.page.goto('https://www.instagram.com/', { waitUntil: 'networkidle' });
    
    // Check if already logged in by looking for home feed elements
    const homeFeed = await this.page.$('article, svg[aria-label="Home"], svg[aria-label="Search"]');
    if (homeFeed) {
      console.log('✅ Already logged in!\n');
      await this.saveSession();
      return true;
    }
    
    // Wait for login form
    try {
      await this.page.waitForSelector('input[name="username"]', { timeout: 10000 });
    } catch {
      console.log('Login form not found, checking if already logged in...');
      // Might be on a different page, try to navigate home
      await this.page.goto('https://www.instagram.com/', { waitUntil: 'networkidle' });
      const loggedIn = await this.page.$('article, svg[aria-label="Home"]');
      if (loggedIn) {
        console.log('✅ Already logged in!\n');
        await this.saveSession();
        return true;
      }
      return false;
    }
    
    // Fill login form
    console.log('Entering credentials...');
    await this.page.fill('input[name="username"]', username);
    await this.page.waitForTimeout(500); // Natural typing delay
    await this.page.fill('input[name="password"]', password);
    await this.page.waitForTimeout(500);
    
    // Click login button
    await this.page.click('button[type="submit"]');
    
    // Wait for navigation - could be to home feed or save login page
    console.log('Waiting for login to complete...');
    await this.page.waitForTimeout(3000);
    
    // Check for error message first
    const errorText = await this.page.$eval('#slfErrorAlert', el => el.textContent).catch(() => null);
    if (errorText) {
      console.error('❌ Login failed:', errorText);
      return false;
    }
    
    // Handle "Save Your Login Info?" page
    const saveLoginButton = await this.page.$('button:has-text("Save Info"), button:has-text("Not Now")');
    if (saveLoginButton) {
      console.log('Handling "Save Your Login Info?" prompt...');
      // Click "Not Now" to skip saving login
      const notNowButton = await this.page.$('button:has-text("Not Now")');
      if (notNowButton) {
        await notNowButton.click();
        await this.page.waitForTimeout(2000);
      }
    }
    
    // Handle "Turn on Notifications?" popup
    const notificationButton = await this.page.$('button:has-text("Turn On"), button:has-text("Not Now")');
    if (notificationButton) {
      console.log('Handling notifications prompt...');
      const notNowButton = await this.page.$('button:has-text("Not Now")');
      if (notNowButton) {
        await notNowButton.click();
        await this.page.waitForTimeout(2000);
      }
    }
    
    // Final check - are we on the home feed?
    const finalCheck = await this.page.$('article, svg[aria-label="Home"], svg[aria-label="Search"], a[href="/explore/"]');
    if (finalCheck) {
      console.log('✅ Login successful!\n');
      await this.saveSession();
      return true;
    }
    
    // If we're still not logged in, take a screenshot for debugging
    await this.page.screenshot({ path: 'login-debug.png' });
    console.error('❌ Login failed: Could not verify login success');
    console.error('   Screenshot saved as login-debug.png for debugging');
    
    return false;
  }

  async saveSession() {
    const state = await this.context.storageState();
    fs.writeFileSync(CONFIG.SESSION_FILE, JSON.stringify(state, null, 2));
    console.log('💾 Session saved for future use\n');
  }

  async handlePopups() {
    // Handle "Save Your Login Info?" popup
    const notNowButton = await this.page.$('button:has-text("Not Now")');
    if (notNowButton) {
      await notNowButton.click();
      await this.page.waitForTimeout(1000);
    }
    
    // Handle "Turn on Notifications?" popup
    const notNowButton2 = await this.page.$('button:has-text("Not Now")');
    if (notNowButton2) {
      await notNowButton2.click();
      await this.page.waitForTimeout(1000);
    }
  }

  async scrapeAccount(username) {
    const profile = ACCOUNT_PROFILES[username] || {};
    username = username.replace('@', '');
    
    console.log(`\n📸 Scraping @${username}...`);
    
    try {
      // Navigate to profile
      await this.page.goto(`https://www.instagram.com/${username}/`, { 
        waitUntil: 'networkidle',
        timeout: 30000 
      });
      
      // Wait for posts to load
      await this.page.waitForTimeout(2000);
      
      // Get posts
      const posts = await this.page.$$('article a[href*="/p/"]');
      console.log(`  Found ${posts.length} posts`);
      
      if (posts.length === 0) {
        console.log('  No posts found');
        return [];
      }
      
      const events = [];
      
      // Check first 3 posts
      for (let i = 0; i < Math.min(3, posts.length); i++) {
        console.log(`  Checking post ${i + 1}...`);
        
        // Click on post
        await posts[i].click();
        await this.page.waitForTimeout(2000);
        
        // Extract caption
        const caption = await this.page.$eval(
          'h1', 
          el => {
            const captionEl = el.nextElementSibling;
            return captionEl ? captionEl.textContent : '';
          }
        ).catch(() => '');
        
        // Extract image
        const imageUrl = await this.page.$eval(
          'article img[style*="object-fit"]',
          el => el.src
        ).catch(() => '');
        
        // Get post URL
        const postUrl = this.page.url();
        
        // Analyze if it's an event
        const eventData = this.analyzePost(caption, profile);
        
        if (eventData.isEvent) {
          events.push({
            name: eventData.name || `${profile.name} Event`,
            studio: profile.name || username,
            location: profile.name,
            address: profile.address || 'Vancouver, BC',
            date: eventData.date || this.getNextWeekday(),
            time: eventData.time || '7:00 PM',
            price: eventData.price || profile.defaultPrice || '30',
            description: this.generateDescription(caption, profile.name),
            original_caption: caption.substring(0, 500),
            instagram_url: postUrl,
            image_url: imageUrl,
            source: 'Instagram',
            confidence_score: eventData.confidence,
            indicators_found: eventData.indicators.join(', ')
          });
          
          console.log(`    ✅ Event detected: ${eventData.name}`);
        } else {
          console.log(`    ⏭️  Not an event (confidence: ${eventData.confidence})`);
        }
        
        // Close post modal
        await this.page.keyboard.press('Escape');
        await this.page.waitForTimeout(CONFIG.RATE_LIMIT);
      }
      
      return events;
      
    } catch (error) {
      console.error(`  Error scraping @${username}:`, error.message);
      return [];
    }
  }

  analyzePost(caption, profile) {
    const captionLower = caption.toLowerCase();
    const indicators = [];
    
    // Check for event indicators
    if (captionLower.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}/i)) {
      indicators.push('date');
    }
    if (captionLower.match(/\d{1,2}(:\d{2})?\s*(am|pm)/i)) {
      indicators.push('time');
    }
    if (captionLower.match(/\$\d+|\d+\s*dollars?|free/i)) {
      indicators.push('price');
    }
    if (captionLower.match(/class|workshop|session|event|bootcamp/i)) {
      indicators.push('event-keyword');
    }
    if (captionLower.match(/sign up|register|book|reserve|spots? available/i)) {
      indicators.push('booking');
    }
    if (captionLower.match(/join us|come|don't miss|limited/i)) {
      indicators.push('call-to-action');
    }
    
    const confidence = indicators.length / 6;
    const isEvent = indicators.length >= 2;
    
    // Extract event details
    let name = 'Workshop';
    if (captionLower.includes('boxing')) name = 'Boxing Class';
    else if (captionLower.includes('pottery')) name = 'Pottery Workshop';
    else if (captionLower.includes('yoga')) name = 'Yoga Session';
    else if (captionLower.includes('dance')) name = 'Dance Class';
    else if (captionLower.includes('cooking')) name = 'Cooking Class';
    
    // Extract date
    const dateMatch = caption.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2})/i);
    const date = dateMatch ? this.parseDate(dateMatch[0]) : null;
    
    // Extract time
    const timeMatch = caption.match(/(\d{1,2})(:\d{2})?\s*(am|pm)/i);
    const time = timeMatch ? timeMatch[0].toUpperCase() : null;
    
    // Extract price
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

  getNextWeekday() {
    const date = new Date();
    date.setDate(date.getDate() + 7);
    return date.toISOString().split('T')[0];
  }

  generateDescription(caption, studio) {
    const words = caption.split(' ').slice(0, 30).join(' ');
    return `Join ${studio} for an exciting experience. ${words}...`;
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
        console.log(`    📤 Sent to Google Sheets: ${event.name}`);
      } else {
        console.error(`    ❌ Failed to send: ${result.error}`);
      }
    } catch (error) {
      console.error(`    ❌ Error sending to sheets:`, error.message);
    }
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// ============= MAIN EXECUTION =============

async function main() {
  const scraper = new InstagramLoginScraper();
  
  try {
    await scraper.initialize();
    
    // Get credentials from user
    console.log('📝 Please enter your Instagram credentials');
    console.log('   (Your password will not be displayed)\n');
    
    // For testing, we'll prompt for credentials
    // In production, you'd store these securely
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    const username = await new Promise(resolve => {
      readline.question('Instagram username/email: ', resolve);
    });
    
    const password = await new Promise(resolve => {
      // Hide password input
      readline.question('Instagram password: ', (answer) => {
        console.log(''); // New line after password
        resolve(answer);
      });
      readline._writeToOutput = function _writeToOutput(stringToWrite) {
        if (stringToWrite.includes('Instagram password:')) {
          readline.output.write(stringToWrite);
        } else {
          readline.output.write('*');
        }
      };
    });
    
    readline.close();
    
    // Login
    const loginSuccess = await scraper.login(username, password);
    
    if (!loginSuccess) {
      console.error('Failed to login. Please check your credentials.');
      return;
    }
    
    // Scrape accounts
    console.log('\n🎯 Starting to scrape accounts...');
    console.log('=====================================');
    
    let totalEvents = 0;
    
    for (const account of INSTAGRAM_ACCOUNTS) {
      const events = await scraper.scrapeAccount(account);
      
      // Send events to Google Sheets
      for (const event of events) {
        await scraper.sendToGoogleSheets(event);
        totalEvents++;
      }
      
      // Rate limiting between accounts
      await scraper.page.waitForTimeout(CONFIG.RATE_LIMIT);
    }
    
    console.log('\n=====================================');
    console.log(`✅ Scraping complete!`);
    console.log(`📊 Total events found: ${totalEvents}`);
    console.log(`📍 View in Google Sheets:`);
    console.log(`   https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
  } catch (error) {
    console.error('Fatal error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { InstagramLoginScraper };