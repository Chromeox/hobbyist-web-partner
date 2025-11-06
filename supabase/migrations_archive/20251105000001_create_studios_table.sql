-- Migration: Create Studios Table
-- This table was missing but referenced by many other tables
-- Date: 2024-11-05

-- ============================================
-- CREATE STUDIOS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS studios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    business_name TEXT,
    slug TEXT UNIQUE,
    description TEXT,
    
    -- Contact Information
    email TEXT,
    phone TEXT,
    website TEXT,
    
    -- Address
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    postal_code TEXT,
    country TEXT DEFAULT 'US',
    
    -- Business Details
    business_registration_number TEXT,
    tax_id TEXT,
    business_type TEXT, -- LLC, Corporation, etc.
    
    -- Platform Integration
    stripe_account_id TEXT, -- Stripe Connect account
    commission_rate DECIMAL(5,4) DEFAULT 0.15, -- Platform commission (15%)
    
    -- Settings
    timezone TEXT DEFAULT 'America/Vancouver',
    currency TEXT DEFAULT 'CAD',
    booking_settings JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}',
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'closed')),
    is_verified BOOLEAN DEFAULT false,
    verification_documents JSONB DEFAULT '[]',
    
    -- Analytics
    total_classes INTEGER DEFAULT 0,
    total_students INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2),
    total_revenue DECIMAL(12,2) DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    verified_at TIMESTAMPTZ,
    
    -- Search and Performance
    search_vector tsvector
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_studios_slug ON studios(slug);
CREATE INDEX IF NOT EXISTS idx_studios_status ON studios(status);
CREATE INDEX IF NOT EXISTS idx_studios_city ON studios(city);
CREATE INDEX IF NOT EXISTS idx_studios_created_at ON studios(created_at);
CREATE INDEX IF NOT EXISTS idx_studios_stripe_account_id ON studios(stripe_account_id);

-- Search index
CREATE INDEX IF NOT EXISTS idx_studios_search ON studios USING GIN(search_vector);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;

-- Studios are publicly viewable (for marketplace)
CREATE POLICY "Public can view active studios" ON studios
    FOR SELECT USING (status = 'active');

-- Only studio staff can view/edit their studio
CREATE POLICY "Studio staff can manage their studio" ON studios
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM studio_staff 
            WHERE user_id = auth.uid() 
            AND studio_id = studios.id
        )
    );

-- Platform admins can manage all studios
CREATE POLICY "Admins can manage all studios" ON studios
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- ============================================
-- TRIGGERS
-- ============================================

-- Update search vector on changes
CREATE OR REPLACE FUNCTION update_studio_search_vector()
RETURNS trigger AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.city, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.business_name, '')), 'D');
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER studios_search_vector_update
    BEFORE INSERT OR UPDATE ON studios
    FOR EACH ROW EXECUTE FUNCTION update_studio_search_vector();

-- ============================================
-- GRANTS
-- ============================================

GRANT ALL ON studios TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'studios') THEN
        RAISE EXCEPTION 'Studios table was not created successfully';
    END IF;
    
    RAISE NOTICE 'Studios table created successfully';
END $$;