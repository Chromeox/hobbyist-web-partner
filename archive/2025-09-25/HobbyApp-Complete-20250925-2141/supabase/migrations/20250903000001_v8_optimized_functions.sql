-- V8-Optimized Database Functions
-- These functions work with the V8-optimized TypeScript code
-- for maximum performance

-- Function: Optimized booking creation with atomic credit deduction
CREATE OR REPLACE FUNCTION create_booking_optimized(p_booking jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_booking_id uuid;
    v_user_id uuid;
    v_credits_required int;
    v_current_balance int;
    v_class_capacity int;
    v_current_bookings int;
BEGIN
    -- Extract values once for efficiency
    v_booking_id := (p_booking->>'id')::uuid;
    v_user_id := (p_booking->>'user_id')::uuid;
    v_credits_required := CASE 
        WHEN p_booking->>'payment_method' = 'credit' 
        THEN (p_booking->>'credits_used')::int 
        ELSE 0 
    END;
    
    -- Start transaction
    BEGIN
        -- Check class availability (with row lock)
        SELECT capacity, 
               (SELECT COUNT(*) FROM bookings 
                WHERE class_id = (p_booking->>'class_id')::uuid 
                AND status = 'confirmed')
        INTO v_class_capacity, v_current_bookings
        FROM classes 
        WHERE id = (p_booking->>'class_id')::uuid
        FOR UPDATE;
        
        IF v_current_bookings >= v_class_capacity THEN
            RAISE EXCEPTION 'Class is full';
        END IF;
        
        -- Handle credit deduction if needed
        IF v_credits_required > 0 THEN
            -- Lock user's credit row and check balance
            SELECT balance INTO v_current_balance
            FROM user_credits
            WHERE user_id = v_user_id
            FOR UPDATE;
            
            IF v_current_balance < v_credits_required THEN
                RAISE EXCEPTION 'Insufficient credits';
            END IF;
            
            -- Deduct credits
            UPDATE user_credits
            SET balance = balance - v_credits_required,
                updated_at = now()
            WHERE user_id = v_user_id;
            
            -- Log credit transaction
            INSERT INTO credit_transactions (
                user_id, amount, type, balance_after, 
                reference_id, reference_type, description
            ) VALUES (
                v_user_id, 
                v_credits_required, 
                'debit', 
                v_current_balance - v_credits_required,
                v_booking_id, 
                'booking', 
                'Class booking'
            );
        END IF;
        
        -- Create booking
        INSERT INTO bookings (
            id, user_id, class_id, studio_id, status,
            payment_method, credits_used, amount_paid,
            cancelled_at, cancellation_reason, attended,
            notes, created_at, updated_at
        ) VALUES (
            v_booking_id,
            v_user_id,
            (p_booking->>'class_id')::uuid,
            (p_booking->>'studio_id')::uuid,
            'confirmed', -- Auto-confirm after payment
            p_booking->>'payment_method',
            v_credits_required,
            (p_booking->>'amount_paid')::decimal,
            NULL,
            NULL,
            false,
            p_booking->>'notes',
            now(),
            now()
        );
        
        -- Update class booking count
        UPDATE classes
        SET bookings_count = bookings_count + 1,
            updated_at = now()
        WHERE id = (p_booking->>'class_id')::uuid;
        
        -- Return the created booking as JSON
        RETURN to_jsonb(b.*) 
        FROM bookings b 
        WHERE b.id = v_booking_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback happens automatically
            RAISE;
    END;
END;
$$;

-- Function: Optimized booking cancellation with credit refund
CREATE OR REPLACE FUNCTION cancel_booking_optimized(
    p_booking_id uuid,
    p_reason text DEFAULT 'User requested'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_booking record;
    v_refund_credits boolean;
    v_credits_to_refund int;
BEGIN
    -- Get booking details with lock
    SELECT b.*, c.start_time
    INTO v_booking
    FROM bookings b
    JOIN classes c ON b.class_id = c.id
    WHERE b.id = p_booking_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking not found';
    END IF;
    
    IF v_booking.status != 'confirmed' THEN
        RAISE EXCEPTION 'Booking already cancelled or completed';
    END IF;
    
    -- Determine if credits should be refunded (24hr policy)
    v_refund_credits := v_booking.start_time > (now() + interval '24 hours');
    v_credits_to_refund := CASE 
        WHEN v_refund_credits AND v_booking.payment_method = 'credit' 
        THEN v_booking.credits_used 
        ELSE 0 
    END;
    
    -- Start cancellation
    BEGIN
        -- Update booking status
        UPDATE bookings
        SET status = 'cancelled',
            cancelled_at = now(),
            cancellation_reason = p_reason,
            updated_at = now()
        WHERE id = p_booking_id;
        
        -- Refund credits if applicable
        IF v_credits_to_refund > 0 THEN
            UPDATE user_credits
            SET balance = balance + v_credits_to_refund,
                updated_at = now()
            WHERE user_id = v_booking.user_id;
            
            -- Log credit refund
            INSERT INTO credit_transactions (
                user_id, amount, type, 
                reference_id, reference_type, description
            ) VALUES (
                v_booking.user_id,
                v_credits_to_refund,
                'credit',
                p_booking_id,
                'booking_cancellation',
                'Booking cancellation refund'
            );
        END IF;
        
        -- Update class booking count
        UPDATE classes
        SET bookings_count = bookings_count - 1,
            updated_at = now()
        WHERE id = v_booking.class_id;
        
        -- Check and promote from waitlist
        PERFORM promote_from_waitlist(v_booking.class_id);
        
        -- Return updated booking
        RETURN to_jsonb(b.*) 
        FROM bookings b 
        WHERE b.id = p_booking_id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
END;
$$;

-- Function: Get booking statistics with efficient aggregation
CREATE OR REPLACE FUNCTION get_booking_stats_optimized(
    p_studio_id uuid,
    p_start_date timestamptz,
    p_end_date timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
    v_stats jsonb;
BEGIN
    -- Single query for all stats (more efficient than multiple queries)
    SELECT jsonb_build_object(
        'total', COUNT(*),
        'confirmed', COUNT(*) FILTER (WHERE status = 'confirmed'),
        'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled'),
        'completed', COUNT(*) FILTER (WHERE status = 'completed'),
        'revenue', COALESCE(SUM(amount_paid) FILTER (WHERE status IN ('confirmed', 'completed')), 0),
        'credits', COALESCE(SUM(credits_used) FILTER (WHERE status IN ('confirmed', 'completed')), 0),
        'avg_credits_per_booking', COALESCE(AVG(credits_used) FILTER (WHERE credits_used > 0), 0),
        'cancellation_rate', 
            CASE 
                WHEN COUNT(*) > 0 
                THEN ROUND(COUNT(*) FILTER (WHERE status = 'cancelled')::numeric / COUNT(*) * 100, 2)
                ELSE 0
            END
    ) INTO v_stats
    FROM bookings
    WHERE studio_id = p_studio_id
        AND created_at >= p_start_date
        AND created_at <= p_end_date;
    
    RETURN v_stats;
END;
$$;

-- Function: Batch validate bookings for efficiency
CREATE OR REPLACE FUNCTION validate_bookings_batch(p_bookings jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
    v_result jsonb := '[]'::jsonb;
    v_booking jsonb;
    v_validation jsonb;
    v_user_credits int;
    v_class record;
    v_existing_booking uuid;
BEGIN
    -- Process each booking in the batch
    FOR v_booking IN SELECT * FROM jsonb_array_elements(p_bookings)
    LOOP
        -- Get class details
        SELECT * INTO v_class
        FROM classes
        WHERE id = (v_booking->>'class_id')::uuid;
        
        IF NOT FOUND THEN
            v_validation := jsonb_build_object(
                'booking_id', v_booking->>'id',
                'valid', false,
                'reason', 'Class not found'
            );
        ELSE
            -- Check for existing booking
            SELECT id INTO v_existing_booking
            FROM bookings
            WHERE user_id = (v_booking->>'user_id')::uuid
                AND class_id = (v_booking->>'class_id')::uuid
                AND status = 'confirmed'
            LIMIT 1;
            
            IF FOUND THEN
                v_validation := jsonb_build_object(
                    'booking_id', v_booking->>'id',
                    'valid', false,
                    'reason', 'Already booked'
                );
            ELSIF v_class.bookings_count >= v_class.capacity THEN
                v_validation := jsonb_build_object(
                    'booking_id', v_booking->>'id',
                    'valid', false,
                    'reason', 'Class full'
                );
            ELSIF v_booking->>'payment_method' = 'credit' THEN
                -- Check credits
                SELECT balance INTO v_user_credits
                FROM user_credits
                WHERE user_id = (v_booking->>'user_id')::uuid;
                
                IF v_user_credits < (v_booking->>'credits_required')::int THEN
                    v_validation := jsonb_build_object(
                        'booking_id', v_booking->>'id',
                        'valid', false,
                        'reason', 'Insufficient credits'
                    );
                ELSE
                    v_validation := jsonb_build_object(
                        'booking_id', v_booking->>'id',
                        'valid', true
                    );
                END IF;
            ELSE
                v_validation := jsonb_build_object(
                    'booking_id', v_booking->>'id',
                    'valid', true
                );
            END IF;
        END IF;
        
        v_result := v_result || v_validation;
    END LOOP;
    
    RETURN v_result;
END;
$$;

-- Function: Promote from waitlist
CREATE OR REPLACE FUNCTION promote_from_waitlist(p_class_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_waitlist_user record;
    v_available_spots int;
BEGIN
    -- Calculate available spots
    SELECT capacity - bookings_count INTO v_available_spots
    FROM classes
    WHERE id = p_class_id;
    
    IF v_available_spots <= 0 THEN
        RETURN;
    END IF;
    
    -- Get first person from waitlist
    SELECT * INTO v_waitlist_user
    FROM waitlist
    WHERE class_id = p_class_id
        AND status = 'waiting'
    ORDER BY created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED; -- Skip if being processed by another transaction
    
    IF FOUND THEN
        -- Update waitlist entry
        UPDATE waitlist
        SET status = 'promoted',
            promoted_at = now()
        WHERE id = v_waitlist_user.id;
        
        -- Send notification (via trigger or external service)
        INSERT INTO notifications (
            user_id,
            type,
            title,
            message,
            data
        ) VALUES (
            v_waitlist_user.user_id,
            'waitlist_promotion',
            'You''re off the waitlist!',
            'A spot has opened up in your waitlisted class.',
            jsonb_build_object('class_id', p_class_id)
        );
    END IF;
END;
$$;

-- Create indexes for V8-optimized queries
CREATE INDEX IF NOT EXISTS idx_bookings_composite 
ON bookings(studio_id, status, created_at DESC) 
WHERE status IN ('confirmed', 'completed');

CREATE INDEX IF NOT EXISTS idx_classes_availability 
ON classes(id, capacity, bookings_count) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_credits_lookup 
ON user_credits(user_id, balance);

CREATE INDEX IF NOT EXISTS idx_credit_transactions_user 
ON credit_transactions(user_id, created_at DESC);

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_booking_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_booking_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION get_booking_stats_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION validate_bookings_batch TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION create_booking_optimized IS 'V8-optimized booking creation with atomic credit handling';
COMMENT ON FUNCTION cancel_booking_optimized IS 'V8-optimized booking cancellation with automatic refunds';
COMMENT ON FUNCTION get_booking_stats_optimized IS 'Efficient aggregation for booking statistics';
COMMENT ON FUNCTION validate_bookings_batch IS 'Batch validation for multiple bookings';