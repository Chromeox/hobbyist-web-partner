-- HOBBY CREDIT SYSTEM UPDATE
-- Updates credit system from 0.5-4.0 credits to 6-15 credits per class
-- Aligns with creative hobby focus and competitive ClassPass-style pricing
-- Created: 2025-09-13

-- ============================================
-- PART 1: CLASS TIERS UPDATE (6-15 CREDITS)
-- ============================================

-- Update existing class tiers to hobby-focused 6-15 credit system
UPDATE class_tiers SET 
    name = 'Creative Starter',
    credit_required = 6.0,
    price_range_min = 15.00,
    price_range_max = 25.00,
    description = 'Intro pottery, basic drawing, beginner-friendly creative classes'
WHERE name = 'Drop-in Yoga/Meditation';

UPDATE class_tiers SET 
    name = 'Hobby Explorer',
    credit_required = 8.0,
    price_range_min = 25.00,
    price_range_max = 35.00,
    description = 'DJ workshops, boxing basics, painting classes'
WHERE name = 'Regular Fitness';

UPDATE class_tiers SET 
    name = 'Skill Builder',
    credit_required = 10.0,
    price_range_min = 35.00,
    price_range_max = 50.00,
    description = 'Wheel throwing, intermediate classes, technique focus'
WHERE name = 'Specialized Hobby';

UPDATE class_tiers SET 
    name = 'Master Workshop',
    credit_required = 12.0,
    price_range_min = 50.00,
    price_range_max = 70.00,
    description = 'Advanced ceramics, music production, expert instruction'
WHERE name = 'Premium Instruction';

UPDATE class_tiers SET 
    name = 'Intensive Experience',
    credit_required = 15.0,
    price_range_min = 70.00,
    price_range_max = 95.00,
    description = 'Multi-session intensives, private coaching, immersive workshops'
WHERE name = 'Intensive Workshop';

-- Remove Elite Training tier (consolidate into Intensive Experience)
DELETE FROM class_tiers WHERE name = 'Elite Training';

-- ============================================
-- PART 2: CREDIT PACKS UPDATE (KEEP PRICES, ADJUST CREDITS)
-- ============================================

-- Update credit amounts while keeping existing price points
-- New structure provides 35-45% better value than ClassPass

UPDATE credit_packs SET 
    credits = 20,
    description = 'Perfect for trying out new creative hobbies - 3-4 classes'
WHERE name = 'Starter'; -- $25 = $1.25/credit

UPDATE credit_packs SET 
    credits = 45,
    name = 'Explore More',
    description = 'Great for exploring different creative disciplines'
WHERE name = 'Explorer'; -- $55 = $1.22/credit

UPDATE credit_packs SET 
    credits = 80,
    name = 'Get Serious', 
    description = 'Most popular - ideal for regular creative practice'
WHERE name = 'Regular'; -- $95 = $1.19/credit

UPDATE credit_packs SET 
    credits = 145,
    name = 'Go Deep',
    description = 'For dedicated creative learners - intensive exploration'
WHERE name = 'Enthusiast'; -- $170 = $1.17/credit

UPDATE credit_packs SET 
    credits = 260,
    name = 'Unlimited Creativity',
    description = 'Best value for daily creators and multi-discipline learners'
WHERE name = 'Power User'; -- $300 = $1.15/credit

-- ============================================
-- PART 3: SUBSCRIPTION PLANS UPDATE (ENHANCED ROLLOVER)
-- ============================================

-- Add rollover_percentage column if it doesn't exist
ALTER TABLE subscription_plans 
ADD COLUMN IF NOT EXISTS rollover_percentage INTEGER DEFAULT 25;

-- Update subscription plans with increased credits and generous rollover
UPDATE subscription_plans SET 
    name = 'Creative Explorer',
    monthly_credits = 40,
    rollover_percentage = 50,
    description = 'Perfect for weekend creative warriors',
    features = ARRAY['40 credits monthly', '50% rollover (20 credits max)', 'Basic app features', 'Community access']
WHERE name = 'Casual';

UPDATE subscription_plans SET 
    name = 'Hobby Regular',
    monthly_credits = 75,
    rollover_percentage = 60,
    description = 'For regular creative enthusiasts and skill builders',
    features = ARRAY['75 credits monthly', '60% rollover (45 credits max)', 'Priority booking', 'Guest passes', 'Workshop discounts']
WHERE name = 'Active';

UPDATE subscription_plans SET 
    name = 'Creative Enthusiast',
    monthly_credits = 150,
    rollover_percentage = 75,
    description = 'Unlimited creative possibilities and intensive learning',
    features = ARRAY['150 credits monthly', '75% rollover (112 credits max)', 'Premium support', 'Exclusive workshops', 'Multi-studio access']
WHERE name = 'Premium';

