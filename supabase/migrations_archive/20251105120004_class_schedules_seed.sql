-- Class Schedules Seed Data
-- Generate realistic schedules for all classes over the next 3 months
-- Date: 2025-11-05

-- ============================================
-- PART 1: HELPER FUNCTION FOR SCHEDULE GENERATION
-- ============================================

-- Create a temporary function to generate realistic schedules
CREATE OR REPLACE FUNCTION generate_class_schedules()
RETURNS void AS $$
DECLARE
    class_record RECORD;
    schedule_date DATE;
    schedule_time TIME;
    end_time TIMESTAMPTZ;
    start_time TIMESTAMPTZ;
    days_of_week INTEGER[];
    day_of_week INTEGER;
    week_offset INTEGER;
BEGIN
    -- Clear existing schedules to prevent duplicates
    DELETE FROM class_schedules;
    
    -- Loop through all active classes
    FOR class_record IN SELECT id, duration, max_participants, category FROM classes WHERE is_active = true
    LOOP
        -- Determine schedule pattern based on class category
        CASE 
            WHEN class_record.category IN ('Yoga', 'Dance') THEN
                -- Yoga and Dance: Multiple times per week
                days_of_week := ARRAY[1, 3, 5, 7]; -- Mon, Wed, Fri, Sun
                schedule_time := '18:30'::TIME; -- Evening classes
            WHEN class_record.category IN ('Cooking') THEN
                -- Cooking: Weekend focused
                days_of_week := ARRAY[6, 7]; -- Sat, Sun
                schedule_time := CASE WHEN random() > 0.5 THEN '14:00'::TIME ELSE '10:30'::TIME END;
            WHEN class_record.category IN ('Ceramics', 'Arts', 'Woodworking') THEN
                -- Creative arts: Mixed schedule
                days_of_week := ARRAY[2, 4, 6]; -- Tue, Thu, Sat
                schedule_time := CASE 
                    WHEN random() > 0.6 THEN '19:00'::TIME 
                    WHEN random() > 0.3 THEN '14:00'::TIME 
                    ELSE '10:00'::TIME 
                END;
            WHEN class_record.category IN ('Photography', 'Music') THEN
                -- Skills-based: Weekends and evenings
                days_of_week := ARRAY[4, 6, 7]; -- Thu, Sat, Sun
                schedule_time := CASE WHEN random() > 0.5 THEN '19:30'::TIME ELSE '15:00'::TIME END;
            WHEN class_record.category IN ('Glass', 'Metalworking', 'Jewelry') THEN
                -- Specialized crafts: Weekend workshops
                days_of_week := ARRAY[6, 7]; -- Sat, Sun
                schedule_time := '10:00'::TIME;
            ELSE
                -- Default pattern
                days_of_week := ARRAY[6, 7];
                schedule_time := '14:00'::TIME;
        END CASE;
        
        -- Generate schedules for next 12 weeks
        FOR week_offset IN 0..11
        LOOP
            FOREACH day_of_week IN ARRAY days_of_week
            LOOP
                -- Calculate the actual date
                schedule_date := CURRENT_DATE + (week_offset * 7) + (day_of_week - EXTRACT(DOW FROM CURRENT_DATE)::INTEGER);
                
                -- Only create future schedules
                IF schedule_date >= CURRENT_DATE THEN
                    -- Add some time variation (±30 minutes)
                    schedule_time := schedule_time + (random() * INTERVAL '60 minutes' - INTERVAL '30 minutes');
                    
                    -- Create start and end timestamps
                    start_time := schedule_date + schedule_time;
                    end_time := start_time + (class_record.duration || ' minutes')::INTERVAL;
                    
                    -- Insert the schedule with realistic availability
                    INSERT INTO class_schedules (
                        class_id, 
                        start_time, 
                        end_time, 
                        spots_available, 
                        spots_total,
                        is_cancelled
                    ) VALUES (
                        class_record.id,
                        start_time,
                        end_time,
                        GREATEST(1, class_record.max_participants - FLOOR(random() * (class_record.max_participants * 0.7))::INTEGER), -- Some classes partially booked
                        class_record.max_participants,
                        CASE WHEN random() < 0.02 THEN true ELSE false END -- 2% cancellation rate
                    );
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated schedules for all classes over next 12 weeks';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 2: EXECUTE SCHEDULE GENERATION
-- ============================================

-- Generate all the schedules
SELECT generate_class_schedules();

-- ============================================
-- PART 3: ADD SOME SPECIAL HOLIDAY SCHEDULES
-- ============================================

