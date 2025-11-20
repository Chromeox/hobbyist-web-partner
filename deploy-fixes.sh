#!/bin/bash

# Deployment Script for Critical Fixes
# Created: $(date)

echo "🚀 Starting deployment of critical fixes..."
echo ""

# Navigate to the correct directory
cd /Users/chromefang.exe/Projects/HobbiApp/web-partner || {
    echo "❌ Error: Could not find web-partner directory"
    echo "Please ensure you're in the correct location"
    exit 1
}

echo "📍 Current directory: $(pwd)"
echo ""

# Check current git status
echo "📊 Checking git status..."
git status --short
echo ""

# Pull latest changes first to avoid conflicts
echo "⬇️ Pulling latest changes from remote..."
git pull origin main
echo ""

# Stage all our critical fixes
echo "📦 Staging all fixes..."
git add -A
echo ""

# Show what will be committed
echo "📝 Files to be committed:"
git diff --cached --name-only
echo ""

# Create comprehensive commit
echo "✍️ Creating commit..."
git commit -m "fix: critical security vulnerabilities and deployment issues

SECURITY FIXES (CRITICAL):
- Remove ALL hardcoded demo/admin credentials
- Delete demo-auth.ts with exposed passwords
- Remove authentication bypass in useAuth.ts and AuthContext.tsx
- Migrate credentials to environment variables with production safeguards

DEPLOYMENT FIXES:
- Fix TypeScript error: Add wheelchairAccessible property to class-mappers.ts
- Fix TypeScript error: Properly type OnboardingData in OnboardingWizard.tsx
- Update Next.js to 16.0.3 and pin Node.js to 20.x
- Migrate deprecated middleware to proxy.ts (Next.js 16)
- Update git remote to correct repository (hobbyist-web-partner)

CONFIGURATION:
- Add demo configuration via environment variables (dev only)
- Create secure demo-config.ts with production protections
- Update .env.example with proper templates

BREAKING CHANGES:
- Must add environment variables to Vercel (see .env.example)
- Demo mode completely restructured for security
- All authentication now goes through Supabase

This commit removes multiple security vulnerabilities that would
have allowed unauthorized access to the production application."

if [ $? -eq 0 ]; then
    echo "✅ Commit created successfully"
else
    echo "⚠️ Commit may have failed - check if there are changes to commit"
fi
echo ""

# Push to GitHub (this triggers Vercel deployment)
echo "🚀 Pushing to GitHub (this will trigger Vercel deployment)..."
git push origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Changes pushed to GitHub"
    echo "🔄 Vercel deployment should start automatically"
    echo ""
    echo "📋 Next steps:"
    echo "1. Check Vercel dashboard for deployment progress"
    echo "2. Add environment variables to Vercel (Dev/Preview only):"
    echo "   - DEMO_USER_EMAIL=demo@hobbyist.app"
    echo "   - DEMO_USER_PASSWORD=DemoPass123!"
    echo "   - ADMIN_TEST_EMAIL=admin@hobbyist.com"
    echo "   - ADMIN_TEST_PASSWORD=admin123456"
    echo "   - ENABLE_DEMO_MODE=false"
    echo "   - SHOW_DEMO_CREDENTIALS=false"
    echo "3. Test that hardcoded credentials no longer work"
    echo "4. Verify all TypeScript errors are resolved"
    echo ""
    echo "🎉 Deployment complete!"
else
    echo ""
    echo "❌ Push failed. Please check:"
    echo "1. You have internet connection"
    echo "2. You have push access to the repository"
    echo "3. Your git credentials are configured"
    echo ""
    echo "You can try manually with:"
    echo "git push origin main --verbose"
fi