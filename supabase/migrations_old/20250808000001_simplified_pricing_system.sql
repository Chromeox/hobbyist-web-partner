-- Simplified Credit-Based Pricing System
-- Implements 3-tier credit packs with 15% flat studio commission

-- Credit Packs Table
CREATE TABLE credit_packs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    credit_amount INTEGER NOT NULL,
    price_cents INTEGER NOT NULL,
    bonus_credits INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Credit Balances
CREATE TABLE user_credits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credit_balance INTEGER DEFAULT 0,
    total_earned INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Credit Transactions Log
CREATE TABLE credit_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('purchase', 'spend', 'refund', 'bonus', 'admin_adjustment')),
    credit_amount INTEGER NOT NULL, -- positive for additions, negative for deductions
    balance_after INTEGER NOT NULL,
    reference_type VARCHAR(50), -- 'credit_pack_purchase', 'class_booking', 'refund', etc.
    reference_id UUID, -- ID of the purchase, booking, etc.
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Credit Pack Purchases
CREATE TABLE credit_pack_purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    credit_pack_id UUID REFERENCES credit_packs(id),
    stripe_payment_intent_id VARCHAR(255),
    amount_paid_cents INTEGER NOT NULL,
    credits_received INTEGER NOT NULL,
    bonus_credits INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update Classes table to include credit cost
ALTER TABLE classes 
ADD COLUMN credit_cost INTEGER DEFAULT 1,
ADD COLUMN allow_credit_payment BOOLEAN DEFAULT true;

-- Update Bookings table for credit payments
ALTER TABLE bookings 
ADD COLUMN payment_method VARCHAR(50) DEFAULT 'card' CHECK (payment_method IN ('card', 'credits', 'apple_pay', 'google_pay')),
ADD COLUMN credits_used INTEGER DEFAULT 0;

-- Studio Commission Settings (15% flat rate)
CREATE TABLE studio_commission_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    studio_id UUID, -- For future multi-studio support
    commission_rate DECIMAL(5,4) DEFAULT 0.15 NOT NULL, -- 15%
    minimum_payout_cents INTEGER DEFAULT 2000, -- $20 minimum
    payout_frequency VARCHAR(20) DEFAULT 'weekly' CHECK (payout_frequency IN ('daily', 'weekly', 'monthly')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default 3-tier credit packs
INSERT INTO credit_packs (name, description, credit_amount, price_cents, bonus_credits, display_order) VALUES
('Starter Pack', 'Perfect for trying out classes', 5, 2500, 0, 1), -- $25 for 5 credits
('Popular Pack', 'Best value for regular students', 12, 5000, 3, 2), -- $50 for 12 credits + 3 bonus = 15 total
('Premium Pack', 'Maximum savings for dedicated learners', 25, 9000, 10, 3); -- $90 for 25 credits + 10 bonus = 35 total

-- Insert default commission settings (15% flat rate)
INSERT INTO studio_commission_settings (commission_rate, minimum_payout_cents, payout_frequency) VALUES
(0.15, 2000, 'weekly');

-- Indexes for performance
CREATE INDEX idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON credit_transactions(created_at DESC);
CREATE INDEX idx_credit_pack_purchases_user_id ON credit_pack_purchases(user_id);
CREATE INDEX idx_credit_pack_purchases_status ON credit_pack_purchases(status);
CREATE INDEX idx_classes_credit_cost ON classes(credit_cost);
CREATE INDEX idx_bookings_payment_method ON bookings(payment_method);

-- Row Level Security
ALTER TABLE credit_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_pack_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_commission_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Credit packs are viewable by everyone" ON credit_packs FOR SELECT USING (is_active = true);

CREATE POLICY "Users can view their own credits" ON user_credits FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can manage user credits" ON user_credits FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view their own transactions" ON credit_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can manage credit transactions" ON credit_transactions FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view their own purchases" ON credit_pack_purchases FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create their own purchases" ON credit_pack_purchases FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "System can manage credit purchases" ON credit_pack_purchases FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Commission settings viewable by instructors" ON studio_commission_settings FOR SELECT USING (true);
CREATE POLICY "Only admins can manage commission settings" ON studio_commission_settings FOR ALL USING (auth.role() = 'service_role');

-- Functions for credit management
CREATE OR REPLACE FUNCTION get_user_credit_balance(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(
        (SELECT credit_balance FROM user_credits WHERE user_id = p_user_id),
        0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION add_user_credits(
    p_user_id UUID,
    p_credit_amount INTEGER,
    p_transaction_type VARCHAR(50),
    p_reference_type VARCHAR(50) DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_new_balance INTEGER;
BEGIN
    -- Insert or update user credits
    INSERT INTO user_credits (user_id, credit_balance, total_earned, last_activity_at)
    VALUES (p_user_id, p_credit_amount, GREATEST(0, p_credit_amount), NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        credit_balance = user_credits.credit_balance + p_credit_amount,
        total_earned = user_credits.total_earned + GREATEST(0, p_credit_amount),
        total_spent = user_credits.total_spent + GREATEST(0, -p_credit_amount),
        last_activity_at = NOW(),
        updated_at = NOW();

    -- Get the new balance
    SELECT credit_balance INTO v_new_balance FROM user_credits WHERE user_id = p_user_id;

    -- Log the transaction
    INSERT INTO credit_transactions (
        user_id, transaction_type, credit_amount, balance_after,
        reference_type, reference_id, description
    ) VALUES (
        p_user_id, p_transaction_type, p_credit_amount, v_new_balance,
        p_reference_type, p_reference_id, p_description
    );

    RETURN v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION spend_user_credits(
    p_user_id UUID,
    p_credit_amount INTEGER,
    p_reference_type VARCHAR(50),
    p_reference_id UUID,
    p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
BEGIN
    -- Get current balance
    SELECT credit_balance INTO v_current_balance FROM user_credits WHERE user_id = p_user_id;
    
    -- Check if user has enough credits
    IF v_current_balance IS NULL OR v_current_balance < p_credit_amount THEN
        RETURN FALSE;
    END IF;

    -- Deduct credits
    v_new_balance := add_user_credits(
        p_user_id,
        -p_credit_amount,
        'spend',
        p_reference_type,
        p_reference_id,
        p_description
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate studio commission (15% flat rate)
CREATE OR REPLACE FUNCTION calculate_studio_commission(p_amount_cents INTEGER)
RETURNS TABLE(
    commission_cents INTEGER,
    instructor_payout_cents INTEGER,
    commission_rate DECIMAL
) AS $$
DECLARE
    v_rate DECIMAL := 0.15; -- 15% flat rate
BEGIN
    RETURN QUERY SELECT
        (p_amount_cents * v_rate)::INTEGER as commission_cents,
        (p_amount_cents * (1 - v_rate))::INTEGER as instructor_payout_cents,
        v_rate as commission_rate;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_credit_packs_updated_at BEFORE UPDATE ON credit_packs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_credits_updated_at BEFORE UPDATE ON user_credits
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_pack_purchases_updated_at BEFORE UPDATE ON credit_pack_purchases
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_studio_commission_settings_updated_at BEFORE UPDATE ON studio_commission_settings
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();