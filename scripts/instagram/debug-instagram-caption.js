/**
 * Debug script to find the correct caption selector
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Load credentials
function loadCredentials() {
  const content = fs.readFileSync(path.join(__dirname, '.env.instagram'), 'utf8');
  const lines = content.split('\n');
  const creds = {};
  
  lines.forEach(line => {
    if (line.includes('=') && !line.startsWith('#')) {
      const [key, value] = line.split('=');
      creds[key.trim()] = value.trim();
    }
  });
  
  return creds;
}

async function debugCaption() {
  const creds = loadCredentials();
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  
  console.log('🔍 Caption Debug Tool\n');
  
  // Login
  await page.goto('https://www.instagram.com/');
  await page.waitForSelector('input[name="username"]', { timeout: 10000 });
  await page.fill('input[name="username"]', creds.INSTAGRAM_USERNAME);
  await page.fill('input[name="password"]', creds.INSTAGRAM_PASSWORD);
  await page.click('button[type="submit"]');
  
  await page.waitForTimeout(5000);
  
  // Dismiss popups
  const notNow = await page.$('button:has-text("Not Now")');
  if (notNow) await notNow.click();
  
  console.log('✅ Logged in\n');
  
  // Go to a test account
  await page.goto('https://www.instagram.com/rumbleboxingmp/');
  await page.waitForTimeout(3000);
  
  // Click first post
  const posts = await page.$$('article a[href*="/p/"]');
  if (posts.length > 0) {
    console.log('📸 Opening first post...\n');
    await posts[0].click();
    await page.waitForTimeout(3000);
    
    // Try different methods to get caption
    console.log('🔍 Testing different caption selectors:\n');
    
    // Method 1: Look for the username followed by the caption
    try {
      const caption1 = await page.$eval(
        'h2 + span',
        el => el.textContent
      );
      console.log('Method 1 (h2 + span):', caption1?.substring(0, 50));
    } catch {
      console.log('Method 1: Not found');
    }
    
    // Method 2: Look in the comments section
    try {
      const caption2 = await page.$eval(
        'ul > div[role="button"] span',
        el => el.textContent
      );
      console.log('Method 2 (comments section):', caption2?.substring(0, 50));
    } catch {
      console.log('Method 2: Not found');
    }
    
    // Method 3: Get the first comment (usually the caption)
    try {
      const comments = await page.$$eval(
        'ul li[role="menuitem"] span, ul div[role="button"] span',
        elements => elements.map(el => el.textContent)
      );
      console.log('Method 3 (comments):', comments[0]?.substring(0, 50));
    } catch {
      console.log('Method 3: Not found');
    }
    
    // Method 4: Look for specific caption container
    try {
      const caption4 = await page.$eval(
        'article div h2 ~ span',
        el => el.textContent
      );
      console.log('Method 4 (article h2 ~ span):', caption4?.substring(0, 50));
    } catch {
      console.log('Method 4: Not found');
    }
    
    // Method 5: Get all spans and filter
    try {
      const allSpans = await page.$$eval(
        'span',
        elements => elements.map(el => ({
          text: el.textContent,
          hasLink: el.closest('a') !== null,
          parent: el.parentElement?.tagName
        }))
      );
      
      // Find spans that are long enough and not links
      const possibleCaptions = allSpans.filter(s => 
        s.text.length > 50 && 
        !s.hasLink && 
        !s.text.includes('followers') &&
        !s.text.includes('posts') &&
        !s.text.includes('Photo shared by')
      );
      
      console.log('\nPossible captions found:');
      possibleCaptions.slice(0, 3).forEach((s, i) => {
        console.log(`  ${i + 1}. ${s.text.substring(0, 50)}...`);
      });
    } catch (e) {
      console.log('Method 5: Error', e.message);
    }
    
    // Take screenshot for manual inspection
    await page.screenshot({ path: 'debug-caption.png' });
    console.log('\n📸 Screenshot saved as debug-caption.png');
  }
  
  console.log('\nKeeping browser open for 10 seconds...');
  await page.waitForTimeout(10000);
  
  await browser.close();
}

debugCaption();