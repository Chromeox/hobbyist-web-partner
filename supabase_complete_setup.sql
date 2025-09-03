-- ================================================
-- Complete Supabase Setup Script
-- After migrations 03-08 are applied
-- ================================================

-- ================================================
-- 1. ENABLE REAL-TIME ON KEY TABLES
-- ================================================

-- Enable real-time for user-facing tables
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE classes;
ALTER PUBLICATION supabase_realtime ADD TABLE user_credits;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE waitlists;
ALTER PUBLICATION supabase_realtime ADD TABLE reviews;
ALTER PUBLICATION supabase_realtime ADD TABLE student_progress;
ALTER PUBLICATION supabase_realtime ADD TABLE achievements;
ALTER PUBLICATION supabase_realtime ADD TABLE leaderboard_entries;

-- Enable real-time for partner portal tables
ALTER PUBLICATION supabase_realtime ADD TABLE partner_analytics;
ALTER PUBLICATION supabase_realtime ADD TABLE studio_commission_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE revenue_share_transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE payout_requests;

-- ================================================
-- 2. STORAGE BUCKETS CONFIGURATION
-- ================================================

-- Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
    ('class-images', 'class-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
    ('venue-images', 'venue-images', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
    ('certificates', 'certificates', false, 20971520, ARRAY['application/pdf', 'image/jpeg', 'image/png']),
    ('chat-attachments', 'chat-attachments', false, 52428800, ARRAY['image/*', 'application/pdf', 'video/mp4', 'video/quicktime'])
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Set up RLS policies for storage buckets
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Class images policies
CREATE POLICY "Class images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'class-images');

CREATE POLICY "Partners can upload class images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'class-images' AND 
    EXISTS (
        SELECT 1 FROM partner_users 
        WHERE user_id = auth.uid()
    )
);

-- ================================================
-- 3. TEST DATA INSERTION
-- ================================================

-- Insert test venues (Vancouver area)
INSERT INTO venues (name, address, city, province, postal_code, country, latitude, longitude, capacity, amenities)
VALUES
    ('Kitsilano Community Centre', '2690 Larch St', 'Vancouver', 'BC', 'V6K 4B5', 'Canada', 49.2578, -123.1552, 50, 
     ARRAY['parking', 'changerooms', 'water_fountain', 'wheelchair_accessible']),
    ('Mount Pleasant Studio', '245 E Broadway', 'Vancouver', 'BC', 'V5T 1W4', 'Canada', 49.2627, -123.0982, 30,
     ARRAY['parking', 'changerooms', 'lockers']),
    ('Coal Harbour Fitness', '1055 W Hastings St', 'Vancouver', 'BC', 'V6E 2E9', 'Canada', 49.2879, -123.1199, 40,
     ARRAY['parking', 'changerooms', 'lockers', 'showers', 'cafe']),
    ('Yaletown Movement Space', '1275 Pacific Blvd', 'Vancouver', 'BC', 'V6Z 2T9', 'Canada', 49.2747, -123.1219, 35,
     ARRAY['changerooms', 'water_fountain', 'wheelchair_accessible'])
ON CONFLICT DO NOTHING;

-- Insert test instructors
INSERT INTO instructors (user_id, bio, certifications, specialties, years_experience, rating, total_reviews)
VALUES
    ('11111111-1111-1111-1111-111111111111'::uuid, 
     'Certified yoga instructor specializing in Vinyasa and Yin yoga. Passionate about mindful movement.',
     ARRAY['RYT-200', 'RYT-500', 'Yin Yoga Certification'],
     ARRAY['Vinyasa', 'Yin Yoga', 'Meditation'],
     5, 4.8, 127),
    ('22222222-2222-2222-2222-222222222222'::uuid,
     'Professional pottery instructor with 10+ years experience. Featured artist at Vancouver Art Gallery.',
     ARRAY['BFA Ceramics', 'Teaching Certificate'],
     ARRAY['Wheel Throwing', 'Hand Building', 'Glazing'],
     10, 4.9, 89),
    ('33333333-3333-3333-3333-333333333333'::uuid,
     'Boxing coach and personal trainer. Former amateur champion.',
     ARRAY['NCCP Level 2', 'First Aid', 'Personal Training Certificate'],
     ARRAY['Boxing', 'HIIT', 'Strength Training'],
     7, 4.7, 203)
ON CONFLICT DO NOTHING;

-- Insert test hobby categories
INSERT INTO hobby_categories (name, slug, description, icon, color, display_order, is_featured)
VALUES
    ('Fitness', 'fitness', 'Stay active with boxing, yoga, pilates, and more', 'dumbbell', '#FF6B6B', 1, true),
    ('Arts & Crafts', 'arts-crafts', 'Express creativity through pottery, painting, and crafts', 'palette', '#4ECDC4', 2, true),
    ('Music', 'music', 'Learn instruments, singing, and music production', 'music', '#95E1D3', 3, true),
    ('Cooking', 'cooking', 'Master culinary skills from around the world', 'utensils', '#F38181', 4, true),
    ('Dance', 'dance', 'Move to the rhythm with various dance styles', 'users', '#AA96DA', 5, true),
    ('Photography', 'photography', 'Capture moments and develop your visual eye', 'camera', '#8FCACA', 6, false),
    ('Language', 'language', 'Learn new languages and cultures', 'globe', '#C8B6E2', 7, false),
    ('Wellness', 'wellness', 'Focus on mental and physical wellbeing', 'heart', '#FAD6A5', 8, false)
ON CONFLICT DO NOTHING;

-- Insert test classes
INSERT INTO classes (
    instructor_id, venue_id, title, description, category_id,
    start_time, end_time, capacity, credits_required, skill_level,
    requirements, what_to_bring, cancellation_policy, tags
)
VALUES
    ('11111111-1111-1111-1111-111111111111'::uuid,
     (SELECT id FROM venues WHERE name = 'Kitsilano Community Centre' LIMIT 1),
     'Morning Vinyasa Flow',
     'Start your day with an energizing vinyasa practice suitable for all levels.',
     (SELECT id FROM hobby_categories WHERE slug = 'fitness' LIMIT 1),
     NOW() + INTERVAL '2 days' + TIME '09:00',
     NOW() + INTERVAL '2 days' + TIME '10:30',
     20, 2, 'all_levels',
     'Bring your own mat', 'Yoga mat, water bottle, towel',
     'Free cancellation up to 24 hours before class',
     ARRAY['yoga', 'morning', 'vinyasa', 'flow']),
     
    ('22222222-2222-2222-2222-222222222222'::uuid,
     (SELECT id FROM venues WHERE name = 'Mount Pleasant Studio' LIMIT 1),
     'Pottery Wheel Basics',
     'Learn the fundamentals of wheel throwing and create your first pieces.',
     (SELECT id FROM hobby_categories WHERE slug = 'arts-crafts' LIMIT 1),
     NOW() + INTERVAL '3 days' + TIME '18:00',
     NOW() + INTERVAL '3 days' + TIME '20:00',
     12, 3, 'beginner',
     'Wear clothes you don''t mind getting dirty', 'Apron (provided), towel',
     'Free cancellation up to 48 hours before class',
     ARRAY['pottery', 'ceramics', 'wheel', 'beginner']),
     
    ('33333333-3333-3333-3333-333333333333'::uuid,
     (SELECT id FROM venues WHERE name = 'Coal Harbour Fitness' LIMIT 1),
     'Boxing Fundamentals',
     'Learn proper form, footwork, and basic combinations in this beginner-friendly class.',
     (SELECT id FROM hobby_categories WHERE slug = 'fitness' LIMIT 1),
     NOW() + INTERVAL '1 day' + TIME '17:30',
     NOW() + INTERVAL '1 day' + TIME '18:30',
     15, 2, 'beginner',
     'No experience necessary', 'Hand wraps, water bottle (gloves provided)',
     'Free cancellation up to 12 hours before class',
     ARRAY['boxing', 'fitness', 'cardio', 'strength'])
ON CONFLICT DO NOTHING;

-- Insert test credit packs (pricing tiers)
INSERT INTO credit_packs (name, credits, price, savings, description, is_popular, display_order)
VALUES
    ('Starter Pack', 5, 25.00, 0, 'Perfect for trying new hobbies', false, 1),
    ('Explorer Pack', 12, 50.00, 10, 'Most popular choice for regular hobbyists', true, 2),
    ('Enthusiast Pack', 25, 90.00, 35, 'Best value for dedicated learners', false, 3)
ON CONFLICT DO NOTHING;

-- Insert test marketplace items
INSERT INTO marketplace_items (
    seller_id, title, description, category, price, 
    condition, location, images, is_available
)
VALUES
    ('11111111-1111-1111-1111-111111111111'::uuid,
     'Yoga Mat - Like New',
     'High-quality Manduka yoga mat, used only a few times. Non-slip surface.',
     'equipment',
     45.00,
     'like_new',
     'Kitsilano, Vancouver',
     ARRAY['https://example.com/mat1.jpg'],
     true),
     
    ('22222222-2222-2222-2222-222222222222'::uuid,
     'Pottery Tool Set',
     'Complete set of pottery tools including ribs, wires, and trimming tools.',
     'supplies',
     30.00,
     'good',
     'Mount Pleasant, Vancouver',
     ARRAY['https://example.com/tools1.jpg'],
     true)
ON CONFLICT DO NOTHING;

-- Insert test achievements
INSERT INTO achievements (
    name, description, icon, points, category,
    criteria_type, criteria_value, tier
)
VALUES
    ('First Steps', 'Book your first class', 'star', 10, 'milestone', 'classes_booked', 1, 'bronze'),
    ('Regular', 'Attend 5 classes', 'trophy', 50, 'milestone', 'classes_attended', 5, 'silver'),
    ('Dedicated', 'Attend 20 classes', 'award', 100, 'milestone', 'classes_attended', 20, 'gold'),
    ('Explorer', 'Try 3 different categories', 'compass', 30, 'exploration', 'categories_tried', 3, 'bronze'),
    ('Social Butterfly', 'Write 5 reviews', 'message-circle', 25, 'community', 'reviews_written', 5, 'bronze'),
    ('Streak Master', '7-day attendance streak', 'flame', 75, 'consistency', 'streak_days', 7, 'silver')
ON CONFLICT DO NOTHING;

-- Create sample users for testing (only in development)
-- Note: In production, users are created through Supabase Auth
DO $$
BEGIN
    -- Only insert test users if we're in a development environment
    -- You can remove this block in production
    IF current_database() = 'postgres' THEN
        -- Sample student user
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
        VALUES 
            ('44444444-4444-4444-4444-444444444444'::uuid, 
             'student@test.com', 
             crypt('password123', gen_salt('bf')),
             NOW(), NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        INSERT INTO profiles (id, email, full_name, username, avatar_url)
        VALUES 
            ('44444444-4444-4444-4444-444444444444'::uuid,
             'student@test.com',
             'Test Student',
             'teststudent',
             'https://api.dicebear.com/7.x/avataaars/svg?seed=student')
        ON CONFLICT DO NOTHING;
        
        -- Give test student some credits
        INSERT INTO user_credits (user_id, balance, lifetime_credits)
        VALUES ('44444444-4444-4444-4444-444444444444'::uuid, 10, 10)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- ================================================
-- 4. EDGE FUNCTIONS SETUP
-- ================================================
-- Note: Edge functions are created through Supabase CLI or Dashboard
-- The SQL here creates the database functions that edge functions will call

-- Function to process credit purchase
CREATE OR REPLACE FUNCTION process_credit_purchase(
    p_user_id uuid,
    p_pack_id uuid,
    p_payment_intent_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pack record;
    v_result jsonb;
BEGIN
    -- Get credit pack details
    SELECT * INTO v_pack FROM credit_packs WHERE id = p_pack_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Credit pack not found');
    END IF;
    
    -- Add credits to user
    INSERT INTO user_credits (user_id, balance, lifetime_credits)
    VALUES (p_user_id, v_pack.credits, v_pack.credits)
    ON CONFLICT (user_id) DO UPDATE
    SET balance = user_credits.balance + v_pack.credits,
        lifetime_credits = user_credits.lifetime_credits + v_pack.credits;
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, amount, transaction_type, 
        description, payment_intent_id
    )
    VALUES (
        p_user_id, v_pack.credits, 'purchase',
        'Purchased ' || v_pack.name, p_payment_intent_id
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'credits_added', v_pack.credits,
        'new_balance', (SELECT balance FROM user_credits WHERE user_id = p_user_id)
    );
END;
$$;

-- Function to handle class booking
CREATE OR REPLACE FUNCTION book_class(
    p_user_id uuid,
    p_class_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_class record;
    v_user_credits integer;
    v_booking_id uuid;
BEGIN
    -- Get class details
    SELECT * INTO v_class FROM classes WHERE id = p_class_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Class not found');
    END IF;
    
    -- Check if class is full
    IF (SELECT COUNT(*) FROM bookings WHERE class_id = p_class_id AND status = 'confirmed') >= v_class.capacity THEN
        RETURN jsonb_build_object('success', false, 'error', 'Class is full');
    END IF;
    
    -- Check user credits
    SELECT balance INTO v_user_credits FROM user_credits WHERE user_id = p_user_id;
    
    IF v_user_credits < v_class.credits_required THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient credits');
    END IF;
    
    -- Create booking
    INSERT INTO bookings (user_id, class_id, status, credits_used)
    VALUES (p_user_id, p_class_id, 'confirmed', v_class.credits_required)
    RETURNING id INTO v_booking_id;
    
    -- Deduct credits
    UPDATE user_credits
    SET balance = balance - v_class.credits_required
    WHERE user_id = p_user_id;
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, amount, transaction_type, 
        description, booking_id
    )
    VALUES (
        p_user_id, -v_class.credits_required, 'booking',
        'Booked: ' || v_class.title, v_booking_id
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'credits_used', v_class.credits_required
    );
END;
$$;

-- ================================================
-- VERIFICATION QUERIES
-- ================================================

-- Check real-time enabled tables
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- Check storage buckets
SELECT id, name, public FROM storage.buckets;

-- Count test data
SELECT 
    (SELECT COUNT(*) FROM venues) as venues_count,
    (SELECT COUNT(*) FROM instructors) as instructors_count,
    (SELECT COUNT(*) FROM classes) as classes_count,
    (SELECT COUNT(*) FROM hobby_categories) as categories_count,
    (SELECT COUNT(*) FROM credit_packs) as credit_packs_count,
    (SELECT COUNT(*) FROM achievements) as achievements_count;

NOTIFY setup_complete, 'Supabase configuration completed successfully!';