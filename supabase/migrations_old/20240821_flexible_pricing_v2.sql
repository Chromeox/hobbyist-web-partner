-- Flexible Pricing System V2 Migration
-- Implements tiered credit system, insurance program, and retention features

-- ============================================
-- CREDIT PACKAGES (REVISED)
-- ============================================

-- Drop existing credit_packs if exists and recreate with new structure
DROP TABLE IF EXISTS credit_packs CASCADE;

CREATE TABLE credit_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    credits INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    price_per_credit DECIMAL(10,2) GENERATED ALWAYS AS (price / credits) STORED,
    savings_percentage INTEGER,
    is_popular BOOLEAN DEFAULT false,
    description TEXT,
    stripe_product_id TEXT,
    stripe_price_id TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE credit_packs ENABLE ROW LEVEL SECURITY;

-- Public read access for credit packages
CREATE POLICY "Credit packages are viewable by everyone" ON credit_packs
    FOR SELECT USING (active = true);

-- Insert Vancouver market-based packages
INSERT INTO credit_packs (name, credits, price, savings_percentage, is_popular, description) VALUES
    ('Starter', 10, 25.00, NULL, false, 'Perfect for trying out'),
    ('Explorer', 25, 55.00, 12, false, '1-2 classes per week'),
    ('Regular', 50, 95.00, 24, true, 'Most popular choice'),
    ('Enthusiast', 100, 170.00, 32, false, '4-5 classes per week'),
    ('Power User', 200, 300.00, 40, false, 'Best value for daily users');

-- ============================================
-- SUBSCRIPTION PLANS
-- ============================================

DROP TABLE IF EXISTS subscription_plans CASCADE;

CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL,
    monthly_credits INTEGER NOT NULL,
    rollover_limit INTEGER NOT NULL,
    perks JSONB DEFAULT '[]'::jsonb,
    is_popular BOOLEAN DEFAULT false,
    stripe_product_id TEXT,
    stripe_price_id TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Subscription plans are viewable by everyone" ON subscription_plans
    FOR SELECT USING (active = true);

-- Insert subscription tiers
INSERT INTO subscription_plans (name, monthly_price, monthly_credits, rollover_limit, perks, is_popular) VALUES
    ('Casual', 39.00, 20, 5, '["Basic access"]', false),
    ('Active', 69.00, 40, 10, '["Priority booking", "1 guest pass/month"]', true),
    ('Premium', 119.00, 80, 20, '["All perks", "Equipment rental", "Exclusive classes"]', false),
    ('Elite', 179.00, 150, 30, '["VIP treatment", "Personal trainer consultation", "3 guest passes"]', false);

-- ============================================
-- CLASS TIERS (CREDIT REQUIREMENTS)
-- ============================================

CREATE TABLE class_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_name TEXT NOT NULL UNIQUE,
    base_credits DECIMAL(3,1) NOT NULL,
    min_price DECIMAL(10,2) NOT NULL,
    max_price DECIMAL(10,2) NOT NULL,
    studio_commission_rate DECIMAL(3,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE class_tiers ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Class tiers are viewable by everyone" ON class_tiers
    FOR SELECT USING (true);

-- Insert class tier definitions
INSERT INTO class_tiers (tier_name, base_credits, min_price, max_price, studio_commission_rate, description) VALUES
    ('community', 0.5, 10.00, 15.00, 0.75, 'Community center and budget classes'),
    ('standard', 1.0, 20.00, 30.00, 0.70, 'Regular studio classes'),
    ('premium', 2.0, 35.00, 50.00, 0.72, 'Specialized and workshop classes'),
    ('exclusive', 3.0, 60.00, 80.00, 0.75, 'High-end and private group classes'),
    ('masterclass', 4.0, 85.00, 105.00, 0.75, 'Celebrity instructor and luxury experiences');

-- Add tier to classes table
ALTER TABLE classes ADD COLUMN IF NOT EXISTS tier_name TEXT DEFAULT 'standard';
ALTER TABLE classes ADD COLUMN IF NOT EXISTS dynamic_credits DECIMAL(3,1);

-- ============================================
-- CREDIT INSURANCE PROGRAM
-- ============================================

CREATE TABLE credit_insurance_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_name TEXT NOT NULL UNIQUE,
    monthly_price DECIMAL(10,2) NOT NULL,
    features JSONB NOT NULL,
    rollover_rules JSONB NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE credit_insurance_plans ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Insurance plans are viewable by everyone" ON credit_insurance_plans
    FOR SELECT USING (active = true);

-- Insert insurance tiers
INSERT INTO credit_insurance_plans (plan_name, monthly_price, features, rollover_rules) VALUES
    ('basic', 3.00, 
     '["Credits rollover 1 extra month", "Emergency pause (once/year)"]',
     '{"months": 1, "emergency_pause": true}'),
    ('plus', 5.00, 
     '["Unlimited rollover", "Gift unused credits", "Pause anytime", "Credit refund (once/year)"]',
     '{"unlimited": true, "gifting": true, "pause_anytime": true, "annual_refund": true}'),
    ('premium', 8.00, 
     '["Everything in Plus", "Convert to gift cards", "Priority booking", "Exclusive sessions"]',
     '{"unlimited": true, "gifting": true, "gift_cards": true, "priority": true, "exclusive_access": true}');

-- User insurance subscriptions
CREATE TABLE user_insurance_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES credit_insurance_plans(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
    stripe_subscription_id TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    paused_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, status)
);

