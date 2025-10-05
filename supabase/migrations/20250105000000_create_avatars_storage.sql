-- Create avatars storage bucket for profile pictures
-- Migration: 20250105000000_create_avatars_storage.sql

-- Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

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

-- Verify bucket was created
SELECT id, name, public
FROM storage.buckets
WHERE id = 'avatars';

-- Verify policies were created
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
