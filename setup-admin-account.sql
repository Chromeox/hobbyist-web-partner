-- ============================================
-- Admin Account Setup for admin@hobbi.com
-- ============================================
-- Run this in Supabase SQL Editor AFTER running better-auth-schema.sql
--
-- Password: $tarFox64*4455
-- ⚠️ CHANGE THIS PASSWORD AFTER FIRST LOGIN!
--
-- Instructions:
-- 1. Go to: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql
-- 2. Copy and paste this entire file
-- 3. Click "Run" or press Cmd+Enter
-- 4. Verify success message
-- 5. Test login at your app's sign-in page
-- ============================================

-- Step 1: Create or update the admin user
INSERT INTO "user" (
  email,
  "emailVerified",
  role,
  "accountType",
  "firstName",
  "lastName",
  name
)
VALUES (
  'admin@hobbi.com',
  true,
  'admin',
  'admin',
  'Admin',
  'User',
  'Admin User'
)
ON CONFLICT (email)
DO UPDATE SET
  "emailVerified" = true,
  role = 'admin',
  "accountType" = 'admin',
  "firstName" = 'Admin',
  "lastName" = 'User',
  name = 'Admin User',
  "updatedAt" = NOW();

-- Step 2: Create or update password account
INSERT INTO "account" (
  "userId",
  "accountId",
  "providerId",
  password
)
VALUES (
  (SELECT id FROM "user" WHERE email = 'admin@hobbi.com'),
  'admin@hobbi.com',
  'credential',
  '$2b$10$6MC.DlKWlgtKaHoc7mPcuujV8cUeW/OaUw..T/YhAe.dGNp5.bClm'
)
ON CONFLICT ("providerId", "accountId")
DO UPDATE SET
  password = '$2b$10$6MC.DlKWlgtKaHoc7mPcuujV8cUeW/OaUw..T/YhAe.dGNp5.bClm',
  "updatedAt" = NOW();

-- Step 3: Verify the setup
SELECT
  u.id,
  u.email,
  u.role,
  u."accountType",
  u."firstName",
  u."lastName",
  u."emailVerified",
  u."createdAt",
  a."providerId",
  CASE
    WHEN a.password IS NOT NULL THEN '✅ Password Set'
    ELSE '❌ No Password'
  END as password_status
FROM "user" u
LEFT JOIN "account" a ON u.id = a."userId" AND a."providerId" = 'credential'
WHERE u.email = 'admin@hobbi.com';

-- Success! Admin account setup complete
--
-- Email: admin@hobbi.com
-- Password: $tarFox64*4455
--
-- ⚠️  IMPORTANT:
-- 1. Test login at your app's sign-in page
-- 2. Change this password after first login!
-- 3. Keep this password secure until changed
--
-- Next steps:
-- - Access admin portal at: /internal/admin
-- - Update your password in settings
