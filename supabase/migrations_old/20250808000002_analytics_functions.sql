-- Analytics Functions for Studio Revenue Reporting
-- Provides aggregated data for commission summaries and revenue reporting

-- Function to get commission summary grouped by time period
CREATE OR REPLACE FUNCTION get_commission_summary(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_group_by TEXT DEFAULT 'day',
    p_instructor_id UUID DEFAULT NULL
)
RETURNS TABLE(
    period TIMESTAMPTZ,
    booking_count BIGINT,
    total_revenue BIGINT,
    total_commission BIGINT,
    total_payouts BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE_TRUNC(p_group_by, b.created_at) as period,
        COUNT(b.id) as booking_count,
        COALESCE(SUM(b.amount), 0)::BIGINT as total_revenue,
        COALESCE(SUM(b.commission_amount), 0)::BIGINT as total_commission,
        COALESCE(SUM(b.instructor_payout), 0)::BIGINT as total_payouts
    FROM bookings b
    INNER JOIN classes c ON b.class_id = c.id
    INNER JOIN instructor_profiles ip ON c.instructor_id = ip.id
    WHERE 
        b.created_at >= p_start_date 
        AND b.created_at <= p_end_date
        AND b.payment_status = 'succeeded'
        AND (p_instructor_id IS NULL OR ip.user_id = p_instructor_id)
    GROUP BY DATE_TRUNC(p_group_by, b.created_at)
    ORDER BY DATE_TRUNC(p_group_by, b.created_at);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get instructor performance metrics
CREATE OR REPLACE FUNCTION get_instructor_performance(
    p_instructor_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE(
    total_classes INTEGER,
    total_bookings BIGINT,
    total_revenue BIGINT,
    total_commission BIGINT,
    total_payout BIGINT,
    average_class_size DECIMAL,
    credit_bookings BIGINT,
    card_bookings BIGINT,
    cancellation_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT c.id)::INTEGER as total_classes,
        COUNT(b.id) as total_bookings,
        COALESCE(SUM(b.amount), 0)::BIGINT as total_revenue,
        COALESCE(SUM(b.commission_amount), 0)::BIGINT as total_commission,
        COALESCE(SUM(b.instructor_payout), 0)::BIGINT as total_payout,
        CASE 
            WHEN COUNT(DISTINCT c.id) > 0 
            THEN ROUND(COUNT(b.id)::DECIMAL / COUNT(DISTINCT c.id), 2)
            ELSE 0
        END as average_class_size,
        COUNT(CASE WHEN b.payment_method = 'credits' THEN 1 END) as credit_bookings,
        COUNT(CASE WHEN b.payment_method != 'credits' THEN 1 END) as card_bookings,
        CASE 
            WHEN COUNT(b.id) > 0 
            THEN ROUND((COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END)::DECIMAL / COUNT(b.id)) * 100, 2)
            ELSE 0
        END as cancellation_rate
    FROM classes c
    LEFT JOIN bookings b ON c.id = b.class_id AND b.created_at >= p_start_date AND b.created_at <= p_end_date
    INNER JOIN instructor_profiles ip ON c.instructor_id = ip.id
    WHERE 
        ip.user_id = p_instructor_id
        AND c.created_at >= p_start_date 
        AND c.created_at <= p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get credit usage analytics
CREATE OR REPLACE FUNCTION get_credit_usage_analytics(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE(
    total_credit_packs_sold BIGINT,
    total_credits_purchased BIGINT,
    total_credits_spent BIGINT,
    total_credit_pack_revenue BIGINT,
    active_credit_users BIGINT,
    average_credits_per_user DECIMAL,
    credit_utilization_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(credit_packs.total_packs_sold, 0) as total_credit_packs_sold,
        COALESCE(credit_packs.total_credits_purchased, 0) as total_credits_purchased,
        COALESCE(credit_usage.total_credits_spent, 0) as total_credits_spent,
        COALESCE(credit_packs.total_revenue, 0) as total_credit_pack_revenue,
        COALESCE(active_users.active_count, 0) as active_credit_users,
        CASE 
            WHEN active_users.active_count > 0 
            THEN ROUND(credit_packs.total_credits_purchased::DECIMAL / active_users.active_count, 2)
            ELSE 0
        END as average_credits_per_user,
        CASE 
            WHEN credit_packs.total_credits_purchased > 0 
            THEN ROUND((credit_usage.total_credits_spent::DECIMAL / credit_packs.total_credits_purchased) * 100, 2)
            ELSE 0
        END as credit_utilization_rate
    FROM (
        SELECT 1 as dummy
    ) d
    LEFT JOIN (
        SELECT 
            COUNT(*)::BIGINT as total_packs_sold,
            SUM(credits_received + bonus_credits)::BIGINT as total_credits_purchased,
            SUM(amount_paid_cents)::BIGINT as total_revenue
        FROM credit_pack_purchases 
        WHERE status = 'completed' 
        AND created_at >= p_start_date 
        AND created_at <= p_end_date
    ) credit_packs ON true
    LEFT JOIN (
        SELECT 
            SUM(ABS(credit_amount))::BIGINT as total_credits_spent
        FROM credit_transactions 
        WHERE transaction_type = 'spend'
        AND created_at >= p_start_date 
        AND created_at <= p_end_date
    ) credit_usage ON true
    LEFT JOIN (
        SELECT 
            COUNT(DISTINCT user_id)::BIGINT as active_count
        FROM user_credits 
        WHERE credit_balance > 0
        AND last_activity_at >= p_start_date
    ) active_users ON true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get top performing classes by revenue
CREATE OR REPLACE FUNCTION get_top_classes_by_revenue(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    class_id UUID,
    class_title VARCHAR,
    instructor_name TEXT,
    total_bookings BIGINT,
    total_revenue BIGINT,
    total_commission BIGINT,
    average_participants DECIMAL,
    credit_bookings BIGINT,
    card_bookings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as class_id,
        c.title as class_title,
        COALESCE(ip.business_name, up.first_name || ' ' || up.last_name) as instructor_name,
        COUNT(b.id) as total_bookings,
        COALESCE(SUM(b.amount), 0)::BIGINT as total_revenue,
        COALESCE(SUM(b.commission_amount), 0)::BIGINT as total_commission,
        CASE 
            WHEN COUNT(b.id) > 0 
            THEN ROUND(AVG(array_length(b.attendees, 1)), 2)
            ELSE 0
        END as average_participants,
        COUNT(CASE WHEN b.payment_method = 'credits' THEN 1 END) as credit_bookings,
        COUNT(CASE WHEN b.payment_method != 'credits' THEN 1 END) as card_bookings
    FROM classes c
    INNER JOIN instructor_profiles ip ON c.instructor_id = ip.id
    INNER JOIN user_profiles up ON ip.user_id = up.user_id
    LEFT JOIN bookings b ON c.id = b.class_id 
        AND b.created_at >= p_start_date 
        AND b.created_at <= p_end_date
        AND b.payment_status = 'succeeded'
    GROUP BY c.id, c.title, ip.business_name, up.first_name, up.last_name
    ORDER BY total_revenue DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes to optimize analytics queries
CREATE INDEX IF NOT EXISTS idx_bookings_created_at_payment_status ON bookings(created_at, payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_class_payment_method ON bookings(class_id, payment_method);
CREATE INDEX IF NOT EXISTS idx_credit_pack_purchases_created_status ON credit_pack_purchases(created_at, status);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_created_type ON credit_transactions(created_at, transaction_type);
CREATE INDEX IF NOT EXISTS idx_user_credits_last_activity ON user_credits(last_activity_at);

-- Grant permissions for analytics functions
GRANT EXECUTE ON FUNCTION get_commission_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_instructor_performance TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_usage_analytics TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_classes_by_revenue TO authenticated;