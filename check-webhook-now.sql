-- Quick check for webhook events (run this now!)

-- Check if ANY events exist
SELECT COUNT(*) as total_events FROM stripe_payment_events;

-- Check most recent event (should be within last minute if working)
SELECT
  event_type,
  stripe_payment_intent_id,
  amount / 100.0 as amount_dollars,
  status,
  created_at,
  NOW() - created_at as age
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 1;

-- If no rows, check if table exists properly
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'stripe_payment_events'
  AND table_schema = 'public'
ORDER BY ordinal_position;
