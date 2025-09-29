-- Missing Revenue Sharing and Payout Tables
-- Completing migration 07

-- Revenue shares tracking
CREATE TABLE IF NOT EXISTS public.revenue_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    instructor_id UUID REFERENCES public.instructors(id),
    studio_id UUID REFERENCES public.studios(id),
    
    -- Financial details
    total_amount DECIMAL(10, 2) NOT NULL,
    instructor_share DECIMAL(10, 2),
    studio_share DECIMAL(10, 2),
    platform_fee DECIMAL(10, 2),
    
    -- Share percentages
    instructor_percentage DECIMAL(5, 2),
    studio_percentage DECIMAL(5, 2),
    platform_percentage DECIMAL(5, 2) DEFAULT 15.00,
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'pending',
    processed_at TIMESTAMPTZ,
    payout_request_id UUID,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT check_shares CHECK (
        COALESCE(instructor_share, 0) + 
        COALESCE(studio_share, 0) + 
        COALESCE(platform_fee, 0) = total_amount
    )
);

-- Payout requests from instructors/studios
CREATE TABLE IF NOT EXISTS public.payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES auth.users(id),
    requester_type VARCHAR(20) NOT NULL CHECK (requester_type IN ('instructor', 'studio')),
    
    -- Payout details
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CAD',
    payout_method VARCHAR(50) NOT NULL,
    payout_details JSONB,
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'pending',
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    transaction_id VARCHAR(255),
    
    -- Notes and metadata
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Batch payouts for efficiency
CREATE TABLE IF NOT EXISTS public.payout_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Batch details
    total_amount DECIMAL(10, 2) NOT NULL,
    total_requests INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'CAD',
    
    -- Processing details
    status VARCHAR(50) DEFAULT 'created',
    processor VARCHAR(50), -- stripe, paypal, bank_transfer
    processor_batch_id VARCHAR(255),
    
    -- Timing
    scheduled_for TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Results
    successful_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    error_details JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Link payout requests to batches
ALTER TABLE public.payout_requests 
    ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES public.payout_batches(id);

-- Revenue analytics view
CREATE OR REPLACE VIEW public.revenue_analytics AS
SELECT
    DATE_TRUNC('month', rs.created_at) AS month,
    rs.studio_id,
    rs.instructor_id,
    COUNT(DISTINCT rs.booking_id) AS total_bookings,
    SUM(rs.total_amount) AS gross_revenue,
    SUM(rs.instructor_share) AS instructor_earnings,
    SUM(rs.studio_share) AS studio_earnings,
    SUM(rs.platform_fee) AS platform_revenue,
    AVG(rs.instructor_percentage) AS avg_instructor_percentage,
    AVG(rs.studio_percentage) AS avg_studio_percentage
FROM public.revenue_shares rs
WHERE rs.status = 'processed'
GROUP BY DATE_TRUNC('month', rs.created_at), rs.studio_id, rs.instructor_id;

-- Commission overrides for special deals
CREATE TABLE IF NOT EXISTS public.commission_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Target (instructor or studio specific)
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('instructor', 'studio')),
    target_id UUID NOT NULL,
    
    -- Override details
    commission_percentage DECIMAL(5, 2) NOT NULL,
    reason TEXT,
    
    -- Validity period
    valid_from DATE NOT NULL,
    valid_until DATE,
    is_active BOOLEAN DEFAULT true,
    
    -- Approval tracking
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_active_override UNIQUE (target_type, target_id, is_active)
);

-- Enable RLS on all tables
ALTER TABLE public.revenue_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_overrides ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Revenue shares: viewable by involved parties (simplified due to missing columns)
CREATE POLICY "View own revenue shares" ON public.revenue_shares
    FOR SELECT USING (
        auth.uid() IN (
            SELECT b.user_id FROM public.bookings b WHERE b.id = revenue_shares.booking_id
            -- Note: instructor and studio ownership validation would require user relationship tables
        )
    );

-- Payout requests: users can manage their own
CREATE POLICY "Manage own payout requests" ON public.payout_requests
    FOR ALL USING (auth.uid() = requester_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_revenue_shares_booking ON public.revenue_shares(booking_id);
CREATE INDEX IF NOT EXISTS idx_revenue_shares_instructor ON public.revenue_shares(instructor_id);
CREATE INDEX IF NOT EXISTS idx_revenue_shares_studio ON public.revenue_shares(studio_id);
CREATE INDEX IF NOT EXISTS idx_revenue_shares_status ON public.revenue_shares(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_requester ON public.payout_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON public.payout_requests(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_batch ON public.payout_requests(batch_id);
CREATE INDEX IF NOT EXISTS idx_commission_overrides_target ON public.commission_overrides(target_type, target_id);

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;