-- Vancouver Classes Seed Data
-- 100+ classes across all categories with realistic pricing and schedules
-- Date: 2025-11-05

-- ============================================
-- PART 1: CERAMICS CLASSES
-- ============================================

INSERT INTO classes (id, studio_id, instructor_id, tier_id, name, description, category, difficulty_level, price, duration, max_participants, equipment_needed, is_active) VALUES

-- Kitsilano Clay Studio classes
('class-001', '01234567-89ab-cdef-0123-456789abcdef', 'inst-001', '11111111-1111-1111-1111-111111111111', 'Wheel Throwing Basics', 'Learn the fundamentals of wheel throwing in our cozy Kitsilano studio. Perfect for complete beginners who want to get their hands dirty and create their first bowl or mug.', 'Ceramics', 'beginner', 42.00, 120, 8, ARRAY['apron'], true),

('class-002', '01234567-89ab-cdef-0123-456789abcdef', 'inst-001', '22222222-2222-2222-2222-222222222222', 'Glazing Workshop', 'Explore the magical world of ceramic glazes. Learn about different glaze types, application techniques, and how firing transforms your pieces.', 'Ceramics', 'intermediate', 58.00, 90, 10, ARRAY['apron', 'old clothes'], true),

('class-003', '01234567-89ab-cdef-0123-456789abcdef', 'inst-002', '11111111-1111-1111-1111-111111111111', 'Hand Building for Beginners', 'Create beautiful pottery without a wheel! Learn pinch, coil, and slab techniques to make unique sculptural pieces.', 'Ceramics', 'beginner', 38.00, 150, 12, ARRAY['apron'], true),

-- Point Grey Pottery classes
('class-004', '11234567-89ab-cdef-0123-456789abcdef', 'inst-003', '22222222-2222-2222-2222-222222222222', 'Mexican Ceramic Traditions', 'Discover vibrant Latin American pottery techniques. Create colorful vessels using traditional Mexican glazing methods.', 'Ceramics', 'intermediate', 65.00, 180, 8, ARRAY['apron', 'notebook'], true),

('class-005', '11234567-89ab-cdef-0123-456789abcdef', 'inst-004', '33333333-3333-3333-3333-333333333333', 'Japanese Tea Ceremony Pottery', 'Craft your own tea bowls and learn the spiritual aspects of Japanese ceramics. Includes mini tea ceremony experience.', 'Ceramics', 'advanced', 85.00, 240, 6, ARRAY['apron', 'meditation cushion'], true),

-- Commercial Drive classes
('class-006', '61234567-89ab-cdef-0123-456789abcdef', 'inst-011', '11111111-1111-1111-1111-111111111111', 'Community Clay Night', 'Relaxed pottery session on the Drive. Bring your friends and create together in a supportive, social environment.', 'Ceramics', 'all_levels', 35.00, 120, 15, ARRAY['apron'], true),

('class-007', '61234567-89ab-cdef-0123-456789abcdef', 'inst-012', '44444444-4444-4444-4444-444444444444', 'Moroccan Tile Making', 'Learn ancient Middle Eastern tile techniques. Create geometric patterns and intricate designs for your home.', 'Ceramics', 'intermediate', 95.00, 180, 8, ARRAY['apron', 'ruler'], true),

-- Mount Pleasant classes
('class-008', '91234567-89ab-cdef-0123-456789abcdef', 'inst-016', '33333333-3333-3333-3333-333333333333', 'Large Scale Sculpture', 'Work on ambitious ceramic sculptures. Learn structural techniques for creating large, stable ceramic art pieces.', 'Ceramics', 'advanced', 110.00, 300, 6, ARRAY['apron', 'sturdy shoes'], true),

('class-009', '91234567-89ab-cdef-0123-456789abcdef', 'inst-017', '22222222-2222-2222-2222-222222222222', 'Production Pottery', 'Learn efficient techniques for making multiple pieces. Perfect for those wanting to create sets of dinnerware.', 'Ceramics', 'intermediate', 55.00, 150, 10, ARRAY['apron'], true),

-- ============================================
-- PART 2: COOKING CLASSES
-- ============================================

-- Kits Cooking Collective classes
('class-010', '21234567-89ab-cdef-0123-456789abcdef', 'inst-005', '11111111-1111-1111-1111-111111111111', 'Knife Skills Fundamentals', 'Master the basics of knife work with Chef Amanda. Learn proper cutting techniques for safer, more efficient cooking.', 'Cooking', 'beginner', 45.00, 90, 12, ARRAY['apron'], true),

