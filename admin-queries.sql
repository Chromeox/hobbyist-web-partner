-- Better Auth Admin Queries
-- Copy and paste these into Supabase SQL Editor

-- ========================================
-- VIEW USERS
-- ========================================

-- List all users with their roles
SELECT
  id,
  email,
  role,
  "accountType",
  "firstName",
  "lastName",
  "businessName",
  "emailVerified",
  "createdAt"::date as joined
FROM "user"
ORDER BY "createdAt" DESC;

-- Count users by role
SELECT role, COUNT(*) as count
FROM "user"
GROUP BY role
ORDER BY count DESC;

-- Find specific user by email
SELECT * FROM "user"
WHERE email = 'your@email.com';

-- ========================================
-- UPDATE USER ROLES
-- ========================================

-- Make a user an admin
UPDATE "user"
SET role = 'admin', "accountType" = 'admin'
WHERE email = 'your@email.com';

-- Make a user a studio
UPDATE "user"
SET role = 'studio', "accountType" = 'studio'
WHERE email = 'studio@example.com';

-- Make a user an instructor
UPDATE "user"
SET role = 'instructor', "accountType" = 'instructor'
WHERE email = 'instructor@example.com';

-- Make a user a student (default)
UPDATE "user"
SET role = 'student', "accountType" = 'student'
WHERE email = 'student@example.com';

-- ========================================
-- UPDATE USER DETAILS
-- ========================================

-- Update user's name and business
UPDATE "user"
SET
  "firstName" = 'John',
  "lastName" = 'Doe',
  "businessName" = 'Awesome Studio'
WHERE email = 'user@example.com';

-- Verify a user's email manually
UPDATE "user"
SET "emailVerified" = true
WHERE email = 'user@example.com';

-- ========================================
-- VIEW SESSIONS
-- ========================================

-- View all active sessions
SELECT
  s.id,
  s."userId",
  u.email,
  s."expiresAt",
  s."ipAddress",
  s."userAgent",
  s."createdAt"
FROM "session" s
JOIN "user" u ON s."userId" = u.id
WHERE s."expiresAt" > NOW()
ORDER BY s."createdAt" DESC;

-- View sessions for specific user
SELECT * FROM "session"
WHERE "userId" = (SELECT id FROM "user" WHERE email = 'user@example.com')
ORDER BY "createdAt" DESC;

-- ========================================
-- DELETE USERS (USE CAREFULLY!)
-- ========================================

-- Delete a specific user (this will cascade delete their sessions and accounts)
DELETE FROM "user"
WHERE email = 'user@example.com';

-- Delete all unverified users older than 30 days
DELETE FROM "user"
WHERE "emailVerified" = false
  AND "createdAt" < NOW() - INTERVAL '30 days';

-- ========================================
-- VIEW OAUTH ACCOUNTS
-- ========================================

-- View OAuth provider connections
SELECT
  a.id,
  u.email,
  a."providerId",
  a."accountId",
  a."createdAt"
FROM "account" a
JOIN "user" u ON a."userId" = u.id
ORDER BY a."createdAt" DESC;

-- Find users who signed up with Google
SELECT DISTINCT u.*
FROM "user" u
JOIN "account" a ON u.id = a."userId"
WHERE a."providerId" = 'google';

-- ========================================
-- BULK OPERATIONS
-- ========================================

-- Verify all emails (development only!)
UPDATE "user" SET "emailVerified" = true;

-- Set default role for all users without a role
UPDATE "user"
SET role = 'student'
WHERE role IS NULL;
