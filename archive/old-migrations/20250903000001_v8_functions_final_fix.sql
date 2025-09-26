-- V8-Optimized Database Functions (FINAL FIX)
-- Fully adapted to actual database schema

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
    v_credits_required decimal(3,1);
    v_current_balance decimal(5,1);
    v_spots_available int;
    v_current_bookings int;
BEGIN
    -- Extract values once for efficiency
    v_booking_id := (p_booking->>'id')::uuid;
    v_user_id := (p_booking->>'user_id')::uuid;
    v_credits_required := CASE
        WHEN p_booking->>'payment_method' = 'credits'
        THEN (p_booking->>'credits_used')::decimal
        ELSE 0
    END;

    -- Start transaction
    BEGIN
        -- Check class availability using actual schema
        SELECT cs.spots_available,
               (SELECT COUNT(*) FROM bookings
                WHERE class_schedule_id = (p_booking->>'class_schedule_id')::uuid
                AND status = 'confirmed')
        INTO v_spots_available, v_current_bookings
        FROM class_schedules cs
        WHERE cs.id = (p_booking->>'class_schedule_id')::uuid
        FOR UPDATE;

        IF v_current_bookings >= v_spots_available THEN
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
                RAISE EXCEPTION 'Insufficient credit balance';
            END IF;

            -- Deduct credits atomically
            UPDATE user_credits
            SET balance = balance - v_credits_required,
                updated_at = NOW()
            WHERE user_id = v_user_id;

            -- Log credit transaction
            INSERT INTO credit_transactions (
                user_id, type, amount, balance_after,
                booking_id, description, created_at
            ) VALUES (
                v_user_id,
                'debit',
                v_credits_required,
                v_current_balance - v_credits_required,
                v_booking_id,
                'Booking credit deduction',
                NOW()
            );
        END IF;

        -- Create booking using actual schema
        INSERT INTO bookings (
            id, user_id, class_schedule_id, status,
            payment_method, credits_used,
            cancelled_at, cancellation_reason,
            created_at, updated_at
        ) VALUES (
            v_booking_id,
            v_user_id,
            (p_booking->>'class_schedule_id')::uuid,
            'confirmed',
            p_booking->>'payment_method',
            v_credits_required,
            NULL,
            NULL,
            NOW(),
            NOW()
        );

        RETURN jsonb_build_object(
            'success', true,
            'booking_id', v_booking_id,
            'credits_used', v_credits_required,
            'new_balance', v_current_balance - v_credits_required
        );

    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Booking failed: %', SQLERRM;
    END;
END;
$$;

-- Function: Get analytics using actual schema
CREATE OR REPLACE FUNCTION get_studio_analytics_optimized(
    p_date_from date DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_date_to date DEFAULT CURRENT_DATE
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'total_bookings', COUNT(b.id),
        'confirmed_bookings', COUNT(b.id) FILTER (WHERE b.status = 'confirmed'),
        'cancelled_bookings', COUNT(b.id) FILTER (WHERE b.status = 'cancelled'),
        'revenue', COALESCE(SUM(ct.amount) FILTER (WHERE ct.type = 'debit'), 0),
        'credits_used', COALESCE(SUM(b.credits_used), 0),
        'popular_classes', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'class_name', c.name,
                    'booking_count', booking_counts.cnt
                )
            )
            FROM (
                SELECT cs.class_id, COUNT(*) as cnt
                FROM bookings b
                JOIN class_schedules cs ON b.class_schedule_id = cs.id
                WHERE b.created_at::date BETWEEN p_date_from AND p_date_to
                GROUP BY cs.class_id
                ORDER BY cnt DESC
                LIMIT 5
            ) booking_counts
            JOIN classes c ON c.id = booking_counts.class_id
        )
    )
    INTO v_result
    FROM bookings b
    LEFT JOIN credit_transactions ct ON b.id = ct.booking_id
    WHERE b.created_at::date BETWEEN p_date_from AND p_date_to;

    RETURN v_result;
END;
$$;

-- Create optimized indexes using correct column names
CREATE INDEX IF NOT EXISTS idx_bookings_schedule_status
ON bookings(class_schedule_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_bookings_user_status
ON bookings(user_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_class_schedules_class_time
ON class_schedules(class_id, start_time);

-- Grant permissions
GRANT EXECUTE ON FUNCTION create_booking_optimized(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION get_studio_analytics_optimized(date, date) TO authenticated;

-- Verification
DO $$
BEGIN
    RAISE NOTICE 'V8 Optimized Functions (Final Fix): All functions created successfully!';
    RAISE NOTICE 'Schema corrections applied:';
    RAISE NOTICE '- Uses class_schedule_id (not class_id)';
    RAISE NOTICE '- Uses spots_available (not capacity)';
    RAISE NOTICE '- Uses start_time (not scheduled_date)';
    RAISE NOTICE '- Removed all non-existent column references';
END $$;