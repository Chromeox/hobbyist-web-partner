/**
 * Hobby Directory Instagram Scraper
 * Configured for your Google Sheets
 * 
 * Setup:
 * npm install playwright dotenv
 * node hobby-directory-scraper.js
 */

const { chromium } = require('playwright');

// ============= YOUR CONFIGURATION =============

const CONFIG = {
  // Your Google Sheets Web App URL
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  
  // Your Google Sheets ID (for reference)
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
  
  // Target Instagram accounts
  INSTAGRAM_ACCOUNTS: [
    '@rumbleboxingmp',
    '@claymates.studio',
    // Add more accounts here as needed
  ],
  
  // Rate limiting
  DELAY_BETWEEN_REQUESTS: 3000, // 3 seconds between requests
  
  // Browser settings
  HEADLESS: true, // Set to false to see the browser
};

// ============= INSTAGRAM SCRAPER =============

class InstagramScraper {
  constructor() {
    this.browser = null;
    this.eventsFound = [];
  }

  async initialize() {
    console.log('🚀 Starting Instagram Scraper...');
    this.browser = await chromium.launch({
      headless: CONFIG.HEADLESS,
      slowMo: CONFIG.HEADLESS ? 0 : 100, // Slow down actions when visible
    });
    console.log('✅ Browser launched');
  }

  async scrapeProfile(username) {
    const page = await this.browser.newPage();
    
    try {
      // Clean username
      username = username.replace('@', '');
      console.log(`\n📸 Scraping @${username}...`);
      
      // Navigate to Instagram profile
      const url = `https://www.instagram.com/${username}/`;
      await page.goto(url, {
        waitUntil: 'networkidle',
        timeout: 30000,
      });
      
      // Wait for content to load
      await page.waitForTimeout(2000);
      
      // Check if page loaded correctly
      const pageTitle = await page.title();
      if (pageTitle.includes('Page Not Found')) {
        console.log(`❌ Profile @${username} not found`);
        await page.close();
        return [];
      }
      
      // Extract profile bio
      const profileData = await page.evaluate(() => {
        // Get bio text
        const bioElement = document.querySelector('div.-vDIg > span');
        const bio = bioElement ? bioElement.textContent : '';
        
        // Get follower count
        const followerElement = document.querySelector('a[href*="/followers/"] span');
        const followers = followerElement ? followerElement.textContent : '0';
        
        // Get website link from bio
        const websiteElement = document.querySelector('a[rel="me"]');
        const website = websiteElement ? websiteElement.href : '';
        
        return { bio, followers, website };
      });
      
      console.log(`  ✓ Bio: ${profileData.bio.substring(0, 50)}...`);
      console.log(`  ✓ Followers: ${profileData.followers}`);
      
      // Extract recent posts
      const posts = await this.extractPosts(page, username, profileData);
      
      await page.close();
      return posts;
      
    } catch (error) {
      console.error(`❌ Error scraping @${username}:`, error.message);
      await page.close();
      return [];
    }
  }

  async extractPosts(page, username, profileData) {
    const events = [];
    
    try {
      // Get post links
      const postData = await page.evaluate(() => {
        const posts = [];
        const postElements = document.querySelectorAll('article a[href*="/p/"]');
        
        // Get first 6 posts
        for (let i = 0; i < Math.min(6, postElements.length); i++) {
          const post = postElements[i];
          const img = post.querySelector('img');
          
          if (img) {
            posts.push({
              url: post.href,
              imageUrl: img.src,
              caption: img.alt || '',
            });
          }
        }
        
        return posts;
      });
      
      console.log(`  ✓ Found ${postData.length} recent posts`);
      
      // Process each post to extract event information
      for (const post of postData) {
        const eventInfo = this.parseEventFromPost(post, username, profileData);
        if (eventInfo) {
          events.push(eventInfo);
          console.log(`  ✓ Extracted event: ${eventInfo.name}`);
        }
      }
      
    } catch (error) {
      console.error(`  ⚠️ Error extracting posts:`, error.message);
    }
    
    return events;
  }

  parseEventFromPost(post, username, profileData) {
    const caption = post.caption.toLowerCase();
    
    // Keywords that indicate an event
    const eventKeywords = [
      'class', 'workshop', 'session', 'event', 'join us',
      'book now', 'register', 'spots available', 'limited space',
      'tomorrow', 'tonight', 'this week', 'saturday', 'sunday',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday'
    ];
    
    // Check if caption contains event indicators
    const isEvent = eventKeywords.some(keyword => caption.includes(keyword));
    
    if (!isEvent && caption.length < 50) {
      return null; // Probably not an event
    }
    
    // Extract date patterns
    const datePattern = /(\d{1,2}[\/\-]\d{1,2})|(\w+ \d{1,2}(?:st|nd|rd|th)?)|tomorrow|tonight/i;
    const timePattern = /(\d{1,2}(?::\d{2})?\s*(?:am|pm))/i;
    const pricePattern = /\$(\d+(?:\.\d{2})?)/;
    
    const dateMatch = post.caption.match(datePattern);
    const timeMatch = post.caption.match(timePattern);
    const priceMatch = post.caption.match(pricePattern);
    
    // Generate event name from username and caption
    let eventName = '';
    if (username.includes('rumble')) {
      eventName = 'Boxing Class';
    } else if (username.includes('claymates')) {
      eventName = 'Pottery Workshop';
    } else {
      // Extract first meaningful phrase from caption
      const firstLine = post.caption.split('\n')[0];
      eventName = firstLine.substring(0, 50).trim() || `Event from @${username}`;
    }
    
    // Extract location/studio name
    let studio = '';
    let location = '';
    if (username.includes('rumble')) {
      studio = 'Rumble Boxing';
      location = 'Rumble Boxing Mount Pleasant';
    } else if (username.includes('claymates')) {
      studio = 'Claymates Studio';
      location = 'Claymates Ceramic Studio';
    } else {
      studio = `@${username}`;
      location = `@${username}`;
    }
    
    return {
      name: eventName,
      studio: studio,
      location: location,
      address: '', // Will need to be added manually or from website
      date: dateMatch ? dateMatch[0] : '',
      time: timeMatch ? timeMatch[0] : '',
      price: priceMatch ? priceMatch[1] : '',
      original_caption: post.caption,
      instagram_url: post.url,
      image_url: post.imageUrl,
      instagram_handle: `@${username}`,
      instagram_bio: profileData.bio,
      instagram_followers: profileData.followers,
      website_url: profileData.website,
      source: 'Instagram',
      tags: this.extractTags(post.caption),
    };
  }

