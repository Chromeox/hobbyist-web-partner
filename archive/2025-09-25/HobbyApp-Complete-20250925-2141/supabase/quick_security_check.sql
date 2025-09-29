-- QUICK SECURITY CHECK
-- Run this after migrations to verify critical security features

-- 1. Check RLS Coverage
SELECT 
    COUNT(*) FILTER (WHERE rowsecurity = true) as protected_tables,
    COUNT(*) as total_tables,
    ROUND(100.0 * COUNT(*) FILTER (WHERE rowsecurity = true) / COUNT(*), 1) as protection_percentage,
    CASE 
        WHEN COUNT(*) FILTER (WHERE rowsecurity = true) = COUNT(*) THEN '✅ FULLY PROTECTED'
        ELSE '⚠️ ' || (COUNT(*) - COUNT(*) FILTER (WHERE rowsecurity = true)) || ' TABLES UNPROTECTED!'
    END as status
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename NOT IN ('schema_migrations', 'supabase_migrations');

-- 2. Check Critical User Tables
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '✅' ELSE '❌' END as RLS,
    (SELECT COUNT(*) FROM pg_policies p WHERE p.tablename = t.tablename) as policies
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename IN (
    'user_credits',
    'bookings', 
    'credit_transactions',
    'classes',
    'class_schedules'
)
ORDER BY tablename;

-- 3. Check Security Functions Exist
SELECT 
    'Security Functions' as check_type,
    COUNT(*) FILTER (WHERE proname = 'check_rate_limit') as rate_limit_fn,
    COUNT(*) FILTER (WHERE proname = 'log_security_event') as logging_fn,
    COUNT(*) FILTER (WHERE proname = 'check_suspicious_activity') as detection_fn,
    CASE 
        WHEN COUNT(*) FILTER (WHERE proname IN ('check_rate_limit', 'log_security_event', 'check_suspicious_activity')) = 3 
        THEN '✅ ALL PRESENT'
        ELSE '⚠️ SOME MISSING'
    END as status
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace;

-- 4. Check Security Tables Created
SELECT 
    'Security Infrastructure' as check_type,
    EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'security_audit_log') as audit_log,
    EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'api_rate_limits') as rate_limits,
    EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'failed_login_attempts') as login_tracking,
    CASE 
        WHEN EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'security_audit_log')
        AND EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'api_rate_limits')
        AND EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'failed_login_attempts')
        THEN '✅ COMPLETE'
        ELSE '❌ INCOMPLETE'
    END as status;

-- 5. Final Summary
SELECT 
    '🔐 SECURITY DEPLOYMENT SUMMARY' as report,
    NOW() as checked_at;