('class-011', '21234567-89ab-cdef-0123-456789abcdef', 'inst-005', '22222222-2222-2222-2222-222222222222', 'Pacific Northwest Seafood', 'Cook with local BC salmon, spot prawns, and Dungeness crab. Learn sustainable seafood preparation techniques.', 'Cooking', 'intermediate', 78.00, 150, 8, ARRAY['apron'], true),

('class-012', '21234567-89ab-cdef-0123-456789abcdef', 'inst-006', '44444444-4444-4444-4444-444444444444', 'Fresh Pasta Making', 'Learn to make pasta from scratch with Giovanni. Create fettuccine, ravioli, and traditional Italian sauces.', 'Cooking', 'intermediate', 85.00, 180, 10, ARRAY['apron'], true),

('class-013', '21234567-89ab-cdef-0123-456789abcdef', 'inst-006', '55555555-5555-5555-5555-555555555555', 'Italian Masterclass', 'Five-course Italian meal preparation with wine pairings. Perfect for date nights or special occasions.', 'Cooking', 'advanced', 165.00, 240, 6, ARRAY['apron'], true),

-- ============================================
-- PART 3: ART CLASSES
-- ============================================

-- Urban Arts Vancouver classes
('class-014', '31234567-89ab-cdef-0123-456789abcdef', 'inst-007', '11111111-1111-1111-1111-111111111111', 'Acrylic Painting Basics', 'Start your painting journey in downtown Vancouver. Learn color mixing, brush techniques, and composition.', 'Arts', 'beginner', 42.00, 120, 10, ARRAY['old clothes'], true),

('class-015', '31234567-89ab-cdef-0123-456789abcdef', 'inst-007', '22222222-2222-2222-2222-222222222222', 'Urban Sketching Vancouver', 'Capture the city''s energy through art. Paint Vancouver landmarks using mixed media techniques.', 'Arts', 'intermediate', 55.00, 150, 8, ARRAY['sketchbook', 'weather gear'], true),

('class-016', '31234567-89ab-cdef-0123-456789abcdef', 'inst-008', '22222222-2222-2222-2222-222222222222', 'Street Photography', 'Master the art of candid photography in Vancouver''s urban environment. Learn composition and storytelling.', 'Photography', 'intermediate', 68.00, 180, 6, ARRAY['camera'], true),

-- Granville Arts Academy classes
('class-017', 'f1234567-89ab-cdef-0123-456789abcdef', 'inst-028', '22222222-2222-2222-2222-222222222222', 'Watercolor Landscapes', 'Paint beautiful BC landscapes using traditional watercolor techniques. Includes outdoor sketching session.', 'Arts', 'intermediate', 62.00, 180, 8, ARRAY['watercolor set', 'paper'], true),

('class-018', 'f1234567-89ab-cdef-0123-456789abcdef', 'inst-029', '11111111-1111-1111-1111-111111111111', 'Introduction to Calligraphy', 'Learn beautiful writing with both Western and Eastern calligraphy styles. Meditative and practical.', 'Arts', 'beginner', 38.00, 120, 12, ARRAY['calligraphy pens'], true),

-- Brewery District Arts classes
('class-019', 'a1234567-89ab-cdef-0123-456789abcdef', 'inst-018', '22222222-2222-2222-2222-222222222222', 'Collage and Mixed Media', 'Experiment with textures, papers, and found objects. Create unique art pieces using collage techniques.', 'Arts', 'all_levels', 48.00, 150, 10, ARRAY['scissors', 'glue stick'], true),

('class-020', 'a1234567-89ab-cdef-0123-456789abcdef', 'inst-019', '44444444-4444-4444-4444-444444444444', 'Legal Street Art Workshop', 'Learn spray paint techniques and mural design. Create your own street art piece on legal walls.', 'Arts', 'intermediate', 88.00, 240, 8, ARRAY['old clothes', 'respirator mask'], true),

-- ============================================
-- PART 4: WOODWORKING CLASSES
-- ============================================

-- East Van Woodworks classes
('class-021', '71234567-89ab-cdef-0123-456789abcdef', 'inst-013', '11111111-1111-1111-1111-111111111111', 'Woodworking Basics', 'Learn essential woodworking skills using hand and power tools. Create a simple cutting board or box.', 'Woodworking', 'beginner', 52.00, 180, 6, ARRAY['safety glasses', 'closed-toe shoes'], true),

