-- Migration: Add deleted_at column to profiles table for soft-delete support
-- Required for Clerk webhook user.deleted event handling
-- Run this in Supabase SQL Editor

-- Add deleted_at column if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

-- Create index for efficient queries filtering out deleted profiles
CREATE INDEX IF NOT EXISTS idx_profiles_deleted_at
ON profiles (deleted_at)
WHERE deleted_at IS NULL;

-- Comment for documentation
COMMENT ON COLUMN profiles.deleted_at IS 'Soft delete timestamp - set when user is deleted from Clerk';
