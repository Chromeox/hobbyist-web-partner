-- COMPLETE VANCOUVER PRICING SYSTEM
-- Single comprehensive migration for HobbyistSwiftUI
-- Includes all tables, policies, and initial data

-- ============================================
-- PART 1: BASE TABLES
-- ============================================

-- User Credits Table
CREATE TABLE user_credits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_credits INTEGER DEFAULT 0,
    used_credits INTEGER DEFAULT 0,
    rollover_credits INTEGER DEFAULT 0,
    insurance_plan_id UUID,
    membership_started_at TIMESTAMPTZ DEFAULT NOW(),
    loyalty_tier TEXT DEFAULT 'bronze' CHECK (loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_credits UNIQUE (user_id),
    CONSTRAINT positive_credits CHECK (total_credits >= 0 AND used_credits >= 0)
);

-- Studios Table
CREATE TABLE studios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address TEXT,
    city TEXT DEFAULT 'Vancouver',
    province TEXT DEFAULT 'BC',
    postal_code TEXT,
    commission_rate DECIMAL(5,2) DEFAULT 25.00, -- Platform takes 25-30%
    stripe_account_id TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instructors Table
CREATE TABLE instructors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID REFERENCES studios(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    bio TEXT,
    specialties TEXT[],
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_classes INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Class Tiers Table (defines credit requirements)
CREATE TABLE class_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    credit_required DECIMAL(3,1) NOT NULL,
    price_range_min DECIMAL(10,2),
    price_range_max DECIMAL(10,2),
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classes Table
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
    instructor_id UUID REFERENCES instructors(id) ON DELETE SET NULL,
    tier_id UUID REFERENCES class_tiers(id),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'all_levels')),
    price DECIMAL(10,2) NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    max_participants INTEGER DEFAULT 20,
    equipment_needed TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Class Schedules Table
CREATE TABLE class_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    spots_available INTEGER NOT NULL,
    spots_total INTEGER NOT NULL,
    is_cancelled BOOLEAN DEFAULT false,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_time_range CHECK (end_time > start_time),
    CONSTRAINT valid_spots CHECK (spots_available >= 0 AND spots_available <= spots_total)
);

-- Bookings Table
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    class_schedule_id UUID NOT NULL REFERENCES class_schedules(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'completed', 'no_show', 'waitlisted')),
    credits_used DECIMAL(3,1) NOT NULL,
    payment_method TEXT CHECK (payment_method IN ('credits', 'subscription', 'cash', 'card')),
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    checked_in_at TIMESTAMPTZ,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 2: PRICING TABLES
-- ============================================

-- Credit Packages Table
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
    apple_product_id TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscription Plans Table
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    monthly_credits INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    rollover_percentage INTEGER DEFAULT 25,
    description TEXT,
    features TEXT[],
    stripe_product_id TEXT,
    stripe_price_id TEXT,
    apple_product_id TEXT,
    is_popular BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit Insurance Plans Table
CREATE TABLE credit_insurance_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    monthly_price DECIMAL(10,2) NOT NULL,
    coverage_percentage INTEGER NOT NULL, -- % of credits protected from expiration
    max_protected_credits INTEGER,
    description TEXT,
    stripe_product_id TEXT,
    stripe_price_id TEXT,
    apple_product_id TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Subscriptions Table
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'expired')),
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT false,
    stripe_subscription_id TEXT,
    apple_subscription_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Insurance Subscriptions Table
CREATE TABLE user_insurance_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    insurance_plan_id UUID NOT NULL REFERENCES credit_insurance_plans(id),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    protected_credits INTEGER DEFAULT 0,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    stripe_subscription_id TEXT,
    apple_subscription_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit Transactions Table
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'use', 'refund', 'bonus', 'rollover', 'expire', 'insurance_claim')),
    amount DECIMAL(10,2) NOT NULL,
    credits_amount INTEGER,
    balance_after INTEGER NOT NULL,
    description TEXT,
    reference_id UUID, -- Can reference booking_id, purchase_id, etc.
    reference_type TEXT, -- 'booking', 'purchase', 'subscription', etc.
    stripe_payment_intent_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 3: RETENTION & SOCIAL FEATURES
-- ============================================

-- Squads Table (Social Groups)
CREATE TABLE squads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES auth.users(id),
    max_members INTEGER DEFAULT 10,
    is_private BOOLEAN DEFAULT false,
    join_code TEXT UNIQUE,
    total_classes_attended INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Squad Members Table
