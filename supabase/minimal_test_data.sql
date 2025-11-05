-- Minimal Test Data Setup for Partner Portal
-- Working with current schema constraints
-- Date: 2024-11-05

-- ============================================
-- PART 1: CREATE CALENDAR INTEGRATIONS (Required for classes)
-- ============================================

-- First create calendar integrations (required for classes table)
INSERT INTO calendar_integrations (id, provider, studio_id, sync_enabled, sync_status) VALUES
('f47ac10b-58cc-4372-a567-0e02b2c3d601', 'manual', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', true, 'active'),
('f47ac10b-58cc-4372-a567-0e02b2c3d602', 'manual', 'f47ac10b-58cc-4372-a567-0e02b2c3d480', true, 'active'),
('f47ac10b-58cc-4372-a567-0e02b2c3d603', 'manual', 'f47ac10b-58cc-4372-a567-0e02b2c3d481', true, 'active');

-- ============================================
-- PART 2: SAMPLE CLASSES (Using correct schema)
-- ============================================

-- Flow Yoga Studio Classes
INSERT INTO classes (id, integration_id, external_id, provider, studio_id, title, description, start_time, end_time, instructor_name, instructor_email, location, category, price, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d401',
    'f47ac10b-58cc-4372-a567-0e02b2c3d601',
    'flow-morning-vinyasa-001',
    'manual',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Morning Vinyasa Flow',
    'Energizing vinyasa flow to start your day. All levels welcome.',
    '2024-11-06 07:00:00-08',
    '2024-11-06 08:15:00-08',
    'Sarah Chen',
    'sarah@flowyogavancouver.ca',
    'Studio A',
    'Yoga',
    28.00,
    20,
    12
),
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d402',
    'f47ac10b-58cc-4372-a567-0e02b2c3d601',
    'flow-hot-yoga-001',
    'manual',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479',
    'Hot Yoga 26+2',
    'Traditional hot yoga sequence in heated room (40°C). Bring water!',
    '2024-11-06 18:30:00-08',
    '2024-11-06 19:45:00-08',
    'Sarah Chen',
    'sarah@flowyogavancouver.ca',
    'Hot Room',
    'Yoga',
    32.00,
    25,
    18
);

-- Strength & Conditioning Classes
INSERT INTO classes (id, integration_id, external_id, provider, studio_id, title, description, start_time, end_time, instructor_name, instructor_email, location, category, price, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d404',
    'f47ac10b-58cc-4372-a567-0e02b2c3d602',
    'strength-crossfit-001',
    'manual',
    'f47ac10b-58cc-4372-a567-0e02b2c3d480',
    'CrossFit WOD',
    'Workout of the day featuring functional movements at high intensity.',
    '2024-11-06 06:00:00-08',
    '2024-11-06 07:00:00-08',
    'Mike Rodriguez',
    'mike@vanstrength.ca',
    'Main Gym',
    'Strength Training',
    35.00,
    12,
    10
);

-- Clay & Create Classes  
INSERT INTO classes (id, integration_id, external_id, provider, studio_id, title, description, start_time, end_time, instructor_name, instructor_email, location, category, price, max_participants, current_participants) VALUES
(
    'f47ac10b-58cc-4372-a567-0e02b2c3d406',
    'f47ac10b-58cc-4372-a567-0e02b2c3d603',
    'clay-wheel-beginner-001',
    'manual',
    'f47ac10b-58cc-4372-a567-0e02b2c3d481',
    'Beginner Wheel Throwing',
    'Learn the basics of pottery wheel throwing. Clay and tools included.',
    '2024-11-06 19:00:00-08',
    '2024-11-06 21:00:00-08',
    'Emma Wilson',
    'emma@clayandcreate.ca',
    'Wheel Room',
    'Pottery',
    45.00,
    8,
    6
);

-- ============================================
-- PART 3: SAMPLE BOOKINGS (Using student_id from students table)
-- ============================================

-- Get student IDs for bookings
INSERT INTO bookings (id, student_id, session_id, amount_paid, status, credits_used, payment_method) 
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d701',
    'f47ac10b-58cc-4372-a567-0e02b2c3d501', -- Alice Johnson
    'f47ac10b-58cc-4372-a567-0e02b2c3d401', -- Morning Vinyasa (using class ID as session)
    28.00,
    'confirmed',
    1,
    'credits'
WHERE EXISTS (SELECT 1 FROM students WHERE id = 'f47ac10b-58cc-4372-a567-0e02b2c3d501');

INSERT INTO bookings (id, student_id, session_id, amount_paid, status, credits_used, payment_method) 
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d702',
    'f47ac10b-58cc-4372-a567-0e02b2c3d502', -- Bob Smith  
    'f47ac10b-58cc-4372-a567-0e02b2c3d404', -- CrossFit WOD
    35.00,
    'confirmed',
    1,
    'card'
WHERE EXISTS (SELECT 1 FROM students WHERE id = 'f47ac10b-58cc-4372-a567-0e02b2c3d502');

INSERT INTO bookings (id, student_id, session_id, amount_paid, status, credits_used, payment_method) 
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d703',
    'f47ac10b-58cc-4372-a567-0e02b2c3d503', -- Carol Davis
    'f47ac10b-58cc-4372-a567-0e02b2c3d406', -- Pottery class
    45.00,
    'confirmed',
    2,
    'credits'
WHERE EXISTS (SELECT 1 FROM students WHERE id = 'f47ac10b-58cc-4372-a567-0e02b2c3d503');

-- ============================================
-- PART 4: CREDIT TRANSACTIONS
-- ============================================

-- Sample credit transactions
INSERT INTO credit_transactions (id, user_id, transaction_type, amount, credits_amount, balance_after, description, reference_type) 
SELECT 
    'f47ac10b-58cc-4372-a567-0e02b2c3d801',
    s.user_id,
    'purchase',
    75.00,
    25,
    25,
    'Credit pack purchase - 25 credits',
    'purchase'
FROM students s 
WHERE s.id = 'f47ac10b-58cc-4372-a567-0e02b2c3d501'
AND s.user_id IS NOT NULL
LIMIT 1;

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify data was inserted
DO $$
BEGIN
    RAISE NOTICE 'Minimal test data setup completed:';
    RAISE NOTICE '- Studios: %', (SELECT COUNT(*) FROM studios);
    RAISE NOTICE '- Calendar Integrations: %', (SELECT COUNT(*) FROM calendar_integrations);
    RAISE NOTICE '- Classes: %', (SELECT COUNT(*) FROM classes);
    RAISE NOTICE '- Students: %', (SELECT COUNT(*) FROM students);
    RAISE NOTICE '- Bookings: %', (SELECT COUNT(*) FROM bookings);
    RAISE NOTICE '- Credit Transactions: %', (SELECT COUNT(*) FROM credit_transactions);
    
    -- Show studio data
    RAISE NOTICE 'Studio Details:';
    FOR r IN SELECT name, status, city FROM studios ORDER BY name LOOP
        RAISE NOTICE '  - % (%) in %', r.name, r.status, r.city;
    END LOOP;
END $$;