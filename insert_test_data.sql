-- ================================================
-- Insert Test Data for Existing Schema
-- ================================================

-- Insert test instructor profiles (using existing table)
INSERT INTO instructor_profiles (
    bio, certifications, specialties, 
    years_experience, rating, total_reviews, hourly_rate
)
VALUES
    ('Certified yoga instructor specializing in Vinyasa and Yin yoga. Passionate about mindful movement.',
     ARRAY['RYT-200', 'RYT-500', 'Yin Yoga Certification'],
     ARRAY['Vinyasa', 'Yin Yoga', 'Meditation'],
     5, 4.8, 127, 85.00),
    ('Professional pottery instructor with 10+ years experience. Featured artist at Vancouver Art Gallery.',
     ARRAY['BFA Ceramics', 'Teaching Certificate'],
     ARRAY['Wheel Throwing', 'Hand Building', 'Glazing'],
     10, 4.9, 89, 95.00),
    ('Boxing coach and personal trainer. Former amateur champion.',
     ARRAY['NCCP Level 2', 'First Aid', 'Personal Training Certificate'],
     ARRAY['Boxing', 'HIIT', 'Strength Training'],
     7, 4.7, 203, 75.00)
ON CONFLICT DO NOTHING;

-- Insert test studios
INSERT INTO studios (
    name, email, phone, description, owner_id,
    subscription_tier, commission_rate, status
)
VALUES
    ('Kitsilano Yoga Studio', 'info@kitsyoga.com', '604-555-0101',
     'Premier yoga studio in the heart of Kitsilano', '11111111-1111-1111-1111-111111111111'::uuid,
     'professional', 0.15, 'active'),
    ('Mount Pleasant Pottery', 'hello@mppottery.com', '604-555-0102',
     'Creative pottery studio for all skill levels', '22222222-2222-2222-2222-222222222222'::uuid,
     'professional', 0.15, 'active'),
    ('Coal Harbour Boxing', 'train@chboxing.com', '604-555-0103',
     'Elite boxing and fitness training', '33333333-3333-3333-3333-333333333333'::uuid,
     'professional', 0.15, 'active')
ON CONFLICT DO NOTHING;

-- Insert studio locations
INSERT INTO studio_locations (
    studio_id, name, address, city, state, zip, country,
    latitude, longitude, capacity, is_primary
)
SELECT 
    s.id, 
    s.name || ' Main Location',
    CASE 
        WHEN s.name LIKE '%Kitsilano%' THEN '2690 Larch St'
        WHEN s.name LIKE '%Mount Pleasant%' THEN '245 E Broadway'
        ELSE '1055 W Hastings St'
    END,
    'Vancouver', 'BC',
    CASE 
        WHEN s.name LIKE '%Kitsilano%' THEN 'V6K 4B5'
        WHEN s.name LIKE '%Mount Pleasant%' THEN 'V5T 1W4'
        ELSE 'V6E 2E9'
    END,
    'Canada',
    CASE 
        WHEN s.name LIKE '%Kitsilano%' THEN 49.2578
        WHEN s.name LIKE '%Mount Pleasant%' THEN 49.2627
        ELSE 49.2879
    END,
    CASE 
        WHEN s.name LIKE '%Kitsilano%' THEN -123.1552
        WHEN s.name LIKE '%Mount Pleasant%' THEN -123.0982
        ELSE -123.1199
    END,
    CASE 
        WHEN s.name LIKE '%Kitsilano%' THEN 50
        WHEN s.name LIKE '%Mount Pleasant%' THEN 30
        ELSE 40
    END,
    true
FROM studios s
WHERE s.name IN ('Kitsilano Yoga Studio', 'Mount Pleasant Pottery', 'Coal Harbour Boxing')
ON CONFLICT DO NOTHING;

