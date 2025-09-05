/**
 * Test Web App Connection
 * Verifies that Playwright can send data to Google Sheets
 */

const CONFIG = {
  WEB_APP_URL: 'https://script.google.com/macros/s/AKfycbzOUDxHQiKqoVOjicCHiFP4-6UO5DbunB4-QZgrdvbKjgRj_ITyG6O-eWyV5O62oD8Ntw/exec',
  SPREADSHEET_ID: '14eJ3FmupDb3SrXhLywN9gjanFC8bzL4N4mgs9fodq_w',
};

async function testWebApp() {
  console.log('🧪 Testing Web App connection...\n');
  console.log(`📊 Sheet ID: ${CONFIG.SPREADSHEET_ID}`);
  console.log(`🌐 Web App: ${CONFIG.WEB_APP_URL.substring(0, 60)}...\n`);
  
  const testEvent = {
    name: 'Test Pottery Class from Playwright',
    studio: 'Test Studio',
    location: 'Test Location',
    address: '123 Test St, Vancouver',
    date: '2024-01-25',
    time: '6:00 PM',
    price: '75',
    original_caption: 'This is a test event sent from Playwright to verify the connection works',
    source: 'Test',
    tags: 'test, pottery, workshop',
    instagram_handle: '@test_account'
  };
  
  console.log('📤 Sending test event...');
  
  try {
    const response = await fetch(CONFIG.WEB_APP_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testEvent),
    });
    
    const result = await response.json();
    
    if (result.success) {
      console.log('\n✅ SUCCESS! Web App connection working!');
      console.log('📊 Check your sheet: https://docs.google.com/spreadsheets/d/' + CONFIG.SPREADSHEET_ID);
      console.log('\n🎯 Next steps:');
      console.log('1. Check "Events Staging" tab for the test event');
      console.log('2. Run the full scraper: node hobby-directory-scraper.js');
    } else {
      console.log('\n❌ Connection failed:', result.error);
    }
  } catch (error) {
    console.log('\n❌ Error:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('1. Check that the Web App is deployed');
    console.log('2. Verify "Anyone" can access it');
    console.log('3. Make sure the URL is correct');
  }
}

testWebApp();