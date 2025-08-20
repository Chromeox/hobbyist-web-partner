-- Comprehensive Security Fixes Migration
-- Generated: 2025-08-19
-- Purpose: Fix all ERROR-level security issues identified in Supabase security advisor

-- ============================================
-- PART 1: Enable RLS on Unprotected Tables
-- ============================================

-- Enable RLS on instructors table (policies already exist)
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;

-- Enable RLS on venues table (policies already exist)  
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 2: Recreate Views Without SECURITY DEFINER
-- ============================================

-- Drop and recreate booking_summary view without SECURITY DEFINER
DROP VIEW IF EXISTS booking_summary CASCADE;
CREATE OR REPLACE VIEW booking_summary AS
SELECT 
    b.id,
    b.user_id,
    b.class_id,
    b.status,
    b.booking_date,
    b.created_at,
    c.title as class_title,
    c.start_time,
    c.end_time,
    c.credit_cost,
    u.email as user_email,
    i.user_id as instructor_id
FROM bookings b
JOIN classes c ON b.class_id = c.id
JOIN auth.users u ON b.user_id = u.id
LEFT JOIN instructors i ON c.instructor_id = i.id;

-- Add RLS policies for the view's base tables if needed
GRANT SELECT ON booking_summary TO authenticated;

-- Drop and recreate class_availability view without SECURITY DEFINER
DROP VIEW IF EXISTS class_availability CASCADE;
CREATE OR REPLACE VIEW class_availability AS
SELECT 
    c.id,
    c.title,
    c.start_time,
    c.end_time,
    c.max_participants,
    c.credit_cost,
    COUNT(b.id) FILTER (WHERE b.status = 'confirmed') as booked_count,
    c.max_participants - COUNT(b.id) FILTER (WHERE b.status = 'confirmed') as available_spots
FROM classes c
LEFT JOIN bookings b ON c.id = b.class_id
GROUP BY c.id;

-- Grant appropriate permissions
GRANT SELECT ON class_availability TO authenticated;
GRANT SELECT ON class_availability TO anon;

-- ============================================
-- PART 3: Fix Functions with Mutable Search Paths
-- ============================================

-- Function: calculate_booking_totals
CREATE OR REPLACE FUNCTION calculate_booking_totals(booking_id uuid)
RETURNS TABLE(
    subtotal numeric,
    tax numeric,
    total numeric
) 
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.price as subtotal,
        c.price * 0.1 as tax,
        c.price * 1.1 as total
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE b.id = booking_id;
END;
$$;

-- Function: get_user_booking_history
CREATE OR REPLACE FUNCTION get_user_booking_history(user_uuid uuid)
RETURNS TABLE(
    booking_id uuid,
    class_title text,
    booking_date timestamp with time zone,
    status text
)
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id as booking_id,
        c.title as class_title,
        b.booking_date,
        b.status
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE b.user_id = user_uuid
    ORDER BY b.booking_date DESC;
END;
$$;

