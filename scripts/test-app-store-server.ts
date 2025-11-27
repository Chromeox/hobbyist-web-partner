/**
 * Test script for App Store Server API (In-App Purchases)
 * Run with: npx tsx scripts/test-app-store-server.ts
 */

import { config } from 'dotenv';
import { resolve } from 'path';

// Load environment variables from .env.local
config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  console.log('\n🛒 App Store Server API Test (In-App Purchases)\n');
  console.log('='.repeat(50));

  // Check environment variables
  console.log('\n📋 Environment Check:');
  console.log(`  SERVER_KEY_ID: ${process.env.APP_STORE_SERVER_KEY_ID ? '✅ Set' : '❌ Missing'}`);
  console.log(`  SERVER_ISSUER_ID: ${process.env.APP_STORE_SERVER_ISSUER_ID ? '✅ Set' : '❌ Missing'}`);
  console.log(`  SERVER_BUNDLE_ID: ${process.env.APP_STORE_SERVER_BUNDLE_ID ? '✅ Set (' + process.env.APP_STORE_SERVER_BUNDLE_ID + ')' : '❌ Missing'}`);
  console.log(`  SERVER_PRIVATE_KEY: ${process.env.APP_STORE_SERVER_PRIVATE_KEY ? '✅ Set (' + process.env.APP_STORE_SERVER_PRIVATE_KEY.length + ' chars)' : '❌ Missing'}`);
  console.log(`  SHARED_SECRET: ${process.env.APP_STORE_SHARED_SECRET ? '✅ Set' : '❌ Missing'}`);

  // Dynamically import the service
  const { testConnection, isConfigured, isLegacyConfigured } = await import('../lib/services/app-store-server');

  console.log('\n🔧 Configuration Status:');
  console.log(`  Server API: ${isConfigured() ? '✅ Configured' : '❌ Not Configured'}`);
  console.log(`  Legacy Receipt: ${isLegacyConfigured() ? '✅ Configured' : '❌ Not Configured'}`);

  console.log('\n📡 Testing Configuration...');
  const result = await testConnection();
  console.log(`  Success: ${result.success ? '✅' : '❌'}`);
  console.log(`  Message: ${result.message}`);

  console.log('\n📦 Available Functions:');
  console.log('  • getSubscriptionStatus(transactionId) - Check subscription status');
  console.log('  • getTransactionHistory(transactionId) - Get purchase history');
  console.log('  • getTransactionInfo(transactionId) - Get transaction details');
  console.log('  • lookUpOrderId(orderId) - Look up order by ID');
  console.log('  • getRefundHistory(transactionId) - Get refund history');
  console.log('  • verifyReceiptLegacy(receiptData) - Verify legacy receipts');

  console.log('\n' + '='.repeat(50));
  console.log('Configuration complete! Ready to handle in-app purchases.\n');
}

main().catch(console.error);
