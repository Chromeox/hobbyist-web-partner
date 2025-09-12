#!/usr/bin/env node

/**
 * Integration Helper for Hobby Classes Directory
 * Prepares Airtable base for WhaleSync and Webflow integration
 */

const https = require('https');
const readline = require('readline');

class IntegrationHelper {
    constructor(apiKey, baseId) {
        this.apiKey = apiKey;
        this.baseId = baseId;
        this.baseUrl = 'https://api.airtable.com/v0';
        this.integrationConfig = {};
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

    // Generate WhaleSync configuration
    async generateWhaleSyncConfig() {
        console.log('\n🐋 Generating WhaleSync Configuration...');
        
        try {
            const tables = await this.makeRequest('GET', `/v0/bases/${this.baseId}/tables`);
            const classesTable = tables.tables.find(t => t.name === 'Classes');
            
            if (!classesTable) {
                throw new Error('Classes table not found');
            }

            const whaleSyncConfig = {
                source: {
                    type: "airtable",
                    baseId: this.baseId,
                    tableId: classesTable.id,
                    viewName: "Active Classes"
                },
                destination: {
                    type: "webflow",
                    collectionName: "hobby-classes"
                },
                fieldMapping: {
                    "Class_Name": { webflowField: "name", type: "plaintext" },
                    "Description": { webflowField: "description", type: "richtext" },
                    "Price_CAD": { webflowField: "price", type: "number" },
                    "Event_Date": { webflowField: "event-date", type: "datetime" },
                    "Duration_Minutes": { webflowField: "duration", type: "number" },
                    "Max_Participants": { webflowField: "max-spots", type: "number" },
                    "Spots_Available": { webflowField: "spots-available", type: "number" },
                    "Instructor_Name": { webflowField: "instructor", type: "plaintext" },
                    "Difficulty_Level": { webflowField: "difficulty", type: "option" },
                    "Registration_URL": { webflowField: "registration-link", type: "link" },
                    "Image_URL": { webflowField: "featured-image", type: "image" },
                    "SEO_Slug": { webflowField: "slug", type: "plaintext" }
                },
                syncSettings: {
                    frequency: "every 30 minutes",
                    direction: "airtable-to-webflow",
                    deleteBehavior: "unpublish",
                    createNewItems: true,
                    updateExistingItems: true
                },
                filters: {
                    status: "Active"
                }
            };

            this.integrationConfig.whaleSync = whaleSyncConfig;
            console.log('✅ WhaleSync configuration generated');
            
            return whaleSyncConfig;
            
        } catch (error) {
            console.error('❌ Failed to generate WhaleSync config:', error.message);
            throw error;
        }
    }

    // Generate Webflow CMS structure
    generateWebflowCMS() {
        console.log('\n🌐 Generating Webflow CMS Structure...');
        
        const cmsStructure = {
            collections: [
                {
                    name: "Hobby Classes",
                    slug: "hobby-classes",
                    description: "Vancouver hobby class listings",
                    fields: [
                        { name: "Name", slug: "name", type: "PlainText", required: true },
                        { name: "Description", slug: "description", type: "RichText" },
                        { name: "Studio Name", slug: "studio-name", type: "PlainText" },
                        { name: "Category", slug: "category", type: "PlainText" },
                        { name: "Price", slug: "price", type: "Number", helpText: "Price in CAD" },
                        { name: "Event Date", slug: "event-date", type: "DateTime" },
                        { name: "Duration", slug: "duration", type: "Number", helpText: "Duration in minutes" },
                        { name: "Max Spots", slug: "max-spots", type: "Number" },
                        { name: "Spots Available", slug: "spots-available", type: "Number" },
                        { name: "Instructor", slug: "instructor", type: "PlainText" },
                        { name: "Difficulty", slug: "difficulty", type: "Option", options: ["Beginner", "Intermediate", "Advanced", "All Levels"] },
                        { name: "Registration Link", slug: "registration-link", type: "Link" },
                        { name: "Featured Image", slug: "featured-image", type: "Image" },
                        { name: "Slug", slug: "slug", type: "PlainText" }
                    ]
                },
                {
                    name: "Studios",
                    slug: "studios", 
                    description: "Partner studios and venues",
                    fields: [
                        { name: "Studio Name", slug: "studio-name", type: "PlainText", required: true },
                        { name: "Description", slug: "description", type: "RichText" },
                        { name: "Website", slug: "website", type: "Link" },
                        { name: "Instagram", slug: "instagram", type: "PlainText" },
                        { name: "Partnership Tier", slug: "partnership-tier", type: "Option", options: ["Premium Partner", "Standard Partner", "Basic Listing"] },
                        { name: "Logo", slug: "logo", type: "Image" },
                        { name: "Location", slug: "location", type: "PlainText" }
                    ]
                },
                {
                    name: "Categories",
                    slug: "categories",
                    description: "Hobby class categories",
                    fields: [
                        { name: "Category Name", slug: "category-name", type: "PlainText", required: true },
                        { name: "Description", slug: "description", type: "RichText" },
                        { name: "Icon", slug: "icon", type: "PlainText", helpText: "Icon class name" },
                        { name: "Color", slug: "color", type: "Color" },
                        { name: "Featured", slug: "featured", type: "Switch" }
                    ]
                }
            ],
            pages: [
                {
                    name: "Class Listing",
                    slug: "classes",
                    type: "Collection List",
                    collection: "hobby-classes",
                    description: "Main classes directory page"
                },
                {
                    name: "Class Detail",
                    slug: "class",
                    type: "Collection Page", 
                    collection: "hobby-classes",
                    description: "Individual class detail pages"
                },
                {
                    name: "Studio Profile",
                    slug: "studio",
                    type: "Collection Page",
                    collection: "studios",
                    description: "Studio profile pages"
                },
                {
                    name: "Category Browse",
                    slug: "category",
                    type: "Collection Page",
                    collection: "categories", 
                    description: "Category browsing pages"
                }
            ]
        };

        this.integrationConfig.webflow = cmsStructure;
        console.log('✅ Webflow CMS structure generated');
        
        return cmsStructure;
    }

    // Generate API endpoints documentation
    generateAPIDocumentation() {
        console.log('\n📚 Generating API Documentation...');
        
        const apiDoc = {
            baseUrl: `https://api.airtable.com/v0/${this.baseId}`,
            authentication: {
                type: "Bearer Token",
                header: "Authorization: Bearer YOUR_API_TOKEN"
            },
            endpoints: [
                {
                    name: "Get Active Classes",
                    method: "GET",
                    url: `/Classes?filterByFormula={Status}='Active'&sort[0][field]=Event_Date&sort[0][direction]=asc`,
                    description: "Retrieve all active classes sorted by event date",
                    response: "Array of class records with all fields"
                },
                {
                    name: "Get Classes This Week",
                    method: "GET", 
                    url: `/Classes?filterByFormula=AND({Status}='Active',IS_AFTER({Event_Date},TODAY()),IS_BEFORE({Event_Date},DATEADD(TODAY(),7,'days')))`,
                    description: "Get classes happening in the next 7 days",
                    response: "Filtered array of upcoming classes"
                },
                {
                    name: "Get Studios by Partnership Tier",
                    method: "GET",
                    url: `/Studios?filterByFormula={Partnership_Tier}='Premium Partner'&sort[0][field]=Studio_Name`,
                    description: "Get studios by partnership level",
                    response: "Array of studio records"
                },
                {
                    name: "Submit User Suggestion",
                    method: "POST",
                    url: `/User_Submissions`,
                    description: "Submit new class or studio suggestion",
                    requestBody: {
                        records: [{
                            fields: {
                                "Submission_Type": "New Class",
                                "Submitter_Name": "John Doe",
                                "Submitter_Email": "john@example.com",
                                "Class_Name": "Advanced Pottery",
                                "Studio_Name": "Clay Works",
                                "Details": "Weekend pottery class for experienced students",
                                "Website_URL": "https://clayworks.com",
                                "Status": "Pending Review"
                            }
                        }]
                    }
                }
            ],
            webhooks: {
                description: "Set up webhooks for real-time sync",
                triggerEvents: ["record.created", "record.updated", "record.deleted"],
                payloadFormat: "Airtable standard webhook payload",
                securityNote: "Verify webhook signatures for security"
            },
            rateLimits: {
                requests: "5 per second per base",
                recommendation: "Implement exponential backoff"
            }
        };

        this.integrationConfig.api = apiDoc;
        console.log('✅ API documentation generated');
        
        return apiDoc;
    }

    // Export all configurations
    exportConfigurations() {
        console.log('\n💾 Exporting Integration Configurations...');
        
        const timestamp = new Date().toISOString().split('T')[0];
        const exportData = {
            metadata: {
                baseId: this.baseId,
                generatedAt: new Date().toISOString(),
                version: "1.0.0",
                purpose: "Hobby Classes Directory Integration Setup"
            },
            whaleSync: this.integrationConfig.whaleSync,
            webflow: this.integrationConfig.webflow,
            api: this.integrationConfig.api,
            setupInstructions: {
                whaleSync: [
                    "1. Sign up for WhaleSync account",
                    "2. Connect Airtable using your API token",
                    "3. Connect Webflow using site token",
                    "4. Import the generated field mapping configuration",
                    "5. Test sync with a few sample records",
                    "6. Enable automatic sync every 30 minutes"
                ],
                webflow: [
                    "1. Create new CMS collections using the provided structure", 
                    "2. Set up collection pages with appropriate layouts",
                    "3. Configure dynamic content binding",
                    "4. Test manual data entry to verify structure",
                    "5. Generate site API token for WhaleSync integration"
                ],
                testing: [
                    "1. Create test records in Airtable",
                    "2. Verify data appears correctly in Webflow",
                    "3. Test filtering and sorting functionality",
                    "4. Validate SEO-friendly URLs",
                    "5. Check mobile responsiveness"
                ]
            }
        };

        const configJson = JSON.stringify(exportData, null, 2);
        
        // In a real implementation, you would write this to a file
        console.log('✅ Configuration exported');
        console.log('\n📋 Integration Summary:');
        console.log(`• Base ID: ${this.baseId}`);
        console.log(`• WhaleSync Config: ✅ Generated`);
        console.log(`• Webflow CMS: ✅ Structured`);
        console.log(`• API Docs: ✅ Complete`);
        
        return configJson;
    }

    // Main execution
    async execute() {
        console.log('🔗 Starting Integration Configuration Generation...\n');
        
        try {
            await this.generateWhaleSyncConfig();
            this.generateWebflowCMS();
            this.generateAPIDocumentation();
            const config = this.exportConfigurations();
            
            console.log('\n🎉 Integration configuration complete!');
            console.log('\nNext Steps:');
            console.log('1. Set up WhaleSync account and configure sync');
            console.log('2. Create Webflow CMS collections using provided structure');
            console.log('3. Test integration with sample data');
            console.log('4. Monitor sync performance and adjust as needed');
            
            return config;
            
        } catch (error) {
            console.error('\n💥 Integration setup failed:', error.message);
            throw error;
        }
    }
}

// Interactive setup
async function main() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    function askQuestion(question) {
        return new Promise(resolve => rl.question(question, resolve));
    }

    console.log('🔗 Hobby Classes Directory - Integration Helper');
    console.log('=============================================\n');
    
    const apiKey = await askQuestion('Enter your Airtable API token: ');
    const baseId = await askQuestion('Enter your Base ID: ');

    rl.close();

    const helper = new IntegrationHelper(apiKey, baseId);
    
    try {
        const config = await helper.execute();
        
        // Save configuration to file
        const fs = require('fs');
        const filename = `integration-config-${Date.now()}.json`;
        fs.writeFileSync(filename, config);
        console.log(`\n💾 Configuration saved to: ${filename}`);
        
    } catch (error) {
        console.error('Integration setup failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = IntegrationHelper;