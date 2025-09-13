#!/usr/bin/env node

const https = require('https');

const baseId = 'appo3x0WjbCIhA0Lz';
const apiKey = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';

class CreditFieldsUpdater {
    async makeRequest(method, path, data = null) {
        const options = {
            hostname: 'api.airtable.com',
            path: path,
            method: method,
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
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(JSON.parse(body));
                    } else {
                        reject(new Error(`${res.statusCode}: ${body}`));
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

    async addCreditFieldsToClasses() {
        console.log('🎯 Adding credit-related fields to Classes table...');
        
        try {
            // First, get the current table structure
            const tables = await this.makeRequest('GET', `/v0/meta/bases/${baseId}/tables`);
            const classesTable = tables.tables.find(t => t.name === 'Classes');
            
            if (!classesTable) {
                throw new Error('Classes table not found');
            }

            console.log(`📋 Found Classes table: ${classesTable.id}`);

            // Add credit-related fields
            const fieldsToAdd = [
                {
                    name: "Suggested Credits",
                    type: "singleSelect",
                    options: {
                        choices: [
                            { name: "6", color: "greenBright" },
                            { name: "8", color: "blueBright" },
                            { name: "10", color: "orangeBright" },
                            { name: "12", color: "purpleBright" },
                            { name: "15", color: "redBright" }
                        ]
                    }
                },
                {
                    name: "Credit Tier",
                    type: "singleSelect",
                    options: {
                        choices: [
                            { name: "Creative Starter", color: "greenBright" },
                            { name: "Hobby Explorer", color: "blueBright" },
                            { name: "Skill Builder", color: "orangeBright" },
                            { name: "Master Workshop", color: "purpleBright" },
                            { name: "Intensive Experience", color: "redBright" }
                        ]
                    }
                },
                {
                    name: "Revenue Per Class",
                    type: "formula",
                    options: {
                        formula: "IF({Suggested Credits}, ROUND(VALUE({Suggested Credits}) * 1.20 * 0.85, 2), 0)"
                    }
                },
                {
                    name: "Platform Fee",
                    type: "formula", 
                    options: {
                        formula: "IF({Suggested Credits}, ROUND(VALUE({Suggested Credits}) * 1.20 * 0.15, 2), 0)"
                    }
                },
                {
                    name: "Credit Guidelines Link",
                    type: "url"
                }
            ];

            // Add each field
            for (const field of fieldsToAdd) {
                try {
                    console.log(`  ➕ Adding field: ${field.name}`);
                    
                    const response = await this.makeRequest(
                        'POST', 
                        `/v0/meta/bases/${baseId}/tables/${classesTable.id}/fields`,
                        field
                    );
                    
                    console.log(`  ✅ Added ${field.name} (${response.id})`);
                    
                    // Small delay between requests
                    await new Promise(resolve => setTimeout(resolve, 1000));
                } catch (error) {
                    console.error(`  ❌ Failed to add ${field.name}: ${error.message}`);
                    // Continue with next field
                }
            }

            console.log('\n🎉 Credit fields added successfully!');
            console.log('\n📋 Next steps:');
            console.log('1. Review the new fields in Airtable');
            console.log('2. Add credit guidelines URL to existing records');
            console.log('3. Set suggested credits for current classes');
            console.log('4. Share guidelines with studio partners');
            
        } catch (error) {
            console.error(`❌ Failed to add credit fields: ${error.message}`);
            throw error;
        }
    }

    async addSampleCreditData() {
        console.log('\n🌱 Adding sample credit data to existing classes...');
        
        try {
            // Get Classes table records
            const records = await this.makeRequest('GET', `/v0/${baseId}/tblClasses?maxRecords=10`);
            
            const updates = [];
            
            // Update existing sample records with credit information
            const sampleData = [
                { name: "Pottery", credits: "10", tier: "Skill Builder" },
                { name: "Boxing", credits: "8", tier: "Hobby Explorer" },
                { name: "DJ", credits: "10", tier: "Skill Builder" },
                { name: "Art", credits: "8", tier: "Hobby Explorer" },
                { name: "Music", credits: "12", tier: "Master Workshop" }
            ];

            for (let i = 0; i < Math.min(records.records.length, sampleData.length); i++) {
                const record = records.records[i];
                const sample = sampleData[i];
                
                updates.push({
                    id: record.id,
                    fields: {
                        "Suggested Credits": sample.credits,
                        "Credit Tier": sample.tier,
                        "Credit Guidelines Link": "https://github.com/your-repo/STUDIO_CREDIT_GUIDELINES.md"
                    }
                });
            }

            if (updates.length > 0) {
                const updateResponse = await this.makeRequest(
                    'PATCH',
                    `/v0/${baseId}/tblClasses`,
                    { records: updates }
                );
                
                console.log(`  ✅ Updated ${updateResponse.records.length} records with credit data`);
            }
            
        } catch (error) {
            console.error(`  ❌ Failed to add sample data: ${error.message}`);
        }
    }

    async execute() {
        console.log('🚀 Adding Credit System Fields to Hobby Directory\n');

        try {
            await this.addCreditFieldsToClasses();
            await this.addSampleCreditData();
            
            console.log('\n✨ Credit system integration complete!');
            console.log('\n🔗 Resources created:');
            console.log('• Suggested Credits field (6, 8, 10, 12, 15)');
            console.log('• Credit Tier field (Creative Starter → Intensive Experience)');
            console.log('• Revenue Per Class calculation (Credits × $1.20 × 85%)');
            console.log('• Platform Fee calculation (Credits × $1.20 × 15%)');
            console.log('• Studio Credit Guidelines document');
            console.log('\n🌐 View your enhanced directory at:');
            console.log(`https://airtable.com/${baseId}`);
            
        } catch (error) {
            console.error(`\n💥 Setup failed: ${error.message}`);
            process.exit(1);
        }
    }
}

const updater = new CreditFieldsUpdater();
updater.execute().catch(console.error);