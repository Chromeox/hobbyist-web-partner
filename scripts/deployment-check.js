#!/usr/bin/env node

// Deployment Health Check Script
// Verifies all necessary files are present for successful Vercel deployment

const fs = require('fs');
const path = require('path');

console.log('🔍 HobbyistSwiftUI Web Partner - Deployment Health Check\n');

const checks = [
  {
    name: 'package.json exists',
    check: () => fs.existsSync('package.json'),
    fix: 'Create package.json with proper Next.js dependencies'
  },
  {
    name: 'package-lock.json exists', 
    check: () => fs.existsSync('package-lock.json'),
    fix: 'Run "npm install" to generate package-lock.json'
  },
  {
    name: 'next.config.js exists',
    check: () => fs.existsSync('next.config.js'),
    fix: 'Create next.config.js with basic Next.js configuration'
  },
  {
    name: 'vercel.json exists',
    check: () => fs.existsSync('vercel.json'),
    fix: 'Create vercel.json to explicitly configure build settings'
  },
  {
    name: 'App directory exists',
    check: () => fs.existsSync('app') && fs.statSync('app').isDirectory(),
    fix: 'Create app/ directory with Next.js 13+ App Router structure'
  },
  {
    name: 'Main layout file exists',
    check: () => fs.existsSync('app/layout.tsx') || fs.existsSync('app/layout.js'),
    fix: 'Create app/layout.tsx as root layout component'
  },
  {
    name: 'Home page exists',
    check: () => fs.existsSync('app/page.tsx') || fs.existsSync('app/page.js'),
    fix: 'Create app/page.tsx as home page component'
  },
  {
    name: 'Next.js dependency in package.json',
    check: () => {
      try {
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        return pkg.dependencies && pkg.dependencies.next;
      } catch {
        return false;
      }
    },
    fix: 'Add Next.js to dependencies: npm install next react react-dom'
  },
  {
    name: 'Build script in package.json',
    check: () => {
      try {
        const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        return pkg.scripts && pkg.scripts.build;
      } catch {
        return false;
      }
    },
    fix: 'Add build script: "build": "next build"'
  },
  {
    name: 'Node.js version compatibility',
    check: () => {
      const nodeVersion = process.version.match(/v(\d+)/)[1];
      return parseInt(nodeVersion) >= 18;
    },
    fix: 'Upgrade to Node.js 18+ or set "engines" in package.json'
  }
];

let allPassed = true;

checks.forEach(({ name, check, fix }) => {
  const passed = check();
  const status = passed ? '✅' : '❌';
  console.log(`${status} ${name}`);
  
  if (!passed) {
    console.log(`   💡 Fix: ${fix}\n`);
    allPassed = false;
  }
});

// Count dependencies
try {
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  const depCount = Object.keys(pkg.dependencies || {}).length;
  const devDepCount = Object.keys(pkg.devDependencies || {}).length;
  console.log(`\n📦 Dependencies: ${depCount} production, ${devDepCount} development`);
  
  if (depCount < 10) {
    console.log('⚠️  Warning: Low dependency count might indicate missing packages');
  }
} catch (error) {
  console.log('❌ Could not read package.json');
}

console.log('\n' + '='.repeat(50));
if (allPassed) {
  console.log('🎉 All checks passed! Deployment should work correctly.');
} else {
  console.log('🚨 Some issues found. Please fix the items above.');
  process.exit(1);
}