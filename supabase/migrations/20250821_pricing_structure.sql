-- Migration: Optimal Pricing Structure Implementation
-- Description: Implements credit packages, subscriptions, and dynamic pricing

-- ============================================
-- CREDIT PACKAGES TABLE
-- ============================================

-- Drop existing credit_packs table if it exists
DROP TABLE IF EXISTS credit_packs CASCADE;

-- Create new optimized credit packages
CREATE TABLE credit_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    credits INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    price_per_credit DECIMAL(10,2) GENERATED ALWAYS AS (price / credits) STORED,
    savings_percentage INTEGER DEFAULT 0,
    is_popular BOOLEAN DEFAULT FALSE,
    is_best_value BOOLEAN DEFAULT FALSE,
    description TEXT,
    badge_text TEXT,
    sort_order INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    stripe_price_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert optimized credit packages
INSERT INTO credit_packages (name, display_name, credits, price, savings_percentage, is_popular, is_best_value, description, badge_text, sort_order) VALUES
('trial', 'Trial Package', 5, 19.00, 0, FALSE, FALSE, 'Perfect for trying out classes', NULL, 1),
('casual', 'Casual Package', 15, 49.00, 14, FALSE, FALSE, 'Great for weekly classes', NULL, 2),
('regular', 'Regular Package', 30, 89.00, 22, TRUE, FALSE, 'Our most popular choice', 'MOST POPULAR', 3),
('power', 'Power Package', 60, 159.00, 30, FALSE, TRUE, 'Best value for regular attendees', 'BEST VALUE', 4),
('studio', 'Studio Package', 100, 239.00, 37, FALSE, FALSE, 'Perfect for groups and businesses', 'BULK DISCOUNT', 5);

-- ============================================
-- SUBSCRIPTION PLANS TABLE
-- ============================================

CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL,
    monthly_credits INTEGER NOT NULL,
    rollover_limit INTEGER DEFAULT 0,
    additional_credit_discount INTEGER DEFAULT 0, -- Percentage discount on buying more credits
    early_booking_hours INTEGER DEFAULT 0, -- Hours of early access to book classes
    guest_passes_per_month INTEGER DEFAULT 0,
    perks JSONB DEFAULT '[]'::jsonb,
    stripe_price_id TEXT,
    stripe_product_id TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert subscription plans
INSERT INTO subscription_plans (
    name, display_name, monthly_price, monthly_credits, 
    rollover_limit, additional_credit_discount, early_booking_hours, 
    guest_passes_per_month, perks, sort_order
) VALUES
(
    'basic',
    'Basic',
    49.00,
    15,
    0,
    5,
    0,
    0,
    '["Cancel anytime", "Mobile app access"]'::jsonb,
    1
),
(
    'plus',
    'Plus',
    79.00,
    25,
    5,
    10,
    24,
    1,
    '["Priority booking", "Guest passes", "Class recordings", "Cancel anytime"]'::jsonb,
    2
),
(
    'premium',
    'Premium',
    149.00,
    50,
    10,
    15,
    48,
    2,
    '["Priority booking", "Guest passes", "Free equipment", "Exclusive sessions", "Class recordings"]'::jsonb,
    3
),
(
    'unlimited',
    'Unlimited',
    199.00,
    999, -- Effectively unlimited
    0,
    20,
    48,
    3,
    '["Unlimited classes", "All premium perks", "Personal trainer consultation", "Nutrition planning"]'::jsonb,
    4
);

-- ============================================
-- USER SUBSCRIPTIONS TABLE
-- ============================================

CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT NOT NULL CHECK (status IN ('active', 'cancelled', 'past_due', 'paused')),
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMPTZ,
    stripe_subscription_id TEXT UNIQUE,
    stripe_customer_id TEXT,
    credits_remaining INTEGER NOT NULL DEFAULT 0,
    rollover_credits INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, status) -- Only one active subscription per user
);

-- ============================================
-- DYNAMIC PRICING RULES TABLE
-- ============================================

CREATE TABLE pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_type TEXT NOT NULL CHECK (rule_type IN ('class_type', 'time_slot', 'instructor', 'demand', 'promotional')),
    name TEXT NOT NULL,
    credit_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.0, -- 0.5 = half credit, 2.0 = double credits
    conditions JSONB NOT NULL, -- Flexible conditions for the rule
    priority INTEGER DEFAULT 0, -- Higher priority rules override lower ones
    is_active BOOLEAN DEFAULT TRUE,
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert dynamic pricing rules
INSERT INTO pricing_rules (rule_type, name, credit_multiplier, conditions, priority) VALUES
-- Standard pricing
('class_type', 'Standard Classes', 1.0, '{"class_types": ["yoga", "pilates", "fitness"]}', 0),

