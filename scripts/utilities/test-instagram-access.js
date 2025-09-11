/**
 * Test Instagram Access
 * Check if Instagram is blocking or requiring login
 */

const { chromium } = require('playwright');

async function testAccess() {
  console.log('🔍 Testing Instagram access...\n');
  
  const browser = await chromium.launch({ 
    headless: false,  // Show browser to see what's happening
    slowMo: 100      // Slow down for visibility
  });
  
  try {
    const page = await browser.newPage();
    
    console.log('Opening Instagram profile: @rumbleboxingmp');
    await page.goto('https://www.instagram.com/rumbleboxingmp/', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    console.log('Waiting for page to load...');
    await page.waitForTimeout(3000);
    
    // Check page title
    const title = await page.title();
    console.log('Page title:', title);
    
    // Check for login prompt
    const loginButton = await page.$('button:has-text("Log in")');
    if (loginButton) {
      console.log('⚠️  Instagram is showing login prompt');
    }
    
    // Check for posts
    const posts = await page.$$('article a[href*="/p/"]');
    console.log('Posts found:', posts.length);
    
    // Check for "No posts yet" message
    const noPosts = await page.$('text="No Posts Yet"');
    if (noPosts) {
      console.log('⚠️  Profile shows "No Posts Yet"');
    }
    
    // Try to get follower count
    const followers = await page.$eval(
      'a[href*="/followers/"] span', 
      el => el.textContent
    ).catch(() => 'Not found');
    console.log('Followers:', followers);
    
    // Take screenshot for debugging
    await page.screenshot({ path: 'instagram-test.png' });
    console.log('\n📸 Screenshot saved as instagram-test.png');
    
    console.log('\nKeeping browser open for 10 seconds...');
    await page.waitForTimeout(10000);
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await browser.close();
    console.log('\n✅ Test complete');
  }
}

testAccess();