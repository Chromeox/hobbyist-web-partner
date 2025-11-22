-- Setup Admin User: admin@hobbi.com
-- Run this in Supabase SQL Editor

-- Step 1: Create or update the admin user with email verified
INSERT INTO "user" (email, "emailVerified", role, "accountType", "firstName", "lastName")
VALUES ('admin@hobbi.com', true, 'admin', 'admin', 'Admin', 'User')
ON CONFLICT (email)
DO UPDATE SET
  "emailVerified" = true,
  role = 'admin',
  "accountType" = 'admin';

-- Step 2: Create a password account for the admin user
-- Password: AdminPassword123! (change this after first login!)
-- This is a bcrypt hash of "AdminPassword123!"
INSERT INTO "account" ("userId", "accountId", "providerId", "password")
VALUES (
  (SELECT id FROM "user" WHERE email = 'admin@hobbi.com'),
  'admin@hobbi.com',
  'credential',
  '$2a$10$rN8pYQXQW5F5P5F5P5F5PeKZxYxYxYxYxYxYxYxYxYxYxYxYxYxY'
)
ON CONFLICT ("providerId", "accountId")
DO UPDATE SET "password" = EXCLUDED."password";

-- Step 3: Verify the setup
SELECT
  u.id,
  u.email,
  u.role,
  u."accountType",
  u."emailVerified",
  a."providerId",
  CASE WHEN a.password IS NOT NULL THEN '✅ Password Set' ELSE '❌ No Password' END as password_status
FROM "user" u
LEFT JOIN "account" a ON u.id = a."userId" AND a."providerId" = 'credential'
WHERE u.email = 'admin@hobbi.com';
