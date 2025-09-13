#!/usr/bin/env node

/**
 * Hobby Classes Directory - Airtable Table Creator
 * Creates tables and fields in an existing Airtable base
 */

const https = require('https');
const readline = require('readline');

class AirtableTableCreator {
    constructor(apiKey) {
        this.apiKey = apiKey;
        this.baseUrl = 'https://api.airtable.com/v0';
    }

    async makeRequest(method, endpoint, data = null) {
        const options = {
            hostname: 'api.airtable.com',
            path: endpoint,
            method: method,
            headers: {
                'Authorization': `Bearer ${this.apiKey}`,
                'Content-Type': 'application/json'
            }
        };

        return new Promise((resolve, reject) => {
            const req = https.request(options, (res) => {
                let body = '';
                res.on('data', (chunk) => body += chunk);
                res.on('end', () => {
                    try {
                        const response = JSON.parse(body);
                        if (res.statusCode >= 400) {
                            reject(new Error(`API Error ${res.statusCode}: ${JSON.stringify(response)}`));
                        } else {
                            resolve(response);
                        }
                    } catch (e) {
                        reject(new Error(`Failed to parse response: ${body}`));
                    }
                });
            });

            req.on('error', reject);
            
            if (data) {
                req.write(JSON.stringify(data));
            }
            req.end();
        });
    }

    async createTable(baseId, tableData) {
        console.log(`Creating table: ${tableData.name}...`);
        
        try {
            const response = await this.makeRequest('POST', `/v0/bases/${baseId}/tables`, tableData);
            console.log(`✅ Created table: ${tableData.name}`);
            return response;
        } catch (error) {
            console.error(`❌ Failed to create table ${tableData.name}: ${error.message}`);
            throw error;
        }
    }

    getTableDefinitions() {
        return [
            {
                name: "Categories",
                description: "Hobby class categories",
                fields: [
                    { name: "Name", type: "singleLineText" },
                    { name: "Description", type: "multilineText" },
                    { name: "Color", type: "singleLineText" },
                    { name: "Icon", type: "singleLineText" },
                    { name: "Sort Order", type: "number" }
                ]
            },
            {
                name: "Locations", 
                description: "Vancouver locations and neighborhoods",
                fields: [
                    { name: "Name", type: "singleLineText" },
                    { name: "Neighborhood", type: "singleLineText" },
                    { name: "Address", type: "singleLineText" },
                    { name: "Postal Code", type: "singleLineText" },
                    { name: "Transit", type: "multipleSelects", options: { choices: [
                        { name: "SkyTrain" }, { name: "Bus" }, { name: "SeaBus" }
                    ]}}
                ]
            },
            {
                name: "Studios",
                description: "Partner studios and instructors", 
                fields: [
                    { name: "Name", type: "singleLineText" },
                    { name: "Description", type: "multilineText" },
                    { name: "Email", type: "email" },
                    { name: "Phone", type: "phoneNumber" },
                    { name: "Website", type: "url" },
                    { name: "Instagram", type: "singleLineText" },
                    { name: "Partnership Tier", type: "singleSelect", options: { choices: [
                        { name: "Premium", color: "purpleBright" },
                        { name: "Standard", color: "blueBright" },
                        { name: "Basic", color: "grayBright" }
                    ]}},
                    { name: "Commission Rate", type: "percent" }
                ]
            },
            {
                name: "Classes",
                description: "Main hobby class listings",
                fields: [
                    { name: "Name", type: "singleLineText" },
                    { name: "Description", type: "multilineText" },
                    { name: "Date", type: "date", options: { includeTime: true }},
                    { name: "Duration (hours)", type: "number", options: { precision: 1 }},
                    { name: "Price", type: "currency", options: { symbol: "CAD" }},
                    { name: "Max Students", type: "number" },
                    { name: "Current Students", type: "number" },
                    { name: "Instructor", type: "singleLineText" },
                    { name: "Difficulty", type: "singleSelect", options: { choices: [
                        { name: "Beginner" }, { name: "Intermediate" }, { name: "Advanced" }, { name: "All Levels" }
                    ]}},
                    { name: "Status", type: "singleSelect", options: { choices: [
                        { name: "Active", color: "greenBright" },
                        { name: "Full", color: "orangeBright" },
                        { name: "Cancelled", color: "redBright" },
                        { name: "Draft", color: "grayBright" }
                    ]}},
                    { name: "Booking URL", type: "url" },
                    { name: "Image URL", type: "url" },
                    { name: "Tags", type: "multipleSelects", options: { choices: [
                        { name: "Beginner Friendly" }, { name: "Drop-in" }, 
                        { name: "Materials Included" }, { name: "Weekend" }, { name: "Evening" }
                    ]}}
                ]
            },
            {
                name: "User Submissions",
                description: "Community class suggestions",
                fields: [
                    { name: "Type", type: "singleSelect", options: { choices: [
                        { name: "New Class" }, { name: "Studio Suggestion" }, { name: "Update" }
                    ]}},
                    { name: "Submitter Name", type: "singleLineText" },
                    { name: "Submitter Email", type: "email" },
                    { name: "Class Name", type: "singleLineText" },
                    { name: "Studio Name", type: "singleLineText" },
                    { name: "Details", type: "multilineText" },
                    { name: "Website", type: "url" },
                    { name: "Status", type: "singleSelect", options: { choices: [
                        { name: "Pending", color: "yellowBright" },
                        { name: "Approved", color: "greenBright" },
                        { name: "Rejected", color: "redBright" }
                    ]}},
                    { name: "Review Notes", type: "multilineText" },
                    { name: "Submitted", type: "createdTime" }
                ]
            }
        ];
    }

