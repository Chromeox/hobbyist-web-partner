#!/bin/bash

# HobbyistSwiftUI Partner Portal Startup Script
echo "🚀 Starting HobbyistSwiftUI Partner Portal..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Navigate to web-partner directory
cd "$(dirname "$0")"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found. Please run this script from the web-partner directory."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
else
    echo "✅ Dependencies already installed"
fi

# Create .env.local if it doesn't exist
if [ ! -f ".env.local" ]; then
    echo "⚙️  Creating environment configuration..."
    cp .env.example .env.local
    echo "✅ Created .env.local from template"
fi

# Start the development server
echo ""
echo "🌟 Starting Partner Portal Development Server..."
echo ""
echo "📱 Your partner portal will be available at:"
echo "   http://localhost:3000"
echo ""
echo "🎯 Features available:"
echo "   • Multi-step onboarding wizard"
echo "   • Studio dashboard with analytics"
echo "   • Class management (CRUD)"
echo "   • Staff invitation & management"
echo "   • Booking management & communication"
echo "   • Settings & subscription management"
echo ""
echo "🛑 Press Ctrl+C to stop the server"
echo ""

# Run the development server
npm run dev