/**
 * Apple JWT Client Secret Generator
 * Run this script to generate the JWT token needed for Apple OAuth
 */

const fs = require('fs');
const jwt = require('jsonwebtoken');

// Configuration - Your Apple Developer credentials
const config = {
  teamId: '594BDWKT53',               // Team ID from Quantum Hobbyist Group Inc.
  clientId: 'com.hobbyist.partner-portal.web', // Your Services ID
  keyId: 'JMAWKVZS8P',                // Key ID from your downloaded private key
  privateKeyPath: './AuthKey_JMAWKVZS8P.p8' // Path to your downloaded .p8 file
};

function generateAppleClientSecret() {
  try {
    // Read the private key
    const privateKey = fs.readFileSync(config.privateKeyPath, 'utf8');

    // Create JWT payload with proper timing
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: config.teamId,
      iat: now,
      exp: now + (86400 * 179), // 179 days to be safe (max is 180)
      aud: 'https://appleid.apple.com',
      sub: config.clientId,
    };

    // Sign the JWT
    const token = jwt.sign(payload, privateKey, {
      algorithm: 'ES256',
      header: {
        kid: config.keyId,
        typ: 'JWT'
      }
    });

    console.log('✅ Apple Client Secret Generated Successfully!');
    console.log('');
    console.log('Add this to your .env.local file:');
    console.log('APPLE_CLIENT_SECRET=' + token);
    console.log('');
    console.log('⚠️  Important: This token expires in 180 days');
    console.log('   You\'ll need to regenerate it before:', new Date(Date.now() + (86400 * 180 * 1000)).toDateString());

    return token;

  } catch (error) {
    console.error('❌ Error generating Apple Client Secret:');
    console.error(error.message);
    process.exit(1);
  }
}

// Check if jsonwebtoken is installed
try {
  require('jsonwebtoken');
} catch (error) {
  console.error('❌ Missing dependency: jsonwebtoken');
  console.log('Run: npm install jsonwebtoken');
  process.exit(1);
}

// Generate the secret
generateAppleClientSecret();