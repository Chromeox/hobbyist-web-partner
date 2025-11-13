-- Check if webhook events are being recorded in database
-- Run this in Supabase SQL Editor

-- Check recent payment events
SELECT
  event_type,
  stripe_payment_intent_id,
  amount,
  currency,
  status,
  created_at
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 10;

-- Check if any events exist at all
SELECT COUNT(*) as total_events
FROM stripe_payment_events;

-- Check recent transfers
SELECT
  stripe_transfer_id,
  amount,
  currency,
  created_at
FROM stripe_transfers
ORDER BY created_at DESC
LIMIT 5;

-- Check account statuses
SELECT
  stripe_account_id,
  charges_enabled,
  payouts_enabled,
  is_active,
  updated_at
FROM stripe_account_statuses
ORDER BY updated_at DESC
LIMIT 5;
