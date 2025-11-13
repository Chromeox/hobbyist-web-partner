# 📊 Production Monitoring Queries

Use these SQL queries in Supabase to monitor your platform during friend testing.

---

## Daily Revenue

```sql
-- Today's total revenue
SELECT
    COUNT(*) as total_bookings,
    SUM(amount) / 100.0 as total_revenue_dollars,
    SUM(amount) * 0.30 / 100.0 as platform_commission_dollars,
    SUM(amount) * 0.70 / 100.0 as studio_payouts_dollars
FROM stripe_payment_events
WHERE event_type = 'payment_intent.succeeded'
    AND DATE(created_at) = CURRENT_DATE;
```

---

## Recent Activity (Last 24 Hours)

```sql
-- All events in last 24 hours
SELECT
    event_type,
    stripe_payment_intent_id,
    amount / 100.0 as amount_dollars,
    currency,
    status,
    created_at
FROM stripe_payment_events
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## Payment Success Rate

```sql
-- Success vs failure rate
SELECT
    event_type,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM stripe_payment_events
WHERE event_type IN ('payment_intent.succeeded', 'payment_intent.payment_failed')
GROUP BY event_type;
```

---

## Failed Payments (Need Attention)

```sql
-- Show failed payments with error details
SELECT
    stripe_payment_intent_id,
    amount / 100.0 as amount_dollars,
    error_code,
    error_message,
    created_at
FROM stripe_payment_events
WHERE event_type = 'payment_intent.payment_failed'
ORDER BY created_at DESC
LIMIT 10;
```

---

## Studio Performance

```sql
-- Revenue by studio (when you have real bookings with studio data)
SELECT
    booking_id,
    COUNT(*) as bookings,
    SUM(amount) / 100.0 as total_revenue,
    SUM(amount) * 0.70 / 100.0 as studio_earnings
FROM stripe_payment_events
WHERE event_type = 'payment_intent.succeeded'
    AND booking_id IS NOT NULL
GROUP BY booking_id
ORDER BY total_revenue DESC;
```

---

## Weekly Summary

```sql
-- Last 7 days breakdown
SELECT
    DATE(created_at) as date,
    COUNT(*) as successful_payments,
    SUM(amount) / 100.0 as daily_revenue
FROM stripe_payment_events
WHERE event_type = 'payment_intent.succeeded'
    AND created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## Real-Time Monitoring

```sql
-- Last 10 events (refresh frequently during testing)
SELECT
    event_type,
    stripe_payment_intent_id,
    amount / 100.0 as amount_dollars,
    status,
    created_at,
    NOW() - created_at as age
FROM stripe_payment_events
ORDER BY created_at DESC
LIMIT 10;
```

---

## Webhook Health Check

```sql
-- Events per hour (detect gaps)
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as events
FROM stripe_payment_events
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at)
ORDER BY hour DESC;
```

---

## Commission Tracking (Future)

```sql
-- Once you have transfers
SELECT
    t.stripe_transfer_id,
    t.stripe_destination_account,
    t.amount / 100.0 as transfer_amount,
    t.created_at,
    s.name as studio_name
FROM stripe_transfers t
LEFT JOIN studios s ON t.studio_id = s.id
ORDER BY t.created_at DESC
LIMIT 10;
```

---

## Alerts to Set Up

Run these periodically and alert if:

### Payment Failure Rate Too High
```sql
-- Alert if > 10% failure rate
SELECT
    ROUND(
        SUM(CASE WHEN event_type = 'payment_intent.payment_failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) as failure_rate_percentage
FROM stripe_payment_events
WHERE created_at > NOW() - INTERVAL '24 hours';
-- Alert if result > 10
```

### No Recent Events (Webhook Down?)
```sql
-- Alert if no events in last 30 minutes during business hours
SELECT
    MAX(created_at) as last_event,
    NOW() - MAX(created_at) as time_since_last_event
FROM stripe_payment_events;
-- Alert if time_since_last_event > 30 minutes and during business hours
```

---

**Tip**: Save these queries in Supabase's "Saved Queries" for quick access!
