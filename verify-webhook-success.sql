-- Verify Webhook Success - Run in Supabase SQL Editor
-- This should show your test payment event

-- 1. Check most recent payment events
SELECT
  event_type,
  stripe_payment_intent_id,
  amount / 100.0 as amount_dollars,
  currency,
  status,
  created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 5;

-- 2. Count total events by type
SELECT
  event_type,
  COUNT(*) as total_events,
  MAX(created_at) as most_recent
FROM stripe_payment_events
GROUP BY event_type
ORDER BY total_events DESC;

-- 3. Verify webhook is working (should show recent timestamp)
SELECT
  COUNT(*) as total_webhook_events,
  MIN(created_at) as first_event,
  MAX(created_at) as latest_event,
  MAX(created_at) > NOW() - INTERVAL '5 minutes' as received_in_last_5_min
FROM stripe_payment_events;
