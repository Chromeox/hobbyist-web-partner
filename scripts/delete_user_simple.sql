-- Simple User Deletion Script
-- Copy ONE of the queries below and paste into Supabase SQL Editor

-- ============================================================================
-- OPTION 1: Delete by Email Address
-- ============================================================================

DO $$
DECLARE
  user_id_to_delete uuid;
  deletion_result json;
BEGIN
  -- STEP 1: Find user by email
  SELECT id INTO user_id_to_delete
  FROM auth.users
  WHERE email = 'REPLACE_WITH_EMAIL@example.com'; -- <-- CHANGE THIS

  -- STEP 2: Check if user exists
  IF user_id_to_delete IS NULL THEN
    RAISE NOTICE 'User not found with that email';
  ELSE
    -- STEP 3: Delete user and get summary
    SELECT public.admin_delete_user(user_id_to_delete) INTO deletion_result;
    RAISE NOTICE 'Deleted successfully: %', deletion_result;
  END IF;
END $$;


-- ============================================================================
-- OPTION 2: Delete by User UUID (if you know the ID)
-- ============================================================================

-- Just replace the UUID and run this single line:
SELECT public.admin_delete_user('REPLACE-WITH-USER-UUID-HERE');


-- ============================================================================
-- OPTION 3: Preview What Will Be Deleted (Dry Run - Safe to Run)
-- ============================================================================

WITH target_user AS (
  SELECT id FROM auth.users
  WHERE email = 'REPLACE_WITH_EMAIL@example.com' -- <-- CHANGE THIS
)
SELECT
  'User Found' AS status,
  (SELECT email FROM auth.users WHERE id = (SELECT id FROM target_user)) AS email,
  (SELECT COUNT(*) FROM user_profiles WHERE id IN (SELECT id FROM target_user)) AS profiles,
  (SELECT COUNT(*) FROM bookings WHERE user_id IN (SELECT id FROM target_user)) AS bookings,
  (SELECT COUNT(*) FROM class_reviews WHERE user_id IN (SELECT id FROM target_user)) AS reviews,
  (SELECT COUNT(*) FROM credit_transactions WHERE user_id IN (SELECT id FROM target_user)) AS transactions;


-- ============================================================================
-- OPTION 4: View Recent Deletions (Audit Log)
-- ============================================================================

SELECT
  deletion_summary->>'email' AS deleted_email,
  deleted_at,
  deletion_summary->>'created_at' AS user_created_at
FROM user_deletion_audit
ORDER BY deleted_at DESC
LIMIT 10;
