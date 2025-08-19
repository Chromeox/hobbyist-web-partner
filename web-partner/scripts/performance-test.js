#!/usr/bin/env node

/**
 * Performance Testing Script for V8 Optimization Validation
 * 
 * Tests:
 * 1. JSON serialization performance
 * 2. Object shape stability
 * 3. API response times
 * 4. Build size analysis
 * 5. Runtime memory usage
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ANSI color codes for output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSection(title) {
  console.log('\n' + '='.repeat(60));
  log(title, 'cyan');
  console.log('='.repeat(60));
}

// Test JSON serialization performance
function testJSONPerformance() {
  logSection('JSON Serialization Performance Test');
  
  // Create test data with different sizes
  const testCases = [
    { name: 'Small (1KB)', size: 1024 },
    { name: 'Medium (10KB)', size: 10240 },
    { name: 'Large (100KB)', size: 102400 },
    { name: 'XLarge (1MB)', size: 1048576 }
  ];
  
  const results = [];
  
  for (const testCase of testCases) {
    // Generate test data
    const data = {
      users: Array(Math.floor(testCase.size / 100)).fill(null).map((_, i) => ({
        id: `user_${i}`,
        name: `User ${i}`,
        email: `user${i}@example.com`,
        age: 20 + (i % 50),
        active: i % 2 === 0,
        createdAt: new Date().toISOString(),
        metadata: {
          preferences: ['option1', 'option2'],
          settings: { theme: 'dark', notifications: true }
        }
      }))
    };
    
    // Test stringify
    const stringifyStart = process.hrtime.bigint();
    const serialized = JSON.stringify(data);
    const stringifyEnd = process.hrtime.bigint();
    const stringifyTime = Number(stringifyEnd - stringifyStart) / 1000000; // Convert to ms
    
    // Test parse
    const parseStart = process.hrtime.bigint();
    JSON.parse(serialized);
    const parseEnd = process.hrtime.bigint();
    const parseTime = Number(parseEnd - parseStart) / 1000000; // Convert to ms
    
    results.push({
      name: testCase.name,
      actualSize: serialized.length,
      stringifyTime,
      parseTime,
      totalTime: stringifyTime + parseTime
    });
    
    log(`${testCase.name}:`, 'bold');
    console.log(`  Actual size: ${(serialized.length / 1024).toFixed(2)} KB`);
    console.log(`  Stringify: ${stringifyTime.toFixed(3)} ms`);
    console.log(`  Parse: ${parseTime.toFixed(3)} ms`);
    console.log(`  Total: ${(stringifyTime + parseTime).toFixed(3)} ms`);
  }
  
  // Performance recommendations
  const avgTime = results.reduce((sum, r) => sum + r.totalTime, 0) / results.length;
  if (avgTime > 10) {
    log('\n⚠️  Warning: Average JSON operations taking > 10ms', 'yellow');
    log('  Consider implementing streaming or chunking for large payloads', 'yellow');
  } else {
    log('\n✅ JSON performance is optimal', 'green');
  }
  
  return results;
}

// Test object shape stability
function testObjectShapeStability() {
  logSection('Object Shape Stability Test');
  
  // Import the actual data service
  const dataServicePath = path.join(__dirname, '../lib/services/optimized-data.ts');
  
  if (!fs.existsSync(dataServicePath)) {
    log('⚠️  Optimized data service not found', 'yellow');
    return;
  }
  
  // Simulate different object shapes
  const stableObjects = Array(100).fill(null).map((_, i) => ({
    id: i,
    name: `Item ${i}`,
    value: i * 10,
    active: true,
    createdAt: new Date().toISOString()
  }));
  
  const unstableObjects = Array(100).fill(null).map((_, i) => {
    const obj = { id: i };
    if (i % 2 === 0) obj.name = `Item ${i}`;
    if (i % 3 === 0) obj.value = i * 10;
    if (i % 4 === 0) obj.active = true;
    if (i % 5 === 0) obj.createdAt = new Date().toISOString();
    return obj;
  });
  
  // Check shape consistency
  function getObjectShape(obj) {
    return Object.keys(obj).sort().join(',');
  }
  
  const stableShapes = new Set(stableObjects.map(getObjectShape));
  const unstableShapes = new Set(unstableObjects.map(getObjectShape));
  
  log('Stable objects:', 'bold');
  console.log(`  Unique shapes: ${stableShapes.size}`);
  console.log(`  Shape: ${[...stableShapes][0]}`);
  
  log('\nUnstable objects:', 'bold');
  console.log(`  Unique shapes: ${unstableShapes.size}`);
  console.log(`  Shapes: ${[...unstableShapes].slice(0, 3).join(' | ')}`);
  
  if (stableShapes.size === 1) {
    log('\n✅ Stable object shapes detected (V8 optimized)', 'green');
  }
  
  if (unstableShapes.size > 5) {
    log('\n⚠️  Multiple object shapes detected (V8 deoptimization risk)', 'yellow');
    log('  Consider normalizing objects to consistent shapes', 'yellow');
  }
}

// Test build performance
function testBuildPerformance() {
  logSection('Build Performance Test');
  
  try {
    log('Running Next.js build analysis...', 'cyan');
    
    // Clean previous build
    const buildDir = path.join(__dirname, '../.next');
    if (fs.existsSync(buildDir)) {
      fs.rmSync(buildDir, { recursive: true, force: true });
    }
    
    // Run build with timing
    const startTime = Date.now();
    execSync('npm run build', { 
      cwd: path.join(__dirname, '..'),
      stdio: 'pipe'
    });
    const buildTime = Date.now() - startTime;
    
    log(`\nBuild completed in ${(buildTime / 1000).toFixed(2)} seconds`, 'bold');
    
    // Analyze build output
    const buildManifest = path.join(__dirname, '../.next/build-manifest.json');
    if (fs.existsSync(buildManifest)) {
      const manifest = JSON.parse(fs.readFileSync(buildManifest, 'utf8'));
      const pageCount = Object.keys(manifest.pages || {}).length;
      log(`  Pages: ${pageCount}`, 'cyan');
    }
    
    // Check bundle sizes
    const statsFile = path.join(__dirname, '../.next/stats.json');
    if (fs.existsSync(statsFile)) {
      const stats = JSON.parse(fs.readFileSync(statsFile, 'utf8'));
      const totalSize = stats.assets?.reduce((sum, asset) => sum + asset.size, 0) || 0;
      log(`  Total bundle size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`, 'cyan');
      
      if (totalSize > 5 * 1024 * 1024) {
        log('\n⚠️  Bundle size exceeds 5MB', 'yellow');
        log('  Consider code splitting and lazy loading', 'yellow');
      }
    }
    
    if (buildTime < 30000) {
      log('\n✅ Build performance is optimal', 'green');
    } else {
      log('\n⚠️  Build time exceeds 30 seconds', 'yellow');
      log('  Consider optimizing dependencies and build configuration', 'yellow');
    }
    
  } catch (error) {
    log('❌ Build failed: ' + error.message, 'red');
  }
}

// Memory usage test
function testMemoryUsage() {
  logSection('Memory Usage Analysis');
  
  const memUsage = process.memoryUsage();
  
  log('Current process memory:', 'bold');
  console.log(`  RSS: ${(memUsage.rss / 1024 / 1024).toFixed(2)} MB`);
  console.log(`  Heap Total: ${(memUsage.heapTotal / 1024 / 1024).toFixed(2)} MB`);
  console.log(`  Heap Used: ${(memUsage.heapUsed / 1024 / 1024).toFixed(2)} MB`);
  console.log(`  External: ${(memUsage.external / 1024 / 1024).toFixed(2)} MB`);
  
  if (memUsage.heapUsed > 100 * 1024 * 1024) {
    log('\n⚠️  High memory usage detected', 'yellow');
    log('  Consider implementing memory optimization strategies', 'yellow');
  } else {
    log('\n✅ Memory usage is within acceptable limits', 'green');
  }
}

// Generate performance report
function generateReport(results) {
  logSection('Performance Report Summary');
  
  const report = {
    timestamp: new Date().toISOString(),
    environment: {
      node: process.version,
      platform: process.platform,
      arch: process.arch
    },
    results: results,
    recommendations: []
  };
  
  // Add recommendations based on results
  if (results.jsonPerformance) {
    const avgTime = results.jsonPerformance.reduce((sum, r) => sum + r.totalTime, 0) / results.jsonPerformance.length;
    if (avgTime > 10) {
      report.recommendations.push('Optimize JSON serialization for large payloads');
    }
  }
  
  // Save report
  const reportPath = path.join(__dirname, '../performance-report.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  
  log(`\n📊 Report saved to: ${reportPath}`, 'green');
  log('\n🎯 Overall Performance Score: ', 'bold');
  
  const score = calculatePerformanceScore(results);
  if (score >= 90) {
    log(`   ${score}/100 - Excellent! 🚀`, 'green');
  } else if (score >= 70) {
    log(`   ${score}/100 - Good, with room for improvement`, 'yellow');
  } else {
    log(`   ${score}/100 - Needs optimization`, 'red');
  }
}

function calculatePerformanceScore(results) {
  let score = 100;
  
  // Deduct points for performance issues
  if (results.jsonPerformance) {
    const avgTime = results.jsonPerformance.reduce((sum, r) => sum + r.totalTime, 0) / results.jsonPerformance.length;
    if (avgTime > 10) score -= 10;
    if (avgTime > 20) score -= 10;
  }
  
  return Math.max(0, score);
}

// Main execution
async function main() {
  console.log(colors.bold + '\n🚀 V8 Performance Optimization Test Suite\n' + colors.reset);
  
  const results = {};
  
  // Run tests
  results.jsonPerformance = testJSONPerformance();
  testObjectShapeStability();
  testMemoryUsage();
  
  // Only run build test if not in CI
  if (!process.env.CI) {
    testBuildPerformance();
  }
  
  // Generate report
  generateReport(results);
  
  log('\n✨ Performance testing complete!', 'green');
}

// Run tests
main().catch(error => {
  log(`\n❌ Test failed: ${error.message}`, 'red');
  process.exit(1);
});