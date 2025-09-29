# Instructions to Apply Database Migration

Since `supabase db push` requires a database password, you can apply the migration directly through the Supabase Dashboard SQL Editor.

## Steps:

1. **Open Supabase Dashboard SQL Editor**:
   - Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql/new
   - This opens the SQL editor where you can run queries directly

2. **Apply Migrations in Order** (if not already applied):
   
   First, check what tables already exist:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

3. **If `categories` table doesn't exist**, copy and paste the contents of:
   - `/supabase/migrations/03_web_partner_portal_schema.sql`
   - Run the query

4. **Alternative: Apply via Supabase CLI** (requires password):
   ```bash
   cd /Users/chromefang.exe/HobbyApp
   
   # Set the database password as environment variable
   export PGPASSWORD='your-database-password-here'
   
   # Apply migrations
   /opt/homebrew/opt/supabase/bin/supabase db push
   ```

5. **Reset Database Password** (if needed):
   - Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database
   - Click "Reset Database Password"
   - Save the new password securely

## Verification:

After applying the migration, verify the tables were created:

```sql
-- Check if new tables exist
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('categories', 'studios', 'studio_staff', 'studio_classes', 
                   'class_sessions', 'students', 'reservations', 'waitlist', 
                   'campaigns', 'analytics_events');
```

Expected result: `table_count = 10`

## Quick Test Query:

```sql
-- Test categories table
SELECT * FROM public.categories LIMIT 5;
```

This should return the default fitness categories (Yoga, Pilates, HIIT, etc.)

## Troubleshooting:

If you get errors about existing tables:
1. The migration uses `CREATE TABLE IF NOT EXISTS` so it's safe to run multiple times
2. If a table structure conflict occurs, you may need to drop and recreate specific tables

## Important Notes:

- The migration is idempotent (safe to run multiple times)
- It preserves existing `credit_packs` table from previous migrations
- All tables have Row Level Security (RLS) enabled for security
- Default data is inserted for categories and credit packages