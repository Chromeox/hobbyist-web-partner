#!/usr/bin/env node

const https = require('https');
const apiKey = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';

// Test 1: List all bases accessible to this token
async function listBases() {
    console.log('🔍 Testing: List accessible bases...');
    
    const options = {
        hostname: 'api.airtable.com',
        path: '/v0/meta/bases',
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                if (res.statusCode === 200) {
                    const data = JSON.parse(body);
                    console.log('✅ Found accessible bases:');
                    data.bases.forEach(base => {
                        console.log(`  • ${base.name} (${base.id})`);
                    });
                } else {
                    console.log(`❌ Failed: ${body}`);
                }
                resolve();
            });
        });
        req.on('error', (error) => console.error('Request failed:', error.message));
        req.end();
    });
}

// Test 2: Try with the specific base ID
async function testSpecificBase() {
    const baseId = 'appo3x0WjbCIhA0Lz';
    console.log(`\n🔍 Testing specific base: ${baseId}`);
    
    const options = {
        hostname: 'api.airtable.com',
        path: `/v0/meta/bases/${baseId}/tables`,
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                if (res.statusCode === 200) {
                    const data = JSON.parse(body);
                    console.log('✅ Base accessible! Tables found:');
                    data.tables.forEach(table => {
                        console.log(`  • ${table.name} (${table.id})`);
                    });
                } else {
                    console.log(`❌ Base not accessible: ${body}`);
                }
                resolve();
            });
        });
        req.on('error', (error) => console.error('Request failed:', error.message));
        req.end();
    });
}

async function main() {
    await listBases();
    await testSpecificBase();
}

main();