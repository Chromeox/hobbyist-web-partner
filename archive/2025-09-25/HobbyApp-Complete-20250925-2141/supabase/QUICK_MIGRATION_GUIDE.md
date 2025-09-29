# Quick Migration Guide - Apply via Supabase Dashboard

Since the CLI authentication is having issues, let's use the Supabase Dashboard SQL Editor which doesn't require password authentication.

## Step 1: Open SQL Editor
Click this link to open the SQL editor directly:
👉 https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql/new

## Step 2: Run This Query First (Check Existing Tables)
Copy and paste this into the SQL editor:

```sql
-- Check what tables already exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('categories', 'credit_packs', 'studios', 'students')
ORDER BY table_name;
```

Click "Run" to see what tables are already created.

## Step 3: Apply the Migration
Copy the ENTIRE contents of this file:
`/Users/chromefang.exe/HobbyApp/supabase/migrations/03_web_partner_portal_schema.sql`

Paste it into the SQL editor and click "Run".

## Step 4: Verify Success
Run this query to confirm all tables were created:

```sql
-- Verify all tables exist
SELECT COUNT(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('categories', 'studios', 'studio_staff', 'studio_classes', 
                   'class_sessions', 'students', 'reservations', 'waitlist', 
                   'campaigns', 'analytics_events');
```

You should see `table_count = 10`

## Step 5: Test Categories
Run this to see the fitness categories:

```sql
SELECT * FROM public.categories ORDER BY display_order;
```

You should see 8 categories (Yoga, Pilates, HIIT, Dance, etc.)

## ✅ Success Indicators:
- No red error messages in the SQL editor
- Categories table has 8 rows
- Table count query returns 10

## If You Get Errors:

### Error: "relation already exists"
- This is OK! The tables are already created. Skip to Step 4 to verify.

### Error: "permission denied"
- Make sure you're logged into the correct Supabase project
- Try refreshing the page and running again

### Error: "syntax error"
- Make sure you copied the ENTIRE migration file
- Don't modify the SQL before pasting

## After Success:
1. Go back to your dashboard: http://localhost:3000/dashboard
2. The connection test should now show "Connected to Supabase ✓"
3. You'll see "Database fully configured" message

---

## Alternative: Reset Password and Use CLI

If you prefer using the CLI:

1. Reset password here: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database
2. Click "Reset Database Password"
3. Copy the new password
4. Run: `cd /Users/chromefang.exe/HobbyApp`
5. Run: `PGPASSWORD='new-password-here' supabase db push`

But the SQL Editor method above is faster and doesn't require password management!