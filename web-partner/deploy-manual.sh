#!/bin/bash

echo "🚀 Manual Deployment Script for Studio Portal"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Make sure you're in the web-partner directory."
    exit 1
fi

echo "📦 Installing dependencies..."
npm ci

echo "🔨 Building application..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📁 Build files are in .next/ directory"
    echo ""
    echo "Next steps to deploy manually:"
    echo "1. Upload .next/ folder to your hosting provider"
    echo "2. Set environment variables on your hosting platform"
    echo "3. Configure server to serve Next.js static files"
    echo ""
    echo "Alternative platforms to try:"
    echo "• Netlify: https://netlify.com (drag & drop deployment)"
    echo "• Railway: https://railway.app (GitHub integration)"
    echo "• Render: https://render.com (simple deployment)"
    echo ""
    echo "🌟 Build completed successfully - your app is ready!"
else
    echo "❌ Build failed. Check the errors above."
    exit 1
fi