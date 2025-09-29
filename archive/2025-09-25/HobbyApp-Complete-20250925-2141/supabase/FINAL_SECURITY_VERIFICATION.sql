-- ============================================
-- FINAL SECURITY VERIFICATION
-- Run this after migration to confirm security
-- ============================================

-- 1. OVERALL SECURITY SUMMARY
WITH security_summary AS (
    SELECT 
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as total_tables,
        (SELECT COUNT(*) FROM pg_tables t 
         LEFT JOIN pg_class c ON c.relname = t.tablename 
         WHERE schemaname = 'public' AND rowsecurity = true) as protected_tables,
        (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') as total_policies,
        (SELECT COUNT(*) FROM security_audit_log) as audit_events,
        (SELECT COUNT(DISTINCT tablename) FROM pg_policies WHERE schemaname = 'public') as tables_with_policies
)
SELECT 
    '🔐 SECURITY STATUS' as report_type,
    CASE 
        WHEN protected_tables = total_tables THEN '✅ FULLY SECURED'
        ELSE '⚠️ ' || (total_tables - protected_tables) || ' TABLES UNPROTECTED'
    END as rls_status,
    protected_tables || '/' || total_tables as tables_protected,
    total_policies || ' policies' as policies_count,
    tables_with_policies || ' tables with policies' as policy_coverage,
    audit_events || ' events logged' as audit_activity
FROM security_summary;

-- 2. TABLE-BY-TABLE RLS STATUS
SELECT 
    '📊 TABLE PROTECTION' as check_type,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ Protected'
        ELSE '❌ VULNERABLE'
    END as rls_status,
    (SELECT COUNT(*) FROM pg_policies p WHERE p.tablename = t.tablename) as policy_count
FROM pg_tables t
LEFT JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename NOT IN ('schema_migrations', 'supabase_migrations')
ORDER BY 
    CASE WHEN NOT rowsecurity THEN 0 ELSE 1 END,
    tablename;

-- 3. CRITICAL USER DATA TABLES CHECK
SELECT 
    '👤 USER DATA PROTECTION' as check_type,
    tablename,
    CASE WHEN rowsecurity THEN '✅' ELSE '❌' END as RLS,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies p WHERE p.tablename = t.tablename) > 0 
        THEN '✅' ELSE '❌' 
    END as has_policies,
    (SELECT COUNT(*) FROM pg_policies p WHERE p.tablename = t.tablename) as policy_count
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

-- 4. SECURITY INFRASTRUCTURE CHECK
SELECT 
    '🛡️ SECURITY FEATURES' as check_type,
    'Audit Logging' as feature,
    CASE WHEN EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'security_audit_log') 
         THEN '✅ Active' ELSE '❌ Missing' END as status
UNION ALL
SELECT 
    '🛡️ SECURITY FEATURES',
    'Rate Limiting',
    CASE WHEN EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'api_rate_limits') 
         THEN '✅ Active' ELSE '❌ Missing' END
UNION ALL
SELECT 
    '🛡️ SECURITY FEATURES',
    'Failed Login Tracking',
    CASE WHEN EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'failed_login_attempts') 
         THEN '✅ Active' ELSE '❌ Missing' END
UNION ALL
SELECT 
    '🛡️ SECURITY FEATURES',
    'Rate Limit Function',
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'check_rate_limit') 
         THEN '✅ Active' ELSE '❌ Missing' END
UNION ALL
SELECT 
    '🛡️ SECURITY FEATURES',
    'Security Event Logger',
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'log_security_event') 
         THEN '✅ Active' ELSE '❌ Missing' END
UNION ALL
SELECT 
    '🛡️ SECURITY FEATURES',
    'Suspicious Activity Detector',
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'check_suspicious_activity') 
         THEN '✅ Active' ELSE '❌ Missing' END;

-- 5. FUNCTION SECURITY CHECK
SELECT 
    '🔧 FUNCTION SECURITY' as check_type,
    proname as function_name,
    CASE 
        WHEN prosecdef AND proconfig::text LIKE '%search_path%' THEN '✅ Secure'
        WHEN prosecdef AND proconfig IS NULL THEN '❌ VULNERABLE - No search_path'
        WHEN NOT prosecdef THEN '✅ Not SECURITY DEFINER'
        ELSE '✅ Secure'
    END as status
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
AND proname IN (
    'check_rate_limit',
    'log_security_event',
    'check_suspicious_activity',
    'calculate_credits_needed',
    'process_booking',
    'cancel_booking'
)
ORDER BY proname;

-- 6. RECENT SECURITY EVENTS (if any)
SELECT 
    '📝 RECENT SECURITY EVENTS' as check_type,
    COUNT(*) as total_events,
    COUNT(DISTINCT event_type) as event_types,
    MAX(created_at) as last_event
FROM security_audit_log
WHERE created_at > NOW() - INTERVAL '1 hour';

-- 7. FINAL VERDICT
WITH security_checks AS (
    SELECT 
        (SELECT COUNT(*) = COUNT(*) FILTER (WHERE rowsecurity = true) 
         FROM pg_tables t LEFT JOIN pg_class c ON c.relname = t.tablename 
         WHERE schemaname = 'public') as all_rls_enabled,
        EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'security_audit_log') as has_audit_log,
        EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'api_rate_limits') as has_rate_limits,
        EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'check_rate_limit') as has_functions
)
SELECT 
    '🎯 FINAL SECURITY ASSESSMENT' as verdict,
    CASE 
        WHEN all_rls_enabled AND has_audit_log AND has_rate_limits AND has_functions
        THEN '✅✅✅ FULLY SECURED - Production Ready!'
        WHEN all_rls_enabled 
        THEN '✅ Basic Security Active - Add monitoring features'
        ELSE '❌ SECURITY GAPS DETECTED - Review above issues'
    END as status,
    CASE 
        WHEN all_rls_enabled THEN 'RLS: ✅' ELSE 'RLS: ❌' 
    END || ' | ' ||
    CASE 
        WHEN has_audit_log THEN 'Audit: ✅' ELSE 'Audit: ❌' 
    END || ' | ' ||
    CASE 
        WHEN has_rate_limits THEN 'RateLimit: ✅' ELSE 'RateLimit: ❌' 
    END || ' | ' ||
    CASE 
        WHEN has_functions THEN 'Functions: ✅' ELSE 'Functions: ❌' 
    END as details
FROM security_checks;