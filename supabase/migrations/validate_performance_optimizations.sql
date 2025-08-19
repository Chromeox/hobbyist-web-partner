-- =============================================
-- Performance Optimization Validation Script
-- Date: 2025-08-19
-- Purpose: Validate and measure RLS performance improvements
-- =============================================

-- This script helps validate the performance improvements from the optimization migration
-- Run this BEFORE and AFTER applying the migration to measure improvements

-- =============================================
-- STEP 1: Check current RLS policies
-- =============================================

\echo '======================================'
\echo 'Current RLS Policies Analysis'
\echo '======================================'

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%(SELECT auth.uid())%' THEN 'OPTIMIZED (initplan)'
        WHEN qual LIKE '%auth.uid()%' THEN 'NOT OPTIMIZED'
        WHEN qual LIKE '%get_current_user_id()%' THEN 'OPTIMIZED (function)'
        ELSE 'N/A'
    END as optimization_status,
    LENGTH(qual) as policy_complexity
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('user_credits', 'credit_transactions', 'credit_pack_purchases', 
                  'instructors', 'venues', 'studio_commission_settings')
ORDER BY tablename, policyname;

-- =============================================
-- STEP 2: Count total policies per table
-- =============================================

\echo ''
\echo '======================================'
\echo 'Policy Count Per Table (Lower is Better)'
\echo '======================================'

SELECT 
    tablename,
    COUNT(*) as policy_count,
    STRING_AGG(cmd::text, ', ' ORDER BY cmd) as operations_covered
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('user_credits', 'credit_transactions', 'credit_pack_purchases', 
                  'instructors', 'venues', 'studio_commission_settings')
GROUP BY tablename
ORDER BY policy_count DESC, tablename;

-- =============================================
-- STEP 3: Performance benchmark queries
-- =============================================

\echo ''
\echo '======================================'
\echo 'Performance Benchmarks'
\echo '======================================'
\echo 'Run these queries with EXPLAIN ANALYZE to measure performance:'
\echo ''

-- Create a test user for benchmarking (if not exists)
DO $$
BEGIN
    -- Create a test user ID for benchmarking
    IF NOT EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = '00000000-0000-0000-0000-000000000001'
    ) THEN
        -- Note: In production, you'd use proper auth flow
        -- This is just for testing performance
        RAISE NOTICE 'Test user would be created here in a real environment';
    END IF;
END $$;

\echo '-- Benchmark 1: Simple user credits lookup'
\echo 'EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)'
\echo 'SELECT * FROM user_credits WHERE user_id = auth.uid();'
\echo ''

\echo '-- Benchmark 2: User transactions with sorting'
\echo 'EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)'
\echo 'SELECT * FROM credit_transactions'
\echo 'WHERE user_id = auth.uid()'
\echo 'ORDER BY created_at DESC LIMIT 20;'
\echo ''

\echo '-- Benchmark 3: Complex join query'
\echo 'EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE)'
\echo 'SELECT'
\echo '    uc.balance,'
\echo '    COUNT(ct.id) as transaction_count,'
\echo '    SUM(ct.amount) as total_spent,'
\echo '    COUNT(DISTINCT cpp.pack_id) as packs_purchased'
\echo 'FROM user_credits uc'
\echo 'LEFT JOIN credit_transactions ct ON ct.user_id = uc.user_id'
\echo 'LEFT JOIN credit_pack_purchases cpp ON cpp.user_id = uc.user_id'
\echo 'WHERE uc.user_id = auth.uid()'
\echo 'GROUP BY uc.balance;'
\echo ''

-- =============================================
-- STEP 4: Check for problematic patterns
-- =============================================

\echo '======================================'
\echo 'Problematic Pattern Detection'
\echo '======================================'

-- Check for multiple auth.uid() calls in single policy
SELECT 
    tablename,
    policyname,
    (LENGTH(qual) - LENGTH(REPLACE(qual, 'auth.uid()', ''))) / LENGTH('auth.uid()') as auth_uid_call_count,
    CASE 
        WHEN (LENGTH(qual) - LENGTH(REPLACE(qual, 'auth.uid()', ''))) / LENGTH('auth.uid()') > 1 
        THEN 'WARNING: Multiple auth.uid() calls'
        ELSE 'OK'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
AND qual LIKE '%auth.uid()%'
AND qual NOT LIKE '%(SELECT auth.uid())%'
ORDER BY auth_uid_call_count DESC;

