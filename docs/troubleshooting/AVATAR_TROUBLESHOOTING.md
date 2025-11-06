# Avatar Upload System Troubleshooting Guide

## Quick Fix Summary

The main issue was likely that the `user_profiles` table either didn't exist or was missing the `avatar_url` column. I've created a comprehensive migration that should fix all avatar upload issues.

## What was Fixed

1. **Created/Updated user_profiles table** with all required columns including `avatar_url`
2. **Set up proper RLS policies** for both storage and user_profiles
3. **Configured avatars storage bucket** with public read access
4. **Added auto-profile creation** trigger for new users
5. **Backfilled existing users** who didn't have profiles

## Files Created/Modified

- **`/Users/chromefang.exe/HobbyApp/supabase/migrations/20250105000001_fix_avatar_system.sql`** - Comprehensive fix migration
- **`/Users/chromefang.exe/HobbyApp/supabase/test_avatar_system.sql`** - Validation script

## How to Apply the Fix

1. **Start Supabase locally:**
   ```bash
   cd /Users/chromefang.exe/HobbyApp
   npx supabase start
   ```

2. **Apply the migration:**
   ```bash
   npx supabase migration up
   ```

3. **Verify the setup:**
   ```bash
   psql postgresql://postgres:postgres@localhost:54322/postgres -f supabase/test_avatar_system.sql
   ```

## Testing the Complete Pipeline

### 1. Database Verification
Run the test script to ensure all components are properly configured:
```sql
-- Check if everything is set up correctly
\i supabase/test_avatar_system.sql
```

### 2. iOS App Testing
In your iOS app, the upload should now work with this flow:

1. **User uploads image** → `uploadProfilePicture()` in `SimpleSupabaseService.swift`
2. **Image gets stored** → `avatars/profile-photos/{userId}_{UUID}.jpg`
3. **Public URL generated** → `https://[project].supabase.co/storage/v1/object/public/avatars/profile-photos/...`
4. **Profile updated** → `user_profiles.avatar_url` gets the URL

### 3. Expected iOS Console Output
When upload works correctly, you should see:
```
📸 Uploading profile picture to: profile-photos/[userId]_[UUID].jpg
📸 Image size: [bytes] bytes
✅ Upload successful: [response]
✅ Public URL generated: [URL]
📝 Upserting user profile with avatar URL...
✅ User profile upserted successfully (avatar URL saved)
```

## Common Issues & Solutions

### Issue: "relation 'user_profiles' does not exist"
**Solution:** Run the new migration - this creates the table.

### Issue: "column 'avatar_url' does not exist"
**Solution:** The migration adds this column to existing tables.

### Issue: "permission denied for storage object"
**Solution:** The migration sets up proper RLS policies for the avatars bucket.

### Issue: "bucket 'avatars' does not exist"
**Solution:** The migration creates the bucket with proper public settings.

### Issue: Upload succeeds but avatar doesn't show
**Checks:**
1. Verify the URL was saved: `SELECT avatar_url FROM user_profiles WHERE id = '[user_id]'`
2. Test the URL in browser - should be publicly accessible
3. Check iOS image loading code for nil checks

## Storage Policy Details

The migration creates these storage policies:

1. **Upload Policy**: Users can upload to `profile-photos/{their_user_id}_*.jpg`
2. **Update Policy**: Users can update their own photos
3. **Delete Policy**: Users can delete their own photos  
4. **View Policy**: Anyone can view avatars (public read)

## File Path Pattern

The iOS app uploads to: `profile-photos/{userId}_{UUID}.jpg`

The storage policies extract the user ID from the filename using regex: `^profile-photos/([^_]+)_`

## User Profile Policies

1. **Public Read**: Anyone can view user profiles (for displaying avatars)
2. **User Update**: Users can only update their own profile
3. **User Insert**: Users can only create their own profile

## Auto-Profile Creation

New users automatically get a `user_profiles` row when they sign up via the trigger function.

## Debugging Commands

### Check bucket exists:
```sql
SELECT * FROM storage.buckets WHERE id = 'avatars';
```

### Check user profile:
```sql
SELECT * FROM user_profiles WHERE id = '[user_id]';
```

### Check storage policies:
```sql
SELECT * FROM pg_policies WHERE tablename = 'objects' AND policyname LIKE '%avatar%';
```

### Check profile policies:
```sql
SELECT * FROM pg_policies WHERE tablename = 'user_profiles';
```

### Test storage path matching:
```sql
SELECT 
    'profile-photos/123e4567-e89b-12d3-a456-426614174000_abc123.jpg' as path,
    (storage.foldername('profile-photos/123e4567-e89b-12d3-a456-426614174000_abc123.jpg'))[1] as folder,
    (regexp_match('profile-photos/123e4567-e89b-12d3-a456-426614174000_abc123.jpg', '^profile-photos/([^_]+)_'))[1] as user_id;
```

## Production Deployment

When deploying to production:

1. **Apply migration:**
   ```bash
   npx supabase db push
   ```

2. **Verify in Supabase Dashboard:**
   - Storage → Buckets → Check 'avatars' exists and is public
   - Authentication → Settings → Check auto-confirm is enabled if needed
   - Database → Tables → Verify user_profiles has avatar_url column

3. **Test with real user:**
   - Sign up new user
   - Upload profile picture
   - Verify URL is accessible and saved

## Security Considerations

- **Public Bucket**: Avatars are publicly readable (necessary for display)
- **User Isolation**: Users can only upload/modify their own photos
- **Path Validation**: Enforced via RLS policies using filename patterns
- **File Type**: Currently accepts any file type - consider adding validation

## Performance Notes

- **Bucket is public**: No auth required for viewing avatars (faster loading)
- **Upsert Strategy**: Profile updates use upsert to handle missing profiles
- **Indexed**: The user_profiles table should have indexes on id for fast lookups