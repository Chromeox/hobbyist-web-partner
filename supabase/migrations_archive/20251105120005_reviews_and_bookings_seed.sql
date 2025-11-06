-- Reviews and Bookings Seed Data
-- Generate realistic reviews, ratings, and booking history for authentic feel
-- Date: 2025-11-05

-- ============================================
-- PART 1: CREATE SAMPLE USERS FOR BOOKINGS
-- ============================================

-- We'll need to create some sample user profiles for realistic bookings
-- These will be linked to auth.users that would be created through the app

-- First, let's create user_credits records for our sample users
INSERT INTO user_credits (id, user_id, total_credits, used_credits, rollover_credits, loyalty_tier) VALUES
('cred-001', '10000000-0000-0000-0000-000000000001'::uuid, 15, 8, 2, 'silver'),
('cred-002', '10000000-0000-0000-0000-000000000002'::uuid, 25, 12, 5, 'gold'),
('cred-003', '10000000-0000-0000-0000-000000000003'::uuid, 8, 3, 0, 'bronze'),
('cred-004', '10000000-0000-0000-0000-000000000004'::uuid, 30, 18, 8, 'platinum'),
('cred-005', '10000000-0000-0000-0000-000000000005'::uuid, 12, 5, 1, 'silver'),
('cred-006', '10000000-0000-0000-0000-000000000006'::uuid, 20, 14, 3, 'gold'),
('cred-007', '10000000-0000-0000-0000-000000000007'::uuid, 6, 2, 0, 'bronze'),
('cred-008', '10000000-0000-0000-0000-000000000008'::uuid, 40, 25, 12, 'platinum'),
('cred-009', '10000000-0000-0000-0000-000000000009'::uuid, 18, 9, 4, 'gold'),
('cred-010', '10000000-0000-0000-0000-000000000010'::uuid, 10, 4, 1, 'silver');

-- ============================================
-- PART 2: GENERATE REALISTIC BOOKINGS
-- ============================================

-- Function to generate realistic booking history
CREATE OR REPLACE FUNCTION generate_booking_history()
RETURNS void AS $$
DECLARE
    schedule_record RECORD;
    user_ids UUID[] := ARRAY[
        '10000000-0000-0000-0000-000000000001'::uuid,
        '10000000-0000-0000-0000-000000000002'::uuid,
        '10000000-0000-0000-0000-000000000003'::uuid,
        '10000000-0000-0000-0000-000000000004'::uuid,
        '10000000-0000-0000-0000-000000000005'::uuid,
        '10000000-0000-0000-0000-000000000006'::uuid,
        '10000000-0000-0000-0000-000000000007'::uuid,
        '10000000-0000-0000-0000-000000000008'::uuid,
        '10000000-0000-0000-0000-000000000009'::uuid,
        '10000000-0000-0000-0000-000000000010'::uuid
    ];
    selected_user_id UUID;
    booking_status TEXT;
    credits_used DECIMAL;
    should_have_review BOOLEAN;
    rating INTEGER;
    review_text TEXT;
    reviews_array TEXT[] := ARRAY[
        'Amazing class! Sarah is such a patient and knowledgeable instructor.',
        'Loved every minute of it. Can''t wait to come back for more pottery classes.',
        'Great introduction to ceramics. The studio has a wonderful atmosphere.',
        'Perfect for beginners. I felt supported throughout the entire class.',
        'Fantastic workshop! Learned so much about glazing techniques.',
        'Really enjoyed the hands-on experience. Highly recommend!',
        'Beautiful studio space and excellent instruction. Will definitely return.',
        'Such a relaxing and creative experience. Exactly what I needed.',
        'The instructor was incredibly helpful and encouraging.',
        'Great value for money. Left with a beautiful piece I made myself.',
        'Wonderful community vibe. Met some lovely fellow artists.',
        'Professional setup with all the tools and materials needed.',
        'Inspiring class that reignited my passion for pottery.',
        'Well-organized session with clear step-by-step guidance.',
        'Therapeutic and fun. Great way to spend a Saturday afternoon.',
        'Exceeded my expectations. The glazing results were stunning.',
        'Friendly atmosphere and expert instruction. Five stars!',
        'Perfect date activity. Both of us had a blast creating together.',
        'Instructor was patient with all skill levels in the class.',
        'Beautiful finished pieces. Proud to display them at home.',
        'Excellent introduction to wheel throwing. Felt very accomplished.',
        'Great studio with natural light and comfortable workspace.',
        'Would recommend to anyone interested in trying pottery.',
        'Learned techniques I can practice at home. Very valuable.',
        'Fantastic instructor who made everyone feel welcome and capable.'
    ];
    cooking_reviews TEXT[] := ARRAY[
        'Chef Amanda was incredible! Learned knife skills that changed my cooking.',
        'Best pasta making class in Vancouver. Giovanni is a true master.',
        'Pacific Northwest seafood class was amazing. Such fresh ingredients.',
        'Loved the hands-on approach. Took home delicious food and new skills.',
        'Italian masterclass was worth every penny. Felt like being in Italy.',
        'Great techniques for cooking local ingredients. Very Vancouver-focused.',
        'Professional kitchen setup made the experience feel authentic.',
        'Small class size meant lots of individual attention.',
        'Came for a date night and it was perfect. Romantic and fun.',
        'Learned more in 3 hours than years of cooking at home.'
    ];
    art_reviews TEXT[] := ARRAY[
        'Maya''s urban art class opened my eyes to new techniques.',
        'Loved painting Vancouver landmarks. Great for tourists and locals.',
        'Watercolor class with Catherine was like having a private lesson.',
        'Street photography workshop taught me to see the city differently.',
        'Calligraphy class was meditative and surprisingly therapeutic.',
        'Mixed media techniques were exactly what I needed for my art practice.',
        'Acrylic painting basics gave me confidence to continue at home.',
        'Jonathan''s photography instruction was clear and practical.',
        'Beautiful natural light in the Granville studio.',
        'Left feeling inspired and equipped with new artistic skills.'
    ];
