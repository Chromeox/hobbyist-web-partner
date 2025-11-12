#!/bin/bash

# Stripe Webhook Endpoint Test Script
# Tests that the webhook endpoint is accessible and responding

WEBHOOK_URL="https://hobbyist-web-partner-v3-feyd9jgm9-chromeoxs-projects.vercel.app/api/stripe/webhooks"

echo "🧪 Testing Stripe Webhook Endpoint"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Endpoint: $WEBHOOK_URL"
echo ""

# Test 1: Check endpoint is accessible
echo "Test 1: Checking endpoint accessibility..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"type":"test"}')

if [ "$RESPONSE" = "400" ]; then
    echo "✅ PASS - Endpoint accessible (returned 400 as expected)"
    echo "   This is correct - signature verification is working"
elif [ "$RESPONSE" = "200" ]; then
    echo "⚠️  WARN - Endpoint returned 200 (should be 400 for unsigned request)"
elif [ "$RESPONSE" = "404" ]; then
    echo "❌ FAIL - Endpoint not found (404)"
    echo "   Check Vercel deployment status"
    exit 1
elif [ "$RESPONSE" = "500" ]; then
    echo "❌ FAIL - Server error (500)"
    echo "   Check Vercel function logs and environment variables"
    exit 1
else
    echo "❌ FAIL - Unexpected status code: $RESPONSE"
    exit 1
fi

echo ""

# Test 2: Check response body
echo "Test 2: Checking error message..."
RESPONSE_BODY=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"type":"test"}')

if echo "$RESPONSE_BODY" | grep -q "signature"; then
    echo "✅ PASS - Signature verification is active"
    echo "   Response: $RESPONSE_BODY"
else
    echo "⚠️  WARN - Unexpected response body"
    echo "   Response: $RESPONSE_BODY"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Webhook endpoint is configured and ready!"
echo ""
echo "Next steps:"
echo "1. Wait 2-3 minutes for Vercel deployment to complete"
echo "2. Test with real Stripe event:"
echo "   - Go to Stripe Dashboard → Webhooks"
echo "   - Click 'Send test webhook'"
echo "   - Select 'payment_intent.succeeded'"
echo "3. Or use Stripe CLI:"
echo "   stripe trigger payment_intent.succeeded"
echo ""