CREATE TABLE squad_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    classes_attended INTEGER DEFAULT 0,
    last_class_at TIMESTAMPTZ,
    CONSTRAINT unique_squad_member UNIQUE (squad_id, user_id)
);

-- Dynamic Pricing Rules Table
CREATE TABLE dynamic_pricing_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    rule_type TEXT NOT NULL CHECK (rule_type IN ('time_based', 'demand_based', 'seasonal', 'promotional')),
    start_time TIME,
    end_time TIME,
    days_of_week INTEGER[], -- 1=Monday, 7=Sunday
    months INTEGER[], -- 1=January, 12=December
    credit_multiplier DECIMAL(3,2) DEFAULT 1.0,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Promotional Campaigns Table
CREATE TABLE promotional_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    campaign_type TEXT CHECK (campaign_type IN ('percentage', 'fixed_amount', 'bonus_credits', 'free_trial')),
    discount_value DECIMAL(10,2),
    bonus_credits INTEGER,
    valid_from TIMESTAMPTZ NOT NULL,
    valid_until TIMESTAMPTZ NOT NULL,
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    minimum_purchase DECIMAL(10,2),
    applicable_to TEXT[], -- ['credit_packs', 'subscriptions', 'classes']
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Retention Metrics Table
CREATE TABLE retention_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    first_class_date DATE,
    last_class_date DATE,
    total_classes_attended INTEGER DEFAULT 0,
    total_credits_purchased INTEGER DEFAULT 0,
    total_credits_used INTEGER DEFAULT 0,
    favorite_studio_id UUID REFERENCES studios(id),
    favorite_category TEXT,
    average_classes_per_week DECIMAL(3,1),
    retention_score INTEGER DEFAULT 50, -- 0-100
    churn_risk TEXT CHECK (churn_risk IN ('low', 'medium', 'high')),
    last_calculated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- PART 4: INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX idx_studios_city ON studios(city);