BEGIN
    -- Clear existing bookings to prevent duplicates
    DELETE FROM bookings;
    
    -- Generate bookings for past schedules (completed classes)
    FOR schedule_record IN 
        SELECT cs.id, cs.class_id, cs.start_time, cs.spots_total, c.category, ct.credit_required
        FROM class_schedules cs
        JOIN classes c ON cs.class_id = c.id
        JOIN class_tiers ct ON c.tier_id = ct.id
        WHERE cs.start_time < NOW() - INTERVAL '1 hour'
        AND cs.is_cancelled = false
        ORDER BY cs.start_time DESC
        LIMIT 300 -- Limit to most recent past classes
    LOOP
        -- Generate 1-4 bookings per past class (some classes might be less popular)
        FOR i IN 1..LEAST(schedule_record.spots_total, 1 + FLOOR(random() * 4))
        LOOP
            -- Select a random user
            selected_user_id := user_ids[1 + FLOOR(random() * array_length(user_ids, 1))];
            
            -- Determine booking status (most completed classes should be 'completed')
            booking_status := CASE 
                WHEN random() < 0.85 THEN 'completed'
                WHEN random() < 0.95 THEN 'confirmed'
                ELSE 'no_show'
            END;
            
            -- Determine credits used based on tier
            credits_used := schedule_record.credit_required + (random() * 0.5 - 0.25); -- Small variation
            
            -- Insert the booking
            INSERT INTO bookings (
                user_id,
                class_schedule_id,
                status,
                credits_used,
                payment_method,
                checked_in_at,
                created_at,
                updated_at
            ) VALUES (
                selected_user_id,
                schedule_record.id,
                booking_status,
                credits_used,
                'credits',
                CASE WHEN booking_status = 'completed' THEN schedule_record.start_time + INTERVAL '5 minutes' ELSE NULL END,
                schedule_record.start_time - INTERVAL '3 days' - (random() * INTERVAL '4 days'),
                schedule_record.start_time - INTERVAL '3 days' - (random() * INTERVAL '4 days')
            );
            
            -- Add reviews for completed classes (70% chance)
            IF booking_status = 'completed' AND random() < 0.7 THEN
                -- Generate rating (weighted toward higher ratings)
                rating := CASE 
                    WHEN random() < 0.5 THEN 5
                    WHEN random() < 0.8 THEN 4
                    WHEN random() < 0.95 THEN 3
                    ELSE 2
                END;
                
                -- Select appropriate review text based on category
                review_text := CASE 
                    WHEN schedule_record.category = 'Cooking' THEN 
                        cooking_reviews[1 + FLOOR(random() * array_length(cooking_reviews, 1))]
                    WHEN schedule_record.category IN ('Arts', 'Photography') THEN 
                        art_reviews[1 + FLOOR(random() * array_length(art_reviews, 1))]
                    ELSE 
                        reviews_array[1 + FLOOR(random() * array_length(reviews_array, 1))]
                END;
                
                -- Update the booking with review
                UPDATE bookings 
                SET rating = rating, review = review_text
                WHERE user_id = selected_user_id AND class_schedule_id = schedule_record.id;
            END IF;
        END LOOP;
    END LOOP;
    
    -- Generate some future bookings (upcoming classes)
    FOR schedule_record IN 
        SELECT cs.id, cs.class_id, cs.start_time, cs.spots_available, ct.credit_required
        FROM class_schedules cs
        JOIN classes c ON cs.class_id = c.id
        JOIN class_tiers ct ON c.tier_id = ct.id
        WHERE cs.start_time > NOW()
        AND cs.start_time < NOW() + INTERVAL '2 weeks'
        AND cs.spots_available > 0
        AND cs.is_cancelled = false
        ORDER BY random()
        LIMIT 100
    LOOP
        -- Generate 1-3 future bookings per class
        FOR i IN 1..LEAST(schedule_record.spots_available, 1 + FLOOR(random() * 3))
        LOOP
            selected_user_id := user_ids[1 + FLOOR(random() * array_length(user_ids, 1))];
            credits_used := schedule_record.credit_required;
            
            INSERT INTO bookings (
                user_id,
                class_schedule_id,
                status,
                credits_used,
                payment_method,
                created_at,
                updated_at
            ) VALUES (
                selected_user_id,
                schedule_record.id,
                'confirmed',
                credits_used,
                'credits',
                NOW() - (random() * INTERVAL '5 days'),
                NOW() - (random() * INTERVAL '5 days')
            );
            
            -- Update schedule availability
            UPDATE class_schedules 
            SET spots_available = spots_available - 1 
            WHERE id = schedule_record.id;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Generated realistic booking history and future bookings';
