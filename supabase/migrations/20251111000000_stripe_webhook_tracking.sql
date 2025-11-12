-- Stripe Webhook Tracking Migration
-- Adds tables and fields for comprehensive Stripe webhook event tracking
-- Created: 2025-11-11
-- Purpose: Support payment tracking, transfer reconciliation, and payout management

-- ============================================================================
-- 1. STRIPE PAYMENT EVENTS TABLE
-- ============================================================================
-- Comprehensive audit log of all Stripe payment-related webhooks
CREATE TABLE IF NOT EXISTS public.stripe_payment_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Stripe Event Data
    stripe_event_id TEXT UNIQUE NOT NULL,
    stripe_payment_intent_id TEXT NOT NULL,
    event_type TEXT NOT NULL, -- 'payment_intent.succeeded', 'payment_intent.payment_failed', etc.

    -- Payment Details
    amount INTEGER NOT NULL, -- Amount in cents
    currency TEXT DEFAULT 'usd',
    status TEXT NOT NULL, -- 'succeeded', 'failed', 'processing'

    -- Customer & Booking References
    stripe_customer_id TEXT,
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Error Handling
    error_code TEXT,
    error_message TEXT,

    -- Metadata
    payment_method_type TEXT, -- 'card', 'bank_transfer', etc.
    metadata JSONB DEFAULT '{}'::jsonb,
    raw_event JSONB, -- Full Stripe event object for debugging

    -- Timestamps
    stripe_created_at TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stripe_payment_events_intent_id
    ON public.stripe_payment_events(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_stripe_payment_events_booking_id
    ON public.stripe_payment_events(booking_id);
CREATE INDEX IF NOT EXISTS idx_stripe_payment_events_user_id
    ON public.stripe_payment_events(user_id);
CREATE INDEX IF NOT EXISTS idx_stripe_payment_events_status
    ON public.stripe_payment_events(status);
CREATE INDEX IF NOT EXISTS idx_stripe_payment_events_created_at
    ON public.stripe_payment_events(created_at DESC);

-- ============================================================================
-- 2. STRIPE TRANSFERS TABLE
-- ============================================================================
-- Track platform → studio/instructor transfers (commission payments)
CREATE TABLE IF NOT EXISTS public.stripe_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Stripe Transfer Data
    stripe_transfer_id TEXT UNIQUE NOT NULL,
    stripe_destination_account TEXT NOT NULL, -- Connected account ID

    -- Transfer Details
    amount INTEGER NOT NULL, -- Amount in cents
    currency TEXT DEFAULT 'usd',
    description TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'paid', 'failed'

    -- Business References
    studio_id UUID, -- Reference to studio (if using studios table)
    booking_id UUID REFERENCES public.bookings(id) ON DELETE SET NULL,
    revenue_share_id UUID REFERENCES public.revenue_shares(id) ON DELETE SET NULL,

    -- Commission Calculation
    gross_amount INTEGER, -- Original booking amount
    platform_fee INTEGER, -- Platform commission (30%)
    studio_payout INTEGER, -- Amount transferred (70%)

    -- Error Handling
    failure_code TEXT,
    failure_message TEXT,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    raw_transfer JSONB, -- Full Stripe transfer object

    -- Timestamps
    stripe_created_at TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_destination
    ON public.stripe_transfers(stripe_destination_account);
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_studio_id
    ON public.stripe_transfers(studio_id);
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_booking_id
    ON public.stripe_transfers(booking_id);
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_status
    ON public.stripe_transfers(status);
CREATE INDEX IF NOT EXISTS idx_stripe_transfers_created_at
    ON public.stripe_transfers(created_at DESC);

-- ============================================================================
-- 3. STRIPE ACCOUNT STATUSES TABLE
-- ============================================================================
-- Track Stripe Connect account status updates for studios/instructors
CREATE TABLE IF NOT EXISTS public.stripe_account_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Stripe Account Data
    stripe_account_id TEXT UNIQUE NOT NULL,

    -- Account Capabilities
    charges_enabled BOOLEAN DEFAULT false,
    payouts_enabled BOOLEAN DEFAULT false,
    details_submitted BOOLEAN DEFAULT false,

    -- Requirements
    requirements_currently_due TEXT[] DEFAULT ARRAY[]::TEXT[],
    requirements_eventually_due TEXT[] DEFAULT ARRAY[]::TEXT[],
    requirements_past_due TEXT[] DEFAULT ARRAY[]::TEXT[],
    requirements_disabled_reason TEXT,

    -- Account Status
    account_type TEXT, -- 'standard', 'express', 'custom'
    is_active BOOLEAN DEFAULT true,
    deauthorized_at TIMESTAMPTZ,

    -- Business References
    studio_submission_id UUID REFERENCES public.studio_onboarding_submissions(id) ON DELETE CASCADE,

    -- Metadata
    country TEXT DEFAULT 'US',
    default_currency TEXT DEFAULT 'usd',
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_stripe_account_statuses_account_id
    ON public.stripe_account_statuses(stripe_account_id);
CREATE INDEX IF NOT EXISTS idx_stripe_account_statuses_submission_id
    ON public.stripe_account_statuses(studio_submission_id);
CREATE INDEX IF NOT EXISTS idx_stripe_account_statuses_active
    ON public.stripe_account_statuses(is_active);

-- ============================================================================
-- 4. UPDATE PAYOUT_REQUESTS TABLE
-- ============================================================================
-- Add Stripe payout tracking fields to existing payout_requests table
ALTER TABLE public.payout_requests
ADD COLUMN IF NOT EXISTS stripe_payout_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS stripe_transfer_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_arrival_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS stripe_status TEXT, -- 'pending', 'paid', 'failed'
ADD COLUMN IF NOT EXISTS stripe_failure_code TEXT,
ADD COLUMN IF NOT EXISTS stripe_failure_message TEXT,
ADD COLUMN IF NOT EXISTS stripe_metadata JSONB DEFAULT '{}'::jsonb;

-- Index for Stripe payout lookups
CREATE INDEX IF NOT EXISTS idx_payout_requests_stripe_payout_id
    ON public.payout_requests(stripe_payout_id)
    WHERE stripe_payout_id IS NOT NULL;

-- ============================================================================
-- 5. RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.stripe_payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_account_statuses ENABLE ROW LEVEL SECURITY;

-- Stripe Payment Events Policies
CREATE POLICY "Users can view their own payment events"
    ON public.stripe_payment_events
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to payment events"
    ON public.stripe_payment_events
    FOR ALL
    USING (auth.role() = 'service_role');

-- Stripe Transfers Policies
CREATE POLICY "Service role has full access to transfers"
    ON public.stripe_transfers
    FOR ALL
    USING (auth.role() = 'service_role');

-- Studios can view their transfers (simplified - adjust based on your studio auth)
CREATE POLICY "Studios can view their transfers"
    ON public.stripe_transfers
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.studio_onboarding_submissions s
        WHERE s.user_id = auth.uid()
        AND s.stripe_account_id = stripe_transfers.stripe_destination_account
    ));

