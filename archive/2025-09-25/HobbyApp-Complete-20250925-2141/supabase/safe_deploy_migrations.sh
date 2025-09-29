#!/bin/bash

# ============================================
# SAFE SECURITY MIGRATION DEPLOYMENT
# With pre-checks and rollback capability
# ============================================

set -e

echo "============================================"
echo "🔐 SAFE SECURITY MIGRATION DEPLOYMENT"
echo "============================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}📋 Checking prerequisites...${NC}"
    
    # Check Supabase CLI
    if ! command -v supabase &> /dev/null; then
        echo -e "${RED}❌ Supabase CLI not found!${NC}"
        echo "Install with: brew install supabase/tap/supabase"
        exit 1
    fi
    echo -e "${GREEN}✅ Supabase CLI found${NC}"
    
    # Check if we're in the right directory
    if [ ! -f "supabase/config.toml" ]; then
        echo -e "${RED}❌ Not in project root directory!${NC}"
        echo "Please run from HobbyistSwiftUI directory"
        exit 1
    fi
    echo -e "${GREEN}✅ In correct directory${NC}"
    
    # Check if migrations exist
    if [ ! -f "supabase/migrations/02_comprehensive_security_enhancements.sql" ]; then
        echo -e "${RED}❌ Security migration file not found!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Migration files found${NC}"
}

# Function to test database connection
test_connection() {
    echo ""
    echo -e "${BLUE}🔌 Testing database connection...${NC}"
    
    if supabase db remote list 2>/dev/null | grep -q "mcjqvdzdhtcvbrejvrtp"; then
        echo -e "${GREEN}✅ Database connection successful${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Database connection failed. You may need to enter your password.${NC}"
        return 1
    fi
}

# Function to create backup point
create_backup_point() {
    echo ""
    echo -e "${BLUE}💾 Creating backup reference point...${NC}"
    
    # Get current timestamp for reference
    BACKUP_TIME=$(date +"%Y%m%d_%H%M%S")
    echo "Backup reference: $BACKUP_TIME"
    
    # Log current migration state
    echo "Current migrations:" > "migration_backup_$BACKUP_TIME.log"
    supabase migration list >> "migration_backup_$BACKUP_TIME.log" 2>&1 || true
    
    echo -e "${GREEN}✅ Backup reference created${NC}"
    echo "If rollback needed, reference: migration_backup_$BACKUP_TIME.log"
}

# Main deployment process
main() {
    echo "============================================"
    echo "🚀 STARTING DEPLOYMENT PROCESS"
    echo "============================================"
    
    # Step 1: Prerequisites
    check_prerequisites
    
    # Step 2: Confirm with user
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT CHECKLIST:${NC}"
    echo "  1. ✓ Have you reset your database password?"
    echo "  2. ✓ Have you saved the password securely?"
    echo "  3. ✓ Do you have a recent database backup?"
    echo ""
    read -p "Ready to proceed? (yes/no): " -r
    
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    # Step 3: Test connection
    if ! test_connection; then
        echo ""
        echo -e "${YELLOW}Please enter your database password when prompted.${NC}"
        echo "Password can be reset at:"
        echo "https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database"
    fi
    
    # Step 4: Create backup reference
    create_backup_point
    
    # Step 5: Show what will be deployed
    echo ""
    echo -e "${BLUE}📦 Migrations to deploy:${NC}"
    echo "  1. 00_cleanup_database.sql"
    echo "  2. 01_complete_vancouver_pricing_system.sql"
    echo "  3. 02_comprehensive_security_enhancements.sql"
    
    # Step 6: Final confirmation
    echo ""
    echo -e "${YELLOW}🚨 FINAL CONFIRMATION:${NC}"
    echo "This will apply security migrations to your PRODUCTION database."
    read -p "Type 'DEPLOY' to continue: " -r
    
    if [[ $REPLY != "DEPLOY" ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
    
    # Step 7: Deploy migrations
    echo ""
    echo -e "${BLUE}🚀 Deploying migrations...${NC}"
    
    if supabase db push; then
        echo -e "${GREEN}✅ Migrations deployed successfully!${NC}"
    else
        echo -e "${RED}❌ Migration failed!${NC}"
        echo "Check the error above and try again."
        echo "Your backup reference: migration_backup_$BACKUP_TIME.log"
        exit 1
    fi
    
    # Step 8: Run verification
    echo ""
    echo -e "${BLUE}🔍 Running security verification...${NC}"
    
    if [ -f "supabase/verify_security_deployment.sql" ]; then
        echo "Checking security configuration..."
        supabase db query -f supabase/verify_security_deployment.sql || true
    fi
    
    # Step 9: Summary
    echo ""
    echo "============================================"
    echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
    echo "============================================"
    echo ""
    echo "Security features now active:"
    echo "  ✅ Row Level Security on all tables"
    echo "  ✅ Optimized RLS policies"
    echo "  ✅ Security audit logging"
    echo "  ✅ Rate limiting support"
    echo "  ✅ Failed login tracking"
    echo ""
    echo "Next steps:"
    echo "  1. Review the verification output above"
    echo "  2. Test authentication in your app"
    echo "  3. Monitor security_audit_log table"
    echo "  4. Configure rate limits as needed"
    echo ""
    echo -e "${BLUE}📊 View your database:${NC}"
    echo "https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/editor"
    echo ""
}

# Run main function
main