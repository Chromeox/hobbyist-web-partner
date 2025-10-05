# Avatar Storage Setup Guide

## Overview
This guide covers the setup and usage of profile picture uploads to Supabase Storage.

## Architecture

### Storage Structure
```
avatars (bucket)
└── profile-photos/
    ├── {userId}_{uuid}.jpg
    ├── {userId}_{uuid}.jpg
    └── ...
```

### File Naming Convention
- **Format**: `{userId}_{uuid}.jpg`
- **Example**: `123e4567-e89b-12d3-a456-426614174000_a1b2c3d4-5678-90ab-cdef-1234567890ab.jpg`
- **Why**: Allows RLS policies to verify ownership based on userId prefix

## Database Schema

### User Profiles Table
```sql
-- user_profiles table should have:
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    avatar_url TEXT,
    -- other fields...
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Migration Files

### 1. Create Avatars Bucket & Policies
**File**: `20250105000000_create_avatars_storage.sql`

This migration:
- ✅ Creates the `avatars` bucket (public)
- ✅ Enables RLS on `storage.objects`
- ✅ Creates 4 security policies:
  1. Users can upload their own avatars
  2. Users can update their own avatars
  3. Users can delete their own avatars
  4. Public read access for all avatars

### 2. Validation Script
**File**: `validate_avatar_storage.sql`

Run this to verify setup:
```bash
psql $DATABASE_URL -f supabase/migrations/validate_avatar_storage.sql
```

Expected output:
- ✅ Avatars bucket exists
- ✅ RLS is enabled
- ✅ 4 policies exist
- ✅ user_profiles has avatar_url column

## iOS Implementation

### 1. SimpleSupabaseService Methods

#### Upload Profile Picture
```swift
let avatarURL = try await SimpleSupabaseService.shared.uploadProfilePicture(imageData)
```

**Features**:
- Generates unique filename with userId prefix
- Uploads to `avatars/profile-photos/`
- Returns public URL
- Automatically updates `user_profiles.avatar_url`

#### Delete Profile Picture
```swift
try await SimpleSupabaseService.shared.deleteProfilePicture(avatarURL: oldURL)
```

**Features**:
- Extracts file path from URL
- Deletes from Storage
- Clears `user_profiles.avatar_url`

### 2. ProfileView Integration

#### Image Selection
- Uses `PhotosPicker` from PhotosUI
- Supports `.images` matching
- Shows preview before upload

#### Image Processing
- Resizes to max 800x800px (maintains aspect ratio)
- Compresses to JPEG at 0.8 quality
- Typical 4MB photo → ~200KB

#### Upload Flow
```
1. User taps "Change Photo"
2. PhotosPicker opens
3. User selects image
4. Image loads & compresses
5. Upload to Supabase (with progress)
6. URL saved to user_profiles
7. Preview updates
```

## Security Policies Explained

### Upload Policy
```sql
-- Only allows uploads where:
-- 1. Bucket is 'avatars'
-- 2. Path starts with 'profile-photos/'
-- 3. UserId in filename matches authenticated user
```

### Update Policy
```sql
-- Same restrictions as upload
-- Prevents users from modifying others' photos
```

### Delete Policy
```sql
-- Users can only delete their own photos
-- Verified by userId in filename
```

### View Policy
```sql
-- Public read access
-- Anyone can view avatar URLs
```

## Common Issues & Solutions

### Issue: Upload fails with 403 Forbidden
**Cause**: RLS policy rejecting upload
**Solution**: Verify userId in filename matches `auth.uid()`

### Issue: Bucket not found
**Cause**: Migration not run
**Solution**: Run `20250105000000_create_avatars_storage.sql`

### Issue: Image too large
**Cause**: File size exceeds storage limits
**Solution**: Already handled - images compressed to ~200KB

### Issue: URL not updating in user_profiles
**Cause**: Table doesn't have `avatar_url` column
**Solution**: Add column:
```sql
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;
```

## Testing Checklist

### Backend (Supabase)
- [ ] Run migration: `20250105000000_create_avatars_storage.sql`
- [ ] Run validation: `validate_avatar_storage.sql`
- [ ] Verify bucket exists in Supabase dashboard
- [ ] Check RLS policies in Storage settings

### iOS App
- [ ] Build app successfully
- [ ] Tap "Change Photo" button
- [ ] Select image from photo library
- [ ] Verify image preview appears
- [ ] Check upload progress indicator
- [ ] Confirm photo uploads to Supabase
- [ ] Verify avatar_url saved to user_profiles
- [ ] Test image displays after save

### Edge Cases
- [ ] Test with large images (5MB+)
- [ ] Test with small images (< 100KB)
- [ ] Test with different aspect ratios
- [ ] Test upload cancellation
- [ ] Test network failure handling
- [ ] Test with no internet connection

## Deployment Steps

### 1. Run Migration
```p 
```

### 2. Validate Setup
```bash
PGPASSWORD="your_password" psql "postgresql://postgres.project@aws-0-region.pooler.supabase.com:6543/postgres?sslmode=require" \
  -f supabase/migrations/validate_avatar_storage.sql
```

### 3. Test in iOS App
- Build and run app
- Navigate to Profile → Edit Profile
- Test complete upload flow

## Performance Considerations

### Image Optimization
- **Max Dimension**: 800x800px
- **Compression**: 0.8 quality JPEG
- **Average Size**: ~200KB (from 4MB originals)
- **Upload Time**: ~1-2 seconds on 4G

### Storage Costs
- Supabase Free Tier: 1GB storage
- ~5,000 profile pictures at 200KB each
- Upgrade if needed: $0.021/GB/month

## Monitoring

### Check Storage Usage
```sql
SELECT
    COUNT(*) AS total_avatars,
    pg_size_pretty(SUM(metadata->>'size'::bigint)::bigint) AS total_size
FROM storage.objects
WHERE bucket_id = 'avatars';
```

### Recent Uploads
```sql
SELECT
    name,
    created_at,
    pg_size_pretty((metadata->>'size')::bigint) AS file_size
FROM storage.objects
WHERE bucket_id = 'avatars'
ORDER BY created_at DESC
LIMIT 10;
```

## Future Enhancements

- [ ] Add image cropping UI
- [ ] Support multiple image formats (PNG, WebP)
- [ ] Implement CDN caching
- [ ] Add thumbnail generation
- [ ] Support video profile pictures
- [ ] Implement avatar templates/defaults

---

**Last Updated**: 2025-01-05
**Version**: 1.0.0
