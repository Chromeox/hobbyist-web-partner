-- Test Data Setup for Partner Portal
-- Comprehensive realistic data for testing all features
-- Date: 2024-11-05

-- ============================================
-- PART 1: TEST STUDIOS
-- ============================================

-- Insert test studios with realistic Vancouver data
INSERT INTO studios (id, name, business_name, slug, description, email, phone, address_line1, city, state, postal_code, timezone, status, is_verified) VALUES 
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Flow Yoga Studio',
    'Flow Yoga Studio Ltd.',
    'flow-yoga-vancouver',
    'Premium yoga studio in the heart of Vancouver offering Vinyasa, Hatha, and Hot Yoga classes for all levels.',
    'info@flowyogavancouver.ca',
    '+1-604-555-0123',
    '123 Robson Street',
    'Vancouver',
    'BC',
    'V6B 1B8',
    'America/Vancouver',
    'active',
    true
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'Strength & Conditioning',
    'Vancouver Strength Co.',
    'strength-conditioning-van',
    'High-intensity functional fitness training. Olympic lifting, CrossFit-style workouts, and personal training.',
    'team@vanstrength.ca',
    '+1-604-555-0124',
    '456 Main Street',
    'Vancouver',
    'BC',
    'V6A 2T2',
    'America/Vancouver',
    'active',
    true
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d481',
    'Clay & Create Pottery',
    'Clay & Create Studio Inc.',
    'clay-create-pottery',
    'Ceramics studio offering wheel throwing, hand-building, and glazing classes. Open studio time available.',
    'hello@clayandcreate.ca',
    '+1-604-555-0125',
    '789 Commercial Drive',
    'Vancouver',
    'BC',
    'V5L 3X9',
    'America/Vancouver',
    'active',
    true
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d482',
    'Boxing Champions',
    'Champions Boxing Academy',
    'boxing-champions-van',
    'Professional boxing training for all skill levels. Cardio boxing, technique training, and sparring sessions.',
    'contact@boxingchampions.ca',
    '+1-604-555-0126',
    '321 East Hastings',
    'Vancouver',
    'BC',
    'V6A 1P4',
    'America/Vancouver',
    'active',
    false
);

-- ============================================
-- PART 2: STUDIO STAFF & USER PROFILES
-- ============================================

-- Create test user profiles (these would normally be created via auth)
INSERT INTO profiles (id, name, email, role) VALUES
('f47ac10b-58cc-4372-a567-0e02b2c3d001', 'Sarah Chen', 'sarah@flowyogavancouver.ca', 'instructor'),
('f47ac10b-58cc-4372-a567-0e02b2c3d002', 'Mike Rodriguez', 'mike@vanstrength.ca', 'instructor'),
('f47ac10b-58cc-4372-a567-0e02b2c3d003', 'Emma Wilson', 'emma@clayandcreate.ca', 'instructor'),
('f47ac10b-58cc-4372-a567-0e02b2c3d004', 'David Kim', 'david@boxingchampions.ca', 'instructor'),
('f47ac10b-58cc-4372-a567-0e02b2c3d005', 'Lisa Thompson', 'lisa@flowyogavancouver.ca', 'instructor'),
('f47ac10b-58cc-4372-a567-0e02b2c3d006', 'Alex Johnson', 'alex@vanstrength.ca', 'instructor');

