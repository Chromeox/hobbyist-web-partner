/**
 * Debug script for App Store Connect JWT generation
 * Run with: npx tsx scripts/debug-jwt.ts
 */

import { config } from 'dotenv';
import { resolve } from 'path';
import { SignJWT, importPKCS8, decodeJwt } from 'jose';

// Load environment variables from .env.local
config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  console.log('\n🔐 JWT Debug for App Store Connect\n');
  console.log('='.repeat(60));

  const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
  const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
  const privateKey = process.env.APP_STORE_CONNECT_PRIVATE_KEY;

  console.log('\n📋 Raw Values:');
  console.log(`  KEY_ID: "${keyId}"`);
  console.log(`  ISSUER_ID: "${issuerId}"`);
  console.log(`  PRIVATE_KEY length: ${privateKey?.length || 0} chars`);
  console.log(`  PRIVATE_KEY starts with: ${privateKey?.substring(0, 30)}...`);
  console.log(`  PRIVATE_KEY ends with: ...${privateKey?.substring(privateKey.length - 30)}`);

  if (!keyId || !issuerId || !privateKey) {
    console.log('\n❌ Missing required values');
    return;
  }

  // Check if the key has proper newlines
  console.log('\n🔍 Private Key Analysis:');
  console.log(`  Contains literal \\n: ${privateKey.includes('\\n')}`);
  console.log(`  Contains actual newlines: ${privateKey.includes('\n')}`);
  console.log(`  Starts with BEGIN: ${privateKey.trim().startsWith('-----BEGIN')}`);
  console.log(`  Ends with END: ${privateKey.trim().endsWith('-----')}`);

  // Try to parse and fix the key if needed
  let normalizedKey = privateKey;

  // If it has literal \n instead of actual newlines, replace them
  if (privateKey.includes('\\n')) {
    normalizedKey = privateKey.replace(/\\n/g, '\n');
    console.log('\n⚠️ Replaced literal \\\\n with actual newlines');
  }

  console.log('\n📝 Normalized Key Preview:');
  console.log(normalizedKey.substring(0, 100));
  console.log('...');

  try {
    console.log('\n🔑 Attempting to import private key...');
    const key = await importPKCS8(normalizedKey, 'ES256');
    console.log('  ✅ Key imported successfully');

    console.log('\n📝 Generating JWT...');
    const now = Math.floor(Date.now() / 1000);
    const token = await new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: keyId, typ: 'JWT' })
      .setIssuer(issuerId)
      .setIssuedAt(now)
      .setExpirationTime(now + 20 * 60)
      .setAudience('appstoreconnect-v1')
      .sign(key);

    console.log('  ✅ JWT generated successfully');
    console.log(`\n📦 JWT Token (first 100 chars):\n  ${token.substring(0, 100)}...`);

    // Decode and show the payload
    const decoded = decodeJwt(token);
    console.log('\n📋 Decoded JWT Payload:');
    console.log(JSON.stringify(decoded, null, 2));

    // Test the token with Apple's API
    console.log('\n🍎 Testing with App Store Connect API...');
    const response = await fetch('https://api.appstoreconnect.apple.com/v1/apps', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    });

    console.log(`  Response status: ${response.status}`);
    const data = await response.json();
    console.log(`  Response body: ${JSON.stringify(data).substring(0, 500)}`);

  } catch (error) {
    console.log(`\n❌ Error: ${error instanceof Error ? error.message : 'Unknown'}`);
    console.log(error);
  }

  console.log('\n' + '='.repeat(60) + '\n');
}

main().catch(console.error);
