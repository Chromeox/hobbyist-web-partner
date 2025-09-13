#!/usr/bin/env node

/**
 * Hobby Classes Directory - Airtable Base Creator
 * Comprehensive API script to automatically build optimal Airtable base structure
 * 
 * Features:
 * - Creates 5 optimized tables with proper relationships
 * - Populates sample data for testing
 * - Configures views for different use cases  
 * - Prepares for Webflow/WhaleSync integration
 */

const https = require('https');
const readline = require('readline');

class AirtableBaseCreator {
    constructor(apiKey) {
        this.apiKey = apiKey;
        this.baseUrl = 'https://api.airtable.com/v0';
        this.createdBaseId = null;
        this.tableIds = {};
        this.fieldIds = {};
        
        // Rate limiting
        this.requestCount = 0;
        this.lastRequestTime = Date.now();
    }

    // API Request helper with rate limiting
    async makeRequest(method, endpoint, data = null) {
        // Airtable rate limit: 5 requests per second
        const now = Date.now();
        if (now - this.lastRequestTime < 200) {
            await this.sleep(200 - (now - this.lastRequestTime));
        }
        
        this.requestCount++;
        this.lastRequestTime = Date.now();
        
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
                            reject(new Error(`API Error ${res.statusCode}: ${response.error?.message || body}`));
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

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Step 1: Get existing base (manual creation required)
    async getExistingBase(baseId) {
        console.log('🔍 Connecting to existing Hobby Classes Directory base...');
        
        try {
            const response = await this.makeRequest('GET', `/v0/bases/${baseId}/tables`);
            this.createdBaseId = baseId;
            console.log(`✅ Connected to base: ${baseId}`);
            return response;
        } catch (error) {
            throw new Error(`Failed to connect to base: ${error.message}`);
        }
    }

    // Step 2: Define comprehensive table schemas
    getTableSchemas() {
        return {
            Classes: {
                name: "Classes",
                description: "Main hobby class listings with full details",
                fields: [
                    { name: "Class_Name", type: "singleLineText", description: "Name of the hobby class" },
                    { name: "Description", type: "multilineText", description: "Detailed class description" },
                    { name: "Studio", type: "multipleRecordLinks", options: { linkedTableId: "Studios" }},
                    { name: "Category", type: "multipleRecordLinks", options: { linkedTableId: "Categories" }},
                    { name: "Location", type: "multipleRecordLinks", options: { linkedTableId: "Locations" }},
                    { name: "Event_Date", type: "date", options: { dateFormat: { name: "iso" }, includeTime: true }},
                    { name: "Duration_Minutes", type: "number", options: { precision: 0 }},
                    { name: "Price_CAD", type: "currency", options: { symbol: "CAD" }},
                    { name: "Max_Participants", type: "number", options: { precision: 0 }},
                    { name: "Current_Participants", type: "number", options: { precision: 0 }},
                    { name: "Spots_Available", type: "formula", options: { formula: "{Max_Participants} - {Current_Participants}" }},
                    { name: "Instructor_Name", type: "singleLineText" },
                    { name: "Difficulty_Level", type: "singleSelect", options: { choices: [
                        { name: "Beginner" }, { name: "Intermediate" }, { name: "Advanced" }, { name: "All Levels" }
                    ]}},
                    { name: "Status", type: "singleSelect", options: { choices: [
                        { name: "Active", color: "greenBright" },
                        { name: "Full", color: "orangeBright" },
                        { name: "Cancelled", color: "redBright" },
                        { name: "Draft", color: "grayBright" }
                    ]}},
                    { name: "Registration_URL", type: "url" },
                    { name: "Image_URL", type: "url" },
                    { name: "Tags", type: "multipleSelects", options: { choices: [
                        { name: "Beginner Friendly" }, { name: "Drop-in Welcome" }, 
                        { name: "Materials Included" }, { name: "Weekend" }, { name: "Evening" }
                    ]}},
                    { name: "Created_Date", type: "createdTime" },
                    { name: "Last_Modified", type: "lastModifiedTime" },
                    { name: "Source", type: "singleSelect", options: { choices: [
                        { name: "Manual Entry" }, { name: "Web Scrape" }, { name: "API Import" }, { name: "User Submission" }
                    ]}},
                    { name: "SEO_Slug", type: "formula", options: { formula: "LOWER(SUBSTITUTE(SUBSTITUTE({Class_Name}, ' ', '-'), '&', 'and'))" }}
                ]
            },
            
            Studios: {
                name: "Studios",
                description: "Partner studios and venues offering classes",
                fields: [
                    { name: "Studio_Name", type: "singleLineText", description: "Official studio name" },
                    { name: "Description", type: "multilineText" },
                    { name: "Primary_Location", type: "multipleRecordLinks", options: { linkedTableId: "Locations" }},
                    { name: "Contact_Email", type: "email" },
                    { name: "Phone_Number", type: "phoneNumber" },
                    { name: "Website_URL", type: "url" },
                    { name: "Instagram_Handle", type: "singleLineText" },
                    { name: "Partnership_Tier", type: "singleSelect", options: { choices: [
                        { name: "Premium Partner", color: "purpleBright" },
                        { name: "Standard Partner", color: "blueBright" },
                        { name: "Basic Listing", color: "grayBright" },
                        { name: "Prospect", color: "yellowBright" }
                    ]}},
                    { name: "Commission_Rate", type: "percent", options: { precision: 1 }},
                    { name: "Total_Classes", type: "count", options: { linkedRecordFieldId: "Classes" }},
                    { name: "Average_Rating", type: "number", options: { precision: 1 }},
                    { name: "Logo_URL", type: "url" }
                ]
            },

            Categories: {
                name: "Categories", 
                description: "Hobby class categories and subcategories",
                fields: [
                    { name: "Category_Name", type: "singleLineText" },
                    { name: "Description", type: "multilineText" },
                    { name: "Parent_Category", type: "multipleRecordLinks", options: { linkedTableId: "Categories" }},
                    { name: "Icon_Name", type: "singleLineText", description: "Icon identifier for UI" },
                    { name: "Color_Code", type: "singleLineText", description: "Hex color for category" },
                    { name: "SEO_Keywords", type: "multilineText" },
                    { name: "Display_Order", type: "number", options: { precision: 0 }},
                    { name: "Total_Classes", type: "count", options: { linkedRecordFieldId: "Classes" }},
                    { name: "Is_Featured", type: "checkbox" }
                ]
            },

            Locations: {
                name: "Locations",
                description: "Vancouver neighborhoods and venue locations", 
                fields: [
                    { name: "Location_Name", type: "singleLineText" },
                    { name: "Neighborhood", type: "singleLineText" },
                    { name: "Address", type: "singleLineText" },
                    { name: "Postal_Code", type: "singleLineText" },
                    { name: "Latitude", type: "number", options: { precision: 6 }},
                    { name: "Longitude", type: "number", options: { precision: 6 }},
                    { name: "Transit_Nearby", type: "multipleSelects", options: { choices: [
                        { name: "SkyTrain" }, { name: "Bus Routes" }, { name: "SeaBus" }
                    ]}},
                    { name: "Total_Classes", type: "count", options: { linkedRecordFieldId: "Classes" }}
                ]
            },

            User_Submissions: {
                name: "User Submissions",
                description: "Community-submitted class suggestions and feedback",
                fields: [
                    { name: "Submission_Type", type: "singleSelect", options: { choices: [
                        { name: "New Class" }, { name: "Studio Suggestion" }, 
                        { name: "Class Update" }, { name: "Correction" }
                    ]}},
                    { name: "Submitter_Name", type: "singleLineText" },
                    { name: "Submitter_Email", type: "email" },
                    { name: "Class_Name", type: "singleLineText" },
                    { name: "Studio_Name", type: "singleLineText" },
                    { name: "Details", type: "multilineText" },
                    { name: "Website_URL", type: "url" },
                    { name: "Status", type: "singleSelect", options: { choices: [
                        { name: "Pending Review", color: "yellowBright" },
                        { name: "Approved", color: "greenBright" },
                        { name: "Rejected", color: "redBright" },
                        { name: "Need More Info", color: "orangeBright" }
                    ]}},
                    { name: "Review_Notes", type: "multilineText" },
                    { name: "Submitted_Date", type: "createdTime" },
                    { name: "Reviewer", type: "singleLineText" },
                    { name: "Review_Date", type: "date" }
                ]
            }
        };
    }

    // Step 3: Create tables with proper field configurations
    async createTables() {
        console.log('📋 Creating tables and fields...');
        const schemas = this.getTableSchemas();
        
        // First create all tables (Classes already exists from base creation)
        const tableOrder = ['Studios', 'Categories', 'Locations', 'User_Submissions'];
        
        for (const tableName of tableOrder) {
            console.log(`  Creating ${tableName} table...`);
            
            const tableData = {
                name: tableName,
                description: schemas[tableName].description,
                fields: schemas[tableName].fields.filter(field => field.type !== 'multipleRecordLinks')
            };

            try {
                const response = await this.makeRequest('POST', `/v0/bases/${this.createdBaseId}/tables`, tableData);
                this.tableIds[tableName] = response.id;
                console.log(`    ✅ ${tableName} created: ${response.id}`);
            } catch (error) {
                console.error(`    ❌ Failed to create ${tableName}: ${error.message}`);
                throw error;
            }
        }

        // Update Classes table with all fields (it was created with base)
        console.log('  Updating Classes table...');
        const tables = await this.makeRequest('GET', `/v0/bases/${this.createdBaseId}/tables`);
        const classesTable = tables.tables.find(t => t.name === 'Classes');
        this.tableIds['Classes'] = classesTable.id;

        // Add remaining fields to Classes table
        await this.addFieldsToTable('Classes', schemas.Classes.fields);
    }

    async addFieldsToTable(tableName, fields) {
        const tableId = this.tableIds[tableName];
        
        for (const field of fields) {
            if (field.name === 'Class_Name') continue; // Already exists
            
            // Update linked record fields with actual table IDs
            if (field.type === 'multipleRecordLinks' && field.options?.linkedTableId) {
                const linkedTableName = field.options.linkedTableId;
                if (this.tableIds[linkedTableName]) {
                    field.options.linkedTableId = this.tableIds[linkedTableName];
                } else {
                    console.log(`    ⏭️  Skipping ${field.name} - linked table not ready`);
                    continue;
                }
            }

            try {
                const response = await this.makeRequest('POST', `/v0/bases/${this.createdBaseId}/tables/${tableId}/fields`, field);
                console.log(`    ✅ Added field: ${field.name}`);
            } catch (error) {
                console.log(`    ⚠️  Field ${field.name}: ${error.message}`);
            }
        }
    }

    // Step 4: Create sample data
    async populateSampleData() {
        console.log('🌱 Populating sample data...');
        
        // Sample categories
        const categories = [
            { Category_Name: "Pottery & Ceramics", Description: "Clay work, wheel throwing, glazing", Icon_Name: "pottery", Color_Code: "#8B4513", Display_Order: 1, Is_Featured: true },
            { Category_Name: "Music & DJ", Description: "DJ workshops, music production, mixing", Icon_Name: "music", Color_Code: "#FF6B6B", Display_Order: 2, Is_Featured: true },
            { Category_Name: "Fitness & Boxing", Description: "Boxing classes, fitness training", Icon_Name: "boxing", Color_Code: "#4ECDC4", Display_Order: 3, Is_Featured: true },
            { Category_Name: "Art & Drawing", Description: "Drawing, painting, illustration", Icon_Name: "brush", Color_Code: "#45B7D1", Display_Order: 4, Is_Featured: false },
            { Category_Name: "Comedy & Improv", Description: "Stand-up, improv, sketch comedy", Icon_Name: "comedy", Color_Code: "#FFA07A", Display_Order: 5, Is_Featured: true }
        ];

        await this.createRecords('Categories', categories);

        // Sample Vancouver locations
        const locations = [
            { Location_Name: "Downtown Vancouver", Neighborhood: "Downtown", Postal_Code: "V6B", Latitude: 49.2827, Longitude: -123.1207, Transit_Nearby: ["SkyTrain", "Bus Routes"] },
            { Location_Name: "Kitsilano", Neighborhood: "Kitsilano", Postal_Code: "V6K", Latitude: 49.2608, Longitude: -123.1697, Transit_Nearby: ["Bus Routes"] },
            { Location_Name: "Commercial Drive", Neighborhood: "East Vancouver", Postal_Code: "V5L", Latitude: 49.2606, Longitude: -123.0695, Transit_Nearby: ["SkyTrain", "Bus Routes"] },
            { Location_Name: "Gastown", Neighborhood: "Gastown", Postal_Code: "V6A", Latitude: 49.2841, Longitude: -123.1086, Transit_Nearby: ["SkyTrain", "Bus Routes", "SeaBus"] },
            { Location_Name: "Mount Pleasant", Neighborhood: "Mount Pleasant", Postal_Code: "V5T", Latitude: 49.2632, Longitude: -123.1015, Transit_Nearby: ["Bus Routes"] }
        ];

        await this.createRecords('Locations', locations);

        // Sample studios (including Claymates)
        const studios = [
            { 
                Studio_Name: "Claymates Ceramics Studio", 
                Description: "Premier pottery studio in Vancouver offering wheel throwing, hand building, and glazing classes",
                Contact_Email: "hello@claymates.studio",
                Website_URL: "https://claymatesceramicsstudio.com",
                Instagram_Handle: "@claymates.studio",
                Partnership_Tier: "Premium Partner",
                Commission_Rate: 0.15,
                Average_Rating: 4.8
            },
            {
                Studio_Name: "Beat Drop Academy",
                Description: "DJ and music production workshops for all skill levels",
                Contact_Email: "info@beatdrop.ca",
                Instagram_Handle: "@beatdrop_van",
                Partnership_Tier: "Standard Partner", 
                Commission_Rate: 0.12,
                Average_Rating: 4.6
            },
            {
                Studio_Name: "Rumble Boxing",
                Description: "High-energy boxing fitness classes in a supportive environment",
                Contact_Email: "vancouver@rumbleboxing.com",
                Instagram_Handle: "@rumbleboxingmp",
                Partnership_Tier: "Premium Partner",
                Commission_Rate: 0.18,
                Average_Rating: 4.9
            }
        ];

        await this.createRecords('Studios', studios);

        // Sample classes will be added after we get record IDs for linking
        console.log('✅ Sample data populated successfully');
    }

    async createRecords(tableName, records) {
        const tableId = this.tableIds[tableName];
        
        try {
            const response = await this.makeRequest('POST', `/v0/bases/${this.createdBaseId}/${tableId}`, {
                records: records.map(fields => ({ fields }))
            });
            console.log(`  ✅ Created ${records.length} ${tableName} records`);
            return response;
        } catch (error) {
            console.error(`  ❌ Failed to create ${tableName} records: ${error.message}`);
            throw error;
        }
    }

    // Step 5: Create optimized views
    async createViews() {
        console.log('👁️  Creating optimized views...');
        
        const views = {
            Classes: [
                {
                    name: "Active Classes",
                    type: "grid",
                    fieldOrder: ["Class_Name", "Studio", "Category", "Event_Date", "Price_CAD", "Spots_Available", "Status"],
                    visibleFieldIds: [],
                    filterByFormula: "{Status} = 'Active'"
                },
                {
                    name: "This Week",
                    type: "grid", 
                    fieldOrder: ["Class_Name", "Studio", "Event_Date", "Duration_Minutes", "Price_CAD"],
                    visibleFieldIds: [],
                    filterByFormula: "AND({Status} = 'Active', IS_AFTER({Event_Date}, DATEADD(TODAY(), -1, 'days')), IS_BEFORE({Event_Date}, DATEADD(TODAY(), 7, 'days')))"
                }
            ],
            Studios: [
                {
                    name: "Partnership Management",
                    type: "grid",
                    fieldOrder: ["Studio_Name", "Partnership_Tier", "Total_Classes", "Commission_Rate", "Contact_Email"],
                    visibleFieldIds: []
                }
            ],
            User_Submissions: [
                {
                    name: "Pending Review",
                    type: "grid",
                    fieldOrder: ["Submission_Type", "Class_Name", "Studio_Name", "Submitter_Email", "Submitted_Date"],
                    visibleFieldIds: [],
                    filterByFormula: "{Status} = 'Pending Review'"
                }
            ]
        };

        for (const [tableName, tableViews] of Object.entries(views)) {
            const tableId = this.tableIds[tableName];
            for (const view of tableViews) {
                try {
                    await this.makeRequest('POST', `/v0/bases/${this.createdBaseId}/tables/${tableId}/views`, view);
                    console.log(`  ✅ Created view: ${tableName} - ${view.name}`);
                } catch (error) {
                    console.log(`  ⚠️  View creation failed: ${error.message}`);
                }
            }
        }
    }

    // Step 6: Validation and summary
    async validateCreation() {
        console.log('🔍 Validating base structure...');
        
        try {
            const tables = await this.makeRequest('GET', `/v0/bases/${this.createdBaseId}/tables`);
            
            console.log('\n📊 Base Creation Summary:');
            console.log(`Base ID: ${this.createdBaseId}`);
            console.log(`Tables Created: ${tables.tables.length}/5`);
            
            for (const table of tables.tables) {
                console.log(`  • ${table.name}: ${table.fields.length} fields`);
            }
            
            console.log(`\n🌐 Base URL: https://airtable.com/${this.createdBaseId}`);
            console.log('\n✅ Base structure validation complete!');
            
            return {
                baseId: this.createdBaseId,
                tables: tables.tables,
                success: true
            };
        } catch (error) {
            console.error('❌ Validation failed:', error.message);
            return { success: false, error: error.message };
        }
    }

    // Main execution flow
    async execute() {
        try {
            console.log('🚀 Starting Hobby Classes Directory base creation...\n');
            
            await this.createBase();
            await this.sleep(1000); // Allow base to be ready
            
            await this.createTables();
            await this.sleep(2000); // Allow relationships to be set up
            
            await this.populateSampleData();
            await this.createViews();
            
            const validation = await this.validateCreation();
            
            console.log('\n🎉 Hobby Classes Directory base created successfully!');
            console.log('\n📋 Next Steps:');
            console.log('1. Visit your new base and explore the structure');
            console.log('2. Configure WhaleSync integration');
            console.log('3. Set up Webflow connection');
            console.log('4. Begin importing real class data');
            
            return validation;
            
        } catch (error) {
            console.error('\n❌ Base creation failed:', error.message);
            
            if (this.createdBaseId) {
                console.log(`\n🗑️  You may want to delete the incomplete base: ${this.createdBaseId}`);
            }
            
            throw error;
        }
    }
}

// Interactive setup and execution
async function main() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    function askQuestion(question) {
        return new Promise(resolve => rl.question(question, resolve));
    }