CREATE INDEX idx_instructors_studio_id ON instructors(studio_id);
CREATE INDEX idx_classes_studio_id ON classes(studio_id);
CREATE INDEX idx_classes_category ON classes(category);
CREATE INDEX idx_class_schedules_class_id ON class_schedules(class_id);
CREATE INDEX idx_class_schedules_start_time ON class_schedules(start_time);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_schedule_id ON bookings(class_schedule_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON credit_transactions(created_at DESC);
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX idx_squad_members_user_id ON squad_members(user_id);
CREATE INDEX idx_promotional_campaigns_code ON promotional_campaigns(code);
CREATE INDEX idx_retention_metrics_user_id ON retention_metrics(user_id);

-- ============================================
-- PART 5: ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_insurance_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_insurance_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE dynamic_pricing_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotional_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE retention_metrics ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies
DO $$ 
BEGIN
    -- User Credits policies
    CREATE POLICY "Users can view own credits" ON user_credits
        FOR ALL USING (auth.uid() = user_id);

    -- Studios policies
    CREATE POLICY "Public can view active studios" ON studios
        FOR SELECT USING (is_active = true);

    -- Instructors policies
    CREATE POLICY "Public can view active instructors" ON instructors
        FOR SELECT USING (is_active = true);

    -- Class Tiers policies
    CREATE POLICY "Public can view class tiers" ON class_tiers
        FOR SELECT USING (true);

    -- Classes policies
    CREATE POLICY "Public can view active classes" ON classes
        FOR SELECT USING (is_active = true);

    -- Class Schedules policies
    CREATE POLICY "Public can view future schedules" ON class_schedules
        FOR SELECT USING (start_time > NOW() AND is_cancelled = false);

    -- Bookings policies
    CREATE POLICY "Users can view own bookings" ON bookings
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY "Users can create own bookings" ON bookings
        FOR INSERT WITH CHECK (auth.uid() = user_id);
    
    CREATE POLICY "Users can update own bookings" ON bookings
        FOR UPDATE USING (auth.uid() = user_id);

    -- Credit Packs policies
    CREATE POLICY "Public can view active credit packs" ON credit_packs
        FOR SELECT USING (is_active = true);

    -- Subscription Plans policies
    CREATE POLICY "Public can view active subscription plans" ON subscription_plans
        FOR SELECT USING (is_active = true);

    -- Credit Insurance Plans policies
    CREATE POLICY "Public can view active insurance plans" ON credit_insurance_plans
        FOR SELECT USING (is_active = true);

    -- User Subscriptions policies
    CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
        FOR ALL USING (auth.uid() = user_id);

    -- User Insurance Subscriptions policies
    CREATE POLICY "Users can view own insurance" ON user_insurance_subscriptions
        FOR ALL USING (auth.uid() = user_id);

    -- Credit Transactions policies
    CREATE POLICY "Users can view own transactions" ON credit_transactions
        FOR SELECT USING (auth.uid() = user_id);

    -- Squads policies
    CREATE POLICY "Public can view public squads" ON squads
        FOR SELECT USING (is_private = false OR creator_id = auth.uid());
    
    CREATE POLICY "Users can create squads" ON squads
        FOR INSERT WITH CHECK (creator_id = auth.uid());

    -- Squad Members policies
    CREATE POLICY "Squad members can view squad" ON squad_members
        FOR SELECT USING (user_id = auth.uid());
    
    CREATE POLICY "Users can join squads" ON squad_members
        FOR INSERT WITH CHECK (user_id = auth.uid());

    -- Dynamic Pricing Rules policies
    CREATE POLICY "Public can view active pricing rules" ON dynamic_pricing_rules
        FOR SELECT USING (is_active = true);

    -- Promotional Campaigns policies
    CREATE POLICY "Public can view active campaigns" ON promotional_campaigns
        FOR SELECT USING (is_active = true AND valid_from <= NOW() AND valid_until >= NOW());

    -- Retention Metrics policies
    CREATE POLICY "Users can view own metrics" ON retention_metrics
        FOR SELECT USING (auth.uid() = user_id);
END $$;

-- ============================================
-- PART 6: INITIAL DATA
-- ============================================

-- Insert Class Tiers (Vancouver market based)
INSERT INTO class_tiers (name, credit_required, price_range_min, price_range_max, description) VALUES
    ('Drop-in Yoga/Meditation', 0.5, 10, 15, 'Casual drop-in classes'),
    ('Regular Fitness', 1.0, 20, 30, 'Standard fitness and gym classes'),
    ('Specialized Hobby', 1.5, 35, 50, 'Pottery, painting, crafts'),
    ('Premium Instruction', 2.0, 55, 75, 'Advanced workshops, master classes'),
    ('Intensive Workshop', 3.0, 80, 105, 'Full-day or multi-session intensives'),
    ('Elite Training', 4.0, 110, 150, 'One-on-one coaching, specialized training');

-- Insert Credit Packages (Vancouver pricing)
INSERT INTO credit_packs (name, credits, price, savings_percentage, is_popular, description) VALUES
    ('Starter', 10, 25.00, NULL, false, 'Perfect for trying out new classes'),
    ('Explorer', 25, 55.00, 12, false, 'Great for 1-2 classes per week'),
    ('Regular', 50, 95.00, 24, true, 'Most popular - ideal for regular attendees'),
    ('Enthusiast', 100, 170.00, 32, false, 'For dedicated practitioners (4-5 classes/week)'),
    ('Power User', 200, 300.00, 40, false, 'Best value for daily class-goers');

-- Insert Subscription Plans
INSERT INTO subscription_plans (name, monthly_credits, price, rollover_percentage, description, features) VALUES
    ('Casual', 30, 39.00, 25, 'Perfect for weekend warriors', ARRAY['30 credits monthly', '25% rollover', 'Basic app features']),
    ('Active', 60, 69.00, 30, 'For regular fitness enthusiasts', ARRAY['60 credits monthly', '30% rollover', 'Priority booking', 'Guest passes']),
    ('Premium', 120, 119.00, 50, 'Unlimited possibilities', ARRAY['120 credits monthly', '50% rollover', 'Premium support', 'Exclusive classes']),
    ('Elite', 200, 179.00, 100, 'The ultimate experience', ARRAY['200 credits monthly', '100% rollover', 'Concierge service', 'All premium features']);

-- Insert Credit Insurance Plans
INSERT INTO credit_insurance_plans (name, monthly_price, coverage_percentage, max_protected_credits, description) VALUES
    ('Basic Protection', 3.00, 100, 25, 'Protects up to 25 credits from expiration'),
    ('Plus Protection', 5.00, 100, 60, 'Protects up to 60 credits from expiration'),
    ('Premium Protection', 8.00, 100, NULL, 'Protects unlimited credits from expiration');

-- Insert Dynamic Pricing Rules (Peak hours and seasonal)
INSERT INTO dynamic_pricing_rules (name, rule_type, start_time, end_time, days_of_week, credit_multiplier, description, priority) VALUES
    ('Morning Peak', 'time_based', '06:00', '08:00', ARRAY[1,2,3,4,5], 1.25, 'Weekday morning rush', 1),
    ('Evening Peak', 'time_based', '17:00', '19:00', ARRAY[1,2,3,4,5], 1.25, 'Weekday evening rush', 1),
    ('Weekend Discount', 'time_based', '14:00', '17:00', ARRAY[6,7], 0.85, 'Weekend afternoon discount', 2),
    ('Winter Bonus', 'seasonal', NULL, NULL, NULL, 0.80, 'November-February 20% discount', 3);

-- Update dynamic pricing for winter months
UPDATE dynamic_pricing_rules 
SET months = ARRAY[11, 12, 1, 2] 
WHERE name = 'Winter Bonus';

-- ============================================
-- PART 7: HELPER FUNCTIONS
-- ============================================

-- Function to calculate credits needed for a class
CREATE OR REPLACE FUNCTION calculate_credits_needed(
    p_class_id UUID,
    p_schedule_time TIMESTAMPTZ
) RETURNS DECIMAL AS $$
DECLARE
    v_base_credits DECIMAL;
    v_multiplier DECIMAL := 1.0;
    v_final_credits DECIMAL;
BEGIN
    -- Get base credits from class tier
    SELECT ct.credit_required INTO v_base_credits
    FROM classes c
    JOIN class_tiers ct ON c.tier_id = ct.id
    WHERE c.id = p_class_id;

    -- Apply dynamic pricing rules
    SELECT COALESCE(MAX(credit_multiplier), 1.0) INTO v_multiplier
    FROM dynamic_pricing_rules
    WHERE is_active = true
    AND (
        (rule_type = 'time_based' 
         AND start_time <= p_schedule_time::TIME 
         AND end_time >= p_schedule_time::TIME
         AND EXTRACT(DOW FROM p_schedule_time) = ANY(days_of_week))
        OR
        (rule_type = 'seasonal' 
         AND EXTRACT(MONTH FROM p_schedule_time) = ANY(months))
    )
    ORDER BY priority DESC
    LIMIT 1;

    v_final_credits := v_base_credits * v_multiplier;
    
    RETURN ROUND(v_final_credits, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to process credit rollover
CREATE OR REPLACE FUNCTION process_monthly_rollover() RETURNS void AS $$
DECLARE
    v_user RECORD;
    v_rollover_amount INTEGER;
    v_rollover_percentage INTEGER;
BEGIN
    FOR v_user IN 
        SELECT uc.*, sp.rollover_percentage
        FROM user_credits uc
        JOIN user_subscriptions us ON uc.user_id = us.user_id
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.status = 'active'
        AND uc.total_credits - uc.used_credits > 0
    LOOP
        -- Calculate rollover based on subscription plan
        v_rollover_amount := FLOOR((v_user.total_credits - v_user.used_credits) * v_user.rollover_percentage / 100);
        
        -- Update user credits
        UPDATE user_credits
        SET rollover_credits = v_rollover_amount,
            updated_at = NOW()
        WHERE user_id = v_user.user_id;
        
        -- Log the rollover transaction
        INSERT INTO credit_transactions (
            user_id, 
            transaction_type, 
            credits_amount, 
            balance_after, 
            description
        ) VALUES (
            v_user.user_id,
            'rollover',
            v_rollover_amount,
            v_rollover_amount,
            'Monthly credit rollover - ' || v_user.rollover_percentage || '% retained'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 8: FINAL SETUP
-- ============================================

-- Add comments for documentation
COMMENT ON TABLE user_credits IS 'Tracks user credit balances and insurance status';
COMMENT ON TABLE studios IS 'Partner studios offering classes in Vancouver';
COMMENT ON TABLE classes IS 'Class definitions with pricing tiers';
COMMENT ON TABLE bookings IS 'User bookings for scheduled classes';
COMMENT ON TABLE credit_packs IS 'One-time credit purchase packages';
COMMENT ON TABLE subscription_plans IS 'Monthly subscription options with rollover';
COMMENT ON TABLE credit_insurance_plans IS 'Insurance to prevent credit expiration';
COMMENT ON TABLE squads IS 'Social groups for accountability and motivation';
COMMENT ON TABLE dynamic_pricing_rules IS 'Time and season-based pricing adjustments';
COMMENT ON TABLE retention_metrics IS 'User engagement and retention tracking';

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Success message
DO $$ 
BEGIN
    RAISE NOTICE 'Vancouver Pricing System successfully deployed!';
    RAISE NOTICE 'Tables created: 18';
    RAISE NOTICE 'Credit packages: 5 ($25-$300)';
    RAISE NOTICE 'Subscription plans: 4 ($39-$179/month)';
    RAISE NOTICE 'Insurance options: 3 ($3-$8/month)';
    RAISE NOTICE 'Ready for production use!';
END $$;