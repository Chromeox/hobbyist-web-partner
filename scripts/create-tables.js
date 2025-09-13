#!/usr/bin/env node

const https = require('https');

const baseId = 'appo3x0WjbCIhA0Lz';
const apiKey = 'patkZyDlb3grpvosY.79ae3e51397643e8ae689529b4727e54d976a609267dfb2341955206d045c375';

class HobbyDirectoryCreator {
    constructor() {
        this.tableIds = {};
    }

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

    async createTable(tableData) {
        console.log(`🏗️ Creating table: ${tableData.name}...`);
        
        try {
            const response = await this.makeRequest('POST', `/v0/meta/bases/${baseId}/tables`, tableData);
            this.tableIds[tableData.name] = response.id;
            console.log(`✅ Created ${tableData.name} (${response.id})`);
            return response;
        } catch (error) {
            console.error(`❌ Failed to create ${tableData.name}: ${error.message}`);
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
                    { name: "Sort Order", type: "number", options: { precision: 0 } },
                    { name: "Featured", type: "checkbox" }
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
                    { name: "Latitude", type: "number", options: { precision: 6 } },
                    { name: "Longitude", type: "number", options: { precision: 6 } },
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
                    { name: "Commission Rate", type: "percent", options: { precision: 1 } },
                    { name: "Logo URL", type: "url" }
                ]
            },
            {
                name: "Classes",
                description: "Main hobby class listings",
                fields: [
                    { name: "Name", type: "singleLineText" },
                    { name: "Description", type: "multilineText" },
                    { name: "Date", type: "date", options: { dateFormat: { name: "iso" }, includeTime: true }},
                    { name: "Duration Hours", type: "number", options: { precision: 1 } },
                    { name: "Price CAD", type: "currency", options: { symbol: "CAD" } },
                    { name: "Max Students", type: "number", options: { precision: 0 } },
                    { name: "Current Students", type: "number", options: { precision: 0 } },
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
                    ]}},
                    { name: "Source", type: "singleSelect", options: { choices: [
                        { name: "Manual Entry" }, { name: "Web Scrape" }, { name: "API Import" }, { name: "User Submission" }
                    ]}},
                    { name: "Created", type: "createdTime" }
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

    async addSampleData() {
        console.log('\n🌱 Adding sample data...');
        
        // Categories
        const categories = [
            { Name: "Pottery & Ceramics", Description: "Clay work, wheel throwing, glazing", Color: "#8B4513", Icon: "pottery", "Sort Order": 1, Featured: true },
            { Name: "Music & DJ", Description: "DJ workshops, music production", Color: "#FF6B6B", Icon: "music", "Sort Order": 2, Featured: true },
            { Name: "Fitness & Boxing", Description: "Boxing classes, fitness training", Color: "#4ECDC4", Icon: "boxing", "Sort Order": 3, Featured: true },
            { Name: "Art & Drawing", Description: "Drawing, painting, illustration", Color: "#45B7D1", Icon: "brush", "Sort Order": 4, Featured: false },
            { Name: "Comedy & Improv", Description: "Stand-up, improv, sketch comedy", Color: "#FFA07A", Icon: "comedy", "Sort Order": 5, Featured: true }
        ];

        await this.addRecords('Categories', categories);

        // Locations
        const locations = [
            { Name: "Downtown Vancouver", Neighborhood: "Downtown", "Postal Code": "V6B", Latitude: 49.2827, Longitude: -123.1207, Transit: ["SkyTrain", "Bus"] },
            { Name: "Kitsilano", Neighborhood: "Kitsilano", "Postal Code": "V6K", Latitude: 49.2608, Longitude: -123.1697, Transit: ["Bus"] },
            { Name: "Commercial Drive", Neighborhood: "East Vancouver", "Postal Code": "V5L", Latitude: 49.2606, Longitude: -123.0695, Transit: ["SkyTrain", "Bus"] },
            { Name: "Mount Pleasant", Neighborhood: "Mount Pleasant", "Postal Code": "V5T", Latitude: 49.2632, Longitude: -123.1015, Transit: ["Bus"] }
        ];

        await this.addRecords('Locations', locations);

        // Studios
        const studios = [
            {
                Name: "Claymates Ceramics Studio",
                Description: "Premier pottery studio offering wheel throwing and glazing classes",
                Email: "hello@claymates.studio",
                Website: "https://claymatesceramicsstudio.com",
                Instagram: "@claymates.studio",
                "Partnership Tier": "Premium",
                "Commission Rate": 0.15
            },
            {
                Name: "Rumble Boxing",
                Description: "High-energy boxing fitness classes",
                Instagram: "@rumbleboxingmp",
                "Partnership Tier": "Premium",
                "Commission Rate": 0.18
            }
        ];

        await this.addRecords('Studios', studios);

        console.log('✅ Sample data added successfully!');
    }

    async addRecords(tableName, records) {
        try {
            const tableId = this.tableIds[tableName];
            await this.makeRequest('POST', `/v0/${baseId}/${tableId}`, {
                records: records.map(fields => ({ fields }))
            });
            console.log(`  ✅ Added ${records.length} ${tableName} records`);
        } catch (error) {
            console.error(`  ❌ Failed to add ${tableName} records: ${error.message}`);
        }
    }

    async execute() {
        console.log('🚀 Creating Hobby Classes Directory structure...\n');

        const tables = this.getTableDefinitions();
        
        for (const tableData of tables) {
            try {
                await this.createTable(tableData);
                // Small delay between requests
                await new Promise(resolve => setTimeout(resolve, 1000));
            } catch (error) {
                console.error(`Failed: ${error.message}`);
            }
        }

        await this.addSampleData();

        console.log('\n🎉 Hobby Classes Directory created successfully!');
        console.log('\n📋 Next steps:');
        console.log('1. Add relationships between tables');
        console.log('2. Create views for workflow management');
        console.log('3. Set up Webflow CMS collections');
        console.log('4. Configure WhaleSync integration');
        console.log(`\n🌐 Base URL: https://airtable.com/${baseId}`);
    }
}

const creator = new HobbyDirectoryCreator();
creator.execute().catch(console.error);