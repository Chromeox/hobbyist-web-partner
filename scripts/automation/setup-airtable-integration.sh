#!/bin/bash

# Setup Script for Direct Airtable Integration
# This replaces Google Sheets with direct Airtable API

echo "🔧 Setting up Direct Airtable Integration"
echo "=====================================\n"

# Check if we're in the right directory
if [ ! -f "scripts/automation/airtable-direct-scraper.js" ]; then
    echo "❌ Please run this from the project root directory"
    exit 1
fi

cd scripts/automation

# Install required packages
echo "📦 Installing required packages..."
npm install airtable playwright dotenv

if [ $? -ne 0 ]; then
    echo "❌ Failed to install packages"
    exit 1
fi

echo "✅ Packages installed successfully\n"

# Copy environment template
if [ ! -f ".env.airtable" ]; then
    echo "📄 Creating environment file..."
    cp env.airtable.template .env.airtable
    echo "✅ Created .env.airtable from template\n"
else
    echo "ℹ️ .env.airtable already exists\n"
fi

# Instructions for user
echo "🔑 SETUP INSTRUCTIONS:"
echo "=====================\n"
echo "1. Get your Airtable Personal Access Token:"
echo "   → Go to: https://airtable.com/create/tokens"
echo "   → Create new token with permissions:"
echo "     - data.records:read"
echo "     - data.records:write"
echo "   → Select your base scope\n"

echo "2. Get your Airtable Base ID:"
echo "   → Go to: https://airtable.com/api"
echo "   → Select your base"
echo "   → Copy the Base ID (starts with 'app')\n"

echo "3. Update .env.airtable with your values:"
echo "   → AIRTABLE_TOKEN=your_token_here"
echo "   → AIRTABLE_BASE_ID=your_base_id_here\n"

echo "4. Test the integration:"
echo "   → node airtable-direct-scraper.js\n"

echo "🎯 BENEFITS OF THIS CHANGE:"
echo "==========================\n"
echo "✅ Eliminates Google Sheets complexity"
echo "✅ No more manual CSV exports"
echo "✅ Direct data flow: Instagram → Airtable → Webflow"
echo "✅ Faster and more reliable"
echo "✅ Matches your documentation's recommended architecture\n"

echo "📝 Next steps after setup:"
echo "1. Test the scraper: node airtable-direct-scraper.js"
echo "2. Update your cron jobs to use this script"
echo "3. Verify WhaleSync continues syncing to Webflow"
echo "4. Remove old Google Sheets scripts\n"

echo "🚀 Setup complete! Edit .env.airtable to get started."