    async createAllTables(baseId) {
        console.log('🚀 Creating Hobby Directory tables...\n');
        
        const tables = this.getTableDefinitions();
        const results = [];
        
        for (const tableData of tables) {
            try {
                const result = await this.createTable(baseId, tableData);
                results.push(result);
                
                // Small delay between requests
                await new Promise(resolve => setTimeout(resolve, 1000));
            } catch (error) {
                console.error(`Failed to create ${tableData.name}:`, error.message);
                // Continue with other tables
            }
        }
        
        console.log('\n✅ Table creation complete!');
        console.log('\n📋 Next steps:');
        console.log('1. Add relationships between tables manually');
        console.log('2. Import sample data');
        console.log('3. Set up Webflow CMS collections');
        console.log('4. Configure WhaleSync integration');
        
        return results;
    }
}

async function main() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    function ask(question) {
        return new Promise(resolve => rl.question(question, resolve));
    }

    console.log('🎨 Hobby Classes Directory - Table Creator');
    console.log('==========================================\n');
    
    console.log('⚠️  MANUAL SETUP REQUIRED FIRST:');
    console.log('1. Go to https://airtable.com');
    console.log('2. Create new base called "Hobby Classes Directory"');
    console.log('3. Delete the default table');
    console.log('4. Copy the base ID from URL (starts with "app...")');
    console.log('5. Get your API token from https://airtable.com/create/tokens\n');

    const baseId = await ask('Enter your Airtable Base ID (app...): ');
    if (!baseId || !baseId.startsWith('app')) {
        console.log('❌ Invalid base ID format');
        rl.close();
        return;
    }

    const apiKey = await ask('Enter your API token (pat...): ');
    if (!apiKey || !apiKey.startsWith('pat')) {
        console.log('❌ Invalid API token format');
        rl.close();
        return;
    }

    rl.close();

    const creator = new AirtableTableCreator(apiKey);
    
    try {
        await creator.createAllTables(baseId);
        console.log(`\n🎉 Success! Base URL: https://airtable.com/${baseId}`);
    } catch (error) {
        console.error('\n💥 Setup failed:', error.message);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = AirtableTableCreator;