-- =============================================
-- STEP 5: Index usage analysis
-- =============================================

\echo ''
\echo '======================================'
\echo 'Index Coverage for RLS Queries'
\echo '======================================'

SELECT 
    t.tablename,
    i.indexname,
    i.indexdef,
    CASE 
        WHEN i.indexdef LIKE '%user_id%' THEN 'GOOD: Covers user_id'
        ELSE 'Check if needed'
    END as rls_coverage
FROM pg_tables t
LEFT JOIN pg_indexes i ON t.tablename = i.tablename AND t.schemaname = i.schemaname
WHERE t.schemaname = 'public'
AND t.tablename IN ('user_credits', 'credit_transactions', 'credit_pack_purchases', 
                    'instructors', 'venues')
ORDER BY t.tablename, i.indexname;

-- =============================================
-- STEP 6: Generate performance comparison report
-- =============================================

\echo ''
\echo '======================================'
\echo 'Expected Performance Improvements'
\echo '======================================'

SELECT 
    'auth.uid() → (SELECT auth.uid())' as optimization,
    '50-70%' as expected_improvement,
    'Converts volatile function to stable initplan' as explanation
UNION ALL
SELECT 
    'Policy consolidation' as optimization,
    '20-30%' as expected_improvement,
    'Reduces number of policy evaluations per query' as explanation
UNION ALL
SELECT 
    'Index optimization' as optimization,
    '10-20%' as expected_improvement,
    'Ensures RLS queries use appropriate indexes' as explanation;

-- =============================================
-- STEP 7: Create performance tracking table
-- =============================================

-- Create a table to track performance metrics over time
CREATE TABLE IF NOT EXISTS rls_performance_metrics (
    id SERIAL PRIMARY KEY,
    test_date TIMESTAMPTZ DEFAULT NOW(),
    migration_applied BOOLEAN DEFAULT FALSE,
    test_name VARCHAR(100),
    execution_time_ms DECIMAL(10, 3),
    buffers_hit INTEGER,
    buffers_read INTEGER,
    rows_returned INTEGER,
    notes TEXT
);

\echo ''
\echo '======================================'
\echo 'Performance Tracking'
\echo '======================================'
\echo 'Use the rls_performance_metrics table to track improvements over time.'
\echo 'Insert benchmark results before and after migration for comparison.'

-- =============================================
-- STEP 8: Quick validation checks
-- =============================================

\echo ''
\echo '======================================'
\echo 'Quick Validation Checks'
\echo '======================================'

DO $$
DECLARE
    optimized_count INTEGER;
    unoptimized_count INTEGER;
    total_policies INTEGER;
    optimization_percentage DECIMAL;
BEGIN
    -- Count optimized policies
    SELECT COUNT(*) INTO optimized_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND (qual LIKE '%(SELECT auth.uid())%' OR qual LIKE '%get_current_user_id()%');
    
    -- Count unoptimized policies
    SELECT COUNT(*) INTO unoptimized_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND qual LIKE '%auth.uid()%'
    AND qual NOT LIKE '%(SELECT auth.uid())%'
    AND qual NOT LIKE '%get_current_user_id()%';
    
    -- Calculate total
    total_policies := optimized_count + unoptimized_count;
    
    IF total_policies > 0 THEN
        optimization_percentage := (optimized_count::DECIMAL / total_policies) * 100;
        
        RAISE NOTICE '';
        RAISE NOTICE 'RLS Optimization Summary:';
        RAISE NOTICE '  Optimized policies: %', optimized_count;
        RAISE NOTICE '  Unoptimized policies: %', unoptimized_count;
        RAISE NOTICE '  Optimization rate: %% ', ROUND(optimization_percentage, 2);
        RAISE NOTICE '';
        
        IF optimization_percentage = 100 THEN
            RAISE NOTICE '✓ All policies are optimized!';
        ELSIF optimization_percentage >= 80 THEN
            RAISE NOTICE '⚠ Most policies are optimized, but some remain unoptimized.';
        ELSE
            RAISE NOTICE '✗ Many policies need optimization. Run the migration!';
        END IF;
    ELSE
        RAISE NOTICE 'No auth.uid() based policies found.';
    END IF;
END $$;

-- =============================================
-- End of validation script
-- =============================================

\echo ''
\echo '======================================'
\echo 'Validation Complete'
\echo '======================================'
\echo 'Review the results above to assess RLS performance status.'
\echo 'Run the migration script to apply optimizations.'