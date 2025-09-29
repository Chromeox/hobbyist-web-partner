#!/usr/bin/env node

const https = require('https');

const baseId = 'appo3x0WjbCIhA0Lz';
const apiKey = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';

async function testAPI() {
    console.log('🔍 Testing Airtable API connection...');
    
    const options = {
        hostname: 'api.airtable.com',
        path: `/v0/bases/${baseId}/tables`,
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Status: ${res.statusCode}`);
                console.log(`Response: ${body}`);
                
                if (res.statusCode === 200) {
                    console.log('✅ API connection successful!');
                    const data = JSON.parse(body);
                    console.log(`Found ${data.tables.length} existing tables`);
                } else {
                    console.log('❌ API connection failed');
                }
                resolve();
            });
        });

        req.on('error', (error) => {
            console.error('❌ Request failed:', error.message);
            reject(error);
        });

        req.end();
    });
}

async function createTable() {
    console.log('\n🏗️ Attempting to create Categories table...');
    
    const tableData = {
        name: "Categories",
        description: "Hobby class categories",
        fields: [
            { name: "Name", type: "singleLineText" },
            { name: "Description", type: "multilineText" }
        ]
    };

    const options = {
        hostname: 'api.airtable.com',
        path: `/v0/bases/${baseId}/tables`,
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => body += chunk);
            res.on('end', () => {
                console.log(`Create Table Status: ${res.statusCode}`);
                console.log(`Create Table Response: ${body}`);
                
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    console.log('✅ Table creation successful!');
                } else {
                    console.log('❌ Table creation failed');
                }
                resolve();
            });
        });

        req.on('error', (error) => {
            console.error('❌ Create request failed:', error.message);
            reject(error);
        });

        req.write(JSON.stringify(tableData));
        req.end();
    });
}

async function main() {
    try {
        await testAPI();
        await createTable();
    } catch (error) {
        console.error('Test failed:', error.message);
    }
}

main();