-- Add some special Christmas/New Year workshops
INSERT INTO class_schedules (class_id, start_time, end_time, spots_available, spots_total, is_cancelled)
SELECT 
    id,
    '2025-12-21 14:00:00'::TIMESTAMPTZ,
    '2025-12-21 17:00:00'::TIMESTAMPTZ,
    max_participants,
    max_participants,
    false
FROM classes 
WHERE category IN ('Ceramics', 'Arts', 'Cooking') 
AND name LIKE '%Workshop%'
LIMIT 10;

-- Add New Year's creative workshops
INSERT INTO class_schedules (class_id, start_time, end_time, spots_available, spots_total, is_cancelled)
SELECT 
    id,
    '2026-01-04 10:00:00'::TIMESTAMPTZ,
    ('2026-01-04 10:00:00'::TIMESTAMPTZ + (duration || ' minutes')::INTERVAL),
    max_participants,
    max_participants,
    false
FROM classes 
WHERE category IN ('Arts', 'Dance', 'Wellness')
AND difficulty_level = 'beginner'
LIMIT 15;

-- ============================================
-- PART 4: UPDATE SOME SCHEDULES FOR REALISM
-- ============================================

-- Make some popular evening classes fully booked
UPDATE class_schedules 
SET spots_available = 0 
WHERE class_id IN (
    SELECT c.id FROM classes c 
    WHERE c.category IN ('Yoga', 'Cooking', 'Dance')
) 
AND EXTRACT(HOUR FROM start_time) BETWEEN 18 AND 20
AND start_time < NOW() + INTERVAL '2 weeks'
AND random() < 0.3; -- 30% of popular evening classes

-- Make some weekend workshops nearly full
UPDATE class_schedules 
SET spots_available = GREATEST(1, FLOOR(spots_total * 0.2))
WHERE EXTRACT(DOW FROM start_time) IN (0, 6) -- Sunday or Saturday
AND start_time > NOW() + INTERVAL '1 week'
AND start_time < NOW() + INTERVAL '4 weeks'
AND random() < 0.4; -- 40% of weekend workshops

-- Cancel a few classes for realism (instructor sick, etc.)
UPDATE class_schedules 
SET is_cancelled = true, 
    cancellation_reason = CASE 
        WHEN random() < 0.5 THEN 'Instructor unavailable'
        WHEN random() < 0.8 THEN 'Insufficient enrollment'
        ELSE 'Studio maintenance'
    END
WHERE start_time > NOW() + INTERVAL '3 days'
AND start_time < NOW() + INTERVAL '2 weeks'
AND random() < 0.03; -- 3% cancellation rate

-- ============================================
-- PART 5: CLEANUP AND OPTIMIZATION
-- ============================================

-- Drop the temporary function
DROP FUNCTION generate_class_schedules();

-- Update statistics for query optimization
ANALYZE class_schedules;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
    schedule_count INTEGER;
    future_schedules INTEGER;
    available_classes INTEGER;
    cancelled_classes INTEGER;
    full_classes INTEGER;
    avg_availability DECIMAL;
BEGIN
    SELECT COUNT(*) INTO schedule_count FROM class_schedules;
    SELECT COUNT(*) INTO future_schedules FROM class_schedules WHERE start_time > NOW();
    SELECT COUNT(*) INTO available_classes FROM class_schedules WHERE spots_available > 0 AND start_time > NOW() AND is_cancelled = false;
    SELECT COUNT(*) INTO cancelled_classes FROM class_schedules WHERE is_cancelled = true;
    SELECT COUNT(*) INTO full_classes FROM class_schedules WHERE spots_available = 0 AND is_cancelled = false;
    SELECT AVG(spots_available::DECIMAL / NULLIF(spots_total, 0)) INTO avg_availability FROM class_schedules WHERE is_cancelled = false;
    
    IF schedule_count < 500 THEN
        RAISE EXCEPTION 'Not enough schedules created: %', schedule_count;
    END IF;
    
    IF future_schedules < 400 THEN
        RAISE EXCEPTION 'Not enough future schedules: %', future_schedules;
    END IF;
    
    IF available_classes < 200 THEN
        RAISE EXCEPTION 'Not enough available classes: %', available_classes;
    END IF;
    
    IF avg_availability < 0.3 OR avg_availability > 0.9 THEN
        RAISE EXCEPTION 'Unrealistic average availability: %', avg_availability;
    END IF;
    
    RAISE NOTICE 'Successfully created % total schedules', schedule_count;
    RAISE NOTICE '% future schedules, % available, % cancelled, % full', 
                 future_schedules, available_classes, cancelled_classes, full_classes;
    RAISE NOTICE 'Average availability: %', avg_availability;
END $$;