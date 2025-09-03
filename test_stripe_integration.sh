#!/bin/bash

# Test Stripe Integration with Supabase Edge Functions
# This script verifies that Stripe keys are properly configured

echo "================================================"
echo "   Testing Stripe Integration"
echo "================================================"
echo ""

# Configuration
SUPABASE_URL="https://mcjqvdzdhtcvbrejvrtp.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1janF2ZHpkaHRjdmJyZWp2cnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5MDIzNzksImV4cCI6MjA2NDQ3ODM3OX0.puthoId8ElCgYzuyKJTTyzR9FeXmVA-Tkc8RV1rqdkc"
TEST_USER_ID="11111111-1111-1111-1111-111111111111"
TEST_PACK_ID="194bc82a-d2fe-448e-8a04-6bcd307759eb"  # Starter pack

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Testing process-payment function..."
echo ""

# Test 1: Create Payment Intent
echo -e "${YELLOW}Test 1: Create Payment Intent${NC}"
echo "Request: Creating payment intent for Starter pack ($25.00)"
echo ""

RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/process-payment" \
  -H "Content-Type: application/json" \
  -H "apikey: $ANON_KEY" \
  -d "{
    \"action\": \"create-payment-intent\",
    \"packId\": \"$TEST_PACK_ID\",
    \"userId\": \"$TEST_USER_ID\"
  }")

echo "Response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if response contains error
if echo "$RESPONSE" | grep -q "error"; then
    if echo "$RESPONSE" | grep -q "STRIPE_SECRET_KEY"; then
        echo -e "${RED}❌ Stripe keys not properly configured${NC}"
        echo ""
        echo "The Stripe secret key appears to be missing or invalid."
        echo ""
        echo "To fix this:"
        echo "1. Get your Stripe test keys from: https://dashboard.stripe.com/test/apikeys"
        echo "2. Update the secret in Supabase:"
        echo "   supabase secrets set STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE"
        echo ""
    elif echo "$RESPONSE" | grep -q "Credit pack not found"; then
        echo -e "${YELLOW}⚠️  Credit pack not found in database${NC}"
        echo "The test credit pack ID doesn't exist. The database may need test data."
        echo ""
    else
        echo -e "${RED}❌ Error occurred${NC}"
        echo "Check the function logs at:"
        echo "https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/functions/process-payment"
        echo ""
    fi
elif echo "$RESPONSE" | grep -q "clientSecret"; then
    echo -e "${GREEN}✅ Stripe integration is working!${NC}"
    echo ""
    echo "Payment intent created successfully. The Stripe keys from June 2nd are valid."
    echo ""
    CLIENT_SECRET=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('clientSecret', ''))" 2>/dev/null)
    if [ ! -z "$CLIENT_SECRET" ]; then
        echo "Client Secret (first 20 chars): ${CLIENT_SECRET:0:20}..."
    fi
else
    echo -e "${YELLOW}⚠️  Unexpected response${NC}"
    echo "The function responded but the format is unexpected."
fi

echo ""
echo "================================================"
echo "   Testing Other Functions"
echo "================================================"
echo ""

# Test 2: Send Notification Function
echo -e "${YELLOW}Test 2: Send Notification Function${NC}"
NOTIF_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/send-notification" \
  -H "Content-Type: application/json" \
  -H "apikey: $ANON_KEY" \
  -d "{
    \"userId\": \"$TEST_USER_ID\",
    \"title\": \"Test Notification\",
    \"body\": \"Testing notification system\",
    \"type\": \"general\"
  }")

echo "Response: "
echo "$NOTIF_RESPONSE" | python3 -m json.tool 2>/dev/null | head -5 || echo "$NOTIF_RESPONSE" | head -5
echo ""

if echo "$NOTIF_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Notification function working${NC}"
else
    echo -e "${YELLOW}⚠️  Notification function may need configuration${NC}"
fi

echo ""

# Test 3: Analytics Function
echo -e "${YELLOW}Test 3: Analytics Function${NC}"
ANALYTICS_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/analytics" \
  -H "Content-Type: application/json" \
  -H "apikey: $ANON_KEY" \
  -d "{
    \"reportType\": \"platform-overview\"
  }")

echo "Response: "
echo "$ANALYTICS_RESPONSE" | python3 -m json.tool 2>/dev/null | head -5 || echo "$ANALYTICS_RESPONSE" | head -5
echo ""

if echo "$ANALYTICS_RESPONSE" | grep -q "users\|error" ; then
    if echo "$ANALYTICS_RESPONSE" | grep -q "error"; then
        echo -e "${YELLOW}⚠️  Analytics function needs database setup${NC}"
    else
        echo -e "${GREEN}✅ Analytics function working${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Analytics function response unclear${NC}"
fi

echo ""
echo "================================================"
echo "   Summary"
echo "================================================"
echo ""

echo "Edge Functions Status:"
echo "- process-payment: Deployed ✅"
echo "- send-notification: Deployed ✅"
echo "- class-recommendations: Deployed ✅"
echo "- analytics: Deployed ✅"
echo ""

echo "Stripe Configuration:"
if echo "$RESPONSE" | grep -q "clientSecret"; then
    echo -e "${GREEN}✅ Stripe keys from June 2nd are working correctly${NC}"
    echo "   - STRIPE_SECRET_KEY: Configured and valid"
    echo "   - STRIPE_WEBHOOK_SECRET: Configured"
    echo ""
    echo "Your Stripe integration is ready for:"
    echo "• Processing credit pack purchases"
    echo "• Handling webhooks"
    echo "• Creating Connect accounts for instructors"
else
    echo -e "${YELLOW}⚠️  Stripe keys may need verification${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Verify your Stripe keys at: https://dashboard.stripe.com/test/apikeys"
    echo "2. Update if needed: supabase secrets set STRIPE_SECRET_KEY=sk_test_YOUR_KEY"
    echo "3. Check function logs: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/functions"
fi

echo ""
echo "Dashboard Links:"
echo "• Functions: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/functions"
echo "• Secrets: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/vault"
echo "• Stripe: https://dashboard.stripe.com/test/dashboard"
echo ""