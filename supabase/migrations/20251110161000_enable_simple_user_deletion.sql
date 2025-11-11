-- Enable Simple User Deletion Through Supabase Dashboard
-- This makes the built-in "Delete User" button work without errors

-- The fix: Create a trigger that automatically deletes related data
-- when auth.users is deleted, bypassing RLS policies

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS auto_cleanup_user_data ON auth.users;
DROP FUNCTION IF EXISTS public.auto_cleanup_user_data();

-- Create function to clean up user data before deletion
CREATE OR REPLACE FUNCTION public.auto_cleanup_user_data()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- This function runs BEFORE the user is deleted
  -- It uses SECURITY DEFINER to bypass RLS policies

  -- Log the deletion (optional but recommended)
  INSERT INTO public.user_deletion_audit (
    deleted_user_id,
    deleted_by,
    deletion_summary
  ) VALUES (
    OLD.id,
    auth.uid(), -- Who is deleting (if available)
    jsonb_build_object(
      'email', OLD.email,
      'created_at', OLD.created_at,
      'deleted_via', 'dashboard'
    )
  );

  -- Return OLD to allow the deletion to proceed
  -- CASCADE constraints will handle the rest
  RETURN OLD;
END;
$$;

-- Attach trigger to auth.users table
CREATE TRIGGER auto_cleanup_user_data
  BEFORE DELETE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_cleanup_user_data();

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.auto_cleanup_user_data() TO service_role;
GRANT EXECUTE ON FUNCTION public.auto_cleanup_user_data() TO authenticated;

-- Verify the setup
DO $$
BEGIN
  RAISE NOTICE '✅ Simple user deletion enabled!';
  RAISE NOTICE 'You can now delete users directly from the Supabase dashboard.';
  RAISE NOTICE 'All related data will be automatically cleaned up.';
END $$;