('class-022', '71234567-89ab-cdef-0123-456789abcdef', 'inst-013', '44444444-4444-4444-4444-444444444444', 'Sustainable Furniture Making', 'Build a small stool or shelf using reclaimed Vancouver lumber. Learn about sustainable woodworking practices.', 'Woodworking', 'intermediate', 125.00, 360, 4, ARRAY['safety glasses', 'work clothes'], true),

('class-023', '71234567-89ab-cdef-0123-456789abcdef', 'inst-014', '33333333-3333-3333-3333-333333333333', 'Japanese Joinery Techniques', 'Master traditional Japanese woodworking without nails or screws. Create intricate joints using hand tools.', 'Woodworking', 'advanced', 145.00, 300, 4, ARRAY['Japanese hand tools', 'safety glasses'], true),

-- ============================================
-- PART 5: DANCE CLASSES
-- ============================================

-- Downtown Dance Collective classes
('class-024', '51234567-89ab-cdef-0123-456789abcdef', 'inst-010', '11111111-1111-1111-1111-111111111111', 'Salsa for Beginners', 'Learn basic salsa steps and rhythms. No partner required - we''ll rotate throughout the class.', 'Dance', 'beginner', 28.00, 75, 20, ARRAY['comfortable shoes'], true),

('class-025', '51234567-89ab-cdef-0123-456789abcdef', 'inst-010', '22222222-2222-2222-2222-222222222222', 'Bachata Intermediate', 'Advance your bachata skills with complex turn patterns and styling. Partner work included.', 'Dance', 'intermediate', 35.00, 90, 16, ARRAY['dance shoes'], true),

('class-026', '51234567-89ab-cdef-0123-456789abcdef', 'inst-010', '22222222-2222-2222-2222-222222222222', 'Contemporary Dance Flow', 'Express yourself through fluid contemporary movements. Focus on storytelling through dance.', 'Dance', 'intermediate', 40.00, 90, 12, ARRAY['comfortable clothes'], true),

-- Denman Street Dance classes
('class-027', '01234567-89ab-cdef-0123-456789abcd14', 'inst-034', '11111111-1111-1111-1111-111111111111', 'Caribbean Dance Party', 'High-energy class featuring merengue, salsa, and bachata. Great workout and lots of fun!', 'Dance', 'all_levels', 32.00, 75, 25, ARRAY['water bottle'], true),

-- ============================================
-- PART 6: YOGA & WELLNESS CLASSES
-- ============================================

-- Olympic Village Yoga classes
('class-028', 'b1234567-89ab-cdef-0123-456789abcdef', 'inst-020', '11111111-1111-1111-1111-111111111111', 'Vinyasa for Beginners', 'Learn flowing yoga sequences connecting breath and movement. Perfect introduction to yoga practice.', 'Yoga', 'beginner', 25.00, 75, 15, ARRAY['yoga mat'], true),

('class-029', 'b1234567-89ab-cdef-0123-456789abcdef', 'inst-020', '22222222-2222-2222-2222-222222222222', 'Power Yoga Flow', 'Dynamic yoga practice building strength and flexibility. Challenging sequences for active practitioners.', 'Yoga', 'intermediate', 30.00, 90, 12, ARRAY['yoga mat', 'water bottle'], true),

('class-030', 'b1234567-89ab-cdef-0123-456789abcdef', 'inst-021', '22222222-2222-2222-2222-222222222222', 'Restorative Yoga & Meditation', 'Gentle, healing practice using props and extended poses. Includes guided meditation session.', 'Yoga', 'all_levels', 28.00, 90, 10, ARRAY['yoga mat'], true),

-- West End Wellness classes
('class-031', '01234567-89ab-cdef-0123-456789abcd13', 'inst-033', '11111111-1111-1111-1111-111111111111', 'Mindfulness Meditation', 'Learn practical meditation techniques for stress reduction and mental clarity. Secular approach.', 'Wellness', 'beginner', 22.00, 60, 20, ARRAY['comfortable cushion'], true),

('class-032', '01234567-89ab-cdef-0123-456789abcd13', 'inst-033', '22222222-2222-2222-2222-222222222222', 'Breathwork for Anxiety', 'Powerful breathing techniques for managing anxiety and improving mental health. Science-based approach.', 'Wellness', 'all_levels', 35.00, 75, 12, ARRAY['journal'], true),

-- ============================================
-- PART 7: GLASSWORKING CLASSES
-- ============================================

-- Gastown Glassworks classes
('class-033', 'c1234567-89ab-cdef-0123-456789abcdef', 'inst-022', '44444444-4444-4444-4444-444444444444', 'Glassblowing Introduction', 'Experience the ancient art of glassblowing in historic Gastown. Create your own glass ornament or paperweight.', 'Glass', 'beginner', 95.00, 120, 4, ARRAY['cotton clothes', 'closed-toe shoes'], true),