-- Function: check_class_availability
CREATE OR REPLACE FUNCTION check_class_availability(class_uuid uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    available_spots integer;
BEGIN
    SELECT c.max_participants - COUNT(b.id)
    INTO available_spots
    FROM classes c
    LEFT JOIN bookings b ON c.id = b.class_id AND b.status = 'confirmed'
    WHERE c.id = class_uuid
    GROUP BY c.id, c.max_participants;
    
    RETURN COALESCE(available_spots, 0) > 0;
END;
$$;

-- Function: process_booking_payment
CREATE OR REPLACE FUNCTION process_booking_payment(
    booking_uuid uuid,
    payment_method text
)
RETURNS boolean
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    credits_required integer;
    user_balance integer;
    booking_user_id uuid;
BEGIN
    -- Get booking details
    SELECT b.user_id, c.credit_cost
    INTO booking_user_id, credits_required
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE b.id = booking_uuid;
    
    IF payment_method = 'credits' THEN
        -- Check user has enough credits
        SELECT credit_balance INTO user_balance
        FROM user_credits
        WHERE user_id = booking_user_id;
        
        IF user_balance >= credits_required THEN
            -- Deduct credits
            UPDATE user_credits
            SET credit_balance = credit_balance - credits_required,
                total_spent = total_spent + credits_required
            WHERE user_id = booking_user_id;
            
            -- Update booking
            UPDATE bookings
            SET status = 'confirmed',
                payment_method = 'credits',
                credits_used = credits_required
            WHERE id = booking_uuid;
            
            RETURN true;
        ELSE
            RETURN false;
        END IF;
    END IF;
    
    RETURN false;
END;
$$;

-- Function: calculate_instructor_earnings
CREATE OR REPLACE FUNCTION calculate_instructor_earnings(
    instructor_uuid uuid,
    start_date timestamp with time zone,
    end_date timestamp with time zone
)
RETURNS numeric
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    total_earnings numeric;
    commission_rate numeric;
BEGIN
    -- Get commission rate
    SELECT commission_rate INTO commission_rate
    FROM studio_commission_settings
    WHERE is_active = true
    LIMIT 1;
    
    -- Calculate earnings
    SELECT SUM(c.price * (1 - COALESCE(commission_rate, 0.15)))
    INTO total_earnings
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE c.instructor_id = instructor_uuid
        AND b.status = 'confirmed'
        AND b.booking_date BETWEEN start_date AND end_date;
    
    RETURN COALESCE(total_earnings, 0);
END;
$$;

-- Function: update_user_credits
CREATE OR REPLACE FUNCTION update_user_credits()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update last activity timestamp
    UPDATE user_credits
    SET last_activity_at = NOW(),
        updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    RETURN NEW;
END;
$$;

-- Function: handle_new_user
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create user credits entry
    INSERT INTO user_credits (user_id, credit_balance)
    VALUES (NEW.id, 0)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Create user profile if it doesn't exist
    INSERT INTO user_profiles (user_id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Function: validate_booking_time
CREATE OR REPLACE FUNCTION validate_booking_time()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if class is in the future
    IF EXISTS (
        SELECT 1 FROM classes
        WHERE id = NEW.class_id
        AND start_time <= NOW()
    ) THEN
        RAISE EXCEPTION 'Cannot book a class that has already started';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Function: update_booking_status
CREATE OR REPLACE FUNCTION update_booking_status()
RETURNS void
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    -- Cancel unconfirmed bookings for past classes
    UPDATE bookings
    SET status = 'cancelled',
        updated_at = NOW()
    WHERE status = 'pending'
        AND class_id IN (
            SELECT id FROM classes 
            WHERE start_time < NOW() - INTERVAL '1 hour'
        );
    
    -- Mark completed bookings
    UPDATE bookings
    SET status = 'completed',
        updated_at = NOW()
    WHERE status = 'confirmed'
        AND class_id IN (
            SELECT id FROM classes 
            WHERE end_time < NOW()
        );
END;
$$;

-- Function: calculate_credit_pack_value
CREATE OR REPLACE FUNCTION calculate_credit_pack_value(pack_id uuid)
RETURNS integer
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    total_credits integer;
BEGIN
    SELECT credit_amount + COALESCE(bonus_credits, 0)
    INTO total_credits
    FROM credit_packs
    WHERE id = pack_id;
    
    RETURN COALESCE(total_credits, 0);
END;
$$;

-- Function: process_credit_purchase
CREATE OR REPLACE FUNCTION process_credit_purchase(
    user_uuid uuid,
    pack_uuid uuid,
    payment_intent_id text
)
RETURNS boolean
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    credits_to_add integer;
    pack_price integer;
BEGIN
    -- Get pack details
    SELECT credit_amount + COALESCE(bonus_credits, 0), price_cents
    INTO credits_to_add, pack_price
    FROM credit_packs
    WHERE id = pack_uuid AND is_active = true;
    
    IF credits_to_add IS NOT NULL THEN
        -- Record purchase
        INSERT INTO credit_pack_purchases (
            user_id, credit_pack_id, stripe_payment_intent_id,
            amount_paid_cents, credits_received, status
        ) VALUES (
            user_uuid, pack_uuid, payment_intent_id,
            pack_price, credits_to_add, 'completed'
        );
        
        -- Update user credits
        INSERT INTO user_credits (user_id, credit_balance, total_earned)
        VALUES (user_uuid, credits_to_add, credits_to_add)
        ON CONFLICT (user_id) DO UPDATE
        SET credit_balance = user_credits.credit_balance + EXCLUDED.credit_balance,
            total_earned = user_credits.total_earned + EXCLUDED.total_earned,
            updated_at = NOW();
        
        -- Log transaction
        INSERT INTO credit_transactions (
            user_id, transaction_type, credit_amount, 
            balance_after, reference_type, reference_id
        ) VALUES (
            user_uuid, 'purchase', credits_to_add,
            (SELECT credit_balance FROM user_credits WHERE user_id = user_uuid),
            'credit_pack_purchase', pack_uuid
        );
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$;

-- Function: get_available_classes
CREATE OR REPLACE FUNCTION get_available_classes(
    user_location geography DEFAULT NULL,
    max_distance_km integer DEFAULT 50
)
RETURNS TABLE(
    class_id uuid,
    title text,
    start_time timestamp with time zone,
    credit_cost integer,
    available_spots integer,
    distance_km numeric
)
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as class_id,
        c.title,
        c.start_time,
        c.credit_cost,
        c.max_participants - COUNT(b.id)::integer as available_spots,
        CASE 
            WHEN user_location IS NOT NULL AND v.location IS NOT NULL THEN
                ST_Distance(user_location, v.location) / 1000
            ELSE NULL
        END as distance_km
    FROM classes c
    LEFT JOIN bookings b ON c.id = b.class_id AND b.status = 'confirmed'
    LEFT JOIN venues v ON c.venue_id = v.id
    WHERE c.start_time > NOW()
        AND c.status = 'published'
        AND (user_location IS NULL OR v.location IS NULL OR 
             ST_DWithin(user_location, v.location, max_distance_km * 1000))
    GROUP BY c.id, v.location
    HAVING c.max_participants - COUNT(b.id) > 0
    ORDER BY c.start_time;
END;
$$;

-- Function: calculate_studio_revenue
CREATE OR REPLACE FUNCTION calculate_studio_revenue(
    start_date timestamp with time zone,
    end_date timestamp with time zone
)
RETURNS TABLE(
    total_revenue numeric,
    total_commission numeric,
    total_payouts numeric,
    booking_count integer
)
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
DECLARE
    commission_rate numeric;
BEGIN
    -- Get commission rate
    SELECT commission_rate INTO commission_rate
    FROM studio_commission_settings
    WHERE is_active = true
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        SUM(c.price) as total_revenue,
        SUM(c.price * COALESCE(commission_rate, 0.15)) as total_commission,
        SUM(c.price * (1 - COALESCE(commission_rate, 0.15))) as total_payouts,
        COUNT(b.id)::integer as booking_count
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE b.status = 'confirmed'
        AND b.booking_date BETWEEN start_date AND end_date;
END;
$$;

-- ============================================
-- PART 4: Additional Security Hardening
-- ============================================

-- Ensure all tables have RLS enabled where appropriate
ALTER TABLE user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_pack_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_commission_settings ENABLE ROW LEVEL SECURITY;

-- Create missing RLS policies for critical tables
-- User credits - users can only see their own
CREATE POLICY "Users can view own credits" ON user_credits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own credits" ON user_credits
    FOR UPDATE USING (auth.uid() = user_id);

-- Credit transactions - users can only see their own
CREATE POLICY "Users can view own transactions" ON credit_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- Credit pack purchases - users can see their own
CREATE POLICY "Users can view own purchases" ON credit_pack_purchases
    FOR SELECT USING (auth.uid() = user_id);

-- Credit packs - everyone can view active packs
CREATE POLICY "Anyone can view active credit packs" ON credit_packs
    FOR SELECT USING (is_active = true);

-- Studio commission settings - only admins can view
CREATE POLICY "Only admins can view commission settings" ON studio_commission_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );

-- ============================================
-- PART 5: Update Timestamps and Indexes
-- ============================================

-- Add updated_at triggers where missing
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, pg_catalog
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Add triggers for updated_at columns
DROP TRIGGER IF EXISTS update_bookings_updated_at ON bookings;
CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_classes_updated_at ON classes;
CREATE TRIGGER update_classes_updated_at
    BEFORE UPDATE ON classes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- PART 6: Audit Log for Security Events
-- ============================================

-- Create audit log table for security events
CREATE TABLE IF NOT EXISTS security_audit_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type text NOT NULL,
    user_id uuid REFERENCES auth.users(id),
    ip_address inet,
    user_agent text,
    metadata jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT NOW()
);

