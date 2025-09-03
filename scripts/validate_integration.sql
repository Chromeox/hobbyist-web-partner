-- =====================================================
-- Integration Validation Script
-- Verifies all tables, relationships, and data integrity
-- =====================================================

-- 1. Check Core Tables Exist
SELECT 'Checking Core Tables...' as status;

SELECT table_name, 
       CASE WHEN table_name IS NOT NULL THEN '✓ Exists' ELSE '✗ Missing' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'studios',
    'studio_locations', 
    'instructor_profiles',
    'instructor_studio_partnerships',
    'instructor_reviews',
    'instructor_followers',
    'classes',
    'bookings',
    'categories',
    'credit_packs',
    'user_credits',
    'subscriptions',
    'subscription_tiers',
    'payouts',
    'revenue_shares'
)
ORDER BY table_name;

-- 2. Check Foreign Key Relationships
SELECT 'Checking Foreign Keys...' as status;

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- 3. Check RLS Policies
SELECT 'Checking RLS Policies...' as status;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual IS NOT NULL as has_qual,
    with_check IS NOT NULL as has_with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4. Check Indexes for Performance
SELECT 'Checking Indexes...' as status;

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
    AND indexname NOT LIKE '%_pkey'
ORDER BY tablename, indexname;

-- 5. Check Real-time Subscriptions
SELECT 'Checking Real-time Configuration...' as status;

SELECT 
    pubname,
    schemaname,
    tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- 6. Verify Data Integrity
SELECT 'Checking Data Integrity...' as status;

-- Check for orphaned bookings
SELECT 
    'Orphaned Bookings' as check_type,
    COUNT(*) as count
FROM bookings b
LEFT JOIN classes c ON b.class_id = c.id
WHERE c.id IS NULL;

-- Check for instructors without profiles
SELECT 
    'Instructors without profiles' as check_type,
    COUNT(*) as count
FROM instructors i
LEFT JOIN instructor_profiles ip ON i.user_id = ip.user_id
WHERE ip.id IS NULL;

-- Check for classes without categories
SELECT 
    'Classes without categories' as check_type,
    COUNT(*) as count
FROM classes c
LEFT JOIN categories cat ON c.category_id = cat.id
WHERE cat.id IS NULL;

-- 7. Check Sample Data
SELECT 'Checking Sample Data...' as status;

SELECT 
    'Categories' as table_name,
    COUNT(*) as record_count
FROM categories
UNION ALL
SELECT 
    'Studios' as table_name,
    COUNT(*) as record_count
FROM studios
UNION ALL
SELECT 
    'Instructor Profiles' as table_name,
    COUNT(*) as record_count
FROM instructor_profiles
UNION ALL
SELECT 
    'Classes' as table_name,
    COUNT(*) as record_count
FROM classes
UNION ALL
SELECT 
    'Studio Locations' as table_name,
    COUNT(*) as record_count
FROM studio_locations
ORDER BY table_name;

-- 8. Performance Check - Query Execution Times
SELECT 'Checking Query Performance...' as status;

EXPLAIN ANALYZE
SELECT 
    c.id,
    c.name,
    i.display_name as instructor,
    sl.name as location,
    cat.name as category
FROM classes c
LEFT JOIN instructor_profiles i ON c.instructor_id = i.id
LEFT JOIN studio_locations sl ON c.location_id = sl.id
LEFT JOIN categories cat ON c.category_id = cat.id
LIMIT 10;