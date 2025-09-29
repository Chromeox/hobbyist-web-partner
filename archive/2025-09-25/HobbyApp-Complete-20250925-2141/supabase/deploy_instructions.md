# 🚀 Deploy Security Migrations - Manual Steps

Since the Supabase CLI requires interactive password input, please run these commands manually in your terminal:

## Step 1: Deploy Migrations

Open a new terminal and run:

```bash
cd /Users/chromefang.exe/HobbyApp
supabase db push
```

When prompted:
1. Enter your new database password
2. Wait for migrations to apply (may take 1-2 minutes)

You should see output like:
```
Applying migration 00_cleanup_database.sql...
Applying migration 01_complete_vancouver_pricing_system.sql...
Applying migration 02_comprehensive_security_enhancements.sql...
Finished supabase db push.
```

## Step 2: Verify Deployment

After migrations complete, run the verification:

```bash
supabase db query -f supabase/verify_security_deployment.sql
```

## What to Look For in Verification

✅ **Good Signs:**
- All tables show "✅ ENABLED" for RLS
- Policy counts > 0 for each table
- Functions show "✅ Has search_path"
- Security tables exist
- Summary shows "✅ FULL RLS COVERAGE"

❌ **Issues to Address:**
- Any "❌ DISABLED" RLS status
- Tables with 0 policies
- Functions missing search_path
- Missing security tables

## Alternative: Use Supabase Dashboard

If the CLI continues to have connection issues, you can also deploy via the dashboard:

1. Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql
2. Click "New query"
3. Copy and paste each migration file content:
   - First: `00_cleanup_database.sql`
   - Second: `01_complete_vancouver_pricing_system.sql`
   - Third: `02_comprehensive_security_enhancements.sql`
4. Run each one in order
5. Then run the verification script

## Quick Test After Deployment

Test that RLS is working:

```sql
-- This should return 0 rows (no user context)
SELECT * FROM user_credits;

-- This should show all RLS-enabled tables
SELECT tablename, rowsecurity 
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public' AND rowsecurity = true;
```

## Need Help?

If you encounter any errors:
1. Copy the error message
2. Check the Supabase logs: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/logs
3. I can help troubleshoot the specific issue

---

**Ready?** Run `supabase db push` in your terminal and enter your password when prompted!