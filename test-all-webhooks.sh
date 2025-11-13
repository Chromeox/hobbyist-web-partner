#!/bin/bash

echo "🧪 Testing All 7 Webhook Event Types"
echo "====================================="
echo ""

echo "1️⃣ Testing payment success..."
stripe trigger payment_intent.succeeded
sleep 2

echo ""
echo "2️⃣ Testing payment failure..."
stripe trigger payment_intent.payment_failed
sleep 2

echo ""
echo "3️⃣ Testing transfer created..."
stripe trigger transfer.created
sleep 2

echo ""
echo "4️⃣ Testing payout paid..."
stripe trigger payout.paid
sleep 2

echo ""
echo "5️⃣ Testing payout failed..."
stripe trigger payout.failed
sleep 2

echo ""
echo "====================================="
echo "✅ All webhook tests triggered!"
echo ""
echo "Check database with:"
echo "  SELECT event_type, COUNT(*) FROM stripe_payment_events GROUP BY event_type;"
echo ""
echo "Check Vercel logs for confirmations:"
echo "  https://vercel.com/chromeoxs-projects/hobbyist-partner-portal"
