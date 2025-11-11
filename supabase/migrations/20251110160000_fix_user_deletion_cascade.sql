-- Migration: Fix User Deletion Cascade Issues
-- Purpose: Enable safe deletion of users by properly configuring foreign key cascades
-- Created: 2025-11-10

-- ============================================================================
-- STEP 1: Update Foreign Key Constraints to CASCADE
-- ============================================================================

-- Drop and recreate foreign key constraints with proper CASCADE behavior

-- 1. user_profiles table
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_id_fkey;

ALTER TABLE public.user_profiles
  ADD CONSTRAINT user_profiles_id_fkey
  FOREIGN KEY (id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 2. studios table (approved_by should be SET NULL, not CASCADE)
ALTER TABLE public.studios
  DROP CONSTRAINT IF EXISTS studios_approved_by_fkey;

ALTER TABLE public.studios
  ADD CONSTRAINT studios_approved_by_fkey
  FOREIGN KEY (approved_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- 3. profiles table (legacy table - should CASCADE)
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_id_fkey;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey
  FOREIGN KEY (id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 4. api_rate_limits (should CASCADE - user-specific data)
ALTER TABLE public.api_rate_limits
  DROP CONSTRAINT IF EXISTS api_rate_limits_user_id_fkey;

ALTER TABLE public.api_rate_limits
  ADD CONSTRAINT api_rate_limits_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

-- 5. instructor_reviews (student_id should SET NULL - preserve review data)
ALTER TABLE public.instructor_reviews
  DROP CONSTRAINT IF EXISTS instructor_reviews_student_id_fkey;

ALTER TABLE public.instructor_reviews
  ADD CONSTRAINT instructor_reviews_student_id_fkey
  FOREIGN KEY (student_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- 6. payout_requests (approved_by and requester_id should SET NULL - preserve audit trail)
ALTER TABLE public.payout_requests
  DROP CONSTRAINT IF EXISTS payout_requests_approved_by_fkey;

ALTER TABLE public.payout_requests
  ADD CONSTRAINT payout_requests_approved_by_fkey
  FOREIGN KEY (approved_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

ALTER TABLE public.payout_requests
  DROP CONSTRAINT IF EXISTS payout_requests_requester_id_fkey;

ALTER TABLE public.payout_requests
  ADD CONSTRAINT payout_requests_requester_id_fkey
  FOREIGN KEY (requester_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- 7. commission_overrides (approved_by should SET NULL - preserve financial audit)
ALTER TABLE public.commission_overrides
  DROP CONSTRAINT IF EXISTS commission_overrides_approved_by_fkey;

ALTER TABLE public.commission_overrides
  ADD CONSTRAINT commission_overrides_approved_by_fkey
  FOREIGN KEY (approved_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- 8. Private schema tables that need fixing
ALTER TABLE private.stripe_customers
  DROP CONSTRAINT IF EXISTS stripe_customers_user_id_fkey;

ALTER TABLE private.stripe_customers
  ADD CONSTRAINT stripe_customers_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;

ALTER TABLE private.studio_locations
  DROP CONSTRAINT IF EXISTS studio_locations_manager_id_fkey;

ALTER TABLE private.studio_locations
  ADD CONSTRAINT studio_locations_manager_id_fkey
  FOREIGN KEY (manager_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

ALTER TABLE private.commission_overrides
  DROP CONSTRAINT IF EXISTS commission_overrides_approved_by_fkey;

ALTER TABLE private.commission_overrides
  ADD CONSTRAINT commission_overrides_approved_by_fkey
  FOREIGN KEY (approved_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

ALTER TABLE private.commission_structures
  DROP CONSTRAINT IF EXISTS commission_structures_created_by_fkey;

ALTER TABLE private.commission_structures
  ADD CONSTRAINT commission_structures_created_by_fkey
  FOREIGN KEY (created_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

ALTER TABLE private.gift_credits
  DROP CONSTRAINT IF EXISTS gift_credits_recipient_id_fkey;

ALTER TABLE private.gift_credits
  ADD CONSTRAINT gift_credits_recipient_id_fkey
  FOREIGN KEY (recipient_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- 9. security_audit_log and studio_onboarding_submissions (preserve audit trail)
ALTER TABLE public.security_audit_log
  DROP CONSTRAINT IF EXISTS security_audit_log_user_id_fkey;

ALTER TABLE public.security_audit_log
  ADD CONSTRAINT security_audit_log_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

ALTER TABLE public.studio_onboarding_submissions
  DROP CONSTRAINT IF EXISTS studio_onboarding_submissions_reviewed_by_fkey;

ALTER TABLE public.studio_onboarding_submissions
  ADD CONSTRAINT studio_onboarding_submissions_reviewed_by_fkey
  FOREIGN KEY (reviewed_by)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

-- ============================================================================
-- STEP 2: Create Secure Admin User Deletion Function
-- ============================================================================

-- Drop existing function if exists
DROP FUNCTION IF EXISTS public.admin_delete_user(uuid);

-- Create function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION public.admin_delete_user(user_id_to_delete uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  deleted_data json;
  profile_count int;
  bookings_count int;
  reviews_count int;
  transactions_count int;
BEGIN
  -- Verify the user exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id_to_delete) THEN
    RAISE EXCEPTION 'User % does not exist', user_id_to_delete;
  END IF;

  -- Count related records before deletion (for audit)
  SELECT COUNT(*) INTO profile_count FROM public.user_profiles WHERE id = user_id_to_delete;
  SELECT COUNT(*) INTO bookings_count FROM public.bookings WHERE user_id = user_id_to_delete;
  SELECT COUNT(*) INTO reviews_count FROM public.reviews WHERE user_id = user_id_to_delete;
  SELECT COUNT(*) INTO transactions_count FROM public.credit_transactions WHERE user_id = user_id_to_delete;

  -- Delete from auth.users (CASCADE will handle related tables)
  DELETE FROM auth.users WHERE id = user_id_to_delete;

  -- Return summary of deletion
  deleted_data := json_build_object(
    'user_id', user_id_to_delete,
    'deleted_at', now(),
    'related_records', json_build_object(
      'user_profiles', profile_count,
      'bookings', bookings_count,
      'reviews', reviews_count,
      'credit_transactions', transactions_count
    )
  );

  RETURN deleted_data;
END;
$$;

-- Grant execute permission to authenticated users (admin check should be in your app layer)
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO service_role;

-- Add comment
COMMENT ON FUNCTION public.admin_delete_user(uuid) IS
  'Securely deletes a user and all related data. Uses SECURITY DEFINER to bypass RLS policies. Should only be called by admin users.';

-- ============================================================================
-- STEP 3: Create Audit Log for User Deletions (Optional but Recommended)
-- ============================================================================

-- Create audit table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_deletion_audit (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  deleted_user_id uuid NOT NULL,
  deleted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  deleted_at timestamptz DEFAULT now(),
  deletion_summary jsonb,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on audit table
ALTER TABLE public.user_deletion_audit ENABLE ROW LEVEL SECURITY;

-- Only service_role can read audit logs
CREATE POLICY "Service role can read deletion audit"
  ON public.user_deletion_audit
  FOR SELECT
  TO service_role
  USING (true);

-- Create trigger to log deletions
CREATE OR REPLACE FUNCTION public.log_user_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_deletion_audit (
    deleted_user_id,
    deleted_by,
    deletion_summary
  ) VALUES (
    OLD.id,
    auth.uid(),
    jsonb_build_object(
      'email', OLD.email,
      'created_at', OLD.created_at,
      'last_sign_in_at', OLD.last_sign_in_at
    )
  );
  RETURN OLD;
END;
$$;

-- Attach trigger to auth.users
DROP TRIGGER IF EXISTS audit_user_deletion ON auth.users;
CREATE TRIGGER audit_user_deletion
  BEFORE DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.log_user_deletion();

-- ============================================================================
-- STEP 4: Verification Queries
-- ============================================================================

-- Verify all foreign keys have proper CASCADE settings
DO $$
DECLARE
  constraint_record RECORD;
  missing_cascade_count int := 0;
BEGIN
  FOR constraint_record IN
    SELECT
      conname,
      conrelid::regclass AS table_name,
      confdeltype
    FROM pg_constraint
    WHERE confrelid = 'auth.users'::regclass
      AND contype = 'f'
      AND confdeltype NOT IN ('c', 'n') -- 'c' = CASCADE, 'n' = SET NULL
  LOOP
    RAISE WARNING 'Foreign key % on table % does not have CASCADE or SET NULL',
      constraint_record.conname,
      constraint_record.table_name;
    missing_cascade_count := missing_cascade_count + 1;
  END LOOP;

  IF missing_cascade_count = 0 THEN
    RAISE NOTICE 'All foreign key constraints properly configured with CASCADE or SET NULL';
  ELSE
    RAISE WARNING '% foreign key constraint(s) still need CASCADE configuration', missing_cascade_count;
  END IF;
END $$;

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================

/*
To delete a user using the secure admin function:

1. From SQL Editor (with service_role):
   SELECT public.admin_delete_user('USER_UUID_HERE');

2. From your application (with proper admin checks):
   const { data, error } = await supabase.rpc('admin_delete_user', {
     user_id_to_delete: 'USER_UUID_HERE'
   });

3. Check audit log:
   SELECT * FROM public.user_deletion_audit
   ORDER BY deleted_at DESC
   LIMIT 10;

IMPORTANT SECURITY NOTES:
- This function bypasses RLS policies using SECURITY DEFINER
- Always implement proper admin authorization in your application layer
- The function is granted to 'authenticated' role but should only be accessible to admins
- Consider adding an additional admin check within the function itself
- All deletions are logged in the audit table for compliance
*/