-- Enable RLS
ALTER TABLE user_insurance_subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can view their own insurance
CREATE POLICY "Users can view own insurance" ON user_insurance_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- ENHANCED USER CREDITS TABLE
-- ============================================

-- Add new columns to user_credits
ALTER TABLE user_credits 
    ADD COLUMN IF NOT EXISTS rollover_credits INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS insurance_plan_id UUID REFERENCES credit_insurance_plans(id),
    ADD COLUMN IF NOT EXISTS membership_started_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS loyalty_tier TEXT DEFAULT 'bronze';

-- ============================================
-- CREDIT ROLLOVER TRACKING
-- ============================================

CREATE TABLE credit_rollover_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    credits_rolled INTEGER NOT NULL,
    from_month DATE NOT NULL,
    to_month DATE NOT NULL,
    rollover_type TEXT NOT NULL, -- 'loyalty', 'insurance', 'promotion'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE credit_rollover_history ENABLE ROW LEVEL SECURITY;

-- Users can view their own rollover history
CREATE POLICY "Users can view own rollover history" ON credit_rollover_history
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- DYNAMIC PRICING RULES
-- ============================================

CREATE TABLE dynamic_pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL,
    rule_type TEXT NOT NULL CHECK (rule_type IN ('time_based', 'demand_based', 'seasonal')),
    conditions JSONB NOT NULL,
    credit_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE dynamic_pricing_rules ENABLE ROW LEVEL SECURITY;

-- Public read for active rules
CREATE POLICY "Pricing rules are viewable by everyone" ON dynamic_pricing_rules
    FOR SELECT USING (active = true);

-- Insert time-based pricing rules
INSERT INTO dynamic_pricing_rules (rule_name, rule_type, conditions, credit_multiplier, priority) VALUES
    ('Weekday Peak Morning', 'time_based', 
     '{"days": [1,2,3,4,5], "hours": [6,7,8], "months": []}', 
     1.25, 10),
    ('Weekday Peak Evening', 'time_based', 
     '{"days": [1,2,3,4,5], "hours": [17,18,19], "months": []}', 
     1.25, 10),
    ('Weekday Off-Peak', 'time_based', 
     '{"days": [1,2,3,4,5], "hours": [11,12,13,14], "months": []}', 
     0.75, 5),
    ('Weekend Morning Premium', 'time_based', 
     '{"days": [0,6], "hours": [9,10,11], "months": []}', 
     1.10, 7),
    ('Winter Season Discount', 'seasonal', 
     '{"days": [], "hours": [], "months": [11,12,1,2]}', 
     0.80, 15);

-- ============================================
-- SQUAD FEATURES
-- ============================================

CREATE TABLE squads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_name TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    max_members INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE squad_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('leader', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(squad_id, user_id)
);

CREATE TABLE squad_credits_pool (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    contributed_by UUID NOT NULL REFERENCES auth.users(id),
    credits INTEGER NOT NULL,
    contributed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on squad tables
ALTER TABLE squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_credits_pool ENABLE ROW LEVEL SECURITY;

-- Squad policies
CREATE POLICY "Squad members can view their squads" ON squads
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM squad_members 
            WHERE squad_members.squad_id = squads.id 
            AND squad_members.user_id = auth.uid()
        )
    );

-- ============================================
-- RETENTION METRICS
-- ============================================

CREATE TABLE retention_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    days_since_signup INTEGER,
    classes_attended INTEGER DEFAULT 0,
    credits_used INTEGER DEFAULT 0,
    credits_purchased INTEGER DEFAULT 0,
    friends_referred INTEGER DEFAULT 0,
    squad_activities INTEGER DEFAULT 0,
    app_opens INTEGER DEFAULT 0,
    risk_score INTEGER DEFAULT 0,
    churn_probability DECIMAL(3,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, metric_date)
);

-- Enable RLS
ALTER TABLE retention_metrics ENABLE ROW LEVEL SECURITY;

-- Only admins can view retention metrics
CREATE POLICY "Admins can view retention metrics" ON retention_metrics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_roles.user_id = auth.uid() 
            AND user_roles.role = 'admin'
        )
    );

-- ============================================
-- PROMOTIONAL CAMPAIGNS
-- ============================================

CREATE TABLE promotional_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_name TEXT NOT NULL,
    campaign_type TEXT NOT NULL CHECK (campaign_type IN ('discount', 'bonus_credits', 'free_class', 'referral')),
    discount_percentage INTEGER,
    bonus_credits INTEGER,
    promo_code TEXT UNIQUE,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    conditions JSONB,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE promotional_campaigns ENABLE ROW LEVEL SECURITY;

