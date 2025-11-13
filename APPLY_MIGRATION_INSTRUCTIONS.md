# Quick Migration Application - Stripe Webhooks

## Apply via Supabase Dashboard (2 minutes)

### Step 1: Open SQL Editor

1. Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp
2. Click "SQL Editor" in left sidebar
3. Click "New query"

### Step 2: Copy Migration SQL

Open this file:
```
/Users/chromefang.exe/HobbyApp/supabase/migrations/20251111000000_stripe_webhook_tracking.sql
```

**Or run this command to copy to clipboard:**
```bash
cat /Users/chromefang.exe/HobbyApp/supabase/migrations/20251111000000_stripe_webhook_tracking.sql | pbcopy
```

### Step 3: Paste and Execute

1. Paste the entire migration SQL into the query editor
2. Click "Run" (or Cmd+Enter)
3. Wait for "Success" message

### Step 4: Verify Tables Created

Run this verification query:

```sql
-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'stripe_payment_events',
    'stripe_transfers',
    'stripe_account_statuses'
  )
ORDER BY table_name;

-- Should return 3 rows
```

### Step 5: Verify Functions Created

```sql
-- Check functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%stripe%'
ORDER BY routine_name;

-- Should return 4 functions:
-- - record_stripe_payment_event
-- - record_stripe_transfer
-- - update_payout_status
-- - upsert_stripe_account_status
```

### Step 6: Verify RLS Enabled

```sql
-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'stripe_payment_events',
    'stripe_transfers',
    'stripe_account_statuses'
  );

-- All should show rowsecurity = true
```

---

## ✅ Success Criteria

After running the migration, you should see:
- ✅ 3 new tables created
- ✅ 4 new functions created
- ✅ RLS enabled on all tables
- ✅ payout_requests table updated with new columns
- ✅ No errors in SQL Editor

---

## Next Steps (After Migration Applied)

Once you confirm the migration is applied:

1. Deploy code to Vercel
2. Configure Stripe webhooks
3. Test with Stripe CLI

Let me know when the migration is applied and I'll continue with deployment!