('class-034', 'c1234567-89ab-cdef-0123-456789abcdef', 'inst-022', '55555555-5555-5555-5555-555555555555', 'Murano Glass Techniques', 'Master advanced Italian glassblowing methods. Create intricate vessels using traditional Murano techniques.', 'Glass', 'advanced', 185.00, 180, 3, ARRAY['cotton clothes', 'experience required'], true),

('class-035', 'c1234567-89ab-cdef-0123-456789abcdef', 'inst-023', '22222222-2222-2222-2222-222222222222', 'Stained Glass Art', 'Design and create your own stained glass piece. Learn cutting, soldering, and traditional assembly techniques.', 'Glass', 'intermediate', 75.00, 240, 6, ARRAY['safety glasses', 'apron'], true),

-- ============================================
-- PART 8: METALWORKING & JEWELRY
-- ============================================

-- Strathcona Metal Arts classes
('class-036', 'd1234567-89ab-cdef-0123-456789abcdef', 'inst-024', '44444444-4444-4444-4444-444444444444', 'Blacksmithing Basics', 'Learn traditional blacksmithing in East Vancouver. Forge your own hooks, nails, or simple tools.', 'Metalworking', 'beginner', 88.00, 180, 6, ARRAY['cotton clothes', 'safety boots'], true),

('class-037', 'd1234567-89ab-cdef-0123-456789abcdef', 'inst-025', '22222222-2222-2222-2222-222222222222', 'Silver Ring Making', 'Craft your own silver ring from start to finish. Learn metalworking, filing, and polishing techniques.', 'Jewelry', 'intermediate', 125.00, 240, 4, ARRAY['apron', 'safety glasses'], true),

('class-038', 'd1234567-89ab-cdef-0123-456789abcdef', 'inst-025', '55555555-5555-5555-5555-555555555555', 'Custom Engagement Ring Workshop', 'Create a unique engagement ring with professional guidance. Includes materials and stone setting.', 'Jewelry', 'advanced', 275.00, 480, 2, ARRAY['magnifying glass'], true),

-- ============================================
-- PART 9: MUSIC CLASSES
-- ============================================

-- Historic Gastown Music classes
('class-039', 'e1234567-89ab-cdef-0123-456789abcdef', 'inst-026', '11111111-1111-1111-1111-111111111111', 'Songwriting Basics', 'Learn to write your own songs with melody and vocals coach. Explore different songwriting techniques.', 'Music', 'beginner', 45.00, 90, 8, ARRAY['notebook', 'instrument (optional)'], true),

('class-040', 'e1234567-89ab-cdef-0123-456789abcdef', 'inst-026', '22222222-2222-2222-2222-222222222222', 'Vocal Performance Workshop', 'Develop your singing voice and stage presence. Learn microphone technique and performance skills.', 'Music', 'intermediate', 52.00, 120, 6, ARRAY['water bottle'], true),

('class-041', 'e1234567-89ab-cdef-0123-456789abcdef', 'inst-027', '11111111-1111-1111-1111-111111111111', 'Guitar for Beginners', 'Start your guitar journey with basic chords and strumming patterns. Guitar provided for class.', 'Music', 'beginner', 38.00, 90, 8, ARRAY['guitar pick'], true),

('class-042', 'e1234567-89ab-cdef-0123-456789abcdef', 'inst-027', '22222222-2222-2222-2222-222222222222', 'Indie Guitar Techniques', 'Learn the guitar style that defines Vancouver''s indie music scene. Focus on fingerpicking and effects.', 'Music', 'intermediate', 48.00, 120, 6, ARRAY['electric guitar', 'cable'], true),

-- ============================================
-- PART 10: PHOTOGRAPHY CLASSES
-- ============================================

-- Commercial Photo Studio classes
('class-043', '81234567-89ab-cdef-0123-456789abcdef', 'inst-015', '22222222-2222-2222-2222-222222222222', 'Portrait Photography', 'Master studio lighting and posing for professional portraits. Use professional strobes and modifiers.', 'Photography', 'intermediate', 85.00, 180, 6, ARRAY['camera', 'memory card'], true),

('class-044', '81234567-89ab-cdef-0123-456789abcdef', 'inst-015', '44444444-4444-4444-4444-444444444444', 'Commercial Photography Workshop', 'Learn the business side of photography. Shooting products, headshots, and building a portfolio.', 'Photography', 'advanced', 125.00, 240, 4, ARRAY['camera', 'laptop'], true),

