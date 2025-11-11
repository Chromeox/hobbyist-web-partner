-- Safe User Deletion Script
-- Usage: Replace USER_EMAIL_OR_ID below and execute in Supabase SQL Editor
--
-- This script uses the new admin_delete_user() function that:
-- 1. Bypasses RLS policies using SECURITY DEFINER
-- 2. Automatically cascades to all related tables
-- 3. Logs the deletion to user_deletion_audit
-- 4. Returns a summary of deleted records

-- ============================================================================
-- METHOD 1: Delete by User Email
-- ============================================================================

DO $$
DECLARE
  user_id_to_delete uuid;
  deletion_result json;
BEGIN
  -- Find user ID from email
  SELECT id INTO user_id_to_delete
  FROM auth.users
  WHERE email = 'user@example.com'; -- REPLACE WITH ACTUAL EMAIL

  IF user_id_to_delete IS NULL THEN
    RAISE NOTICE 'User not found with that email address';
  ELSE
    -- Delete user and get summary
    SELECT public.admin_delete_user(user_id_to_delete) INTO deletion_result;

    RAISE NOTICE 'User deleted successfully: %', deletion_result;
  END IF;
END $$;

-- ============================================================================
-- METHOD 2: Delete by User ID (Direct)
-- ============================================================================

-- Replace with actual user UUID
SELECT public.admin_delete_user('00000000-0000-0000-0000-000000000000');

-- ============================================================================
-- METHOD 3: View Audit Log of Recent Deletions
-- ============================================================================

SELECT
  deleted_user_id,
  deletion_summary->>'email' AS deleted_email,
  deleted_at,
  deletion_summary
FROM public.user_deletion_audit
ORDER BY deleted_at DESC
LIMIT 10;

-- ============================================================================
-- METHOD 4: Check What Would Be Deleted (Dry Run)
-- ============================================================================

WITH target_user AS (
  SELECT id
  FROM auth.users
  WHERE email = 'user@example.com' -- REPLACE WITH ACTUAL EMAIL
)
SELECT
  'user_profiles' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.user_profiles
WHERE id IN (SELECT id FROM target_user)

UNION ALL

SELECT
  'bookings' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.bookings
WHERE user_id IN (SELECT id FROM target_user)

UNION ALL

SELECT
  'reviews' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.class_reviews
WHERE user_id IN (SELECT id FROM target_user)

UNION ALL

SELECT
  'credit_transactions' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.credit_transactions
WHERE user_id IN (SELECT id FROM target_user)

UNION ALL

SELECT
  'saved_classes' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.saved_classes
WHERE user_id IN (SELECT id FROM target_user)

UNION ALL

SELECT
  'student_preferences' AS table_name,
  COUNT(*) AS records_to_delete
FROM public.student_preferences
WHERE user_id IN (SELECT id FROM target_user);

-- ============================================================================
-- EMERGENCY: Delete Multiple Users by Email Pattern
-- ============================================================================

-- CAUTION: This will delete ALL users matching the pattern!
-- Uncomment and modify carefully:

/*
DO $$
DECLARE
  user_record RECORD;
  deletion_result json;
  deletion_count int := 0;
BEGIN
  FOR user_record IN
    SELECT id, email
    FROM auth.users
    WHERE email LIKE '%@test.com' -- REPLACE WITH ACTUAL PATTERN
  LOOP
    SELECT public.admin_delete_user(user_record.id) INTO deletion_result;
    deletion_count := deletion_count + 1;
    RAISE NOTICE 'Deleted user: % (%)', user_record.email, user_record.id;
  END LOOP;

  RAISE NOTICE 'Total users deleted: %', deletion_count;
END $$;
*/
