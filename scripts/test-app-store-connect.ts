/**
 * Test script for App Store Connect API
 * Run with: npx tsx scripts/test-app-store-connect.ts
 */

import { config } from 'dotenv';
import { resolve } from 'path';

// Load environment variables from .env.local
config({ path: resolve(__dirname, '../.env.local') });

// Now import the service (after env is loaded)
async function main() {
  console.log('\n🍎 App Store Connect API Test\n');
  console.log('='.repeat(50));

  // Check environment variables
  console.log('\n📋 Environment Check:');
  console.log(`  KEY_ID: ${process.env.APP_STORE_CONNECT_KEY_ID ? '✅ Set' : '❌ Missing'}`);
  console.log(`  ISSUER_ID: ${process.env.APP_STORE_CONNECT_ISSUER_ID ? '✅ Set' : '❌ Missing'}`);
  console.log(`  PRIVATE_KEY: ${process.env.APP_STORE_CONNECT_PRIVATE_KEY ? '✅ Set (' + process.env.APP_STORE_CONNECT_PRIVATE_KEY.length + ' chars)' : '❌ Missing'}`);

  if (!process.env.APP_STORE_CONNECT_KEY_ID ||
      !process.env.APP_STORE_CONNECT_ISSUER_ID ||
      !process.env.APP_STORE_CONNECT_PRIVATE_KEY) {
    console.log('\n❌ Missing required environment variables. Exiting.');
    process.exit(1);
  }

  // Dynamically import the service
  const {
    testConnection,
    getApps,
    getAppByBundleId,
    isConfigured
  } = await import('../lib/services/app-store-connect');

  console.log('\n📡 Testing API Connection...\n');

  // Test 1: Check if configured
  console.log('Test 1: Configuration Check');
  const configured = isConfigured();
  console.log(`  Result: ${configured ? '✅ Configured' : '❌ Not Configured'}`);

  // Test 2: Test connection
  console.log('\nTest 2: API Connection');
  try {
    const result = await testConnection();
    console.log(`  Success: ${result.success ? '✅' : '❌'}`);
    console.log(`  Message: ${result.message}`);
    if (result.apps) {
      console.log(`  Apps found: ${result.apps.length}`);
      result.apps.forEach((app, i) => {
        console.log(`    ${i + 1}. ${app.attributes.name} (${app.attributes.bundleId})`);
      });
    }
  } catch (error) {
    console.log(`  ❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }

  // Test 3: Get specific app
  console.log('\nTest 3: Get Hobbyist App');
  try {
    const app = await getAppByBundleId('com.hobbyist.bookingapp');
    if (app) {
      console.log(`  ✅ Found: ${app.attributes.name}`);
      console.log(`  Bundle ID: ${app.attributes.bundleId}`);
      console.log(`  SKU: ${app.attributes.sku}`);
    } else {
      console.log('  ⚠️ App not found (may not be created in App Store Connect yet)');
    }
  } catch (error) {
    console.log(`  ❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }

  console.log('\n' + '='.repeat(50));
  console.log('Test complete!\n');
}

main().catch(console.error);
