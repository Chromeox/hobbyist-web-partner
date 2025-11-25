-- Better Auth Database Schema (Safe to re-run)
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User table
CREATE TABLE IF NOT EXISTS "user" (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  email TEXT NOT NULL UNIQUE,
  "emailVerified" BOOLEAN NOT NULL DEFAULT false,
  name TEXT,
  image TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
  role TEXT DEFAULT 'student',
  "businessName" TEXT,
  "accountType" TEXT DEFAULT 'student',
  "firstName" TEXT,
  "lastName" TEXT
);

-- Account table (for OAuth providers)
CREATE TABLE IF NOT EXISTS account (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "userId" TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  "accountId" TEXT NOT NULL,
  "providerId" TEXT NOT NULL,
  "accessToken" TEXT,
  "refreshToken" TEXT,
  "idToken" TEXT,
  "expiresAt" TIMESTAMP,
  password TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE("providerId", "accountId")
);

-- Session table
CREATE TABLE IF NOT EXISTS session (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  "userId" TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  "expiresAt" TIMESTAMP NOT NULL,
  token TEXT NOT NULL UNIQUE,
  "ipAddress" TEXT,
  "userAgent" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

-- Verification table (for email verification, password reset)
CREATE TABLE IF NOT EXISTS verification (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  identifier TEXT NOT NULL,
  value TEXT NOT NULL,
  "expiresAt" TIMESTAMP NOT NULL,
  "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS user_email_idx ON "user"(email);
CREATE INDEX IF NOT EXISTS user_role_idx ON "user"(role);
CREATE INDEX IF NOT EXISTS account_userId_idx ON account("userId");
CREATE INDEX IF NOT EXISTS session_userId_idx ON session("userId");
CREATE INDEX IF NOT EXISTS session_token_idx ON session(token);
CREATE INDEX IF NOT EXISTS verification_identifier_idx ON verification(identifier);

-- Updated at triggers function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop existing triggers if they exist (to avoid "already exists" error)
DROP TRIGGER IF EXISTS update_user_updated_at ON "user";
DROP TRIGGER IF EXISTS update_account_updated_at ON account;
DROP TRIGGER IF EXISTS update_session_updated_at ON session;

-- Create triggers
CREATE TRIGGER update_user_updated_at
  BEFORE UPDATE ON "user"
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_account_updated_at
  BEFORE UPDATE ON account
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_session_updated_at
  BEFORE UPDATE ON session
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE "user" ENABLE ROW LEVEL SECURITY;
ALTER TABLE account ENABLE ROW LEVEL SECURITY;
ALTER TABLE session ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Service role has full access to users" ON "user";
DROP POLICY IF EXISTS "Service role has full access to accounts" ON account;
DROP POLICY IF EXISTS "Service role has full access to sessions" ON session;
DROP POLICY IF EXISTS "Service role has full access to verifications" ON verification;

-- Create RLS policies for service role
CREATE POLICY "Service role has full access to users"
  ON "user"
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role has full access to accounts"
  ON account
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role has full access to sessions"
  ON session
  FOR ALL
  USING (auth.role() = 'service_role');

CREATE POLICY "Service role has full access to verifications"
  ON verification
  FOR ALL
  USING (auth.role() = 'service_role');
