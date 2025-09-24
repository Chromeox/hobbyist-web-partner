#!/usr/bin/env node

// Apple OAuth Client Secret Generator for Supabase
// This generates the JWT token needed for SUPABASE_AUTH_EXTERNAL_APPLE_SECRET

const crypto = require('crypto');
const fs = require('fs');

console.log('🍎 Apple OAuth Secret Generator for Hobbyist App\n');

console.log('You need the following from Apple Developer Console:');
console.log('1. Team ID (found in Membership details)');
console.log('2. Service ID (the identifier you just created)');
console.log('3. Key ID (from the AuthKey you\'ll create)');
console.log('4. Private Key file (.p8 file from Apple)\n');

console.log('📱 Your current configuration:');
console.log('- App Bundle ID: com.hobbyist.app');
console.log('- Service ID should be: com.hobbyist.app.auth');
console.log('- Supabase Project: mcjqvdzdhtcvbrejvrtp');
console.log('- Return URL: https://mcjqvdzdhtcvbrejvrtp.supabase.co/auth/v1/callback\n');

console.log('🔑 Steps to get your secret:');
console.log('1. Go to: https://developer.apple.com/account/resources/authkeys/list');
console.log('2. Create a new key with "Sign In with Apple" enabled');
console.log('3. Download the .p8 file');
console.log('4. Come back and run: node generate-apple-secret.js <teamId> <serviceId> <keyId> <path-to-p8-file>');

if (process.argv.length === 6) {
    const [,, teamId, serviceId, keyId, keyPath] = process.argv;

    try {
        const privateKey = fs.readFileSync(keyPath, 'utf8');

        const header = {
            alg: 'ES256',
            kid: keyId
        };

        const payload = {
            iss: teamId,
            iat: Math.floor(Date.now() / 1000),
            exp: Math.floor(Date.now() / 1000) + (86400 * 180), // 180 days
            aud: 'https://appleid.apple.com',
            sub: serviceId
        };

        const token = generateJWT(header, payload, privateKey);

        console.log('\n✅ Apple OAuth Secret Generated!');
        console.log('\nAdd this to your .env.supabase file:');
        console.log(`SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=${token}`);

        // Update the .env file automatically
        const envPath = './.env.supabase';
        let envContent = fs.readFileSync(envPath, 'utf8');
        envContent = envContent.replace(
            /SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=.*/,
            `SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=${token}`
        );
        fs.writeFileSync(envPath, envContent);

        console.log('\n🎉 .env.supabase file updated automatically!');

    } catch (error) {
        console.error('❌ Error generating secret:', error.message);
    }
}

function generateJWT(header, payload, privateKey) {
    const encodedHeader = base64URLEncode(JSON.stringify(header));
    const encodedPayload = base64URLEncode(JSON.stringify(payload));

    const signingInput = `${encodedHeader}.${encodedPayload}`;
    const signature = crypto.sign('sha256', Buffer.from(signingInput), privateKey);
    const encodedSignature = signature.toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');

    return `${signingInput}.${encodedSignature}`;
}

function base64URLEncode(str) {
    return Buffer.from(str)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '');
}