-- Premium pricing
('class_type', 'Premium Classes', 2.0, '{"class_types": ["workshop", "masterclass", "specialty"]}', 10),
('instructor', 'Celebrity Instructors', 2.0, '{"instructor_tier": "celebrity"}', 15),

-- Off-peak discounts
('time_slot', 'Off-Peak Morning', 0.5, '{"time_range": ["11:00", "14:00"]}', 5),
('time_slot', 'Late Evening Discount', 0.75, '{"time_range": ["20:00", "22:00"]}', 5),

-- Peak pricing
('time_slot', 'Peak Morning', 1.5, '{"time_range": ["06:00", "08:00"], "days": ["monday", "tuesday", "wednesday", "thursday", "friday"]}', 10),
('time_slot', 'Peak Evening', 1.5, '{"time_range": ["17:00", "19:00"], "days": ["monday", "tuesday", "wednesday", "thursday", "friday"]}', 10);

-- ============================================
-- PROMOTIONAL CODES TABLE
-- ============================================

CREATE TABLE promo_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed', 'credits')),
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_purchase DECIMAL(10,2),
    applicable_to TEXT[] DEFAULT ARRAY['all'], -- ['all', 'packages', 'subscriptions', 'specific_package_ids']
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    user_limit INTEGER DEFAULT 1, -- How many times each user can use
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert launch promotional codes
INSERT INTO promo_codes (code, description, discount_type, discount_value, minimum_purchase, valid_until) VALUES
('WELCOME20', 'New user 20% off', 'percentage', 20, 0, NOW() + INTERVAL '30 days'),
('FIRST50', 'First purchase 50% off', 'percentage', 50, 0, NOW() + INTERVAL '7 days'),
('FRIEND5', 'Referral bonus 5 credits', 'credits', 5, 0, NOW() + INTERVAL '90 days'),
('BULK15', 'Bulk purchase 15% off', 'percentage', 15, 100, NOW() + INTERVAL '60 days');

-- ============================================
-- LOYALTY REWARDS TABLE
-- ============================================

CREATE TABLE loyalty_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_classes_attended INTEGER DEFAULT 0,
    total_credits_purchased INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    current_tier TEXT DEFAULT 'bronze' CHECK (current_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    points_balance INTEGER DEFAULT 0,
    rewards_earned JSONB DEFAULT '[]'::jsonb,
    next_milestone_classes INTEGER,
    next_milestone_reward TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- REFERRAL PROGRAM TABLE
-- ============================================

CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_email TEXT NOT NULL,
    referred_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired')),
    referrer_reward_credits INTEGER DEFAULT 5,
    referred_reward_credits INTEGER DEFAULT 5,
    referrer_rewarded BOOLEAN DEFAULT FALSE,
    referred_rewarded BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PRICING ANALYTICS TABLE
-- ============================================

CREATE TABLE pricing_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    package_id UUID REFERENCES credit_packages(id),
    subscription_plan_id UUID REFERENCES subscription_plans(id),
    purchases_count INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    average_purchase_value DECIMAL(10,2),
    conversion_rate DECIMAL(5,2),
    churn_rate DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(date, package_id, subscription_plan_id)
);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate dynamic class pricing
CREATE OR REPLACE FUNCTION calculate_class_credits(
    p_class_id UUID
) RETURNS DECIMAL AS $$
DECLARE
    v_base_credits DECIMAL := 1.0;
    v_multiplier DECIMAL := 1.0;
    v_class_record RECORD;
    v_rule RECORD;
BEGIN
    -- Get class details
    SELECT * INTO v_class_record FROM classes WHERE id = p_class_id;
    
    -- Apply pricing rules based on priority
    FOR v_rule IN 
        SELECT * FROM pricing_rules 
        WHERE is_active = TRUE 
        AND (valid_from IS NULL OR valid_from <= NOW())
        AND (valid_until IS NULL OR valid_until >= NOW())
        ORDER BY priority DESC
    LOOP
        -- Check if rule applies based on conditions
        IF v_rule.rule_type = 'class_type' 
           AND v_class_record.class_type = ANY(
               SELECT jsonb_array_elements_text(v_rule.conditions->'class_types')
           ) THEN
            v_multiplier := v_rule.credit_multiplier;
            EXIT; -- Use highest priority matching rule
        END IF;
        
        -- Add more condition checks as needed
    END LOOP;
    
    RETURN v_base_credits * v_multiplier;
END;
$$ LANGUAGE plpgsql;

-- Function to apply promotional code
CREATE OR REPLACE FUNCTION apply_promo_code(
    p_user_id UUID,
    p_code TEXT,
    p_purchase_amount DECIMAL
) RETURNS JSONB AS $$
DECLARE
    v_promo RECORD;
    v_discount DECIMAL := 0;
    v_usage_count INTEGER;
