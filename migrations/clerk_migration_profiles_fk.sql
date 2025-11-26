-- Migration: Update profiles table for Clerk integration
-- This removes the foreign key constraint to auth.users since Clerk manages users externally
-- Run this in Supabase SQL Editor BEFORE testing the Clerk webhook

-- Step 1: Drop the foreign key constraint to auth.users
-- This is necessary because Clerk user IDs (strings like 'user_abc123')
-- are not UUIDs and can't reference auth.users
ALTER TABLE profiles
DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Step 2: Change id column from UUID to TEXT to accept Clerk IDs
-- Note: Only run if your id column is currently UUID type
-- Check current type first with: SELECT data_type FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'id';
-- ALTER TABLE profiles ALTER COLUMN id TYPE TEXT;

-- Step 3: Add deleted_at column for soft-delete support
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

-- Step 4: Create index for efficient queries filtering out deleted profiles
CREATE INDEX IF NOT EXISTS idx_profiles_deleted_at
ON profiles (deleted_at)
WHERE deleted_at IS NULL;

-- Step 5: Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_email
ON profiles (email);

-- Comments for documentation
COMMENT ON TABLE profiles IS 'User profiles synced from Clerk authentication service';
COMMENT ON COLUMN profiles.id IS 'Clerk user ID (string format: user_xxxx)';
COMMENT ON COLUMN profiles.deleted_at IS 'Soft delete timestamp - set when user is deleted from Clerk';

-- Optional: View to filter out deleted profiles
CREATE OR REPLACE VIEW active_profiles AS
SELECT * FROM profiles WHERE deleted_at IS NULL;
