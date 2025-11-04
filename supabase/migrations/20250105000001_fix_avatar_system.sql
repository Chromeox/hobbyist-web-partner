-- Fix Avatar Storage System Migration
-- Created: 2025-01-05
-- Purpose: Create user_profiles table and fix complete avatar upload pipeline

-- ============================================
-- PART 1: Create user_profiles table if it doesn't exist
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid REFERENCES auth.users(id) PRIMARY KEY,
    full_name text,
    bio text,
    avatar_url text,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

-- Add avatar_url column if the table exists but column doesn't
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'user_profiles'
        AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE public.user_profiles ADD COLUMN avatar_url text;
    END IF;
END $$;

-- Enable RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 2: RLS Policies for user_profiles
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- Public can view profiles (for displaying avatars)
CREATE POLICY "Users can view all profiles"
ON public.user_profiles
FOR SELECT
TO public
USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- ============================================
-- PART 3: Storage Bucket Setup
-- ============================================

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    updated_at = now();

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 4: Storage RLS Policies
-- ============================================

-- Drop existing avatar policies to avoid conflicts
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public avatars are viewable by everyone" ON storage.objects;

-- Policy: Users can upload their own profile pictures
CREATE POLICY "Users can upload their own avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = 'profile-photos'
    AND auth.uid()::text = (regexp_match(name, '^profile-photos/([^_]+)_'))[1]
);

-- Policy: Users can update their own profile pictures
CREATE POLICY "Users can update their own avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = 'profile-photos'
    AND auth.uid()::text = (regexp_match(name, '^profile-photos/([^_]+)_'))[1]
)
WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = 'profile-photos'
    AND auth.uid()::text = (regexp_match(name, '^profile-photos/([^_]+)_'))[1]
);

-- Policy: Users can delete their own profile pictures
CREATE POLICY "Users can delete their own avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = 'profile-photos'
    AND auth.uid()::text = (regexp_match(name, '^profile-photos/([^_]+)_'))[1]
);

-- Policy: Anyone can view avatars (public read)
CREATE POLICY "Public avatars are viewable by everyone"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- ============================================
-- PART 5: Auto-Create Profile Function
-- ============================================

-- Create function to handle new user creation (update existing if needed)
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
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- PART 6: Backfill Existing Users
-- ============================================

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

-- ============================================
-- PART 7: Updated At Trigger
-- ============================================

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Add updated_at trigger to user_profiles
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- PART 8: Verification & Validation
-- ============================================

-- Verify avatars bucket exists
DO $$
DECLARE
    bucket_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bucket_count
    FROM storage.buckets
    WHERE id = 'avatars';

    IF bucket_count = 0 THEN
        RAISE EXCEPTION 'Avatars bucket was not created successfully';
    ELSE
        RAISE NOTICE 'Avatars bucket exists and is configured correctly';
    END IF;
END $$;

-- Verify user_profiles table has avatar_url column
DO $$
DECLARE
    column_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'user_profiles'
    AND column_name = 'avatar_url';

    IF column_count = 0 THEN
        RAISE EXCEPTION 'avatar_url column was not created in user_profiles table';
    ELSE
        RAISE NOTICE 'user_profiles table has avatar_url column';
    END IF;
END $$;

-- Verify storage policies exist
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%avatar%';

    IF policy_count < 4 THEN
        RAISE EXCEPTION 'Not all avatar storage policies were created. Expected 4, found %', policy_count;
    ELSE
        RAISE NOTICE 'All avatar storage policies created successfully';
    END IF;
END $$;

-- Show final status
SELECT
    'Avatar system setup complete!' as status,
    (SELECT COUNT(*) FROM storage.buckets WHERE id = 'avatars') as bucket_exists,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'avatar_url') as avatar_column_exists,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%avatar%') as storage_policies_count;