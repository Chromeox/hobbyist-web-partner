-- Migration: Revenue Sharing and Payout System
-- Description: Creates tables for managing instructor payouts, commission structures, and financial reporting
-- Version: 07
-- Date: 2024-01-20

-- =====================================================
-- COMMISSION STRUCTURES
-- =====================================================

-- Commission structure templates
CREATE TABLE IF NOT EXISTS commission_structures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('fixed', 'tiered', 'dynamic', 'custom')),
    base_rate DECIMAL(5,2) NOT NULL CHECK (base_rate >= 0 AND base_rate <= 100),
    is_active BOOLEAN DEFAULT true,
    effective_date DATE NOT NULL,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Commission tiers for tiered structures
CREATE TABLE IF NOT EXISTS commission_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id UUID NOT NULL REFERENCES commission_structures(id) ON DELETE CASCADE,
    min_amount DECIMAL(10,2) NOT NULL CHECK (min_amount >= 0),
    max_amount DECIMAL(10,2) CHECK (max_amount > min_amount),
    rate DECIMAL(5,2) NOT NULL CHECK (rate >= 0 AND rate <= 100),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Commission conditions for dynamic structures
CREATE TABLE IF NOT EXISTS commission_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    structure_id UUID NOT NULL REFERENCES commission_structures(id) ON DELETE CASCADE,
    condition_type VARCHAR(50) NOT NULL CHECK (condition_type IN ('student_count', 'class_count', 'revenue', 'retention')),
    threshold DECIMAL(10,2) NOT NULL,
    adjustment DECIMAL(5,2) NOT NULL,
    operator VARCHAR(10) NOT NULL CHECK (operator IN ('add', 'multiply')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Venue-specific commission assignments
CREATE TABLE IF NOT EXISTS venue_commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    structure_id UUID NOT NULL REFERENCES commission_structures(id),
    override_rate DECIMAL(5,2) CHECK (override_rate >= 0 AND override_rate <= 100),
    effective_date DATE NOT NULL,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(venue_id, effective_date)
);

-- =====================================================
-- PAYOUT SCHEDULES
-- =====================================================

-- Payout schedule configurations
CREATE TABLE IF NOT EXISTS payout_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('weekly', 'bi-weekly', 'monthly', 'custom')),
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    day_of_month INTEGER CHECK (day_of_month >= 1 AND day_of_month <= 31),
    custom_days INTEGER[],
    minimum_payout DECIMAL(10,2) DEFAULT 100.00,
    maximum_payout DECIMAL(10,2),
    processing_time INTEGER DEFAULT 2, -- days
    auto_approve BOOLEAN DEFAULT true,
    notify_before_payout BOOLEAN DEFAULT true,
    notification_days INTEGER DEFAULT 3,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('stripe', 'bank_transfer', 'paypal', 'check')),
    is_active BOOLEAN DEFAULT true,
    next_payout_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Association between schedules and venues
CREATE TABLE IF NOT EXISTS schedule_venues (
    schedule_id UUID NOT NULL REFERENCES payout_schedules(id) ON DELETE CASCADE,
    venue_id UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    PRIMARY KEY (schedule_id, venue_id)
);

-- =====================================================
-- PAYOUT HISTORY
-- =====================================================

-- Individual payouts to instructors
CREATE TABLE IF NOT EXISTS payout_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES users(id),
    schedule_id UUID REFERENCES payout_schedules(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    gross_amount DECIMAL(10,2) NOT NULL CHECK (gross_amount >= 0),
    commission_amount DECIMAL(10,2) NOT NULL CHECK (commission_amount >= 0),
    platform_fees DECIMAL(10,2) DEFAULT 0 CHECK (platform_fees >= 0),
    processing_fees DECIMAL(10,2) DEFAULT 0 CHECK (processing_fees >= 0),
    net_amount DECIMAL(10,2) NOT NULL CHECK (net_amount >= 0),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'scheduled', 'processing', 'completed', 'failed', 'cancelled')),
    payment_method VARCHAR(50) NOT NULL,
    transaction_id VARCHAR(255),
    scheduled_date DATE,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    failure_reason TEXT,
    class_count INTEGER DEFAULT 0,
    student_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Payout batches for grouped processing