-- Create studio staff relationships
INSERT INTO studio_staff (id, studio_id, user_id, email, first_name, last_name, role, specialties, commission_rate, status) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d101',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'f47ac10b-58cc-4372-a567-0e02b2c3d001',
    'sarah@flowyogavancouver.ca',
    'Sarah',
    'Chen',
    'owner',
    ARRAY['Vinyasa Yoga', 'Hot Yoga', 'Meditation'],
    0.75,
    'active'
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d102',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'f47ac10b-58cc-4372-a567-0e02b2c3d005',
    'lisa@flowyogavancouver.ca',
    'Lisa',
    'Thompson',
    'instructor',
    ARRAY['Hatha Yoga', 'Yin Yoga', 'Prenatal Yoga'],
    0.70,
    'active'
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d103',
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'f47ac10b-58cc-4372-a567-0e02b2c3d002',
    'mike@vanstrength.ca',
    'Mike',
    'Rodriguez',
    'owner',
    ARRAY['CrossFit', 'Olympic Lifting', 'HIIT'],
    0.80,
    'active'
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d104',
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'f47ac10b-58cc-4372-a567-0e02b2c3d006',
    'alex@vanstrength.ca',
    'Alex',
    'Johnson',
    'instructor',
    ARRAY['Personal Training', 'Strength Training'],
    0.65,
    'active'
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d105',
    'f47ac10b-58cc-4372-a567-0e02b2c3d481',
    'f47ac10b-58cc-4372-a567-0e02b2c3d003',
    'emma@clayandcreate.ca',
    'Emma',
    'Wilson',
    'owner',
    ARRAY['Wheel Throwing', 'Hand Building', 'Glazing'],
    0.85,
    'active'
);

-- ============================================
-- PART 3: CLASS CATEGORIES
-- ============================================

INSERT INTO categories (id, name, slug, description, color, icon) VALUES
('f47ac10b-58cc-4372-a567-0e02b2c3d201', 'Yoga', 'yoga', 'Mind-body practices including various yoga styles', '#8B5CF6', 'lotus'),
('f47ac10b-58cc-4372-a567-0e02b2c3d202', 'Strength Training', 'strength', 'Weight training and functional fitness', '#EF4444', 'dumbbell'),
('f47ac10b-58cc-4372-a567-0e02b2c3d203', 'Pottery', 'pottery', 'Ceramic arts and pottery making', '#F59E0B', 'palette'),
('f47ac10b-58cc-4372-a567-0e02b2c3d204', 'Boxing', 'boxing', 'Boxing training and martial arts', '#10B981', 'shield'),
('f47ac10b-58cc-4372-a567-0e02b2c3d205', 'HIIT', 'hiit', 'High-intensity interval training', '#F97316', 'zap');

-- ============================================
-- PART 4: CLASS TIERS (Credit Requirements)
-- ============================================

INSERT INTO class_tiers (id, name, credit_required, price_range_min, price_range_max, description) VALUES
('f47ac10b-58cc-4372-a567-0e02b2c3d301', 'Drop-in', 1.0, 25.00, 35.00, 'Single class attendance'),
('f47ac10b-58cc-4372-a567-0e02b2c3d302', 'Premium', 1.5, 35.00, 50.00, 'Premium instructors and smaller class sizes'),
('f47ac10b-58cc-4372-a567-0e02b2c3d303', 'Workshop', 2.0, 50.00, 80.00, 'Specialized workshops and longer sessions'),
('f47ac10b-58cc-4372-a567-0e02b2c3d304', 'Private', 3.0, 80.00, 120.00, 'One-on-one private sessions');

-- ============================================
-- PART 5: SAMPLE CLASSES
-- ============================================

-- Flow Yoga Studio Classes
INSERT INTO classes (id, studio_id, title, description, category, price, start_time, end_time, instructor_name, instructor_email, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d401',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Morning Vinyasa Flow',
    'Energizing vinyasa flow to start your day. All levels welcome.',
    'Yoga',
    28.00,
    '2024-11-06 07:00:00-08',
    '2024-11-06 08:15:00-08',
    'Sarah Chen',
    'sarah@flowyogavancouver.ca',
    20,
    12
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d402',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Hot Yoga 26+2',
    'Traditional hot yoga sequence in heated room (40°C). Bring water!',
    'Yoga',
    32.00,
    '2024-11-06 18:30:00-08',
    '2024-11-06 19:45:00-08',
    'Sarah Chen',
    'sarah@flowyogavancouver.ca',
    25,
    18
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d403',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Gentle Hatha Yoga',
    'Slow-paced practice focusing on basic postures and breathing.',
    'Yoga',
    25.00,
    '2024-11-07 10:00:00-08',
    '2024-11-07 11:15:00-08',
    'Lisa Thompson',
    'lisa@flowyogavancouver.ca',
    15,
    8
);

