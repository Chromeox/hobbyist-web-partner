-- Security Verification Script for HobbyistSwiftUI
-- Run this after applying the security fix migration to verify all issues are resolved

-- ===================================
-- 1. Check for SECURITY DEFINER views
-- ===================================
SELECT 
    'SECURITY DEFINER Views Check' as test_name,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ PASSED - No SECURITY DEFINER views found'
        ELSE '❌ FAILED - Found ' || COUNT(*) || ' SECURITY DEFINER views'
    END as result,
    STRING_AGG(viewname, ', ') as affected_views
FROM pg_views v
JOIN pg_class c ON c.relname = v.viewname
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
AND v.viewname IN ('revenue_analytics', 'class_performance')
AND pg_get_viewdef(c.oid) LIKE '%SECURITY DEFINER%';

-- ===================================
-- 2. Check RLS status on instructors table
-- ===================================
SELECT 
    'Instructors Table RLS Check' as test_name,
    CASE 
        WHEN relrowsecurity THEN '✅ PASSED - RLS is enabled on instructors table'
        ELSE '❌ FAILED - RLS is NOT enabled on instructors table'
    END as result,
    NULL as affected_views
FROM pg_class
WHERE relname = 'instructors'
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ===================================
-- 3. Check RLS status on venues table
-- ===================================
SELECT 
    'Venues Table RLS Check' as test_name,
    CASE 
        WHEN relrowsecurity THEN '✅ PASSED - RLS is enabled on venues table'
        ELSE '❌ FAILED - RLS is NOT enabled on venues table'
    END as result,
    NULL as affected_views
FROM pg_class
WHERE relname = 'venues'
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- ===================================
-- 4. Check RLS policies on instructors table
-- ===================================
SELECT 
    'Instructors RLS Policies Check' as test_name,
    CASE 
        WHEN COUNT(*) >= 3 THEN '✅ PASSED - Found ' || COUNT(*) || ' RLS policies on instructors table'
        ELSE '⚠️ WARNING - Only ' || COUNT(*) || ' RLS policies found on instructors table'
    END as result,
    STRING_AGG(polname, ', ') as affected_views
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'instructors';

-- ===================================
-- 5. Check RLS policies on venues table
-- ===================================
SELECT 
    'Venues RLS Policies Check' as test_name,
    CASE 
        WHEN COUNT(*) >= 2 THEN '✅ PASSED - Found ' || COUNT(*) || ' RLS policies on venues table'
        ELSE '⚠️ WARNING - Only ' || COUNT(*) || ' RLS policies found on venues table'
    END as result,
    STRING_AGG(polname, ', ') as affected_views
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'venues';

-- ===================================
-- 6. List all tables without RLS in public schema
-- ===================================
SELECT 
    'Tables Without RLS' as test_name,
    'ℹ️ INFO - ' || COUNT(*) || ' tables without RLS in public schema' as result,
    STRING_AGG(tablename, ', ') as affected_views
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE t.schemaname = 'public'
AND n.nspname = 'public'
AND NOT c.relrowsecurity
AND t.tablename NOT IN ('schema_migrations', 'migrations'); -- Exclude migration tracking tables

-- ===================================
-- 7. Summary of all security-sensitive tables
-- ===================================
SELECT 
    'Security-Sensitive Tables Summary' as test_name,
    'ℹ️ INFO - RLS Status Overview' as result,
    NULL as affected_views;

SELECT 
    tablename,
    CASE WHEN c.relrowsecurity THEN '✅ RLS Enabled' ELSE '❌ RLS Disabled' END as rls_status,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = t.tablename) as policy_count
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE t.schemaname = 'public'
AND n.nspname = 'public'
AND t.tablename IN (
    'instructors', 'venues', 'bookings', 'classes', 
    'credit_packs', 'user_credits', 'credit_transactions', 
    'credit_pack_purchases', 'studio_commission_settings'
)
ORDER BY t.tablename;

-- ===================================
-- 8. Check for any remaining SECURITY DEFINER functions
-- ===================================
SELECT 
    'SECURITY DEFINER Functions' as test_name,
    'ℹ️ INFO - Functions using SECURITY DEFINER (may be intentional)' as result,
    NULL as affected_views;

SELECT 
    proname as function_name,
    pg_get_function_identity_arguments(oid) as arguments,
    CASE 
        WHEN proname IN (
            'get_commission_summary', 'get_instructor_performance', 
            'get_credit_usage_analytics', 'get_top_classes_by_revenue',
            'get_user_credit_balance', 'add_user_credits', 
            'spend_user_credits', 'calculate_studio_commission'
        ) THEN 'Expected - Analytics/Credit functions'
        ELSE 'Review needed'
    END as status
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND prosecdef = true
ORDER BY proname;