/**
 * Simple Instagram Scraper with File-Based Credentials
 * Reads login from .env.instagram file
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  CREDENTIALS_FILE: path.join(__dirname, '.env.instagram'),
  HEADLESS: false, // Set to true to hide browser
  RATE_LIMIT: 4000, // 4 seconds between actions
};

// Instagram accounts
const INSTAGRAM_ACCOUNTS = [
  '@rumbleboxingmp',
  '@claymates.studio',
  '@yyoga',
  '@harbordance',
  '@dirtykitchenvancouver'
];

// Account profiles
const PROFILES = {
  '@rumbleboxingmp': {
    name: 'Rumble Boxing',
    address: '2935 Main St, Vancouver, BC V5T 3G5',
    price: '35'
  },
  '@claymates.studio': {
    name: 'Claymates Studio',
    address: '3071 Main St, Vancouver, BC V5V 3P1',
    price: '45'
  },
  '@yyoga': {
    name: 'YYoga',
    address: 'Vancouver, BC',
    price: '25'
  },
  '@harbordance': {
    name: 'Harbour Dance',
    address: '927 Granville St, Vancouver, BC',
    price: '20'
  },
  '@dirtykitchenvancouver': {
    name: 'Dirty Kitchen',
    address: 'Vancouver, BC',
    price: '65'
  }
};

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
    
    if (!creds.INSTAGRAM_USERNAME || !creds.INSTAGRAM_PASSWORD) {
      console.error('❌ Please fill in your Instagram credentials in .env.instagram file');
      console.error('   Edit the file at:', CONFIG.CREDENTIALS_FILE);
      process.exit(1);
    }
    
    return creds;
  } catch (error) {
    console.error('❌ Could not read credentials file:', CONFIG.CREDENTIALS_FILE);
    console.error('   Please make sure the file exists and has your login details');
    process.exit(1);
  }
}

async function scrapeInstagram() {
  console.log('🚀 Simple Instagram Scraper\n');
  
  // Load credentials
  const creds = loadCredentials();
  console.log('✅ Credentials loaded from .env.instagram\n');
  
  const browser = await chromium.launch({
    headless: CONFIG.HEADLESS,
    args: ['--disable-blink-features=AutomationControlled']
  });
  
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });
  
  const page = await context.newPage();
  
  try {
    // Go to Instagram
    console.log('🔐 Logging into Instagram...');
    await page.goto('https://www.instagram.com/', { waitUntil: 'networkidle' });
    
    // Wait for and fill login form
    await page.waitForSelector('input[name="username"]', { timeout: 10000 });
    await page.fill('input[name="username"]', creds.INSTAGRAM_USERNAME);
    await page.fill('input[name="password"]', creds.INSTAGRAM_PASSWORD);
    
    // Click login
    await page.click('button[type="submit"]');
    
    // Wait for login to complete
    await page.waitForTimeout(5000);
    
    // Handle any popups
    const notNowButton = await page.$('button:has-text("Not Now")');
    if (notNowButton) {
      await notNowButton.click();
      await page.waitForTimeout(2000);
    }
    
    // Check if logged in
    const homeFeed = await page.$('svg[aria-label="Home"], article');
    if (!homeFeed) {
      console.error('❌ Login failed - check your credentials');
      await page.screenshot({ path: 'login-failed.png' });
      return;
    }
    
    console.log('✅ Logged in successfully!');
    
    // Browse home feed first (more natural)
    console.log('📱 Browsing home feed for a moment...\n');
    await page.waitForTimeout(5000);
    
    // Scroll a bit to seem human
    await page.evaluate(() => window.scrollBy(0, 300));
    await page.waitForTimeout(2000);
    
    // Scrape each account
    let totalEvents = 0;
    const processedPosts = new Set(); // Track processed posts to avoid duplicates
    
    for (const account of INSTAGRAM_ACCOUNTS) {
      const username = account.replace('@', '');
      const profile = PROFILES[account] || {};
      
      console.log(`📸 Scraping @${username}...`);
      
      // Navigate to profile with retry logic
      try {
        await page.goto(`https://www.instagram.com/${username}/`, { 
          waitUntil: 'domcontentloaded',  // Changed from networkidle
          timeout: 15000 
        });
      } catch (error) {
        console.log(`  ⚠️  Timeout loading profile, retrying...`);
        await page.waitForTimeout(3000);
        await page.goto(`https://www.instagram.com/${username}/`, { 
          waitUntil: 'domcontentloaded',
          timeout: 15000 
        });
      }
      
      await page.waitForTimeout(3000);
      
      // Get posts - try multiple selectors
      let posts = await page.$$('article a[href*="/p/"]');
      
      if (posts.length === 0) {
        // Try alternative selector
        posts = await page.$$('a[href*="/p/"]');
      }
      
      console.log(`  Found ${posts.length} posts`);
      
      if (posts.length === 0) {
        // Take screenshot to debug
        await page.screenshot({ path: `debug-${username}.png` });
        console.log(`  📸 Screenshot saved as debug-${username}.png`);
        continue;
      }
      
      // Check first 2 posts
      for (let i = 0; i < Math.min(2, posts.length); i++) {
        console.log(`  Checking post ${i + 1}...`);
        
        // Click post
        await posts[i].click();
        await page.waitForTimeout(3000);
        
        // Get caption - look for the actual post caption
        let caption = '';
        
        // Wait for caption to load
        await page.waitForTimeout(1000);
        
        // Method 1: Try to find caption in the comments section (first comment is usually the caption)
        try {
          // Look for the caption which is usually after the username
          const elements = await page.$$('h2 + span, h3 + span');
          for (const element of elements) {
            const text = await element.textContent();
            if (text && text.length > 20 && !text.includes('followers')) {
              caption = text;
              break;
            }
          }
        } catch {}
        
        // Method 2: If no caption yet, get all spans
        if (!caption) {
          const allSpans = await page.$$eval('span', 
            elements => elements.map(el => el.textContent).filter(t => t && t.length > 30)
          ).catch(() => []);
          
          // Find first span that looks like a caption
          for (const text of allSpans) {
            if (text && 
                !text.includes('followers') &&
                !text.includes('posts') &&
                !text.includes('following') &&
                !text.includes('Photo shared') &&
                !text.includes('May be') &&
                !text.match(/^\d+$/) &&
                text.length > 30) {
              caption = text;
              break;
            }
          }
        }
        
        if (!caption) {
          console.log('    No caption found');
        } else {
          console.log(`    Caption preview: ${caption.substring(0, 50)}...`);
        }
        
        // Get image
        const imageUrl = await page.$eval(
          'article img[style*="object-fit"], div[role="dialog"] img',
          el => el.src
        ).catch(() => '');
        
        // Simple event detection - be more inclusive
        const captionLower = caption.toLowerCase();
        const hasEventIndicators = 
          captionLower.includes('class') ||
          captionLower.includes('workshop') ||
          captionLower.includes('join') ||
          captionLower.includes('tonight') ||
          captionLower.includes('tomorrow') ||
          captionLower.includes('today') ||
          captionLower.includes('session') ||
          captionLower.includes('training') ||
          caption.match(/\d{1,2}(:\d{2})?\s*(am|pm)/i) ||
          caption.match(/monday|tuesday|wednesday|thursday|friday|saturday|sunday/i);
        
        // Only send if it has event indicators
        if (hasEventIndicators && caption.length > 20) {
          // Create unique ID to prevent duplicates
          const postId = `${username}_${caption.substring(0, 30)}`;
          
          if (processedPosts.has(postId)) {
            console.log('    ⏭️  Skipping duplicate');
            await page.keyboard.press('Escape');
            await page.waitForTimeout(2000);
            continue;
          }
          
          processedPosts.add(postId);
          
          // Generate better event name based on caption
          let eventName = 'Class';
          if (captionLower.includes('boxing')) eventName = 'Boxing Class';
          else if (captionLower.includes('pottery')) eventName = 'Pottery Workshop';
          else if (captionLower.includes('yoga')) eventName = 'Yoga Session';
          else if (captionLower.includes('dance')) eventName = 'Dance Class';
          else if (captionLower.includes('bootcamp')) eventName = 'Bootcamp';
          else if (captionLower.includes('workshop')) eventName = 'Workshop';
          else if (captionLower.includes('cooking')) eventName = 'Cooking Class';
          
          // Extract time if present
          const timeMatch = caption.match(/(\d{1,2})(:\d{2})?\s*(am|pm)/i);
          const eventTime = timeMatch ? timeMatch[0].toUpperCase() : '7:00 PM';
          
          // Extract date if present
          let eventDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          const dateMatch = caption.match(/\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{1,2})/i);
          if (dateMatch) {
            // Parse the date from caption
            const months = {jan:'01',feb:'02',mar:'03',apr:'04',may:'05',jun:'06',
                          jul:'07',aug:'08',sep:'09',oct:'10',nov:'11',dec:'12'};
            const month = months[dateMatch[1].substring(0,3).toLowerCase()];
            const day = dateMatch[2].padStart(2, '0');
            eventDate = `2025-${month}-${day}`;
          }
          
          const event = {
            name: eventName,
            studio: profile.name || username,
            location: profile.name || username,
            address: profile.address || 'Vancouver, BC',
            date: eventDate,
            time: eventTime,
            price: profile.price || '30',
            description: caption.substring(0, 200).replace(/[@#]\w+/g, '').trim(),
            original_caption: caption.substring(0, 500),
            instagram_url: page.url(),
            image_url: imageUrl,
            source: 'Instagram',
            confidence_score: 0.75
          };
          
          // Send to Google Sheets
          try {
            const response = await fetch(CONFIG.WEB_APP_URL, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(event)
            });
            
            const result = await response.json();
            if (result.success) {
              console.log(`  ✅ Event sent to Google Sheets`);
              totalEvents++;
            }
          } catch (error) {
            console.error(`  ❌ Failed to send event:`, error.message);
          }
        }
        
        // Close post
        await page.keyboard.press('Escape');
        await page.waitForTimeout(2000);
      }
      
      // Wait between accounts
      await page.waitForTimeout(CONFIG.RATE_LIMIT);
    }
    
    console.log('\n=====================================');
    console.log(`✅ Scraping complete!`);
    console.log(`📊 Events found and sent: ${totalEvents}`);
    console.log(`📍 View in Google Sheets:`);
    console.log(`   https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    await page.screenshot({ path: 'error-screenshot.png' });
  } finally {
    await browser.close();
  }
}

// Run
scrapeInstagram();