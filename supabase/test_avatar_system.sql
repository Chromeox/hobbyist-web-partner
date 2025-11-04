-- Test Avatar System Script
-- Run this after applying the avatar system migration to verify everything works

\echo '========================================='
\echo 'Testing Avatar Upload System'
\echo '========================================='
\echo ''

-- Test 1: Verify avatars bucket exists and is public
\echo '1. Testing avatars bucket configuration...'
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✅ Avatars bucket exists'
        ELSE '❌ Avatars bucket missing'
    END AS bucket_status,
    CASE
        WHEN public = true THEN '✅ Bucket is public'
        ELSE '❌ Bucket is not public'
    END AS public_status
FROM storage.buckets
WHERE id = 'avatars';

-- Test 2: Verify user_profiles table structure
\echo ''
\echo '2. Testing user_profiles table...'
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Test 3: Check RLS is enabled
\echo ''
\echo '3. Checking RLS status...'
SELECT
    schemaname,
    tablename,
    CASE
        WHEN rowsecurity THEN '✅ RLS enabled'
        ELSE '❌ RLS disabled'
    END AS rls_status
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename = 'user_profiles';

-- Test 4: Verify storage policies
\echo ''
\echo '4. Checking storage policies...'
SELECT
    policyname AS policy_name,
    cmd AS operation,
    CASE
        WHEN roles = '{authenticated}' THEN 'authenticated'
        WHEN roles = '{public}' THEN 'public'
        ELSE array_to_string(roles, ', ')
    END AS target_role
FROM pg_policies
WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%avatar%'
ORDER BY policyname;

-- Test 5: Verify profile policies
\echo ''
\echo '5. Checking user_profiles policies...'
SELECT
    policyname AS policy_name,
    cmd AS operation,
    CASE
        WHEN roles = '{authenticated}' THEN 'authenticated'
        WHEN roles = '{public}' THEN 'public'
        ELSE array_to_string(roles, ', ')
    END AS target_role
FROM pg_policies
WHERE tablename = 'user_profiles'
    AND schemaname = 'public'
ORDER BY policyname;

-- Test 6: Test path matching for storage policies
\echo ''
\echo '6. Testing storage path matching...'
-- Simulate the path pattern that iOS will use
WITH test_paths AS (
    SELECT 'profile-photos/123e4567-e89b-12d3-a456-426614174000_abc123.jpg' AS test_path
)
SELECT
    test_path,
    (storage.foldername(test_path))[1] AS folder_name,
    (regexp_match(test_path, '^profile-photos/([^_]+)_'))[1] AS extracted_user_id
FROM test_paths;

-- Test 7: Verify trigger exists
\echo ''
\echo '7. Checking auto-profile creation trigger...'
SELECT
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

\echo ''
\echo '========================================='
\echo 'Avatar System Test Complete!'
\echo '========================================='
\echo ''
\echo 'Expected results:'
\echo '  - Avatars bucket should exist and be public'
\echo '  - user_profiles should have: id, full_name, bio, avatar_url, created_at, updated_at'
\echo '  - RLS should be enabled on user_profiles'
\echo '  - 4 storage policies for avatars (upload, update, delete, view)'
\echo '  - 3 profile policies (view all, update own, insert own)'
\echo '  - Path matching should extract user ID correctly'
\echo '  - Auto-profile trigger should exist'
\echo ''

-- Test 8: Create a test user profile (optional)
-- Uncomment if you want to test with a real UUID
-- INSERT INTO auth.users (id, email, created_at, updated_at, email_confirmed_at)
-- VALUES (
--     '123e4567-e89b-12d3-a456-426614174000',
--     'test@example.com',
--     NOW(),
--     NOW(),
--     NOW()
-- );
--
-- \echo 'Test user profile should be auto-created...'
-- SELECT * FROM user_profiles WHERE id = '123e4567-e89b-12d3-a456-426614174000';