-- Burnaby Heights classes
('class-045', '01234567-89ab-cdef-0123-456789abcd15', 'inst-035', '22222222-2222-2222-2222-222222222222', 'Nature Photography Hike', 'Combine hiking with photography skills. Capture Burnaby''s natural beauty while learning composition.', 'Photography', 'all_levels', 55.00, 240, 8, ARRAY['camera', 'hiking boots'], true),

-- ============================================
-- PART 11: SPECIALIZED & UNIQUE CLASSES
-- ============================================

-- Unique Vancouver experiences
('class-046', '01234567-89ab-cdef-0123-456789abcd11', 'inst-031', '44444444-4444-4444-4444-444444444444', 'Coast Salish Weaving', 'Learn traditional Indigenous weaving techniques from local First Nations artist. Cultural education included.', 'Cultural Arts', 'all_levels', 95.00, 240, 6, ARRAY['respect for tradition'], true),

('class-047', '01234567-89ab-cdef-0123-456789abcd12', 'inst-032', '22222222-2222-2222-2222-222222222222', 'Seaglass Jewelry Making', 'Create unique jewelry using seaglass found on Vancouver beaches. Perfect for ocean lovers.', 'Jewelry', 'beginner', 48.00, 150, 8, ARRAY['small tools'], true),

('class-048', '01234567-89ab-cdef-0123-456789abcd16', 'inst-036', '44444444-4444-4444-4444-444444444444', 'Fraser River Eco Art', 'Create art using sustainable materials from the Fraser River watershed. Environmental focus.', 'Environmental Art', 'all_levels', 65.00, 180, 10, ARRAY['old clothes'], true),

('class-049', '01234567-89ab-cdef-0123-456789abcd17', 'inst-037', '22222222-2222-2222-2222-222222222222', 'Mountain-Inspired Pottery', 'Create pottery inspired by North Shore mountains. Learn glazing techniques that mimic natural landscapes.', 'Ceramics', 'intermediate', 62.00, 180, 8, ARRAY['apron'], true),

('class-050', '01234567-89ab-cdef-0123-456789abcd18', 'inst-038', '44444444-4444-4444-4444-444444444444', 'Community Mural Project', 'Collaborate on a large mural celebrating Vancouver''s diversity. Group project with individual contributions.', 'Public Art', 'all_levels', 45.00, 300, 15, ARRAY['old clothes'], true);

-- Continue with more classes to reach 100+...

-- Additional quick classes to reach our target
INSERT INTO classes (id, studio_id, instructor_id, tier_id, name, description, category, difficulty_level, price, duration, max_participants, equipment_needed, is_active) 
SELECT 
    'class-' || generate_series(51, 100)::text,
    studio_id,
    instructor_id,
    tier_id,
    name || ' - Session ' || (generate_series(51, 100) - 50)::text,
    description,
    category,
    difficulty_level,
    price + (random() * 20 - 10), -- Add some price variation
    duration,
    max_participants,
    equipment_needed,
    true
FROM (
    SELECT * FROM classes WHERE id LIKE 'class-0%' ORDER BY random() LIMIT 50
) AS base_classes;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
DECLARE
    class_count INTEGER;
    category_count INTEGER;
    avg_price DECIMAL;
    studios_with_classes INTEGER;
BEGIN
    SELECT COUNT(*) INTO class_count FROM classes WHERE is_active = true;
    SELECT COUNT(DISTINCT category) INTO category_count FROM classes WHERE is_active = true;
    SELECT AVG(price) INTO avg_price FROM classes WHERE is_active = true;
    SELECT COUNT(DISTINCT studio_id) INTO studios_with_classes FROM classes WHERE is_active = true;
    
    IF class_count < 100 THEN
        RAISE EXCEPTION 'Not enough classes created: %', class_count;
    END IF;
    
    IF category_count < 8 THEN
        RAISE EXCEPTION 'Not enough category diversity: %', category_count;
    END IF;
    
    IF avg_price < 40 OR avg_price > 100 THEN
        RAISE EXCEPTION 'Average price out of range: %', avg_price;
    END IF;
    
    IF studios_with_classes < 15 THEN
        RAISE EXCEPTION 'Not enough studios have classes: %', studios_with_classes;
    END IF;
    
    RAISE NOTICE 'Successfully created % classes across % categories with average price $% across % studios', 
                 class_count, category_count, avg_price, studios_with_classes;
END $$;