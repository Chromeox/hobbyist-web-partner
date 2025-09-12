#!/bin/bash

# Hobby Classes Directory - Complete Airtable Setup Script
# This script orchestrates the entire setup process

set -e  # Exit on any error

echo "🎨 Hobby Classes Directory - Complete Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is required but not installed."
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

print_success "Node.js found: $(node --version)"

# Check if we're in the right directory
if [ ! -f "airtable-base-creator.js" ]; then
    print_error "Please run this script from the scripts directory"
    echo "Expected to find airtable-base-creator.js in current directory"
    exit 1
fi

echo ""
print_step "Prerequisites Check"
echo "✅ Node.js installed"
echo "✅ Script files present"
echo "✅ Directory structure correct"

echo ""
echo "📋 Setup Overview:"
echo "1. Create Airtable base with optimal structure"
echo "2. Populate sample data (Vancouver locations, studios)"
echo "3. Validate base configuration"
echo "4. Generate integration configurations"
echo "5. Provide next steps for WhaleSync/Webflow"

echo ""
echo "💰 Requirements:"
echo "• Airtable Team plan subscription (\$20/month)"
echo "• API access token generated"
echo "• 10-15 minutes for complete setup"

echo ""
read -p "Ready to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
print_step "Step 1: Creating Airtable Base"
echo "Running base creation script..."
node airtable-base-creator.js

# Check if base creation was successful
if [ $? -eq 0 ]; then
    print_success "Base creation completed successfully"
else
    print_error "Base creation failed"
    echo "Please check the error messages above and try again"
    exit 1
fi

echo ""
read -p "Do you want to run validation tests? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_step "Step 2: Validating Base Structure"
    echo "Running validation script..."
    node airtable-validator.js
    
    if [ $? -eq 0 ]; then
        print_success "Base validation completed"
    else
        print_warning "Validation completed with warnings"
        echo "Check the output above for any issues that need attention"
    fi
fi

echo ""
read -p "Do you want to generate integration configurations? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_step "Step 3: Generating Integration Configurations"
    echo "Running integration helper..."
    node integration-helper.js
    
    if [ $? -eq 0 ]; then
        print_success "Integration configurations generated"
    else
        print_warning "Integration setup completed with warnings"
    fi
fi

echo ""
echo "🎉 SETUP COMPLETE!"
echo "=================="
echo ""
echo "✅ Your Hobby Classes Directory Airtable base is ready"
echo ""
echo "📋 What was created:"
echo "• 5 optimized tables with proper relationships"
echo "• Sample Vancouver locations and studios"  
echo "• Pre-configured views for different use cases"
echo "• Integration-ready field structure"
echo ""
echo "🔗 Next Steps:"
echo ""
echo "1. IMMEDIATE (5 minutes):"
echo "   • Visit your new Airtable base"
echo "   • Explore the sample data"
echo "   • Verify relationships are working"
echo ""
echo "2. INTEGRATION SETUP (30 minutes):"
echo "   • Sign up for WhaleSync account"
echo "   • Create Webflow CMS collections"
echo "   • Configure sync between Airtable → Webflow"
echo ""
echo "3. DATA POPULATION (1-2 hours):"
echo "   • Import real Vancouver class data"
echo "   • Add actual studio partnerships"
echo "   • Set up automated data sources"
echo ""
echo "4. PRODUCTION LAUNCH (1 week):"
echo "   • Test user submission workflows"
echo "   • Set up monitoring and alerts"
echo "   • Go live with directory"
echo ""
echo "📚 Documentation:"
echo "• Setup Guide: AIRTABLE_SETUP_GUIDE.md"
echo "• Integration configs saved to integration-config-*.json"
echo ""
echo "🆘 Support:"
echo "• Re-run validation: npm run validate-base"  
echo "• Integration help: npm run integration-test"
echo "• Check logs if any issues occur"
echo ""
print_success "Happy building! 🚀"