CREATE TABLE IF NOT EXISTS payout_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(50) UNIQUE NOT NULL,
    schedule_id UUID REFERENCES payout_schedules(id),
    total_amount DECIMAL(12,2) NOT NULL,
    instructor_count INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending_approval', 'approved', 'processing', 'completed', 'partially_failed', 'failed')),
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- Link payouts to batches
CREATE TABLE IF NOT EXISTS batch_payouts (
    batch_id UUID NOT NULL REFERENCES payout_batches(id) ON DELETE CASCADE,
    payout_id UUID NOT NULL REFERENCES payout_history(id) ON DELETE CASCADE,
    PRIMARY KEY (batch_id, payout_id)
);

-- =====================================================
-- FINANCIAL REPORTS
-- =====================================================

-- Generated financial reports and tax documents
CREATE TABLE IF NOT EXISTS financial_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('1099', 'w9', 'earnings_statement', 'tax_summary', 'commission_report', 'custom')),
    year INTEGER NOT NULL,
    quarter INTEGER CHECK (quarter >= 1 AND quarter <= 4),
    month INTEGER CHECK (month >= 1 AND month <= 12),
    instructor_id UUID REFERENCES users(id),
    venue_id UUID REFERENCES venues(id),
    status VARCHAR(50) NOT NULL CHECK (status IN ('draft', 'generated', 'sent', 'acknowledged')),
    document_url TEXT,
    generated_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    total_amount DECIMAL(12,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Tax document collection tracking
CREATE TABLE IF NOT EXISTS tax_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES users(id),
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('w9', 'w8ben', 'tax_id', 'ein')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'submitted', 'verified', 'expired', 'rejected')),
    document_url TEXT,
    submitted_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id),
    expires_at DATE,
    rejection_reason TEXT,
    tax_id_number VARCHAR(50), -- Encrypted in production
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Report templates for automated generation
CREATE TABLE IF NOT EXISTS report_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    report_type VARCHAR(50) NOT NULL,
    template_body TEXT,
    schedule_frequency VARCHAR(50) CHECK (schedule_frequency IN ('monthly', 'quarterly', 'annually', 'on_demand')),
    recipients TEXT[], -- Email addresses
    is_active BOOLEAN DEFAULT true,
    last_generated_at TIMESTAMPTZ,
    next_generation_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- =====================================================
-- PAYMENT METHODS
-- =====================================================

-- Instructor payment method preferences
CREATE TABLE IF NOT EXISTS instructor_payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES users(id),
    method_type VARCHAR(50) NOT NULL CHECK (method_type IN ('stripe', 'bank_transfer', 'paypal', 'check')),
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    account_details JSONB, -- Encrypted in production
    verified_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(instructor_id, method_type)
);

-- =====================================================
-- EARNINGS TRACKING
-- =====================================================