-- Insert test classes with instructor profiles
INSERT INTO classes (
    instructor_profile_id, studio_id, location_id, 
    title, description, category_id,
    start_time, end_time, capacity, credits_required, 
    skill_level, requirements, what_to_bring, cancellation_policy, tags
)
SELECT 
    ip.id,
    s.id,
    sl.id,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 'Morning Vinyasa Flow'
        WHEN ip.bio LIKE '%pottery%' THEN 'Pottery Wheel Basics'
        ELSE 'Boxing Fundamentals'
    END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 'Start your day with an energizing vinyasa practice suitable for all levels.'
        WHEN ip.bio LIKE '%pottery%' THEN 'Learn the fundamentals of wheel throwing and create your first pieces.'
        ELSE 'Learn proper form, footwork, and basic combinations in this beginner-friendly class.'
    END,
    (SELECT id FROM categories WHERE name = 
        CASE 
            WHEN ip.bio LIKE '%yoga%' THEN 'Wellness & Fitness'
            WHEN ip.bio LIKE '%pottery%' THEN 'Arts & Crafts'
            ELSE 'Wellness & Fitness'
        END
    LIMIT 1),
    NOW() + INTERVAL '2 days' + 
        CASE 
            WHEN ip.bio LIKE '%yoga%' THEN TIME '09:00'
            WHEN ip.bio LIKE '%pottery%' THEN TIME '18:00'
            ELSE TIME '17:30'
        END,
    NOW() + INTERVAL '2 days' + 
        CASE 
            WHEN ip.bio LIKE '%yoga%' THEN TIME '10:30'
            WHEN ip.bio LIKE '%pottery%' THEN TIME '20:00'
            ELSE TIME '18:30'
        END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 20
        WHEN ip.bio LIKE '%pottery%' THEN 12
        ELSE 15
    END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 2
        WHEN ip.bio LIKE '%pottery%' THEN 3
        ELSE 2
    END,
    CASE 
        WHEN ip.bio LIKE '%pottery%' THEN 'beginner'
        WHEN ip.bio LIKE '%boxing%' THEN 'beginner'
        ELSE 'all_levels'
    END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 'Bring your own mat'
        WHEN ip.bio LIKE '%pottery%' THEN 'Wear clothes you don''t mind getting dirty'
        ELSE 'No experience necessary'
    END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN 'Yoga mat, water bottle, towel'
        WHEN ip.bio LIKE '%pottery%' THEN 'Apron (provided), towel'
        ELSE 'Hand wraps, water bottle (gloves provided)'
    END,
    CASE 
        WHEN ip.bio LIKE '%pottery%' THEN 'Free cancellation up to 48 hours before class'
        WHEN ip.bio LIKE '%boxing%' THEN 'Free cancellation up to 12 hours before class'
        ELSE 'Free cancellation up to 24 hours before class'
    END,
    CASE 
        WHEN ip.bio LIKE '%yoga%' THEN ARRAY['yoga', 'morning', 'vinyasa', 'flow']
        WHEN ip.bio LIKE '%pottery%' THEN ARRAY['pottery', 'ceramics', 'wheel', 'beginner']
        ELSE ARRAY['boxing', 'fitness', 'cardio', 'strength']
    END
FROM instructor_profiles ip
CROSS JOIN studios s
CROSS JOIN studio_locations sl
WHERE 
    (ip.bio LIKE '%yoga%' AND s.name LIKE '%Kitsilano%' AND sl.studio_id = s.id) OR
    (ip.bio LIKE '%pottery%' AND s.name LIKE '%Mount Pleasant%' AND sl.studio_id = s.id) OR
    (ip.bio LIKE '%boxing%' AND s.name LIKE '%Coal Harbour%' AND sl.studio_id = s.id)
ON CONFLICT DO NOTHING;

-- Update or insert credit packs (ensure we have the right pricing)
INSERT INTO credit_packs (name, credits, price, description, is_popular, display_order)
VALUES
    ('Starter Pack', 5, 25.00, 'Perfect for trying new hobbies', false, 1),
    ('Explorer Pack', 12, 50.00, 'Most popular choice for regular hobbyists', true, 2),
    ('Enthusiast Pack', 25, 90.00, 'Best value for dedicated learners', false, 3)
ON CONFLICT (name) DO UPDATE SET
    credits = EXCLUDED.credits,
    price = EXCLUDED.price,
    description = EXCLUDED.description,
    is_popular = EXCLUDED.is_popular,
    display_order = EXCLUDED.display_order;

-- Insert sample user credits for testing
INSERT INTO user_credits (user_id, balance, lifetime_credits)
VALUES 
    ('11111111-1111-1111-1111-111111111111'::uuid, 10, 25),
    ('22222222-2222-2222-2222-222222222222'::uuid, 15, 30),
    ('33333333-3333-3333-3333-333333333333'::uuid, 5, 10)
ON CONFLICT (user_id) DO UPDATE SET
    balance = user_credits.balance + EXCLUDED.balance,
    lifetime_credits = user_credits.lifetime_credits + EXCLUDED.lifetime_credits;

-- Verify data was inserted
SELECT 
    'Test Data Summary' as report,
    (SELECT COUNT(*) FROM studios WHERE name LIKE '%Kitsilano%' OR name LIKE '%Mount Pleasant%' OR name LIKE '%Coal Harbour%') as test_studios,
    (SELECT COUNT(*) FROM studio_locations WHERE city = 'Vancouver') as vancouver_locations,
    (SELECT COUNT(*) FROM instructor_profiles WHERE rating > 4.5) as quality_instructors,
    (SELECT COUNT(*) FROM classes WHERE start_time > NOW()) as upcoming_classes,
    (SELECT COUNT(*) FROM credit_packs) as pricing_tiers,
    (SELECT COUNT(*) FROM user_credits WHERE balance > 0) as users_with_credits;