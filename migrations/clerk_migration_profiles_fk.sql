-- CLERK MIGRATION: Update profiles table for Clerk integration

-- Drop ALL RLS policies on profiles table
DROP POLICY IF EXISTS "Users manage own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view active profiles" ON public.profiles;
DROP POLICY IF EXISTS "Service role has full access" ON public.profiles;

-- Drop RLS policies on studios that reference profiles
DROP POLICY IF EXISTS "Admins can manage all studios" ON public.studios;
DROP POLICY IF EXISTS "Studio owners can manage own studios" ON public.studios;
DROP POLICY IF EXISTS "Users can view studios" ON public.studios;

-- Drop FK constraint
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Change id column to TEXT for Clerk IDs
ALTER TABLE public.profiles ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Add deleted_at column
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_deleted_at ON public.profiles (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles (email);

-- Recreate simple RLS policies
CREATE POLICY "Anyone can view active profiles" ON public.profiles FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "Service role has full access" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

-- Create view
CREATE OR REPLACE VIEW public.active_profiles AS SELECT * FROM public.profiles WHERE deleted_at IS NULL;
