/**
 * Single Account Test Scraper
 * Tests with just Rumble Boxing to verify data mapping
 */

const { chromium } = require('playwright');

// YOUR GOOGLE SHEETS WEB APP URL
const WEB_APP_URL = 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec';

async function testSingleAccount() {
  console.log('🧪 Testing Single Account: @rumbleboxingmp');
  console.log('=====================================\n');
  
  const browser = await chromium.launch({ 
    headless: false,
    args: ['--no-sandbox']
  });
  
  try {
    const page = await browser.newPage();
    
    // Go to Rumble Boxing Instagram
    const url = 'https://www.instagram.com/rumbleboxingmp/';
    console.log(`Opening ${url}...`);
    await page.goto(url, { waitUntil: 'networkidle' });
    
    // Wait for posts to load
    await page.waitForTimeout(3000);
    
    // Get first post
    const posts = await page.$$('article a[href*="/p/"]');
    
    if (posts.length === 0) {
      console.log('No posts found');
      return;
    }
    
    console.log(`Found ${posts.length} posts, checking first one...\n`);
    
    // Click first post
    await posts[0].click();
    await page.waitForTimeout(2000);
    
    // Extract caption
    const caption = await page.$eval(
      'h1', 
      el => el.nextElementSibling?.textContent || ''
    ).catch(() => '');
    
    console.log('Caption:', caption.substring(0, 100) + '...\n');
    
    // Create test event with EXPLICIT field names
    const testEvent = {
      name: 'Boxing Class',  // NOT a UUID
      studio: 'Rumble Boxing',
      location: 'Rumble Boxing Mount Pleasant',
      address: '2935 Main St, Vancouver, BC V5T 3G5',  // This goes in address column
      date: '2025-01-20',  // This goes in Event Date column
      time: '6:30 PM',
      price: '35',  // Will get $ added by Apps Script
      description: 'High-energy boxing workout',
      original_caption: caption,
      instagram_url: url,
      source: 'Instagram',
      confidence_score: 0.95,
      indicators_found: 'Manual test entry'
    };
    
    console.log('Sending to Google Sheets:');
    console.log('- name:', testEvent.name);
    console.log('- address:', testEvent.address);
    console.log('- date:', testEvent.date);
    console.log('- price:', testEvent.price);
    console.log('\n');
    
    // Send to Google Sheets
    const response = await fetch(WEB_APP_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testEvent)
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('✅ SUCCESS! Event added to Google Sheets');
      console.log('\n📊 Now check your Google Sheet:');
      console.log('- Name column should show: "Boxing Class"');
      console.log('- Address column should show: "2935 Main St..."');
      console.log('- Event Date should show: "2025-01-20"');
      console.log('- Price should show: "$35" (with dollar sign)');
    } else {
      console.log('❌ FAILED:', result.error);
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await browser.close();
  }
}

// Run the test
testSingleAccount();