END;
$$ LANGUAGE plpgsql;

-- Execute booking generation
SELECT generate_booking_history();

-- ============================================
-- PART 3: UPDATE INSTRUCTOR RATINGS BASED ON REVIEWS
-- ============================================

-- Update instructor ratings and total_classes based on actual bookings and reviews
UPDATE instructors 
SET 
    rating = COALESCE((
        SELECT AVG(b.rating::DECIMAL) 
        FROM bookings b 
        JOIN class_schedules cs ON b.class_schedule_id = cs.id 
        JOIN classes c ON cs.class_id = c.id 
        WHERE c.instructor_id = instructors.id 
        AND b.rating IS NOT NULL
    ), rating),
    total_classes = COALESCE((
        SELECT COUNT(*) 
        FROM bookings b 
        JOIN class_schedules cs ON b.class_schedule_id = cs.id 
        JOIN classes c ON cs.class_id = c.id 
        WHERE c.instructor_id = instructors.id 
        AND b.status = 'completed'
    ), total_classes)
WHERE is_active = true;

-- ============================================
-- PART 4: CLEANUP
-- ============================================

-- Drop the temporary function
DROP FUNCTION generate_booking_history();

-- Update table statistics
ANALYZE bookings;
ANALYZE instructors;
ANALYZE class_schedules;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
    booking_count INTEGER;
    completed_bookings INTEGER;
    future_bookings INTEGER;
    reviews_count INTEGER;
    avg_rating DECIMAL;
    instructors_with_updated_ratings INTEGER;
BEGIN
    SELECT COUNT(*) INTO booking_count FROM bookings;
    SELECT COUNT(*) INTO completed_bookings FROM bookings WHERE status = 'completed';
    SELECT COUNT(*) INTO future_bookings FROM bookings WHERE status = 'confirmed';
    SELECT COUNT(*) INTO reviews_count FROM bookings WHERE review IS NOT NULL;
    SELECT AVG(rating) INTO avg_rating FROM bookings WHERE rating IS NOT NULL;
    SELECT COUNT(*) INTO instructors_with_updated_ratings FROM instructors WHERE rating > 0;
    
    IF booking_count < 200 THEN
        RAISE EXCEPTION 'Not enough bookings created: %', booking_count;
    END IF;
    
    IF completed_bookings < 100 THEN
        RAISE EXCEPTION 'Not enough completed bookings: %', completed_bookings;
    END IF;
    
    IF reviews_count < 50 THEN
        RAISE EXCEPTION 'Not enough reviews created: %', reviews_count;
    END IF;
    
    IF avg_rating < 3.5 OR avg_rating > 5.0 THEN
        RAISE EXCEPTION 'Unrealistic average rating: %', avg_rating;
    END IF;
    
    IF instructors_with_updated_ratings < 30 THEN
        RAISE EXCEPTION 'Not enough instructors have ratings: %', instructors_with_updated_ratings;
    END IF;
    
    RAISE NOTICE 'Successfully created % bookings (% completed, % future)', 
                 booking_count, completed_bookings, future_bookings;
    RAISE NOTICE '% reviews with average rating %, % instructors rated', 
                 reviews_count, avg_rating, instructors_with_updated_ratings;
END $$;