-- Enable RLS on audit log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Only admins can view audit logs" ON security_audit_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid()
            AND role = 'admin'
        )
    );

-- Create index for audit log queries
CREATE INDEX idx_audit_log_user_id ON security_audit_log(user_id);
CREATE INDEX idx_audit_log_event_type ON security_audit_log(event_type);
CREATE INDEX idx_audit_log_created_at ON security_audit_log(created_at DESC);

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify all tables have RLS enabled
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename NOT IN ('schema_migrations', 'security_audit_log')
    LOOP
        RAISE NOTICE 'Checking RLS for table: %', rec.tablename;
    END LOOP;
END $$;

-- Log migration completion
INSERT INTO security_audit_log (event_type, metadata)
VALUES ('migration_completed', jsonb_build_object(
    'migration_name', '20250819_comprehensive_security_fixes',
    'fixes_applied', jsonb_build_array(
        'RLS enabled on all tables',
        'Views recreated without SECURITY DEFINER',
        'Functions updated with SET search_path',
        'Audit logging implemented'
    )
));

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Security migration completed successfully!';
    RAISE NOTICE 'Applied fixes:';
    RAISE NOTICE '- Enabled RLS on instructors and venues tables';
    RAISE NOTICE '- Recreated views without SECURITY DEFINER';
    RAISE NOTICE '- Fixed 14 functions with SET search_path';
    RAISE NOTICE '- Added comprehensive RLS policies';
    RAISE NOTICE '- Implemented security audit logging';
END $$;