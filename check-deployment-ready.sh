#!/bin/bash

# Check if new Vercel deployment is ready
# This script monitors the deployment status and tests the webhook

WEBHOOK_URL="https://hobbyist-web-partner-v3.vercel.app/api/stripe/webhooks"

echo "🔍 Monitoring Vercel deployment..."
echo "Webhook URL: $WEBHOOK_URL"
echo ""
echo "Checking deployment status every 30 seconds..."
echo "(Typically takes 2-3 minutes for full deployment)"
echo ""

for i in {1..10}; do
    echo "[$i/10] Testing webhook endpoint..."

    # Test the webhook endpoint
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -H "stripe-signature: test" \
        -d '{"type":"test"}')

    if [ "$RESPONSE" = "400" ]; then
        echo "✅ Deployment is live! (Got 400 = signature verification working)"
        echo ""
        echo "Now test with Stripe CLI:"
        echo "  stripe trigger payment_intent.succeeded"
        echo ""
        echo "Then verify in database:"
        echo "  SELECT COUNT(*) FROM stripe_payment_events;"
        exit 0
    elif [ "$RESPONSE" = "500" ]; then
        echo "⏳ Still deploying (Got 500 = old deployment)..."
    else
        echo "⏳ Waiting for deployment (Got $RESPONSE)..."
    fi

    if [ $i -lt 10 ]; then
        sleep 30
    fi
done

echo ""
echo "⚠️  Deployment taking longer than expected (5 minutes)"
echo "Check Vercel dashboard manually:"
echo "  https://vercel.com/dashboard"