-- Detailed earnings breakdown per class/booking
CREATE TABLE IF NOT EXISTS earnings_breakdown (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    instructor_id UUID NOT NULL REFERENCES users(id),
    venue_id UUID NOT NULL REFERENCES venues(id),
    class_date DATE NOT NULL,
    gross_amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    platform_fee DECIMAL(10,2) DEFAULT 0,
    processing_fee DECIMAL(10,2) DEFAULT 0,
    net_amount DECIMAL(10,2) NOT NULL,
    payout_id UUID REFERENCES payout_history(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_commission_structures_active ON commission_structures(is_active, effective_date);
CREATE INDEX idx_venue_commissions_venue ON venue_commissions(venue_id, effective_date);
CREATE INDEX idx_payout_history_instructor ON payout_history(instructor_id, status, period_start);
CREATE INDEX idx_payout_history_status ON payout_history(status, scheduled_date);
CREATE INDEX idx_financial_reports_instructor ON financial_reports(instructor_id, year, report_type);
CREATE INDEX idx_tax_documents_instructor ON tax_documents(instructor_id, status);
CREATE INDEX idx_earnings_breakdown_instructor ON earnings_breakdown(instructor_id, class_date);
CREATE INDEX idx_earnings_breakdown_payout ON earnings_breakdown(payout_id);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE commission_structures ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE earnings_breakdown ENABLE ROW LEVEL SECURITY;

-- Instructors can view their own payout history
CREATE POLICY "Instructors can view own payouts" ON payout_history
    FOR SELECT USING (auth.uid() = instructor_id);

-- Instructors can view their own financial reports
CREATE POLICY "Instructors can view own reports" ON financial_reports
    FOR SELECT USING (auth.uid() = instructor_id);

-- Instructors can manage their own payment methods
CREATE POLICY "Instructors can manage own payment methods" ON instructor_payment_methods
    FOR ALL USING (auth.uid() = instructor_id);

-- Instructors can view their own tax documents
CREATE POLICY "Instructors can view own tax documents" ON tax_documents
    FOR SELECT USING (auth.uid() = instructor_id);

-- Instructors can view their own earnings breakdown
CREATE POLICY "Instructors can view own earnings" ON earnings_breakdown
    FOR SELECT USING (auth.uid() = instructor_id);

-- Admins have full access (implement admin check function)
CREATE POLICY "Admins have full access to commission structures" ON commission_structures
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update next payout date when schedule changes
CREATE OR REPLACE FUNCTION update_next_payout_date()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate next payout date based on frequency
    IF NEW.frequency = 'weekly' THEN
        NEW.next_payout_date := CURRENT_DATE + INTERVAL '1 week';
    ELSIF NEW.frequency = 'bi-weekly' THEN
        NEW.next_payout_date := CURRENT_DATE + INTERVAL '2 weeks';
    ELSIF NEW.frequency = 'monthly' THEN
        NEW.next_payout_date := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' + INTERVAL '1 day' * (COALESCE(NEW.day_of_month, 1) - 1);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_next_payout_date
    BEFORE INSERT OR UPDATE OF frequency, day_of_week, day_of_month ON payout_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_next_payout_date();

-- Calculate net amount when payout is created
CREATE OR REPLACE FUNCTION calculate_payout_net_amount()
RETURNS TRIGGER AS $$
BEGIN
    NEW.net_amount := NEW.gross_amount - NEW.commission_amount - COALESCE(NEW.platform_fees, 0) - COALESCE(NEW.processing_fees, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_payout_net
    BEFORE INSERT OR UPDATE OF gross_amount, commission_amount, platform_fees, processing_fees ON payout_history
    FOR EACH ROW
    EXECUTE FUNCTION calculate_payout_net_amount();

-- Update timestamps
CREATE TRIGGER update_commission_structures_updated_at BEFORE UPDATE ON commission_structures
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_venue_commissions_updated_at BEFORE UPDATE ON venue_commissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payout_schedules_updated_at BEFORE UPDATE ON payout_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payout_history_updated_at BEFORE UPDATE ON payout_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_reports_updated_at BEFORE UPDATE ON financial_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tax_documents_updated_at BEFORE UPDATE ON tax_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_templates_updated_at BEFORE UPDATE ON report_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instructor_payment_methods_updated_at BEFORE UPDATE ON instructor_payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SAMPLE DATA (Remove in production)
-- =====================================================

-- Insert default commission structure
INSERT INTO commission_structures (name, type, base_rate, effective_date)
VALUES ('Standard 80/20', 'fixed', 20.00, CURRENT_DATE)
ON CONFLICT DO NOTHING;

-- Insert default payout schedule
INSERT INTO payout_schedules (name, frequency, day_of_month, payment_method)
VALUES ('Monthly Instructor Payout', 'monthly', 1, 'stripe')
ON CONFLICT DO NOTHING;