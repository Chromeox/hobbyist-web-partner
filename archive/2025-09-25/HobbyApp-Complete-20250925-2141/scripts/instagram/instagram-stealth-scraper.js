/**
 * Instagram Stealth Scraper
 * Uses anti-detection techniques to avoid being logged out
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  SESSION_FILE: path.join(__dirname, '.instagram-session.json'),
  USER_DATA_DIR: path.join(__dirname, 'browser-data'),
};

// Test with just one account first
const TEST_ACCOUNTS = ['@rumbleboxingmp'];

class StealthInstagramScraper {
  constructor() {
    this.browser = null;
    this.context = null;
    this.page = null;
  }

  async initialize() {
    console.log('🚀 Starting Stealth Instagram Scraper\n');
    
    // Launch browser with anti-detection settings
    this.browser = await chromium.launch({
      headless: false,
      args: [
        '--disable-blink-features=AutomationControlled',
        '--disable-dev-shm-usage',
        '--no-sandbox',
        '--disable-web-security',
        '--disable-features=IsolateOrigins,site-per-process',
        '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      ]
    });
    
    // Create persistent context (like a normal browser profile)
    this.context = await this.browser.newContext({
      viewport: { width: 1280, height: 800 },
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      // Load saved session if it exists
      storageState: fs.existsSync(CONFIG.SESSION_FILE) 
        ? JSON.parse(fs.readFileSync(CONFIG.SESSION_FILE, 'utf8'))
        : undefined
    });
    
    this.page = await this.context.newPage();
    
    // Remove automation indicators
    await this.page.evaluateOnNewDocument(() => {
      // Override the navigator.webdriver property
      Object.defineProperty(navigator, 'webdriver', {
        get: () => undefined
      });
      
      // Override plugins to look more real
      Object.defineProperty(navigator, 'plugins', {
        get: () => [1, 2, 3, 4, 5]
      });
      
      // Override permissions
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );
    });
  }

  async randomDelay(min = 500, max = 2000) {
    const delay = Math.floor(Math.random() * (max - min + 1) + min);
    await this.page.waitForTimeout(delay);
  }

  async humanType(selector, text) {
    await this.page.click(selector);
    await this.randomDelay(200, 500);
    
    for (const char of text) {
      await this.page.keyboard.type(char);
      await this.page.waitForTimeout(Math.random() * 200 + 50);
    }
  }

  async login(username, password) {
    console.log('🔐 Attempting login...\n');
    
    // Navigate to Instagram
    await this.page.goto('https://www.instagram.com/', { 
      waitUntil: 'domcontentloaded',
      timeout: 30000 
    });
    
    await this.randomDelay(2000, 3000);
    
    // Check if already logged in
    const isLoggedIn = await this.checkIfLoggedIn();
    if (isLoggedIn) {
      console.log('✅ Already logged in from saved session!\n');
      await this.saveSession();
      return true;
    }
    
    // Look for login form
    const hasLoginForm = await this.page.$('input[name="username"]');
    if (!hasLoginForm) {
      console.log('No login form found, checking login status...');
      await this.randomDelay();
      const loggedIn = await this.checkIfLoggedIn();
      if (loggedIn) {
        console.log('✅ Logged in!\n');
        await this.saveSession();
        return true;
      }
      console.error('❌ Could not find login form');
      return false;
    }
    
    // Fill in credentials with human-like typing
    console.log('Typing username...');
    await this.humanType('input[name="username"]', username);
    
    await this.randomDelay(500, 1000);
    
    console.log('Typing password...');
    await this.humanType('input[name="password"]', password);
    
    await this.randomDelay(500, 1500);
    
    // Click login button
    console.log('Clicking login button...');
    const loginButton = await this.page.$('button[type="submit"]:has-text("Log in"), button[type="submit"] div:has-text("Log in")');
    if (loginButton) {
      await loginButton.click();
    } else {
      await this.page.click('button[type="submit"]');
    }
    
    console.log('Waiting for login to process...');
    await this.randomDelay(3000, 5000);
    
    // Check for errors
    const errorMessage = await this.page.$('#slfErrorAlert');
    if (errorMessage) {
      const errorText = await errorMessage.textContent();
      console.error('❌ Login error:', errorText);
      return false;
    }
    
    // Handle intermediate screens
    await this.handlePostLoginScreens();
    
    // Final verification
    await this.randomDelay(2000, 3000);
    const loggedIn = await this.checkIfLoggedIn();
    
    if (loggedIn) {
      console.log('✅ Successfully logged in!\n');
      await this.saveSession();
      return true;
    } else {
      console.error('❌ Login verification failed');
      await this.page.screenshot({ path: 'login-failed.png' });
      console.log('Screenshot saved as login-failed.png');
      return false;
    }
  }

  async checkIfLoggedIn() {
    // Multiple ways to check if logged in
    const selectors = [
      'svg[aria-label="Home"]',
      'a[href="/direct/inbox/"]',
      'a[href*="/explore"]',
      'div[role="main"] article',
      'nav a[href="/"]'
    ];
    
    for (const selector of selectors) {
      const element = await this.page.$(selector);
      if (element) {
        return true;
      }
    }
    
    // Check URL - if we're on the home feed
    const url = this.page.url();
    if (url === 'https://www.instagram.com/' && !url.includes('/accounts/')) {
      // Check if there's actual content
      const hasContent = await this.page.$('article, main[role="main"]');
      if (hasContent) {
        return true;
      }
    }
    
    return false;
  }

  async handlePostLoginScreens() {
    console.log('Handling post-login screens...');
    
    // Wait a moment for any popups to appear
    await this.randomDelay(1500, 2500);
    
    // Handle "Save Your Login Info?" screen
    const saveInfoButtons = await this.page.$$('button');
    for (const button of saveInfoButtons) {
      const text = await button.textContent();
      if (text && text.includes('Not Now')) {
        console.log('Clicking "Not Now" on save login screen...');
        await button.click();
        await this.randomDelay(1000, 2000);
        break;
      }
    }
    
    // Handle "Turn on Notifications?" popup
    await this.randomDelay(1000, 1500);
    const notificationButtons = await this.page.$$('button');
    for (const button of notificationButtons) {
      const text = await button.textContent();
      if (text && text.includes('Not Now')) {
        console.log('Clicking "Not Now" on notifications...');
        await button.click();
        await this.randomDelay(1000, 2000);
        break;
      }
    }
  }

  async saveSession() {
    const state = await this.context.storageState();
    fs.writeFileSync(CONFIG.SESSION_FILE, JSON.stringify(state, null, 2));
    console.log('💾 Session saved\n');
  }

  async scrapeTestAccount() {
    console.log('📸 Testing scrape of @rumbleboxingmp...\n');
    
    // Navigate to profile with random delay
    await this.randomDelay(2000, 3000);
    
    console.log('Navigating to profile...');
    await this.page.goto('https://www.instagram.com/rumbleboxingmp/', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });
    
    await this.randomDelay(3000, 4000);
    
    // Check if we can see posts
    const posts = await this.page.$$('article a[href*="/p/"]');
    console.log(`Found ${posts.length} posts`);
    
    if (posts.length === 0) {
      console.log('No posts found - checking if still logged in...');
      const loggedIn = await this.checkIfLoggedIn();
      console.log('Still logged in?', loggedIn);
      
      // Take screenshot for debugging
      await this.page.screenshot({ path: 'scrape-test.png' });
      console.log('Screenshot saved as scrape-test.png');
      return;
    }
    
    // Click on first post
    console.log('Clicking on first post...');
    await posts[0].click();
    await this.randomDelay(2000, 3000);
    
    // Get caption
    const caption = await this.page.$eval(
      'article h1 + div span',
      el => el.textContent
    ).catch(() => 'Caption not found');
    
    console.log('Caption preview:', caption.substring(0, 100) + '...');
    
    // Close modal
    await this.page.keyboard.press('Escape');
    await this.randomDelay(1000, 2000);
    
    // Send test event to Google Sheets
    const testEvent = {
      name: 'Boxing Class (Test)',
      studio: 'Rumble Boxing',
      location: 'Mount Pleasant',
      address: '2935 Main St, Vancouver, BC',
      date: new Date().toISOString().split('T')[0],
      time: '6:30 PM',
      price: '35',
      description: 'Test event from stealth scraper',
      original_caption: caption.substring(0, 200),
      instagram_url: 'https://www.instagram.com/rumbleboxingmp/',
      source: 'Instagram',
      confidence_score: 0.95
    };
    
    console.log('\n📤 Sending test event to Google Sheets...');
    
    try {
      const response = await fetch(CONFIG.WEB_APP_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(testEvent)
      });
      
      const result = await response.json();
      if (result.success) {
        console.log('✅ Test event sent successfully!');
        console.log(`View at: https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
      } else {
        console.log('❌ Failed to send:', result.error);
      }
    } catch (error) {
      console.error('❌ Error sending to sheets:', error.message);
    }
  }

  async cleanup() {
    console.log('\nKeeping browser open for 10 seconds to observe...');
    await this.page.waitForTimeout(10000);
    
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// Main execution
async function main() {
  const scraper = new StealthInstagramScraper();
  
  try {
    await scraper.initialize();
    
    // Get credentials
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    console.log('📝 Instagram Login\n');
    
    const username = await new Promise(resolve => {
      readline.question('Username/Email: ', resolve);
    });
    
    const password = await new Promise(resolve => {
      readline.question('Password: ', (answer) => {
        console.log(''); // New line after password
        resolve(answer);
      });
      // Hide password input
      readline._writeToOutput = function _writeToOutput(stringToWrite) {
        if (stringToWrite.includes('Password:')) {
          readline.output.write(stringToWrite);
        } else {
          readline.output.write('*');
        }
      };
    });
    
    readline.close();
    
    // Attempt login
    const loginSuccess = await scraper.login(username, password);
    
    if (loginSuccess) {
      // Test scraping
      await scraper.scrapeTestAccount();
    } else {
      console.error('\n❌ Could not complete login');
    }
    
  } catch (error) {
    console.error('Fatal error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// Run
if (require.main === module) {
  main();
}

module.exports = { StealthInstagramScraper };