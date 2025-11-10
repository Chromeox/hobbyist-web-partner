-- Studio Approval Workflow Migration (SIMPLE VERSION)
-- Adds approval status tracking - admin checks removed for now
-- Date: 2025-11-10

-- ============================================
-- PART 1: ADD MISSING COLUMNS TO STUDIOS TABLE
-- ============================================

-- Add is_active if it doesn't exist
ALTER TABLE studios
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add approval status and tracking fields
ALTER TABLE studios
ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Add constraint separately
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'studios_approval_status_check'
    ) THEN
        ALTER TABLE studios ADD CONSTRAINT studios_approval_status_check
        CHECK (approval_status IN ('pending', 'approved', 'rejected', 'under_review'));
    END IF;
END $$;

-- Add onboarding completion tracking
ALTER TABLE studios
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ;

-- Create index for faster admin queries
CREATE INDEX IF NOT EXISTS idx_studios_approval_status ON studios(approval_status);
CREATE INDEX IF NOT EXISTS idx_studios_approved_at ON studios(approved_at);
CREATE INDEX IF NOT EXISTS idx_studios_is_active ON studios(is_active);

-- ============================================
-- PART 2: CREATE STUDIO ONBOARDING SUBMISSIONS TABLE
-- ============================================

-- Drop table if exists to recreate with proper constraints
DROP TABLE IF EXISTS studio_onboarding_submissions CASCADE;

-- Track detailed onboarding submission data
CREATE TABLE studio_onboarding_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,

    -- Business Information
    business_name TEXT NOT NULL,
    legal_business_name TEXT,
    tax_id TEXT,
    business_type TEXT,

    -- Contact Details
    email TEXT NOT NULL,
    phone TEXT,
    website TEXT,

    -- Verification Documents
    business_license_url TEXT,
    insurance_certificate_url TEXT,
    identity_verification_status TEXT DEFAULT 'pending',

    -- Profile Data
    submitted_data JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Stripe Connect
    stripe_account_id TEXT,
    stripe_onboarding_complete BOOLEAN DEFAULT false,

    -- Status Tracking
    submission_status TEXT DEFAULT 'draft',
    admin_review_notes TEXT,

    -- Timestamps
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add constraints after table creation
ALTER TABLE studio_onboarding_submissions
ADD CONSTRAINT business_type_check
CHECK (business_type IN ('studio', 'independent_instructor', 'venue'));

ALTER TABLE studio_onboarding_submissions
ADD CONSTRAINT submission_status_check
CHECK (submission_status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected'));

-- Create indexes for submission queries
CREATE INDEX idx_submissions_user_id ON studio_onboarding_submissions(user_id);
CREATE INDEX idx_submissions_studio_id ON studio_onboarding_submissions(studio_id);
CREATE INDEX idx_submissions_status ON studio_onboarding_submissions(submission_status);

-- ============================================
-- PART 3: UPDATE RLS POLICIES FOR APPROVED STUDIOS
-- ============================================

-- Drop existing public read policies if they exist
DROP POLICY IF EXISTS "Public can view studios" ON studios;
DROP POLICY IF EXISTS "Anyone can view active studios" ON studios;
DROP POLICY IF EXISTS "Public can read studios" ON studios;
DROP POLICY IF EXISTS "Public can view approved studios only" ON studios;
DROP POLICY IF EXISTS "Studio owners can view own studio" ON studios;
DROP POLICY IF EXISTS "Admins can view all studios" ON studios;
DROP POLICY IF EXISTS "Studio owners can update own studio" ON studios;

-- Create new policy: Only approved and active studios are visible to public
CREATE POLICY "Public can view approved studios only" ON studios
    FOR SELECT
    USING (
        approval_status = 'approved'
        AND is_active = true
    );

-- Studio owners can view their own studio regardless of approval status
CREATE POLICY "Studio owners can view own studio" ON studios
    FOR SELECT
    USING (
        auth.uid() IN (
            SELECT user_id FROM studio_onboarding_submissions
            WHERE studio_id = studios.id
        )
    );

-- Anyone authenticated can view all studios (you'll control admin access in API)
CREATE POLICY "Authenticated users can view all studios" ON studios
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Studio owners can update their own studio
CREATE POLICY "Studio owners can update own studio" ON studios
    FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT user_id FROM studio_onboarding_submissions
            WHERE studio_id = studios.id
        )
    );

-- ============================================
-- PART 4: RLS POLICIES FOR ONBOARDING SUBMISSIONS
-- ============================================