BEGIN
    -- Get promo code details
    SELECT * INTO v_promo FROM promo_codes 
    WHERE code = UPPER(p_code)
    AND is_active = TRUE
    AND (valid_from IS NULL OR valid_from <= NOW())
    AND (valid_until IS NULL OR valid_until >= NOW())
    AND (usage_limit IS NULL OR usage_count < usage_limit);
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'Invalid or expired promo code');
    END IF;
    
    -- Check minimum purchase requirement
    IF v_promo.minimum_purchase IS NOT NULL AND p_purchase_amount < v_promo.minimum_purchase THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'Minimum purchase requirement not met');
    END IF;
    
    -- Check user usage limit
    SELECT COUNT(*) INTO v_usage_count 
    FROM promo_code_usage 
    WHERE promo_code_id = v_promo.id AND user_id = p_user_id;
    
    IF v_usage_count >= v_promo.user_limit THEN
        RETURN jsonb_build_object('success', FALSE, 'message', 'You have already used this promo code');
    END IF;
    
    -- Calculate discount
    IF v_promo.discount_type = 'percentage' THEN
        v_discount := p_purchase_amount * (v_promo.discount_value / 100);
    ELSIF v_promo.discount_type = 'fixed' THEN
        v_discount := v_promo.discount_value;
    END IF;
    
    RETURN jsonb_build_object(
        'success', TRUE, 
        'discount', v_discount,
        'discount_type', v_promo.discount_type,
        'discount_value', v_promo.discount_value
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check loyalty rewards
CREATE OR REPLACE FUNCTION check_loyalty_milestone(
    p_user_id UUID
) RETURNS VOID AS $$
DECLARE
    v_loyalty RECORD;
    v_reward_credits INTEGER := 0;
BEGIN
    SELECT * INTO v_loyalty FROM loyalty_rewards WHERE user_id = p_user_id;
    
    -- Check milestones
    IF v_loyalty.total_classes_attended >= 10 AND v_loyalty.total_classes_attended < 25 THEN
        v_reward_credits := 1;
        UPDATE loyalty_rewards SET current_tier = 'silver' WHERE user_id = p_user_id;
    ELSIF v_loyalty.total_classes_attended >= 25 AND v_loyalty.total_classes_attended < 50 THEN
        v_reward_credits := 3;
        UPDATE loyalty_rewards SET current_tier = 'gold' WHERE user_id = p_user_id;
    ELSIF v_loyalty.total_classes_attended >= 50 THEN
        v_reward_credits := 5;
        UPDATE loyalty_rewards SET current_tier = 'platinum' WHERE user_id = p_user_id;
    END IF;
    
    -- Award credits if milestone reached
    IF v_reward_credits > 0 THEN
        INSERT INTO user_credits (user_id, credits, transaction_type, description)
        VALUES (p_user_id, v_reward_credits, 'loyalty_reward', 'Loyalty milestone reward');
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Update subscription credits monthly
CREATE OR REPLACE FUNCTION refresh_subscription_credits()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_period_start > OLD.current_period_start THEN
        -- Add monthly credits
        UPDATE user_credits 
        SET credits = credits + (
            SELECT monthly_credits FROM subscription_plans WHERE id = NEW.plan_id
        )
        WHERE user_id = NEW.user_id;
        
        -- Handle rollover
        UPDATE user_subscriptions
        SET rollover_credits = LEAST(
            credits_remaining,
            (SELECT rollover_limit FROM subscription_plans WHERE id = NEW.plan_id)
        ),
        credits_remaining = (SELECT monthly_credits FROM subscription_plans WHERE id = NEW.plan_id)
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER subscription_credit_refresh
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION refresh_subscription_credits();

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_credit_packages_active ON credit_packages(is_active);
CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);
CREATE INDEX idx_user_subscriptions_user_status ON user_subscriptions(user_id, status);
CREATE INDEX idx_pricing_rules_active ON pricing_rules(is_active, rule_type);
CREATE INDEX idx_promo_codes_code ON promo_codes(code, is_active);
CREATE INDEX idx_referrals_referrer ON referrals(referrer_id, status);
CREATE INDEX idx_loyalty_rewards_user ON loyalty_rewards(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE credit_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Public read access for packages and plans
CREATE POLICY "Public can view active packages" ON credit_packages
    FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Public can view active plans" ON subscription_plans
    FOR SELECT USING (is_active = TRUE);

-- User-specific access for subscriptions and rewards
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own loyalty" ON loyalty_rewards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own referrals" ON referrals
    FOR SELECT USING (auth.uid() = referrer_id);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE credit_packages IS 'Optimized credit package pricing with psychological pricing strategies';
COMMENT ON TABLE subscription_plans IS 'Monthly subscription options with different perk levels';
COMMENT ON TABLE pricing_rules IS 'Dynamic pricing rules for different class types and time slots';
COMMENT ON TABLE loyalty_rewards IS 'Track user loyalty and milestone rewards';
COMMENT ON TABLE referrals IS 'Referral program tracking and rewards';