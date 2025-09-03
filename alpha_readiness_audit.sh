#!/bin/bash

# Comprehensive Alpha Readiness Audit for HobbyistSwiftUI
# This script checks all critical components for alpha launch

echo "================================================"
echo "   HOBBYIST ALPHA READINESS AUDIT"
echo "================================================"
echo ""
echo "Date: $(date)"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Function to check status
check_status() {
    local status=$1
    local component=$2
    local details=$3
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - $component"
        ((PASS++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC} - $component"
        ((FAIL++))
    else
        echo -e "${YELLOW}⚠️  WARN${NC} - $component"
        ((WARN++))
    fi
    
    if [ ! -z "$details" ]; then
        echo "         $details"
    fi
    echo ""
}

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}1. iOS APP STRUCTURE & FEATURES${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check iOS app files
if [ -d "iOS/HobbyistSwiftUI" ]; then
    SWIFT_COUNT=$(find iOS/HobbyistSwiftUI -name "*.swift" -type f | wc -l | tr -d ' ')
    if [ "$SWIFT_COUNT" -gt 50 ]; then
        check_status "PASS" "iOS App Code Base" "$SWIFT_COUNT Swift files found"
    else
        check_status "WARN" "iOS App Code Base" "Only $SWIFT_COUNT Swift files found"
    fi
else
    check_status "FAIL" "iOS App Code Base" "iOS directory not found"
fi

# Check core iOS views
echo "Checking iOS Views..."
for view in "AuthView" "HomeView" "ClassDetailView" "BookingView" "ProfileView" "SettingsView"; do
    if find iOS/HobbyistSwiftUI/Views -name "*${view}*" 2>/dev/null | grep -q .; then
        check_status "PASS" "iOS View: $view" ""
    else
        check_status "FAIL" "iOS View: $view" "Not found"
    fi
done

# Check iOS services
echo "Checking iOS Services..."
for service in "AuthenticationManager" "BookingService" "PaymentService" "NotificationService"; do
    if find iOS/HobbyistSwiftUI/Services -name "*${service}*" 2>/dev/null | grep -q .; then
        check_status "PASS" "iOS Service: $service" ""
    else
        check_status "WARN" "iOS Service: $service" "May be named differently"
    fi
done

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}2. WEB PARTNER PORTAL${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check web portal pages
if [ -d "web-partner/app" ]; then
    check_status "PASS" "Web Portal Structure" "App directory exists"
    
    # Check critical pages
    for page in "dashboard" "onboarding" "auth" "legal"; do
        if [ -d "web-partner/app/$page" ]; then
            check_status "PASS" "Portal Page: $page" ""
        else
            check_status "FAIL" "Portal Page: $page" "Directory not found"
        fi
    done
else
    check_status "FAIL" "Web Portal Structure" "web-partner/app not found"
fi

# Check package.json for dependencies
if [ -f "web-partner/package.json" ]; then
    if grep -q "@supabase/supabase-js" web-partner/package.json; then
        check_status "PASS" "Portal: Supabase Integration" ""
    else
        check_status "FAIL" "Portal: Supabase Integration" "Supabase not in dependencies"
    fi
    
    if grep -q "stripe" web-partner/package.json; then
        check_status "PASS" "Portal: Stripe Integration" ""
    else
        check_status "WARN" "Portal: Stripe Integration" "Stripe not in dependencies"
    fi
fi

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}3. DATABASE & BACKEND${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check Supabase migrations
MIGRATION_COUNT=$(ls supabase/migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')
if [ "$MIGRATION_COUNT" -gt 5 ]; then
    check_status "PASS" "Database Migrations" "$MIGRATION_COUNT migration files"
else
    check_status "WARN" "Database Migrations" "Only $MIGRATION_COUNT migration files"
fi

# Check edge functions
EDGE_FUNC_COUNT=$(ls -d supabase/functions/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$EDGE_FUNC_COUNT" -ge 4 ]; then
    check_status "PASS" "Edge Functions" "$EDGE_FUNC_COUNT functions deployed"
else
    check_status "FAIL" "Edge Functions" "Only $EDGE_FUNC_COUNT functions found"
fi

# Check for critical edge functions
for func in "process-payment" "send-notification" "analytics" "class-recommendations"; do
    if [ -d "supabase/functions/$func" ]; then
        check_status "PASS" "Edge Function: $func" ""
    else
        check_status "FAIL" "Edge Function: $func" "Not found"
    fi
done

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}4. AUTHENTICATION & SECURITY${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check for auth configuration
if [ -f "iOS/HobbyistSwiftUI/Configuration.swift" ]; then
    check_status "PASS" "iOS Configuration File" ""
else
    check_status "FAIL" "iOS Configuration File" "Configuration.swift not found"
fi

# Check for OAuth setup
if grep -q "GOOGLE_CLIENT_ID" web-partner/supabase-credentials.env 2>/dev/null; then
    check_status "PASS" "OAuth Configuration" "Google OAuth configured"
else
    check_status "WARN" "OAuth Configuration" "Google OAuth not fully configured"
fi

# Check security files
if [ -d "iOS/HobbyistSwiftUI/Security" ]; then
    check_status "PASS" "iOS Security Layer" "Security directory exists"
else
    check_status "WARN" "iOS Security Layer" "Security directory not found"
fi

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}5. LEGAL & COMPLIANCE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check for legal pages
if [ -d "web-partner/app/legal" ]; then
    for doc in "privacy" "terms"; do
        if ls web-partner/app/legal/*${doc}* 2>/dev/null | grep -q .; then
            check_status "PASS" "Legal: ${doc^} Policy" ""
        else
            check_status "FAIL" "Legal: ${doc^} Policy" "Not found"
        fi
    done
else
    check_status "FAIL" "Legal Pages" "Legal directory not found"
fi

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}6. PAYMENT SYSTEM${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check Stripe integration
if [ -f "supabase/functions/process-payment/index.ts" ]; then
    check_status "PASS" "Payment Processing Function" ""
else
    check_status "FAIL" "Payment Processing Function" "Not deployed"
fi

# Check for credit system
if grep -q "credit_packs" supabase/migrations/*.sql 2>/dev/null; then
    check_status "PASS" "Credit System Database" "credit_packs table exists"
else
    check_status "FAIL" "Credit System Database" "credit_packs not in migrations"
fi

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}7. NOTIFICATIONS & EMAIL${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Check notification system
if [ -f "supabase/functions/send-notification/index.ts" ]; then
    check_status "PASS" "Push Notification Function" ""
else
    check_status "FAIL" "Push Notification Function" "Not deployed"
fi

# Check for email templates (basic check)
if ls web-partner/*email* 2>/dev/null | grep -q . || ls supabase/functions/*email* 2>/dev/null | grep -q .; then
    check_status "PASS" "Email System" "Email components found"
else
    check_status "WARN" "Email System" "No email templates found"
fi

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}8. CORE USER FLOWS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# List of critical user flows
echo "Critical User Flows Checklist:"
flows=(
    "User Registration/Onboarding"
    "Email Verification"
    "Browse Classes"
    "Book a Class"
    "Purchase Credits"
    "View Bookings"
    "Cancel Booking"
    "User Profile Management"
    "Settings & Preferences"
    "Push Notifications"
)

for flow in "${flows[@]}"; do
    echo "  [ ] $flow"
done
echo ""

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}9. PARTNER PORTAL FLOWS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

echo "Partner Portal Flows Checklist:"
partner_flows=(
    "Studio Registration"
    "OAuth Login (Google)"
    "Dashboard Analytics"
    "Class Management"
    "Booking Management"
    "Revenue Tracking"
    "Payout Requests"
    "Profile Settings"
)

for flow in "${partner_flows[@]}"; do
    echo "  [ ] $flow"
done
echo ""

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}FINAL ALPHA READINESS SCORE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo ""

TOTAL=$((PASS + FAIL + WARN))
SCORE=$((PASS * 100 / TOTAL))

echo "Results Summary:"
echo -e "  ${GREEN}✅ PASS: $PASS${NC}"
echo -e "  ${YELLOW}⚠️  WARN: $WARN${NC}"
echo -e "  ${RED}❌ FAIL: $FAIL${NC}"
echo ""
echo "Total Checks: $TOTAL"
echo -e "Alpha Readiness Score: ${BLUE}${SCORE}%${NC}"
echo ""

if [ "$SCORE" -ge 80 ]; then
    echo -e "${GREEN}🎉 VERDICT: READY FOR ALPHA!${NC}"
    echo "Your app has passed the majority of critical checks."
    echo "Address the warnings and failures during alpha testing."
elif [ "$SCORE" -ge 60 ]; then
    echo -e "${YELLOW}⚠️  VERDICT: NEARLY READY${NC}"
    echo "Your app needs a few critical fixes before alpha."
    echo "Focus on the failed items first."
else
    echo -e "${RED}❌ VERDICT: NOT READY${NC}"
    echo "Significant work needed before alpha launch."
    echo "Address all failed items before proceeding."
fi

echo ""
echo "Next Steps After Alpha Approval:"
echo "1. Apple Developer Account Setup"
echo "2. TestFlight Configuration"
echo "3. Studio Onboarding Process"
echo "4. Hobby Directory Setup (the third pillar)"
echo ""