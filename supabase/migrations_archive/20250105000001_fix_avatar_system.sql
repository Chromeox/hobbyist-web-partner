-- Fix Avatar System Migration
-- Creates/fixes user_profiles table and sets up avatar storage

-- ============================================
-- PART 1: Fix the security migration issue
-- ============================================

-- Remove the problematic line that references non-existent 'venues' table
-- Enable RLS on existing tables only
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 2: Create user_profiles table for avatars
-- ============================================

-- Create user_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON user_profiles
    FOR DELETE USING (auth.uid() = id);

-- ============================================
-- PART 3: Setup avatars storage bucket
-- ============================================

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects (skip if already enabled)
-- Note: RLS is typically already enabled on storage.objects by default in Supabase

-- Storage Policies for avatars bucket
-- Policy: Users can upload their own profile pictures
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
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
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
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
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;
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
DROP POLICY IF EXISTS "Public avatars are viewable by everyone" ON storage.objects;
CREATE POLICY "Public avatars are viewable by everyone"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- ============================================
-- PART 4: Auto-create user profiles for new users
-- ============================================

-- Function to auto-create user profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user_profile()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO user_profiles (id, full_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User')
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Create trigger to auto-create profiles
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user_profile();

-- ============================================
-- PART 5: Backfill existing users
-- ============================================

-- Create profiles for existing users who don't have them
INSERT INTO user_profiles (id, full_name)
SELECT 
    u.id, 
    COALESCE(u.raw_user_meta_data->>'full_name', 'User')
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- PART 6: Updated_at trigger for user_profiles
-- ============================================

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Add trigger for user_profiles updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify bucket was created
SELECT id, name, public
FROM storage.buckets
WHERE id = 'avatars';

-- Verify user_profiles table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify policies were created for storage
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'objects'
    AND schemaname = 'storage'
    AND policyname LIKE '%avatar%'
ORDER BY policyname;

-- Verify policies for user_profiles
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'user_profiles'
    AND schemaname = 'public'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Avatar system migration completed successfully!';
    RAISE NOTICE 'Created:';
    RAISE NOTICE '- user_profiles table with avatar_url column';
    RAISE NOTICE '- avatars storage bucket with public access';
    RAISE NOTICE '- Complete RLS policies for secure uploads';
    RAISE NOTICE '- Auto-profile creation for new users';
    RAISE NOTICE '- Backfilled existing users without profiles';
    RAISE NOTICE 'Your iOS avatar upload should now work perfectly!';
END $$;