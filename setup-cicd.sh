#!/bin/bash

# HobbyistSwiftUI CI/CD Setup Script
# Automates certificate repository creation and Match initialization

set -e

echo "🚀 HobbyistSwiftUI CI/CD Setup Starting..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "iOS/HobbyistSwiftUI.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Please run this script from the HobbyistSwiftUI root directory${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check if Fastlane is installed
if ! command -v fastlane &> /dev/null; then
    echo -e "${YELLOW}⚠️  Fastlane not found. Installing...${NC}"
    gem install fastlane
else
    echo -e "${GREEN}✅ Fastlane installed${NC}"
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Installing with Homebrew...${NC}"
    brew install gh
else
    echo -e "${GREEN}✅ GitHub CLI installed${NC}"
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not authenticated${NC}"
    echo -e "${BLUE}Please authenticate with GitHub:${NC}"
    gh auth login
fi

echo -e "${GREEN}✅ Prerequisites checked${NC}"
echo ""

# Phase 1: Create Certificate Repository
echo -e "${BLUE}📦 Phase 1: Creating Certificate Repository${NC}"

CERT_REPO_NAME="HobbyistSwiftUI-certificates"
CERT_REPO_URL="https://github.com/Chromeox/${CERT_REPO_NAME}.git"

# Check if certificate repository already exists
if gh repo view "Chromeox/${CERT_REPO_NAME}" &> /dev/null; then
    echo -e "${GREEN}✅ Certificate repository already exists: ${CERT_REPO_URL}${NC}"
else
    echo -e "${YELLOW}Creating private certificate repository...${NC}"
    gh repo create "${CERT_REPO_NAME}" \
        --private \
        --description "Certificate storage for HobbyistSwiftUI CI/CD pipeline" \
        --add-readme
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Certificate repository created: ${CERT_REPO_URL}${NC}"
    else
        echo -e "${RED}❌ Failed to create certificate repository${NC}"
        exit 1
    fi
fi

echo ""

# Phase 2: Initialize Match (if not already initialized)
echo -e "${BLUE}🔐 Phase 2: Match Configuration${NC}"

cd iOS

if [ ! -f "Matchfile" ]; then
    echo -e "${YELLOW}Initializing Match for certificate management...${NC}"
    
    # Create Matchfile
    cat > Matchfile << EOF
git_url("${CERT_REPO_URL}")
storage_mode("git")
type("development")
app_identifier(["com.hobbyist.app"])
username("$(git config user.email)")
team_id() # Will be set via DEVELOPER_TEAM_ID environment variable
EOF
    
    echo -e "${GREEN}✅ Matchfile created${NC}"
else
    echo -e "${GREEN}✅ Matchfile already exists${NC}"
fi

cd ..

# Phase 3: Create GitHub Secrets Template
echo -e "${BLUE}📝 Phase 3: GitHub Secrets Configuration${NC}"

cat > github-secrets-template.md << EOF
# GitHub Secrets Configuration for HobbyistSwiftUI CI/CD

## Required Secrets
Go to: https://github.com/Chromeox/HobbyistSwiftUI/settings/secrets/actions

### Apple Developer Credentials
1. **APPLE_ID**: Your Apple Developer account email
2. **DEVELOPER_TEAM_ID**: Your 10-character Team ID from Apple Developer Portal
3. **APP_STORE_CONNECT_TEAM_ID**: Usually same as DEVELOPER_TEAM_ID
4. **FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD**: Generate at appleid.apple.com

### Certificate Management
5. **MATCH_PASSWORD**: Strong password to encrypt certificates (generate with: openssl rand -base64 32)
6. **MATCH_GIT_URL**: ${CERT_REPO_URL}

### Optional Notifications
7. **SLACK_WEBHOOK_URL**: For deployment notifications (optional)
8. **BETA_FEEDBACK_EMAIL**: Email for TestFlight feedback

## Quick Setup Commands
\`\`\`bash
# Generate Match password
echo "MATCH_PASSWORD: \$(openssl rand -base64 32)"

# Get Team ID
echo "Visit: https://developer.apple.com/account/#!/membership/"

# Create App-Specific Password  
echo "Visit: https://appleid.apple.com/account/manage → Security → App-Specific Passwords"
\`\`\`

## Test Commands (after secrets are set)
\`\`\`bash
# Test security scan
gh workflow run "Swift Dependency Security Scan"

# Test TestFlight deployment
gh workflow run "App Store Deployment Automation" \\
  -f deployment_type=testflight \\
  -f changelog="CI/CD pipeline test" \\
  -f skip_tests=true
\`\`\`
EOF

echo -e "${GREEN}✅ GitHub secrets template created: github-secrets-template.md${NC}"

# Phase 4: Validate Current Workflows
echo -e "${BLUE}🔍 Phase 4: Validating CI/CD Workflows${NC}"

if [ -f ".github/workflows/dependency-security-scan.yml" ]; then
    echo -e "${GREEN}✅ Security scan workflow exists${NC}"
else
    echo -e "${RED}❌ Missing security scan workflow${NC}"
fi

if [ -f ".github/workflows/app-store-deployment.yml" ]; then
    echo -e "${GREEN}✅ App Store deployment workflow exists${NC}"
else
    echo -e "${RED}❌ Missing deployment workflow${NC}"
fi

if [ -f "fastlane/Fastfile" ]; then
    echo -e "${GREEN}✅ Fastlane configuration exists${NC}"
else
    echo -e "${RED}❌ Missing Fastlane configuration${NC}"
fi

echo ""

# Summary
echo -e "${GREEN}🎉 CI/CD Setup Complete!${NC}"
echo "=========================================="
echo -e "${BLUE}Next Steps:${NC}"
echo "1. 📝 Configure GitHub secrets using: github-secrets-template.md"
echo "2. 🔐 Set up Apple Developer certificates locally first:"
echo "   cd iOS && fastlane match development --app_identifier com.hobbyist.app"
echo "3. 🧪 Test the pipeline:"
echo "   gh workflow run 'Swift Dependency Security Scan'"
echo "4. 🚀 Deploy to TestFlight:"
echo "   gh workflow run 'App Store Deployment Automation' -f deployment_type=testflight -f changelog='First automated build'"
echo ""
echo -e "${YELLOW}📖 Full documentation: iOS/CICD_SETUP_GUIDE.md${NC}"
echo -e "${GREEN}Certificate Repository: ${CERT_REPO_URL}${NC}"
echo -e "${GREEN}Main Repository: https://github.com/Chromeox/HobbyistSwiftUI${NC}"

# Open relevant files
if command -v open &> /dev/null; then
    echo ""
    echo -e "${BLUE}Opening relevant files...${NC}"
    open github-secrets-template.md
    open https://github.com/Chromeox/HobbyistSwiftUI/settings/secrets/actions
fi
EOF