-- Stripe Account Statuses Policies
CREATE POLICY "Service role has full access to account statuses"
    ON public.stripe_account_statuses
    FOR ALL
    USING (auth.role() = 'service_role');

-- Studios can view their own account status
CREATE POLICY "Studios can view their account status"
    ON public.stripe_account_statuses
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.studio_onboarding_submissions s
        WHERE s.user_id = auth.uid()
        AND s.id = stripe_account_statuses.studio_submission_id
    ));

-- ============================================================================
-- 6. HELPER FUNCTIONS
-- ============================================================================

-- Function to update account status from webhook
CREATE OR REPLACE FUNCTION public.upsert_stripe_account_status(
    p_stripe_account_id TEXT,
    p_charges_enabled BOOLEAN,
    p_payouts_enabled BOOLEAN,
    p_details_submitted BOOLEAN,
    p_requirements_due TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_disabled_reason TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_status_id UUID;
BEGIN
    INSERT INTO public.stripe_account_statuses (
        stripe_account_id,
        charges_enabled,
        payouts_enabled,
        details_submitted,
        requirements_currently_due,
        requirements_disabled_reason,
        updated_at
    ) VALUES (
        p_stripe_account_id,
        p_charges_enabled,
        p_payouts_enabled,
        p_details_submitted,
        p_requirements_due,
        p_disabled_reason,
        NOW()
    )
    ON CONFLICT (stripe_account_id) DO UPDATE SET
        charges_enabled = EXCLUDED.charges_enabled,
        payouts_enabled = EXCLUDED.payouts_enabled,
        details_submitted = EXCLUDED.details_submitted,
        requirements_currently_due = EXCLUDED.requirements_currently_due,
        requirements_disabled_reason = EXCLUDED.requirements_disabled_reason,
        updated_at = NOW()
    RETURNING id INTO v_status_id;

    RETURN v_status_id;
END;
$$;

-- Function to record payment event
CREATE OR REPLACE FUNCTION public.record_stripe_payment_event(
    p_stripe_event_id TEXT,
    p_payment_intent_id TEXT,
    p_event_type TEXT,
    p_amount INTEGER,
    p_currency TEXT,
    p_status TEXT,
    p_customer_id TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_error_code TEXT DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO public.stripe_payment_events (
        stripe_event_id,
        stripe_payment_intent_id,
        event_type,
        amount,
        currency,
        status,
        stripe_customer_id,
        user_id,
        error_code,
        error_message,
        stripe_created_at
    ) VALUES (
        p_stripe_event_id,
        p_payment_intent_id,
        p_event_type,
        p_amount,
        p_currency,
        p_status,
        p_customer_id,
        p_user_id,
        p_error_code,
        p_error_message,
        NOW()
    )
    ON CONFLICT (stripe_event_id) DO NOTHING -- Idempotency
    RETURNING id INTO v_event_id;

    RETURN v_event_id;
END;
$$;

-- Function to record transfer
CREATE OR REPLACE FUNCTION public.record_stripe_transfer(
    p_stripe_transfer_id TEXT,
    p_destination_account TEXT,
    p_amount INTEGER,
    p_currency TEXT,
    p_description TEXT DEFAULT NULL,
    p_studio_id UUID DEFAULT NULL,
    p_booking_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_transfer_id UUID;
BEGIN
    INSERT INTO public.stripe_transfers (
        stripe_transfer_id,
        stripe_destination_account,
        amount,
        currency,
        description,
        studio_id,
        booking_id,
        studio_payout,
        stripe_created_at
    ) VALUES (
        p_stripe_transfer_id,
        p_destination_account,
        p_amount,
        p_currency,
        p_description,
        p_studio_id,
        p_booking_id,
        p_amount, -- Full amount is studio payout (commission already deducted by Stripe)
        NOW()
    )
    ON CONFLICT (stripe_transfer_id) DO NOTHING -- Idempotency
    RETURNING id INTO v_transfer_id;

    RETURN v_transfer_id;
END;
$$;

-- Function to update payout status
CREATE OR REPLACE FUNCTION public.update_payout_status(
    p_stripe_payout_id TEXT,
    p_status TEXT,
    p_arrival_date TIMESTAMPTZ DEFAULT NULL,
    p_failure_code TEXT DEFAULT NULL,
    p_failure_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    UPDATE public.payout_requests
    SET
        stripe_status = p_status,
        stripe_arrival_date = p_arrival_date,
        stripe_failure_code = p_failure_code,
        stripe_failure_message = p_failure_message,
        updated_at = NOW()
    WHERE stripe_payout_id = p_stripe_payout_id;

    RETURN FOUND;
END;
$$;

-- ============================================================================
-- 7. COMMENTS
-- ============================================================================

COMMENT ON TABLE public.stripe_payment_events IS 'Audit log of all Stripe payment webhooks';
COMMENT ON TABLE public.stripe_transfers IS 'Platform-to-studio transfer tracking for commission payments';
COMMENT ON TABLE public.stripe_account_statuses IS 'Stripe Connect account status for studios/instructors';

COMMENT ON FUNCTION public.upsert_stripe_account_status IS 'Upsert Stripe account status from webhook events';
COMMENT ON FUNCTION public.record_stripe_payment_event IS 'Record payment event with idempotency';
COMMENT ON FUNCTION public.record_stripe_transfer IS 'Record transfer with idempotency';
COMMENT ON FUNCTION public.update_payout_status IS 'Update payout request status from webhook';
