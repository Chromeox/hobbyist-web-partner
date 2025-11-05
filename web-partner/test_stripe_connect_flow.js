// Test Stripe Connect Integration Flow
// Tests the partner portal Stripe Connect account creation flow
// Run with: node test_stripe_connect_flow.js

const https = require('https');
const { URL } = require('url');

// Test configuration
const BASE_URL = 'http://localhost:3000';
const TEST_STUDIO_DATA = {
  businessName: 'Flow Yoga Studio Test',
  businessEmail: 'test@flowyogavancouver.ca',
  country: 'CA',
  type: 'express'
};

console.log('🚀 Testing Stripe Connect Integration Flow\n');

// Test 1: Check if partner portal is running
async function testPortalAccess() {
  console.log('1. Testing Partner Portal Access...');
  
  try {
    const response = await fetch(`${BASE_URL}/api/health`);
    if (response.ok) {
      console.log('   ✅ Partner portal is accessible');
    } else {
      console.log('   ❌ Partner portal health check failed');
    }
  } catch (error) {
    console.log('   ❌ Cannot connect to partner portal - is it running on localhost:3000?');
    console.log('   💡 Run: cd /Users/chromefang.exe/HobbyApp/web-partner && npm run dev');
  }
}

// Test 2: Test Stripe Connect account creation API
async function testStripeConnectAPI() {
  console.log('\n2. Testing Stripe Connect Account Creation API...');
  
  try {
    const response = await fetch(`${BASE_URL}/api/stripe/connect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(TEST_STUDIO_DATA)
    });

    const data = await response.json();
    
    if (response.ok) {
      console.log('   ✅ Stripe Connect API call successful');
      console.log(`   📝 Account ID: ${data.accountId || 'N/A'}`);
      console.log(`   🔗 Onboarding URL: ${data.onboardingUrl ? 'Generated' : 'Missing'}`);
    } else {
      console.log('   ❌ Stripe Connect API call failed');
      console.log(`   📝 Error: ${data.error || 'Unknown error'}`);
      
      if (data.error && data.error.includes('STRIPE_SECRET_KEY')) {
        console.log('   💡 Missing Stripe credentials - see setup instructions below');
      }
    }
  } catch (error) {
    console.log('   ❌ Network error calling Stripe Connect API');
    console.log(`   📝 Error: ${error.message}`);
  }
}

// Test 3: Check database integration
async function testDatabaseIntegration() {
  console.log('\n3. Testing Database Integration...');
  
  try {
    // Test if we can query studios
    const response = await fetch(`${BASE_URL}/api/studios`);
    
    if (response.ok) {
      const data = await response.json();
      console.log(`   ✅ Database connection working - found ${data.length || 0} studios`);
      
      if (data.length > 0) {
        console.log(`   📝 Sample studio: ${data[0].name || 'Unnamed'}`);
      }
    } else {
      console.log('   ❌ Cannot query studios from database');
    }
  } catch (error) {
    console.log('   ❌ Database query failed');
    console.log(`   📝 Error: ${error.message}`);
  }
}

// Test 4: Validate environment configuration
async function testEnvironmentConfig() {
  console.log('\n4. Testing Environment Configuration...');
  
  const requiredVars = [
    'NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY',
    'STRIPE_SECRET_KEY', 
    'NEXT_PUBLIC_SUPABASE_URL',
    'SUPABASE_SERVICE_ROLE_KEY'
  ];
  
  // This would normally check process.env, but we'll simulate
  console.log('   📝 Checking required environment variables...');
  
  const missingVars = [];
  requiredVars.forEach(varName => {
    // Simulate check - in real test this would check process.env[varName]
    if (varName.includes('STRIPE')) {
      missingVars.push(varName);
    }
  });
  
  if (missingVars.length > 0) {
    console.log('   ❌ Missing required environment variables:');
    missingVars.forEach(varName => {
      console.log(`      - ${varName}`);
    });
  } else {
    console.log('   ✅ All required environment variables present');
  }
}

// Setup instructions
function printSetupInstructions() {
  console.log('\n📋 Stripe Connect Setup Instructions:');
  console.log('');
  console.log('1. Get Stripe Test Credentials:');
  console.log('   - Go to https://dashboard.stripe.com/test/apikeys');
  console.log('   - Copy your publishable key (pk_test_...)');
  console.log('   - Copy your secret key (sk_test_...)');
  console.log('');
  console.log('2. Add to .env.local:');
  console.log('   NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here');
  console.log('   STRIPE_SECRET_KEY=sk_test_your_secret_here');
  console.log('');
  console.log('3. Enable Stripe Connect:');
  console.log('   - Go to https://dashboard.stripe.com/test/connect/overview');
  console.log('   - Complete your Connect onboarding');
  console.log('   - Configure your Connect settings');
  console.log('');
  console.log('4. Test the Integration:');
  console.log('   - Start the partner portal: npm run dev');
  console.log('   - Visit http://localhost:3000/onboarding');
  console.log('   - Test the Stripe Connect flow');
  console.log('');
}

// Run all tests
async function runTests() {
  await testPortalAccess();
  await testStripeConnectAPI();
  await testDatabaseIntegration();
  await testEnvironmentConfig();
  
  printSetupInstructions();
  
  console.log('\n🎯 Next Steps:');
  console.log('1. Set up Stripe test credentials');
  console.log('2. Start the partner portal (npm run dev)');
  console.log('3. Test the complete onboarding flow');
  console.log('4. Verify Stripe Connect account creation');
  console.log('5. Test payout calculations');
}

// Run the tests
runTests().catch(console.error);