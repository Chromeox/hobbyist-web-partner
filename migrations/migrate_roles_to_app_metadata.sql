-- ================================================================
-- Migration: Move User Roles to app_metadata
-- ================================================================
-- Purpose: Migrate user roles from user_metadata to app_metadata
--          for enhanced security (app_metadata is server-only)
--
-- Security Benefit:
--   - user_metadata can be modified by users via updateUser()
--   - app_metadata can ONLY be modified server-side
--   - Prevents privilege escalation attacks
--
-- Date: 2025-11-19
-- ================================================================

-- Step 1: Migrate admin role for ravenoak@protonmail.com
-- ================================================================
UPDATE auth.users
SET
  raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || '{"role": "admin"}'::jsonb,
  -- Remove from user_metadata for cleanliness (optional)
  raw_user_meta_data = raw_user_meta_data - 'role'
WHERE email = 'ravenoak@protonmail.com';

-- Step 2: Verify the migration
-- ================================================================
SELECT
  id,
  email,
  raw_user_meta_data->>'role' as user_meta_role,
  raw_app_meta_data->>'role' as app_meta_role,
  created_at
FROM auth.users
WHERE email = 'ravenoak@protonmail.com';

-- Expected result:
-- user_meta_role: null (or empty)
-- app_meta_role: admin

-- ================================================================
-- Optional: Migrate ALL existing roles to app_metadata
-- ================================================================
-- Uncomment below to migrate all users with roles in user_metadata

-- UPDATE auth.users
-- SET
--   raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) ||
--     jsonb_build_object('role', raw_user_meta_data->>'role'),
--   raw_user_meta_data = raw_user_meta_data - 'role'
-- WHERE raw_user_meta_data ? 'role'
--   AND raw_user_meta_data->>'role' IS NOT NULL;

-- ================================================================
-- Rollback Script (if needed)
-- ================================================================
-- Uncomment to rollback the migration

-- UPDATE auth.users
-- SET
--   raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) ||
--     jsonb_build_object('role', raw_app_meta_data->>'role'),
--   raw_app_meta_data = raw_app_meta_data - 'role'
-- WHERE email = 'ravenoak@protonmail.com';

-- ================================================================
-- Helper: Check all users with roles
-- ================================================================
-- SELECT
--   id,
--   email,
--   raw_user_meta_data->>'role' as user_role,
--   raw_app_meta_data->>'role' as app_role,
--   created_at
-- FROM auth.users
-- WHERE
--   (raw_user_meta_data ? 'role' AND raw_user_meta_data->>'role' IS NOT NULL)
--   OR (raw_app_meta_data ? 'role' AND raw_app_meta_data->>'role' IS NOT NULL)
-- ORDER BY created_at DESC;

-- ================================================================
-- Post-Migration Notes
-- ================================================================
-- 1. Code already updated to prioritize app_metadata over user_metadata
-- 2. Fallback to user_metadata maintained for backwards compatibility
-- 3. New role assignments should use app_metadata going forward
-- 4. Admin endpoints now enforce server-side role validation
