/**
 * Test Scraper - Run 5 specific Instagram accounts
 * Mix of different types to verify data mapping
 */

const { chromium } = require('playwright');

// Import the main scraper configuration
const mainScript = require('./intelligent-instagram-scraper.js');

// Test with 5 diverse accounts
const TEST_ACCOUNTS = [
  '@rumbleboxingmp',    // Boxing
  '@claymates.studio',  // Pottery  
  '@yyoga',            // Yoga
  '@harbordance',      // Dance
  '@dirtykitchenvancouver' // Cooking
];

console.log('🧪 Testing 5 Instagram Accounts');
console.log('================================');
console.log('Accounts:', TEST_ACCOUNTS.join(', '));
console.log('================================\n');

// Run the test
async function testFiveAccounts() {
  // Call the main scraper with our test accounts
  const { main } = require('./intelligent-instagram-scraper.js');
  
  // This will use the existing configuration but only scrape these 5
  process.argv = ['node', 'test-5-accounts.js', ...TEST_ACCOUNTS];
  
  console.log('Starting scrape of 5 accounts...\n');
}

testFiveAccounts();