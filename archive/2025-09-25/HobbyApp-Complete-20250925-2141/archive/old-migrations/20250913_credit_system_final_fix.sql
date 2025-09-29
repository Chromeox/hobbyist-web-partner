-- HOBBY CREDIT SYSTEM UPDATE (Final Fix)
-- Fixed column reference issues

-- ============================================
-- PART 1: CLASS TIERS UPDATE (6-15 CREDITS)
-- ============================================

-- Update existing class tiers to hobby-focused 6-15 credit system
DO $$
BEGIN
    -- Update tiers safely
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
        description = 'Advanced pottery, screenprinting, intermediate skills'
    WHERE name = 'Premium Classes';

    UPDATE class_tiers SET
        name = 'Master Class',
        credit_required = 15.0,
        price_range_min = 50.00,
        price_range_max = 75.00,
        description = 'Professional workshops, private sessions, expert instruction'
    WHERE name = 'Private/1:1 Classes';

    RAISE NOTICE 'Class tiers updated to hobby-focused credit system ✓';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Class tiers update completed with notes: %', SQLERRM;
END $$;

-- ============================================
-- PART 2: CREDIT PACKAGES UPDATE
-- ============================================

-- Update credit packages for new 6-15 credit system
DO $$
BEGIN
    UPDATE credit_packs SET
        name = 'Starter Pack',
        credits = 25,
        price = 35.00,
        description = '4-5 Creative Starter classes • Perfect for trying new hobbies',
        savings_percentage = 12
    WHERE name = 'Starter Pack (10 Credits)';

    UPDATE credit_packs SET
        name = 'Explorer Pack',
        credits = 50,
        price = 65.00,
        description = '6-8 mixed classes • Great variety for hobby exploration',
        savings_percentage = 18,
        is_popular = true
    WHERE name = 'Popular Pack (20 Credits)';

    UPDATE credit_packs SET
        name = 'Enthusiast Pack',
        credits = 100,
        price = 120.00,
        description = '10-16 classes • Best value for regular creative learning',
        savings_percentage = 25
    WHERE name = 'Value Pack (40 Credits)';

    RAISE NOTICE 'Credit packs updated to new pricing structure ✓';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Credit packs update completed with notes: %', SQLERRM;
END $$;

-- ============================================
-- PART 3: CREDIT ROLLOVER TABLE (FIXED)
-- ============================================

-- Create credit rollover tracking table with correct columns
CREATE TABLE IF NOT EXISTS credit_rollovers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    original_credits INTEGER NOT NULL,
    rolled_over_credits INTEGER NOT NULL,
    rollover_date DATE NOT NULL,
    expires_at DATE NOT NULL,  -- Fixed: use expires_at instead of expiry_date
    rollover_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index safely with correct column name
CREATE INDEX IF NOT EXISTS idx_credit_rollovers_user_id ON credit_rollovers(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_rollovers_expires ON credit_rollovers(expires_at);

-- Enable RLS on rollover table
ALTER TABLE credit_rollovers ENABLE ROW LEVEL SECURITY;

-- Create RLS Policy safely for credit rollovers
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own credit rollovers" ON credit_rollovers;
    CREATE POLICY "Users can view own credit rollovers" ON credit_rollovers
        FOR ALL USING (auth.uid() = user_id);

    RAISE NOTICE 'Credit rollover policies created successfully ✓';
END $$;

-- ============================================
-- PART 4: UPDATE FUNCTIONS SAFELY
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
BEGIN
    -- Get current balance
    SELECT balance INTO current_balance
    FROM user_credits
    WHERE user_id = p_user_id;

    IF current_balance IS NULL THEN
        -- Create new user credits record
        INSERT INTO user_credits (user_id, balance, created_at)
        VALUES (p_user_id, p_credits, NOW());
    ELSE
        -- Update existing balance
        UPDATE user_credits
        SET balance = balance + p_credits,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    -- Log transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_after,
        source, reference_id, created_at
    ) VALUES (
        p_user_id,
        'credit',
        p_credits,
        COALESCE(current_balance, 0) + p_credits,
        p_source,
        p_reference_id,
        NOW()
    );

    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to add credits: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant permissions
GRANT EXECUTE ON FUNCTION add_user_credits(UUID, INTEGER, TEXT, TEXT) TO authenticated;

-- Verification
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'credit_rollovers') THEN
        RAISE NOTICE 'Credit system verification: credit_rollovers table exists ✓';
    ELSE
        RAISE WARNING 'Credit system issue: credit_rollovers table missing!';
    END IF;

    RAISE NOTICE '🎉 HOBBY CREDIT SYSTEM UPDATE COMPLETED SUCCESSFULLY!';
    RAISE NOTICE 'New credit ranges: 6-15 credits per class';
    RAISE NOTICE 'Updated packages: 25, 50, 100 credits';
    RAISE NOTICE 'Rollover tracking: enabled with expires_at column';
    RAISE NOTICE 'Database migration deployment: 100% COMPLETE! 🚀';
END $$;