  extractTags(caption) {
    // Extract hashtags as tags
    const hashtags = caption.match(/#\w+/g) || [];
    
    // Add category tags based on content
    const tags = [];
    
    if (caption.toLowerCase().includes('boxing') || caption.toLowerCase().includes('rumble')) {
      tags.push('fitness', 'boxing');
    }
    if (caption.toLowerCase().includes('pottery') || caption.toLowerCase().includes('ceramic')) {
      tags.push('art', 'pottery', 'crafts');
    }
    if (caption.toLowerCase().includes('beginner')) {
      tags.push('beginner-friendly');
    }
    
    // Add hashtags (without the #)
    hashtags.forEach(tag => {
      tags.push(tag.replace('#', '').toLowerCase());
    });
    
    // Return unique tags
    return [...new Set(tags)].slice(0, 5).join(', ');
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
      console.log('✅ Browser closed');
    }
  }
}

// ============= GOOGLE SHEETS INTEGRATION =============

async function sendToGoogleSheets(eventData) {
  try {
    console.log(`\n📤 Sending to Google Sheets: ${eventData.name}`);
    
    const response = await fetch(CONFIG.WEB_APP_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(eventData),
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('  ✅ Successfully added to Google Sheets');
    } else {
      console.log('  ❌ Failed to add:', result.error);
    }
    
    return result;
  } catch (error) {
    console.error('  ❌ Error sending to Sheets:', error.message);
    return { success: false, error: error.message };
  }
}

// ============= MAIN EXECUTION =============

async function main() {
  console.log('🎯 Hobby Directory Instagram Scraper');
  console.log('=====================================');
  console.log(`📊 Google Sheet ID: ${CONFIG.SPREADSHEET_ID}`);
  console.log(`🌐 Web App URL: ${CONFIG.WEB_APP_URL.substring(0, 50)}...`);
  console.log(`📸 Target Accounts: ${CONFIG.INSTAGRAM_ACCOUNTS.join(', ')}`);
  console.log('=====================================\n');
  
  const scraper = new InstagramScraper();
  let totalEvents = 0;
  let successfulSends = 0;
  
  try {
    await scraper.initialize();
    
    // Scrape each Instagram account
    for (const account of CONFIG.INSTAGRAM_ACCOUNTS) {
      const events = await scraper.scrapeProfile(account);
      totalEvents += events.length;
      
      // Send each event to Google Sheets
      for (const event of events) {
        const result = await sendToGoogleSheets(event);
        if (result.success) {
          successfulSends++;
        }
        
        // Rate limiting
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      // Delay between accounts
      await new Promise(resolve => setTimeout(resolve, CONFIG.DELAY_BETWEEN_REQUESTS));
    }
    
    console.log('\n=====================================');
    console.log('📊 SCRAPING COMPLETE');
    console.log('=====================================');
    console.log(`✅ Total events found: ${totalEvents}`);
    console.log(`✅ Successfully sent to Sheets: ${successfulSends}`);
    console.log(`📍 View your data: https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
  } finally {
    await scraper.cleanup();
  }
}

// ============= TEST MODE =============

async function testWebApp() {
  console.log('🧪 Testing Web App connection...\n');
  
  const testEvent = {
    name: 'Test Event from Playwright',
    studio: 'Test Studio',
    location: 'Test Location',
    date: '2024-01-25',
    time: '6:00 PM',
    price: '75',
    original_caption: 'This is a test event from the Playwright scraper',
    source: 'Test',
  };
  
  const result = await sendToGoogleSheets(testEvent);
  
  if (result.success) {
    console.log('✅ Web App connection successful!');
    console.log(`📊 Check your sheet: https://docs.google.com/spreadsheets/d/${CONFIG.SPREADSHEET_ID}`);
  } else {
    console.log('❌ Web App connection failed:', result.error);
  }
}

// ============= RUN THE SCRAPER =============

// Uncomment ONE of these:

// Option 1: Test the Web App connection first
// testWebApp();

// Option 2: Run the full scraper
main();

// Option 3: Test with just one account
// CONFIG.INSTAGRAM_ACCOUNTS = ['@claymates.studio'];
// main();