-- ============================================
-- SECURITY DEPLOYMENT VERIFICATION SCRIPT
-- Run this after migrations to verify security
-- ============================================

-- 1. Check RLS Status on All Tables
SELECT 
    'RLS Status Check' as check_type,
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ ENABLED'
        ELSE '❌ DISABLED - SECURITY RISK!'
    END as rls_status
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
ORDER BY 
    CASE WHEN NOT rowsecurity THEN 0 ELSE 1 END,
    tablename;

-- 2. Count Policies Per Table
SELECT 
    'Policy Count' as check_type,
    schemaname,
    tablename,
    COUNT(policyname) as policy_count,
    CASE 
        WHEN COUNT(policyname) = 0 THEN '⚠️ No policies!'
        WHEN COUNT(policyname) < 2 THEN '⚠️ Few policies'
        ELSE '✅ OK'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY policy_count ASC, tablename;

-- 3. Check Functions for Security Issues
SELECT 
    'Function Security' as check_type,
    proname as function_name,
    CASE 
        WHEN prosecdef AND proconfig IS NULL THEN '❌ MISSING search_path - SQL INJECTION RISK!'
        WHEN prosecdef AND proconfig IS NOT NULL THEN '✅ Has search_path'
        ELSE '✅ Not SECURITY DEFINER'
    END as security_status,
    prosecdef as is_security_definer
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
ORDER BY 
    CASE WHEN prosecdef AND proconfig IS NULL THEN 0 ELSE 1 END,
    proname;

-- 4. Check for Security Tables
SELECT 
    'Security Tables' as check_type,
    tablename,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE tablename = t.tablename 
            AND schemaname = 'public'
        ) THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM (
    VALUES 
        ('security_audit_log'),
        ('failed_login_attempts'),
        ('api_rate_limits'),
        ('encryption_keys')
) AS t(tablename);

-- 5. Check Critical User Tables
SELECT 
    'Critical Tables RLS' as check_type,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Protected'
        ELSE '❌ VULNERABLE!'
    END as protection_status
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename IN (
    'user_credits',
    'bookings',
    'credit_transactions',
    'user_subscriptions',
    'user_insurance_subscriptions'
)
ORDER BY tablename;

-- 6. Summary Statistics
WITH security_stats AS (
    SELECT 
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as total_tables,
        (SELECT COUNT(*) FROM pg_tables t 
         LEFT JOIN pg_class c ON c.relname = t.tablename 
         WHERE schemaname = 'public' AND rowsecurity = true) as rls_enabled_tables,
        (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as total_policies,
        (SELECT COUNT(*) FROM pg_proc 
         WHERE pronamespace = 'public'::regnamespace 
         AND prosecdef = true) as security_definer_functions,
        (SELECT COUNT(*) FROM pg_proc 
         WHERE pronamespace = 'public'::regnamespace 
         AND prosecdef = true 
         AND proconfig IS NOT NULL) as secure_functions
)
SELECT 
    'SECURITY SUMMARY' as report,
    total_tables || ' tables total' as tables,
    rls_enabled_tables || ' with RLS (' || 
        ROUND(100.0 * rls_enabled_tables / NULLIF(total_tables, 0), 1) || '%)' as rls_coverage,
    total_policies || ' policies defined' as policies,
    CASE 
        WHEN rls_enabled_tables = total_tables THEN '✅ FULL RLS COVERAGE'
        ELSE '⚠️ ' || (total_tables - rls_enabled_tables) || ' TABLES UNPROTECTED!'
    END as rls_status,
    CASE 
        WHEN security_definer_functions = secure_functions THEN '✅ ALL FUNCTIONS SECURE'
        ELSE '❌ ' || (security_definer_functions - secure_functions) || ' FUNCTIONS VULNERABLE!'
    END as function_status
FROM security_stats;

-- 7. Test Rate Limiting Function
SELECT 
    'Rate Limit Function' as test_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'check_rate_limit'
        ) THEN '✅ Function exists'
        ELSE '❌ Function missing'
    END as status;

-- 8. Test Security Event Logging
SELECT 
    'Security Logging' as test_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'log_security_event'
        ) THEN '✅ Function exists'
        ELSE '❌ Function missing'
    END as status;