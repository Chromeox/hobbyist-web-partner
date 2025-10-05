-- Auto-create user_profiles row when new user signs up
-- This ensures profile photos and other profile data can be saved immediately

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert new profile row with user's ID and basic info from auth metadata
    INSERT INTO public.user_profiles (
        id,
        full_name,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NOW(),
        NOW()
    );

    RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Backfill existing users who don't have profiles yet
INSERT INTO public.user_profiles (id, full_name, created_at, updated_at)
SELECT
    au.id,
    COALESCE(au.raw_user_meta_data->>'full_name', ''),
    au.created_at,
    NOW()
FROM auth.users au
LEFT JOIN public.user_profiles up ON au.id = up.id
WHERE up.id IS NULL;

-- Verify the trigger was created
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'on_auth_user_created';

    IF trigger_count = 0 THEN
        RAISE EXCEPTION 'Trigger on_auth_user_created was not created successfully';
    ELSE
        RAISE NOTICE 'Trigger on_auth_user_created created successfully';
    END IF;
END $$;
