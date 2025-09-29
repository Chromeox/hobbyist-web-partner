#!/usr/bin/env node

/**
 * Airtable Base Structure Validator
 * Comprehensive testing and validation script for Hobby Classes Directory
 */

const https = require('https');
const readline = require('readline');

class AirtableValidator {
    constructor(apiKey, baseId) {
        this.apiKey = apiKey;
        this.baseId = baseId;
        this.baseUrl = 'https://api.airtable.com/v0';
        this.results = {
            tables: {},
            relationships: {},
            data: {},
            views: {},
            overall: { passed: 0, failed: 0, warnings: 0 }
        };
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

    logResult(test, status, message) {
        const symbols = { pass: '✅', fail: '❌', warn: '⚠️' };
        console.log(`${symbols[status]} ${test}: ${message}`);
        
        if (status === 'pass') this.results.overall.passed++;
        else if (status === 'fail') this.results.overall.failed++;
        else if (status === 'warn') this.results.overall.warnings++;
    }

    // Test 1: Validate base structure
    async validateBaseStructure() {
        console.log('\n🔍 Testing Base Structure...');
        
        try {
            const tables = await this.makeRequest('GET', `/v0/bases/${this.baseId}/tables`);
            
            const expectedTables = ['Classes', 'Studios', 'Categories', 'Locations', 'User_Submissions'];
            const actualTables = tables.tables.map(t => t.name);
            
            // Check all tables exist
            for (const expectedTable of expectedTables) {
                if (actualTables.includes(expectedTable)) {
                    this.logResult(`Table ${expectedTable}`, 'pass', 'Table exists');
                } else {
                    this.logResult(`Table ${expectedTable}`, 'fail', 'Table missing');
                }
            }
            
            // Check for unexpected tables
            for (const actualTable of actualTables) {
                if (!expectedTables.includes(actualTable)) {
                    this.logResult(`Unexpected Table`, 'warn', `Found unexpected table: ${actualTable}`);
                }
            }

            this.results.tables = tables.tables;
            return tables.tables;
            
        } catch (error) {
            this.logResult('Base Structure', 'fail', `Cannot access base: ${error.message}`);
            throw error;
        }
    }

    // Test 2: Validate field configurations
    async validateFields() {
        console.log('\n📊 Testing Field Configurations...');
        
        const fieldTests = {
            Classes: {
                required: ['Class_Name', 'Description', 'Studio', 'Category', 'Price_CAD', 'Status'],
                formulas: ['Spots_Available', 'SEO_Slug'],
                selects: ['Difficulty_Level', 'Status', 'Source'],
                links: ['Studio', 'Category', 'Location']
            },
            Studios: {
                required: ['Studio_Name', 'Partnership_Tier', 'Commission_Rate'],
                rollups: ['Total_Classes'],
                links: ['Primary_Location']
            },
            Categories: {
                required: ['Category_Name', 'Display_Order'],
                links: ['Parent_Category']
            },
            Locations: {
                required: ['Location_Name', 'Neighborhood'],
                coordinates: ['Latitude', 'Longitude']
            },
            User_Submissions: {
                required: ['Submission_Type', 'Status', 'Submitted_Date'],
                timestamps: ['Submitted_Date', 'Review_Date']
            }
        };

        for (const table of this.results.tables) {
            const tableName = table.name;
            const tests = fieldTests[tableName];
            
            if (!tests) continue;
            
            const fieldNames = table.fields.map(f => f.name);
            
            // Test required fields
            if (tests.required) {
                for (const requiredField of tests.required) {
                    if (fieldNames.includes(requiredField)) {
                        this.logResult(`${tableName}.${requiredField}`, 'pass', 'Required field present');
                    } else {
                        this.logResult(`${tableName}.${requiredField}`, 'fail', 'Required field missing');
                    }
                }
            }
            
            // Test formula fields
            if (tests.formulas) {
                for (const formulaField of tests.formulas) {
                    const field = table.fields.find(f => f.name === formulaField);
                    if (field && field.type === 'formula') {
                        this.logResult(`${tableName}.${formulaField}`, 'pass', 'Formula field configured');
                    } else {
                        this.logResult(`${tableName}.${formulaField}`, 'fail', 'Formula field missing or wrong type');
                    }
                }
            }
            
            // Test linked record fields
            if (tests.links) {
                for (const linkField of tests.links) {
                    const field = table.fields.find(f => f.name === linkField);
                    if (field && field.type === 'multipleRecordLinks') {
                        this.logResult(`${tableName}.${linkField}`, 'pass', 'Linked record field configured');
                    } else {
                        this.logResult(`${tableName}.${linkField}`, 'warn', 'Linked record field missing or wrong type');
                    }
                }
            }
        }
    }

    // Test 3: Validate data integrity
    async validateDataIntegrity() {
        console.log('\n🔗 Testing Data Integrity...');
        
        for (const table of this.results.tables) {
            try {
                const records = await this.makeRequest('GET', `/v0/bases/${this.baseId}/${table.id}?maxRecords=10`);
                
                if (records.records && records.records.length > 0) {
                    this.logResult(`${table.name} Data`, 'pass', `${records.records.length} sample records found`);
                    
                    // Test first record for completeness
                    const firstRecord = records.records[0];
                    const fieldCount = Object.keys(firstRecord.fields).length;
                    const totalFields = table.fields.length;
                    
                    if (fieldCount >= totalFields * 0.5) { // At least 50% of fields populated
                        this.logResult(`${table.name} Completeness`, 'pass', `${fieldCount}/${totalFields} fields populated`);
                    } else {
                        this.logResult(`${table.name} Completeness`, 'warn', `Only ${fieldCount}/${totalFields} fields populated`);
                    }
                    
                } else {
                    this.logResult(`${table.name} Data`, 'warn', 'No sample data found');
                }
                
            } catch (error) {
                this.logResult(`${table.name} Data`, 'fail', `Cannot read data: ${error.message}`);
            }
        }
    }

    // Test 4: Validate relationships
    async validateRelationships() {
        console.log('\n🔗 Testing Table Relationships...');
        
        const expectedRelationships = [
            { from: 'Classes', field: 'Studio', to: 'Studios' },
            { from: 'Classes', field: 'Category', to: 'Categories' },
            { from: 'Classes', field: 'Location', to: 'Locations' },
            { from: 'Studios', field: 'Primary_Location', to: 'Locations' }
        ];
        
        for (const rel of expectedRelationships) {
            const fromTable = this.results.tables.find(t => t.name === rel.from);
            if (!fromTable) continue;
            
            const linkField = fromTable.fields.find(f => f.name === rel.field);
            const toTable = this.results.tables.find(t => t.name === rel.to);
            
            if (linkField && linkField.type === 'multipleRecordLinks' && toTable) {
                if (linkField.options && linkField.options.linkedTableId === toTable.id) {
                    this.logResult(`Relationship`, 'pass', `${rel.from}.${rel.field} → ${rel.to}`);
                } else {
                    this.logResult(`Relationship`, 'warn', `${rel.from}.${rel.field} → ${rel.to} (ID mismatch)`);
                }
            } else {
                this.logResult(`Relationship`, 'fail', `${rel.from}.${rel.field} → ${rel.to} (missing or wrong type)`);
            }
        }
    }

    // Test 5: Validate views
    async validateViews() {
        console.log('\n👁️  Testing Views Configuration...');
        
        const expectedViews = {
            Classes: ['Active Classes', 'This Week'],
            Studios: ['Partnership Management'],
            User_Submissions: ['Pending Review']
        };
        
        for (const [tableName, viewNames] of Object.entries(expectedViews)) {
            const table = this.results.tables.find(t => t.name === tableName);
            if (!table) continue;
            
            for (const viewName of viewNames) {
                const view = table.views.find(v => v.name === viewName);
                if (view) {
                    this.logResult(`View`, 'pass', `${tableName}.${viewName} configured`);
                } else {
                    this.logResult(`View`, 'warn', `${tableName}.${viewName} missing`);
                }
            }
        }
    }

    // Test 6: Performance and optimization checks
    async validatePerformance() {
        console.log('\n⚡ Testing Performance Optimization...');
        
        // Check for indexed fields (primary fields are auto-indexed)
        for (const table of this.results.tables) {
            const primaryField = table.fields.find(f => f.type === 'singleLineText' && f.name.includes('Name'));
            if (primaryField) {
                this.logResult(`Index`, 'pass', `${table.name} has primary field for indexing`);
            } else {
                this.logResult(`Index`, 'warn', `${table.name} may lack optimized primary field`);
            }
        }
        
        // Check for excessive formula fields (can impact performance)
        for (const table of this.results.tables) {
            const formulaFields = table.fields.filter(f => f.type === 'formula');
            if (formulaFields.length <= 5) {
                this.logResult(`Formula Optimization`, 'pass', `${table.name} has ${formulaFields.length} formula fields`);
            } else {
                this.logResult(`Formula Optimization`, 'warn', `${table.name} has ${formulaFields.length} formula fields (may impact performance)`);
            }
        }
    }

    // Generate comprehensive report
    generateReport() {
        console.log('\n📋 VALIDATION REPORT');
        console.log('═'.repeat(50));
        
        const { passed, failed, warnings } = this.results.overall;
        const total = passed + failed + warnings;
        
        console.log(`Total Tests: ${total}`);
        console.log(`✅ Passed: ${passed} (${Math.round(passed/total*100)}%)`);
        console.log(`❌ Failed: ${failed} (${Math.round(failed/total*100)}%)`);
        console.log(`⚠️  Warnings: ${warnings} (${Math.round(warnings/total*100)}%)`);
        
        let status = 'EXCELLENT';
        if (failed > 0) status = 'NEEDS ATTENTION';
        else if (warnings > 3) status = 'GOOD';
        
        console.log(`\nOverall Status: ${status}`);
        
        if (failed === 0 && warnings <= 3) {
            console.log('\n🎉 Base is ready for production use!');
            console.log('\nNext Steps:');
            console.log('1. Configure WhaleSync integration');
            console.log('2. Set up Webflow CMS connection');
            console.log('3. Begin importing production data');
        } else {
            console.log('\n🔧 Recommendations:');
            if (failed > 0) console.log('- Fix failed tests before production use');
            if (warnings > 3) console.log('- Review warnings for potential improvements');
        }
    }

    // Main execution
    async execute() {
        console.log('🔍 Starting Hobby Classes Directory Base Validation...\n');
        console.log(`Base ID: ${this.baseId}`);
        
        try {
            await this.validateBaseStructure();
            await this.validateFields();
            await this.validateDataIntegrity();
            await this.validateRelationships();
            await this.validateViews();
            await this.validatePerformance();
            
            this.generateReport();
            
        } catch (error) {
            console.error('\n💥 Validation failed:', error.message);
            throw error;
        }
    }
}

// Interactive validation runner
async function main() {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    function askQuestion(question) {
        return new Promise(resolve => rl.question(question, resolve));
    }

    console.log('🔍 Hobby Classes Directory - Base Validator');
    console.log('==========================================\n');
    
    const apiKey = await askQuestion('Enter your Airtable API token: ');
    if (!apiKey || !apiKey.startsWith('pat')) {
        console.log('❌ Invalid API token format');
        rl.close();
        return;
    }
    
    const baseId = await askQuestion('Enter your Base ID (starts with app): ');
    if (!baseId || !baseId.startsWith('app')) {
        console.log('❌ Invalid Base ID format');
        rl.close();
        return;
    }

    rl.close();

    // Run validation
    const validator = new AirtableValidator(apiKey, baseId);
    
    try {
        await validator.execute();
    } catch (error) {
        console.error('Validation failed:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = AirtableValidator;