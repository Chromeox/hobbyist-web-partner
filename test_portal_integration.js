#!/usr/bin/env node

/**
 * Partner Portal Integration Test
 * Tests the complete partner portal with real data
 */

const http = require('http');
const https = require('https');

const PORTAL_BASE_URL = 'http://localhost:3000';

/**
 * Make HTTP request
 */
function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const isHttps = url.startsWith('https://');
        const client = isHttps ? https : http;
        
        const req = client.request(url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    body: data
                });
            });
        });
        
        req.on('error', reject);
        
        if (options.body) {
            req.write(options.body);
        }
        
        req.end();
    });
}

/**
 * Test portal endpoints
 */
async function testPortalEndpoints() {
    console.log('🌐 Testing Partner Portal Endpoints');
    console.log('=' .repeat(45));
    
    const tests = [
        {
            name: 'Home Page',
            url: `${PORTAL_BASE_URL}/`,
            expectedStatus: 200
        },
        {
            name: 'Dashboard',
            url: `${PORTAL_BASE_URL}/dashboard`,
            expectedStatus: 200
        },
        {
            name: 'Dashboard Intelligence API',
            url: `${PORTAL_BASE_URL}/api/dashboard/intelligence-data`,
            expectedStatus: 200
        },
        {
            name: 'Studio Metrics API',
            url: `${PORTAL_BASE_URL}/api/dashboard/studio-metrics`,
            expectedStatus: 200
        },
        {
            name: 'Reservations Page',
            url: `${PORTAL_BASE_URL}/dashboard/reservations`,
            expectedStatus: 200
        }
    ];
    
    let passed = 0;
    let total = tests.length;
    
    for (const test of tests) {
        console.log(`\n📋 Testing: ${test.name}`);
        console.log(`   URL: ${test.url}`);
        
        try {
            const response = await makeRequest(test.url);
            
            if (response.statusCode === test.expectedStatus) {
                console.log(`   ✅ Status: ${response.statusCode} (Expected: ${test.expectedStatus})`);
                
                // Check for common issues
                if (response.body.includes('error') || response.body.includes('Error')) {
                    console.log('   ⚠️  Warning: Response contains error messages');
                } else if (response.body.includes('Loading') || response.body.includes('loading')) {
                    console.log('   ℹ️  Note: Page shows loading state');
                } else {
                    console.log('   ✅ Content loaded successfully');
                }
                
                passed++;
            } else {
                console.log(`   ❌ Status: ${response.statusCode} (Expected: ${test.expectedStatus})`);
                if (response.statusCode >= 500) {
                    console.log('   💥 Server error detected');
                } else if (response.statusCode >= 400) {
                    console.log('   🔒 Client error (possibly auth issue)');
                }
            }
            
        } catch (error) {
            console.log(`   ❌ Request failed: ${error.message}`);
            if (error.code === 'ECONNREFUSED') {
                console.log('   🚫 Portal is not running or not accessible');
            }
        }
    }
    
    return { passed, total };
}

/**
 * Test data integration
 */
async function testDataIntegration() {
    console.log('\n📊 Testing Data Integration');
    console.log('=' .repeat(30));
    
    try {
        const response = await makeRequest(`${PORTAL_BASE_URL}/api/dashboard/intelligence-data`);
        
        if (response.statusCode === 200) {
            console.log('✅ API endpoint accessible');
            
            try {
                const data = JSON.parse(response.body);
                
                if (data.error) {
                    console.log(`❌ API Error: ${data.error}`);
                    return false;
                }
                
                // Check for expected data structure
                const expectedKeys = ['totalRevenue', 'totalBookings', 'avgRating', 'totalStudents'];
                const hasExpectedData = expectedKeys.some(key => data.hasOwnProperty(key));
                
                if (hasExpectedData) {
                    console.log('✅ Dashboard data structure is valid');
                    console.log(`   📈 Contains metrics: ${Object.keys(data).join(', ')}`);
                    return true;
                } else {
                    console.log('❌ Unexpected data structure');
                    console.log(`   📋 Received keys: ${Object.keys(data).join(', ')}`);
                    return false;
                }
                
            } catch (parseError) {
                console.log('❌ Invalid JSON response');
                return false;
            }
            
        } else {
            console.log(`❌ API not accessible (Status: ${response.statusCode})`);
            return false;
        }
        
    } catch (error) {
        console.log(`❌ Data integration test failed: ${error.message}`);
        return false;
    }
}

/**
 * Main test runner
 */
async function runPortalTests() {
    console.log('🧪 Partner Portal Integration Tests');
    console.log('=' .repeat(50));
    console.log(`🎯 Target: ${PORTAL_BASE_URL}`);
    
    // Wait a moment for portal to be ready
    console.log('\n⏳ Waiting for portal to be ready...');
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    const endpointResults = await testPortalEndpoints();
    const dataIntegrationSuccess = await testDataIntegration();
    
    console.log('\n📊 Final Test Results');
    console.log('=' .repeat(35));
    console.log(`Endpoint Tests: ${endpointResults.passed}/${endpointResults.total} passed`);
    console.log(`Data Integration: ${dataIntegrationSuccess ? '✅ Success' : '❌ Failed'}`);
    
    const overallSuccess = endpointResults.passed === endpointResults.total && dataIntegrationSuccess;
    
    if (overallSuccess) {
        console.log('\n🎉 Partner Portal Integration Complete!');
        console.log('✅ All systems operational');
        console.log('✅ Ready for studio onboarding');
        console.log('🚀 Portal accessible at: http://localhost:3000');
    } else {
        console.log('\n⚠️  Issues detected in portal integration');
        console.log('❌ Review failures before launch');
    }
    
    return overallSuccess;
}

// Run tests if called directly
if (require.main === module) {
    runPortalTests()
        .then(success => {
            process.exit(success ? 0 : 1);
        })
        .catch(error => {
            console.error('Fatal error:', error);
            process.exit(1);
        });
}

module.exports = { runPortalTests, testPortalEndpoints, testDataIntegration };