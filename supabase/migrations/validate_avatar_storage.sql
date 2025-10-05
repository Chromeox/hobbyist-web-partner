-- Validation Script for Avatar Storage Setup
-- Run this to verify the avatars bucket and policies are correctly configured

\echo '========================================='
\echo 'Avatar Storage Configuration Validation'
\echo '========================================='
\echo ''

-- 1. Check if avatars bucket exists
\echo '1. Checking avatars bucket...'
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✅ Avatars bucket exists'
        ELSE '❌ Avatars bucket NOT found'
    END AS status,
    id,
    name,
    public AS is_public,
    created_at
FROM storage.buckets
WHERE id = 'avatars'
GROUP BY id, name, public, created_at;

\echo ''

-- 2. Check RLS is enabled on storage.objects
\echo '2. Checking RLS status...'
SELECT
    CASE
        WHEN relrowsecurity THEN '✅ RLS is enabled on storage.objects'
        ELSE '❌ RLS is NOT enabled on storage.objects'
    END AS status
FROM pg_class
WHERE relname = 'objects'
    AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

\echo ''

-- 3. Check avatar-related policies
\echo '3. Checking avatar policies...'
SELECT
    policyname AS policy_name,
    cmd AS operation,
    CASE
        WHEN roles = '{authenticated}' THEN 'authenticated'
        WHEN roles = '{public}' THEN 'public'
        ELSE array_to_string(roles, ', ')
    END AS roles
FROM pg_policies
WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%avatar%'
ORDER BY policyname;

\echo ''

-- 4. Count policies
\echo '4. Policy count summary...'
SELECT
    COUNT(*) AS total_avatar_policies
FROM pg_policies
WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%avatar%';

\echo ''

-- 5. Check user_profiles table has avatar_url column
\echo '5. Checking user_profiles schema...'
SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '✅ avatar_url column exists in user_profiles'
        ELSE '❌ avatar_url column NOT found in user_profiles'
    END AS status,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'user_profiles'
    AND column_name = 'avatar_url';

\echo ''
\echo '========================================='
\echo 'Validation Complete!'
\echo '========================================='
\echo ''
\echo 'Expected results:'
\echo '  - Avatars bucket should exist (public)'
\echo '  - RLS should be enabled'
\echo '  - 4 policies should exist (upload, update, delete, view)'
\echo '  - user_profiles should have avatar_url column'
