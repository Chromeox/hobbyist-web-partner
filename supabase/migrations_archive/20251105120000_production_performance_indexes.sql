-- Production Performance Optimization
-- Comprehensive indexing strategy for HobbyApp queries
-- Date: 2025-11-05

-- ============================================
-- PART 1: CORE PERFORMANCE INDEXES
-- ============================================

-- Studios table indexes
CREATE INDEX IF NOT EXISTS idx_studios_city_active ON studios(city, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_studios_name_gin ON studios USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_studios_location ON studios(city, province, postal_code);

-- Instructors table indexes
CREATE INDEX IF NOT EXISTS idx_instructors_studio_active ON instructors(studio_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_instructors_rating ON instructors(rating DESC) WHERE rating > 0;
CREATE INDEX IF NOT EXISTS idx_instructors_specialties_gin ON instructors USING gin(specialties);
CREATE INDEX IF NOT EXISTS idx_instructors_name_gin ON instructors USING gin(to_tsvector('english', name));

-- Classes table indexes
CREATE INDEX IF NOT EXISTS idx_classes_studio_active ON classes(studio_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_classes_category ON classes(category);
CREATE INDEX IF NOT EXISTS idx_classes_difficulty ON classes(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_classes_price_range ON classes(price);
CREATE INDEX IF NOT EXISTS idx_classes_search_gin ON classes USING gin(to_tsvector('english', name || ' ' || description || ' ' || category));
CREATE INDEX IF NOT EXISTS idx_classes_instructor_active ON classes(instructor_id, is_active) WHERE is_active = true;

-- Class schedules table indexes
CREATE INDEX IF NOT EXISTS idx_class_schedules_time_range ON class_schedules(start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_class_schedules_available ON class_schedules(start_time) WHERE spots_available > 0 AND is_cancelled = false;
CREATE INDEX IF NOT EXISTS idx_class_schedules_class_future ON class_schedules(class_id, start_time);
CREATE INDEX IF NOT EXISTS idx_class_schedules_future_spots ON class_schedules(start_time, spots_available) WHERE spots_available > 0;

-- Bookings table indexes  
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON bookings(user_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_schedule_status ON bookings(class_schedule_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_created_desc ON bookings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_user_upcoming ON bookings(user_id, created_at) WHERE status IN ('confirmed', 'waitlisted');

-- User credits table indexes
CREATE INDEX IF NOT EXISTS idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_user_credits_tier ON user_credits(loyalty_tier);

-- ============================================
-- PART 2: SEARCH OPTIMIZATION INDEXES
-- ============================================

-- Full-text search indexes for discovery
CREATE INDEX IF NOT EXISTS idx_studios_full_text ON studios USING gin(
    to_tsvector('english', 
        coalesce(name, '') || ' ' || 
        coalesce(address, '') || ' ' || 
        coalesce(city, '')
    )
);

CREATE INDEX IF NOT EXISTS idx_classes_full_text ON classes USING gin(
    to_tsvector('english', 
        coalesce(name, '') || ' ' || 
        coalesce(description, '') || ' ' || 
        coalesce(category, '')
    )
);

-- ============================================
-- PART 3: ANALYTICS INDEXES
-- ============================================

-- Revenue and booking analytics
CREATE INDEX IF NOT EXISTS idx_bookings_analytics_date ON bookings(created_at, status, credits_used) WHERE status = 'confirmed';
CREATE INDEX IF NOT EXISTS idx_bookings_studio_analytics ON bookings(created_at, status) WHERE status = 'confirmed';

-- User behavior analytics
CREATE INDEX IF NOT EXISTS idx_bookings_user_behavior ON bookings(user_id, created_at, status);
CREATE INDEX IF NOT EXISTS idx_class_schedules_capacity ON class_schedules(class_id, spots_total, spots_available);

-- ============================================
-- PART 4: CONSTRAINT INDEXES FOR PERFORMANCE
-- ============================================

-- Unique constraint indexes that also improve performance
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_credits_unique_user ON user_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_studios_email_unique ON studios(email) WHERE email IS NOT NULL;

-- ============================================
-- PART 5: PARTIAL INDEXES FOR COMMON QUERIES
-- ============================================

-- Active content only
CREATE INDEX IF NOT EXISTS idx_active_studios_city ON studios(city) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_active_classes_category ON classes(category) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_future_schedules ON class_schedules(start_time, class_id) WHERE is_cancelled = false;

-- Available spots only
CREATE INDEX IF NOT EXISTS idx_available_schedules_time ON class_schedules(start_time) 
    WHERE spots_available > 0 AND is_cancelled = false;

-- ============================================
-- PART 6: COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================

-- Studio discovery with location and active status
CREATE INDEX IF NOT EXISTS idx_studios_discovery ON studios(is_active, city, name) WHERE is_active = true;

-- Class discovery with multiple filters
CREATE INDEX IF NOT EXISTS idx_classes_discovery ON classes(is_active, category, difficulty_level, price) WHERE is_active = true;

-- Booking history with status
CREATE INDEX IF NOT EXISTS idx_bookings_history ON bookings(user_id, created_at DESC, status);

-- Instructor performance
CREATE INDEX IF NOT EXISTS idx_instructors_performance ON instructors(studio_id, is_active, rating DESC, total_classes DESC) WHERE is_active = true;

-- ============================================
-- PART 7: VACUUM AND ANALYZE
-- ============================================

-- Update table statistics for query planner
ANALYZE studios;
ANALYZE instructors;  
ANALYZE classes;
ANALYZE class_schedules;
ANALYZE bookings;
ANALYZE user_credits;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify critical indexes exist
DO $$
BEGIN
    -- Check if key performance indexes exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_classes_search_gin'
    ) THEN
        RAISE EXCEPTION 'Critical search index missing: idx_classes_search_gin';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_class_schedules_available'
    ) THEN
        RAISE EXCEPTION 'Critical availability index missing: idx_class_schedules_available';
    END IF;
    
    RAISE NOTICE 'All performance indexes created successfully';
END $$;