-- Public can view active campaigns
CREATE POLICY "Active campaigns are public" ON promotional_campaigns
    FOR SELECT USING (active = true AND valid_from <= NOW() AND valid_until >= NOW());

-- Insert launch promotions
INSERT INTO promotional_campaigns (campaign_name, campaign_type, discount_percentage, promo_code, valid_from, valid_until, max_uses) VALUES
    ('First 100 Users', 'discount', 50, 'EARLY50', NOW(), NOW() + INTERVAL '30 days', 100),
    ('Friend Referral', 'bonus_credits', NULL, NULL, NOW(), NOW() + INTERVAL '365 days', NULL),
    ('Winter Warrior', 'bonus_credits', NULL, 'WINTER20', '2024-11-01', '2025-02-28', NULL);

-- ============================================
-- FUNCTIONS FOR CREDIT CALCULATIONS
-- ============================================

-- Function to calculate credits needed for a class
CREATE OR REPLACE FUNCTION calculate_class_credits(
    p_class_id UUID,
    p_booking_time TIMESTAMPTZ DEFAULT NOW()
) RETURNS DECIMAL(3,1) AS $$
DECLARE
    v_base_credits DECIMAL(3,1);
    v_final_credits DECIMAL(3,1);
    v_multiplier DECIMAL(3,2) DEFAULT 1.0;
    r_rule RECORD;
BEGIN
    -- Get base credits from class tier
    SELECT ct.base_credits INTO v_base_credits
    FROM classes c
    JOIN class_tiers ct ON c.tier_name = ct.tier_name
    WHERE c.id = p_class_id;
    
    -- Apply dynamic pricing rules
    FOR r_rule IN 
        SELECT credit_multiplier, conditions
        FROM dynamic_pricing_rules
        WHERE active = true
        ORDER BY priority DESC
    LOOP
        -- Check if rule applies based on conditions
        -- This is simplified - in production, implement full JSON condition checking
        v_multiplier := v_multiplier * r_rule.credit_multiplier;
    END LOOP;
    
    v_final_credits := v_base_credits * v_multiplier;
    
    RETURN v_final_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate rollover credits
CREATE OR REPLACE FUNCTION calculate_rollover_credits(
    p_user_id UUID,
    p_unused_credits INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_membership_months INTEGER;
    v_insurance_plan TEXT;
    v_rollover_amount INTEGER;
BEGIN
    -- Get membership duration
    SELECT 
        EXTRACT(MONTH FROM AGE(NOW(), membership_started_at)),
        cip.plan_name
    INTO v_membership_months, v_insurance_plan
    FROM user_credits uc
    LEFT JOIN credit_insurance_plans cip ON uc.insurance_plan_id = cip.id
    WHERE uc.user_id = p_user_id;
    
    -- Calculate based on insurance or loyalty
    IF v_insurance_plan IN ('plus', 'premium') THEN
        v_rollover_amount := p_unused_credits; -- Unlimited rollover
    ELSIF v_insurance_plan = 'basic' THEN
        v_rollover_amount := p_unused_credits; -- 1 month rollover
    ELSE
        -- Loyalty-based rollover
        IF v_membership_months < 3 THEN
            v_rollover_amount := p_unused_credits * 0.25;
        ELSIF v_membership_months < 6 THEN
            v_rollover_amount := p_unused_credits * 0.50;
        ELSIF v_membership_months < 12 THEN
            v_rollover_amount := p_unused_credits * 0.75;
        ELSE
            v_rollover_amount := p_unused_credits;
        END IF;
    END IF;
    
    RETURN v_rollover_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX idx_credit_rollover_user_month ON credit_rollover_history(user_id, from_month);
CREATE INDEX idx_squad_members_user ON squad_members(user_id);
CREATE INDEX idx_retention_metrics_user_date ON retention_metrics(user_id, metric_date);
CREATE INDEX idx_promotional_campaigns_active ON promotional_campaigns(active, valid_from, valid_until);
CREATE INDEX idx_classes_tier ON classes(tier_name);

-- ============================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_credit_packs_updated_at BEFORE UPDATE ON credit_packs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_insurance_updated_at BEFORE UPDATE ON user_insurance_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE credit_packs IS 'Vancouver market-based credit packages with flexible pricing';
COMMENT ON TABLE subscription_plans IS 'Monthly subscription tiers with credit allocations and perks';
COMMENT ON TABLE class_tiers IS 'Class categorization for credit requirements based on price ranges';
COMMENT ON TABLE credit_insurance_plans IS 'Optional insurance to prevent credit expiration anxiety';
COMMENT ON TABLE squads IS 'Social accountability groups for improved retention';
COMMENT ON TABLE retention_metrics IS 'User engagement tracking for churn prediction';
COMMENT ON TABLE promotional_campaigns IS 'Time-limited promotions and referral programs';

-- Migration complete!