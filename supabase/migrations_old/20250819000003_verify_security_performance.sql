-- Verification Script for Security & Performance Migrations
-- Generated: 2025-08-19
-- Purpose: Verify that all security and performance fixes have been applied correctly

-- ============================================
-- SECURITY VERIFICATION
-- ============================================

DO $$
DECLARE
    unprotected_tables integer;
    functions_without_search_path integer;
    views_with_definer integer;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECURITY VERIFICATION STARTING...';
    RAISE NOTICE '========================================';
    
    -- Check for tables without RLS
    SELECT COUNT(*) INTO unprotected_tables
    FROM pg_tables t
    LEFT JOIN pg_policies p ON t.tablename = p.tablename
    WHERE t.schemaname = 'public'
        AND t.tablename NOT IN ('schema_migrations', 'security_audit_log')
        AND NOT EXISTS (
            SELECT 1 FROM pg_class c
            WHERE c.relname = t.tablename
            AND c.relrowsecurity = true
        );
    
    IF unprotected_tables > 0 THEN
        RAISE WARNING 'Found % tables without RLS enabled', unprotected_tables;
    ELSE
        RAISE NOTICE '✅ All tables have RLS enabled';
    END IF;
    
    -- Check for functions without search_path
    SELECT COUNT(*) INTO functions_without_search_path
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.prosecdef = true
        AND NOT p.proconfig @> ARRAY['search_path=public, pg_catalog'];
    
    IF functions_without_search_path > 0 THEN
        RAISE WARNING 'Found % functions without proper search_path', functions_without_search_path;
    ELSE
        RAISE NOTICE '✅ All functions have search_path set';
    END IF;
    
    -- Check for views with SECURITY DEFINER
    SELECT COUNT(*) INTO views_with_definer
    FROM pg_views
    WHERE schemaname = 'public'
        AND definition LIKE '%SECURITY DEFINER%';
    
    IF views_with_definer > 0 THEN
        RAISE WARNING 'Found % views with SECURITY DEFINER', views_with_definer;
    ELSE
        RAISE NOTICE '✅ No views with SECURITY DEFINER found';
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SECURITY VERIFICATION COMPLETE';
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- PERFORMANCE VERIFICATION
-- ============================================

DO $$
DECLARE
    missing_indexes integer;
    total_indexes integer;
    materialized_views integer;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PERFORMANCE VERIFICATION STARTING...';
    RAISE NOTICE '========================================';
    
    -- Count total indexes
    SELECT COUNT(*) INTO total_indexes
    FROM pg_indexes
    WHERE schemaname = 'public';
    
    RAISE NOTICE 'Total indexes in public schema: %', total_indexes;
    
    -- Check for missing foreign key indexes
    SELECT COUNT(*) INTO missing_indexes
    FROM (
        SELECT 
            tc.table_name,
            kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
            AND NOT EXISTS (
                SELECT 1
                FROM pg_indexes
                WHERE schemaname = 'public'
                    AND tablename = tc.table_name
                    AND indexdef LIKE '%' || kcu.column_name || '%'
            )
    ) AS missing;
    
    IF missing_indexes > 0 THEN
        RAISE WARNING 'Found % foreign keys without indexes', missing_indexes;
    ELSE
        RAISE NOTICE '✅ All foreign keys have indexes';
    END IF;
    
    -- Check materialized views
    SELECT COUNT(*) INTO materialized_views
    FROM pg_matviews
    WHERE schemaname = 'public';
    
    RAISE NOTICE 'Materialized views created: %', materialized_views;
    
    -- List specific performance features
    RAISE NOTICE '';
    RAISE NOTICE 'Performance Features Status:';
    
    -- Check for BRIN indexes
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND indexdef LIKE '%USING brin%'
    ) THEN
        RAISE NOTICE '✅ BRIN indexes implemented for time-series data';
    ELSE
        RAISE NOTICE '⚠️  No BRIN indexes found';
    END IF;
    
    -- Check for GIN indexes (full-text search)
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND indexdef LIKE '%USING gin%'
    ) THEN
        RAISE NOTICE '✅ GIN indexes implemented for full-text search';
    ELSE
        RAISE NOTICE '⚠️  No GIN indexes found';
    END IF;
    
    -- Check for composite indexes
    IF EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND indexdef LIKE '%,%'
    ) THEN
        RAISE NOTICE '✅ Composite indexes created for complex queries';
    ELSE
        RAISE NOTICE '⚠️  No composite indexes found';
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PERFORMANCE VERIFICATION COMPLETE';
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- DETAILED REPORTS
-- ============================================

-- Report: Tables with RLS status
RAISE NOTICE '';
RAISE NOTICE 'RLS Status by Table:';
SELECT 
    tablename,
    CASE WHEN relrowsecurity THEN '✅ Enabled' ELSE '❌ Disabled' END as rls_status,
    COUNT(p.policyname) as policy_count
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
LEFT JOIN pg_policies p ON t.tablename = p.tablename
WHERE t.schemaname = 'public'
GROUP BY t.tablename, c.relrowsecurity
ORDER BY c.relrowsecurity DESC, t.tablename;

-- Report: Index usage statistics
RAISE NOTICE '';
RAISE NOTICE 'Top 10 Most Used Indexes:';
SELECT 
    indexname,
    idx_scan as scans,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 10;

-- Report: Slow queries (if pg_stat_statements is enabled)
RAISE NOTICE '';
RAISE NOTICE 'Checking for slow queries...';
IF EXISTS (
    SELECT 1 
    FROM pg_available_extensions 
    WHERE name = 'pg_stat_statements' 
    AND installed_version IS NOT NULL
) THEN
    RAISE NOTICE 'pg_stat_statements is enabled - monitor slow queries in dashboard';
ELSE
    RAISE NOTICE 'pg_stat_statements not enabled - consider enabling for query monitoring';
END IF;

-- ============================================
-- FINAL SUMMARY
-- ============================================

DO $$
DECLARE
    total_tables integer;
    protected_tables integer;
    total_functions integer;
    secure_functions integer;
BEGIN
    SELECT COUNT(*) INTO total_tables
    FROM pg_tables
    WHERE schemaname = 'public';
    
    SELECT COUNT(*) INTO protected_tables
    FROM pg_tables t
    JOIN pg_class c ON c.relname = t.tablename
    WHERE t.schemaname = 'public'
        AND c.relrowsecurity = true;
    
    SELECT COUNT(*) INTO total_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public';
    
    SELECT COUNT(*) INTO secure_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
        AND p.proconfig @> ARRAY['search_path=public, pg_catalog'];
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FINAL SUMMARY';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Security Status:';
    RAISE NOTICE '  Tables with RLS: %/%', protected_tables, total_tables;
    RAISE NOTICE '  Secure functions: %/%', secure_functions, total_functions;
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Review any warnings above';
    RAISE NOTICE '2. Enable leaked password protection in Supabase Auth settings';
    RAISE NOTICE '3. Configure pg_cron for automated maintenance';
    RAISE NOTICE '4. Monitor query performance using dashboard';
    RAISE NOTICE '========================================';
END $$;