-- Strength & Conditioning Classes
INSERT INTO classes (id, studio_id, title, description, category, price, start_time, end_time, instructor_name, instructor_email, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d404',
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'CrossFit WOD',
    'Workout of the day featuring functional movements at high intensity.',
    'Strength Training',
    35.00,
    '2024-11-06 06:00:00-08',
    '2024-11-06 07:00:00-08',
    'Mike Rodriguez',
    'mike@vanstrength.ca',
    12,
    10
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d405',
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'Olympic Lifting Workshop',
    'Learn proper form for clean & jerk and snatch movements.',
    'Strength Training',
    65.00,
    '2024-11-08 15:00:00-08',
    '2024-11-08 17:00:00-08',
    'Mike Rodriguez',
    'mike@vanstrength.ca',
    8,
    6
);

-- Clay & Create Classes
INSERT INTO classes (id, studio_id, title, description, category, price, start_time, end_time, instructor_name, instructor_email, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d406',
    'f47ac10b-58cc-4372-a567-0e02b2c3d481',
    'Beginner Wheel Throwing',
    'Learn the basics of pottery wheel throwing. Clay and tools included.',
    'Pottery',
    45.00,
    '2024-11-06 19:00:00-08',
    '2024-11-06 21:00:00-08',
    'Emma Wilson',
    'emma@clayandcreate.ca',
    8,
    6
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d407',
    'f47ac10b-58cc-4372-a567-0e02b2c3d481',
    'Hand Building Workshop',
    'Create functional pottery using hand-building techniques.',
    'Pottery',
    55.00,
    '2024-11-09 14:00:00-08',
    '2024-11-09 17:00:00-08',
    'Emma Wilson',
    'emma@clayandcreate.ca',
    6,
    4
);

-- ============================================
-- PART 6: STUDENT ACCOUNTS
-- ============================================

-- Create test students
INSERT INTO students (id, email, first_name, last_name, phone, credit_balance, status, member_since) VALUES
('f47ac10b-58cc-4372-a567-0e02b2c3d501', 'alice.student@example.com', 'Alice', 'Johnson', '+1-604-555-1001', 15.5, 'active', '2024-01-15'),
('f47ac10b-58cc-4372-a567-0e02b2c3d502', 'bob.student@example.com', 'Bob', 'Smith', '+1-604-555-1002', 8.0, 'active', '2024-02-20'),
('f47ac10b-58cc-4372-a567-0e02b2c3d503', 'carol.student@example.com', 'Carol', 'Davis', '+1-604-555-1003', 25.0, 'active', '2024-03-10'),
('f47ac10b-58cc-4372-a567-0e02b2c3d504', 'david.student@example.com', 'David', 'Wilson', '+1-604-555-1004', 12.0, 'active', '2024-04-05'),
('f47ac10b-58cc-4372-a567-0e02b2c3d505', 'emma.student@example.com', 'Emma', 'Brown', '+1-604-555-1005', 18.5, 'active', '2024-05-12');

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify data was inserted
DO $$
BEGIN
    RAISE NOTICE 'Test data setup completed:';
    RAISE NOTICE '- Studios: %', (SELECT COUNT(*) FROM studios);
    RAISE NOTICE '- Studio Staff: %', (SELECT COUNT(*) FROM studio_staff);
    RAISE NOTICE '- Classes: %', (SELECT COUNT(*) FROM classes);
    RAISE NOTICE '- Students: %', (SELECT COUNT(*) FROM students);
    RAISE NOTICE '- Categories: %', (SELECT COUNT(*) FROM categories);
END $$;