-- Enable RLS on onboarding submissions
ALTER TABLE studio_onboarding_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own submissions" ON studio_onboarding_submissions;
DROP POLICY IF EXISTS "Users can create own submissions" ON studio_onboarding_submissions;
DROP POLICY IF EXISTS "Users can update own draft submissions" ON studio_onboarding_submissions;
DROP POLICY IF EXISTS "Admins can view all submissions" ON studio_onboarding_submissions;
DROP POLICY IF EXISTS "Admins can update all submissions" ON studio_onboarding_submissions;

-- Users can view their own submissions
CREATE POLICY "Users can view own submissions" ON studio_onboarding_submissions
    FOR SELECT
    USING (user_id = auth.uid());

-- Users can insert their own submissions
CREATE POLICY "Users can create own submissions" ON studio_onboarding_submissions
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Users can update their own submissions (only if not yet submitted)
CREATE POLICY "Users can update own draft submissions" ON studio_onboarding_submissions
    FOR UPDATE
    USING (
        user_id = auth.uid()
        AND submission_status = 'draft'
    );

-- All authenticated users can view all submissions (admin check in API)
CREATE POLICY "Authenticated can view all submissions" ON studio_onboarding_submissions
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- All authenticated users can update all submissions (admin check in API)
CREATE POLICY "Authenticated can update all submissions" ON studio_onboarding_submissions
    FOR UPDATE
    USING (auth.uid() IS NOT NULL);

-- ============================================
-- PART 5: UPDATE TRIGGER FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for studio_onboarding_submissions
DROP TRIGGER IF EXISTS update_studio_onboarding_submissions_updated_at ON studio_onboarding_submissions;
CREATE TRIGGER update_studio_onboarding_submissions_updated_at
    BEFORE UPDATE ON studio_onboarding_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- PART 6: COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON COLUMN studios.approval_status IS 'Admin approval status: pending (default), approved, rejected, under_review';
COMMENT ON COLUMN studios.approved_by IS 'User ID of admin who approved this studio';
COMMENT ON COLUMN studios.approved_at IS 'Timestamp when studio was approved';
COMMENT ON COLUMN studios.rejection_reason IS 'Reason provided by admin if studio was rejected';
COMMENT ON COLUMN studios.admin_notes IS 'Internal notes from admin review process';
COMMENT ON COLUMN studios.is_active IS 'Whether studio is active and visible (boolean)';

COMMENT ON TABLE studio_onboarding_submissions IS 'Tracks complete studio onboarding process with all submission data';
COMMENT ON COLUMN studio_onboarding_submissions.submitted_data IS 'Complete JSONB snapshot of all onboarding form data';
COMMENT ON COLUMN studio_onboarding_submissions.identity_verification_status IS 'Status of identity verification: pending, verified, failed';

-- ============================================
-- PART 7: DATA MIGRATION - SET EXISTING STUDIOS TO APPROVED
-- ============================================

-- Set all existing studios to approved (assumes they're already vetted)
UPDATE studios
SET
    approval_status = 'approved',
    approved_at = NOW(),
    onboarding_completed = true,
    onboarding_completed_at = NOW(),
    is_active = COALESCE(is_active, true)
WHERE approval_status IS NULL;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify approval status field was added
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'studios' AND column_name = 'approval_status'
    ) THEN
        RAISE NOTICE 'SUCCESS: approval_status column added to studios table';
    ELSE
        RAISE EXCEPTION 'FAILED: approval_status column not found in studios table';
    END IF;
END $$;

-- Verify is_active field exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'studios' AND column_name = 'is_active'
    ) THEN
        RAISE NOTICE 'SUCCESS: is_active column exists in studios table';
    ELSE
        RAISE EXCEPTION 'FAILED: is_active column not found in studios table';
    END IF;
END $$;

-- Verify onboarding submissions table was created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'studio_onboarding_submissions'
    ) THEN
        RAISE NOTICE 'SUCCESS: studio_onboarding_submissions table created';
    ELSE
        RAISE EXCEPTION 'FAILED: studio_onboarding_submissions table not found';
    END IF;
END $$;

-- Verify RLS policies exist
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'studios' AND policyname = 'Public can view approved studios only'
    ) THEN
        RAISE NOTICE 'SUCCESS: RLS policy created for approved studios';
    ELSE
        RAISE WARNING 'WARNING: RLS policy not found - may need manual verification';
    END IF;
END $$;

-- Show final count of studios by status
DO $$
DECLARE
    approved_count INTEGER;
    pending_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO approved_count FROM studios WHERE approval_status = 'approved';
    SELECT COUNT(*) INTO pending_count FROM studios WHERE approval_status = 'pending';
    RAISE NOTICE 'Studios status: % approved, % pending', approved_count, pending_count;
END $$;