    console.log('🎨 Hobby Classes Directory - Airtable Base Creator');
    console.log('================================================\n');
    
    console.log('Prerequisites:');
    console.log('• Airtable account with Team plan ($20/month)');
    console.log('• API access enabled');
    console.log('• Personal access token generated\n');
    
    const continueSetup = await askQuestion('Ready to proceed? (y/n): ');
    if (continueSetup.toLowerCase() !== 'y') {
        console.log('Setup cancelled.');
        rl.close();
        return;
    }

    console.log('\n📝 API Token Setup:');
    console.log('1. Go to https://airtable.com/create/tokens');
    console.log('2. Click "Create token"');
    console.log('3. Name: "Hobby Directory Base Creator"'); 
    console.log('4. Scopes: data.records:read, data.records:write, schema.bases:write');
    console.log('5. Bases: Choose "All current and future bases" or specific workspace');
    console.log('6. Copy the generated token\n');

    const apiKey = await askQuestion('Enter your Airtable API token: ');
    if (!apiKey || !apiKey.startsWith('pat')) {
        console.log('❌ Invalid API token format. Should start with "pat"');
        rl.close();
        return;
    }

    rl.close();

    // Execute base creation
    const creator = new AirtableBaseCreator(apiKey);
    
    try {
        const result = await creator.execute();
        
        if (result.success) {
            console.log(`\n💾 Save this Base ID: ${result.baseId}`);
            console.log('You\'ll need it for WhaleSync and Webflow integration.');
        }
        
    } catch (error) {
        console.error('\n💥 Creation failed:', error.message);
        process.exit(1);
    }
}

// Export for use as module or run directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = AirtableBaseCreator;