UPDATE subscription_plans SET 
    name = 'Master Creator',
    monthly_credits = 250,
    rollover_percentage = 100,
    description = 'The ultimate creative experience with unlimited rollover',
    features = ARRAY['250 credits monthly', '100% unlimited rollover', 'Concierge service', 'Private workshop access', 'All premium features']
WHERE name = 'Elite';

-- ============================================
-- PART 4: DYNAMIC PRICING RULES UPDATE
-- ============================================

-- Update dynamic pricing rules to work with new credit ranges
-- Adjust multipliers to work with 6-15 credit system

UPDATE dynamic_pricing_rules SET 
    credit_multiplier = 1.2,
    description = 'Weekday morning peak - slight premium for popular times'
WHERE name = 'Morning Peak';

UPDATE dynamic_pricing_rules SET 
    credit_multiplier = 1.2,
    description = 'Weekday evening peak - slight premium for popular times'  
WHERE name = 'Evening Peak';

UPDATE dynamic_pricing_rules SET 
    credit_multiplier = 0.9,
    description = 'Weekend afternoon discount - encourage off-peak exploration'
WHERE name = 'Weekend Discount';

UPDATE dynamic_pricing_rules SET 
    credit_multiplier = 0.85,
    description = 'Winter creativity bonus - November through February discount'
WHERE name = 'Winter Bonus';

-- ============================================
-- PART 5: ADD ROLLOVER TRACKING TABLE
-- ============================================

-- Create table to track credit rollovers for enhanced user experience
CREATE TABLE IF NOT EXISTS credit_rollovers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id),
    original_credits INTEGER NOT NULL,
    rollover_credits INTEGER NOT NULL,
    rollover_percentage INTEGER NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on rollover table
ALTER TABLE credit_rollovers ENABLE ROW LEVEL SECURITY;

-- RLS Policy for credit rollovers
CREATE POLICY "Users can view own credit rollovers" ON credit_rollovers
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- PART 6: UPDATE FUNCTIONS FOR NEW CREDIT SYSTEM
-- ============================================

-- Update add_user_credits function to handle rollover logic
CREATE OR REPLACE FUNCTION add_user_credits(
    p_user_id UUID,
    p_credits INTEGER,
    p_source TEXT,
    p_reference_id TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    current_balance INTEGER;
    new_balance INTEGER;
BEGIN
    -- Get current balance
    SELECT COALESCE(total_credits, 0) INTO current_balance
    FROM user_credits 
    WHERE user_id = p_user_id;
    
    -- Calculate new balance
    new_balance := current_balance + p_credits;
    
    -- Update user credits (create record if doesn't exist)
    INSERT INTO user_credits (user_id, total_credits, updated_at)
    VALUES (p_user_id, new_balance, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        total_credits = new_balance,
        updated_at = NOW();
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id,
        transaction_type,
        amount,
        credits_amount,
        balance_after,
        description,
        reference_id,
        reference_type
    ) VALUES (
        p_user_id,
        p_source,
        0, -- Amount in dollars, 0 for credit additions
        p_credits,
        new_balance,
        CASE p_source
            WHEN 'purchase' THEN 'Credit pack purchase'
            WHEN 'subscription' THEN 'Monthly subscription credits'
            WHEN 'rollover' THEN 'Credit rollover from previous month'
            WHEN 'bonus' THEN 'Bonus credits'
            ELSE p_source
        END,
        p_reference_id,
        p_source
    );
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PART 7: COMMENTS AND DOCUMENTATION
-- ============================================

-- Add table comments for documentation
COMMENT ON TABLE credit_rollovers IS 'Tracks credit rollover history for subscription users';
COMMENT ON COLUMN credit_rollovers.rollover_percentage IS 'Percentage of credits that rolled over (50, 60, 75, or 100)';
COMMENT ON COLUMN credit_rollovers.expires_at IS 'When rollover credits expire (if applicable)';

-- Update existing table comments
COMMENT ON TABLE class_tiers IS 'Creative hobby class tiers with 6-15 credit requirements';
COMMENT ON TABLE credit_packs IS 'One-time credit packages optimized for hobby exploration';
COMMENT ON TABLE subscription_plans IS 'Monthly subscription plans with generous rollover policies';

-- Add column comments for clarity
COMMENT ON COLUMN class_tiers.credit_required IS 'Credits required (6-15 range for hobby classes)';
COMMENT ON COLUMN subscription_plans.rollover_percentage IS 'Percentage of unused credits that rollover monthly';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify class tiers update
-- SELECT name, credit_required, price_range_min, price_range_max, description FROM class_tiers ORDER BY credit_required;

-- Verify credit packs update  
-- SELECT name, credits, price, ROUND(price/credits, 2) as price_per_credit, description FROM credit_packs ORDER BY price;

-- Verify subscription plans update
-- SELECT name, monthly_credits, price, rollover_percentage, description FROM subscription_plans ORDER BY price;

-- End of migration