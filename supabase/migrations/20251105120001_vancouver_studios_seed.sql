-- Vancouver Studios Seed Data
-- Realistic studios across Vancouver neighborhoods with proper details
-- Date: 2025-11-05

-- ============================================
-- PART 1: VANCOUVER STUDIOS DATA
-- ============================================

INSERT INTO studios (id, name, email, phone, address, city, province, postal_code, commission_rate, is_active) VALUES

-- KITSILANO STUDIOS
('01234567-89ab-cdef-0123-456789abcdef', 'Kitsilano Clay Studio', 'hello@kitsclay.com', '604-738-5555', '2367 W 4th Ave', 'Vancouver', 'BC', 'V6K 1P2', 25.00, true),
('11234567-89ab-cdef-0123-456789abcdef', 'Point Grey Pottery', 'info@pointgreypottery.ca', '604-222-3456', '4590 W 10th Ave', 'Vancouver', 'BC', 'V6R 2J1', 27.50, true),
('21234567-89ab-cdef-0123-456789abcdef', 'Kits Cooking Collective', 'cook@kitscooking.com', '604-736-8888', '2055 W 4th Ave', 'Vancouver', 'BC', 'V6J 1N3', 30.00, true),

-- DOWNTOWN/YALETOWN STUDIOS  
('31234567-89ab-cdef-0123-456789abcdef', 'Urban Arts Vancouver', 'studio@urbanartsvancouver.com', '604-687-2222', '1255 Seymour St', 'Vancouver', 'BC', 'V6B 0H1', 28.00, true),
('41234567-89ab-cdef-0123-456789abcdef', 'Yaletown Makers Space', 'makers@yaletownmakers.ca', '604-602-7777', '1328 Homer St', 'Vancouver', 'BC', 'V6B 6A7', 25.00, true),
('51234567-89ab-cdef-0123-456789abcdef', 'Downtown Dance Collective', 'dance@ddcvancouver.com', '604-669-5555', '789 Beatty St', 'Vancouver', 'BC', 'V6B 2M4', 22.50, true),

-- COMMERCIAL DRIVE STUDIOS
('61234567-89ab-cdef-0123-456789abcdef', 'The Drive Clay House', 'clay@driveartists.com', '604-253-4444', '1398 Commercial Dr', 'Vancouver', 'BC', 'V5L 3X5', 24.00, true),
('71234567-89ab-cdef-0123-456789abcdef', 'East Van Woodworks', 'wood@eastvanworks.ca', '604-215-6666', '1756 E 1st Ave', 'Vancouver', 'BC', 'V5N 1A9', 26.50, true),
('81234567-89ab-cdef-0123-456789abcdef', 'Commercial Photo Studio', 'photo@commercialphoto.ca', '604-569-3333', '2010 Commercial Dr', 'Vancouver', 'BC', 'V5N 4A9', 29.00, true),

-- MOUNT PLEASANT STUDIOS
('91234567-89ab-cdef-0123-456789abcdef', 'Main St Ceramics', 'clay@mainstreetceramics.com', '604-879-2222', '4186 Main St', 'Vancouver', 'BC', 'V5V 3P7', 25.50, true),
('a1234567-89ab-cdef-0123-456789abcdef', 'Brewery District Arts', 'arts@brewerydistrict.ca', '604-874-5555', '1681 E 1st Ave', 'Vancouver', 'BC', 'V5N 1A3', 27.00, true),
('b1234567-89ab-cdef-0123-456789abcdef', 'Olympic Village Yoga', 'yoga@ovyoga.ca', '604-559-7777', '1625 Manitoba St', 'Vancouver', 'BC', 'V5Y 0A5', 20.00, true),

-- GASTOWN/STRATHCONA STUDIOS
('c1234567-89ab-cdef-0123-456789abcdef', 'Gastown Glassworks', 'glass@gastownglassworks.com', '604-681-4444', '375 Water St', 'Vancouver', 'BC', 'V6B 5C6', 30.00, true),
('d1234567-89ab-cdef-0123-456789abcdef', 'Strathcona Metal Arts', 'metal@strathconametal.ca', '604-254-8888', '1000 Parker St', 'Vancouver', 'BC', 'V6A 2H2', 28.50, true),
('e1234567-89ab-cdef-0123-456789abcdef', 'Historic Gastown Music', 'music@gastownmusic.com', '604-682-6666', '317 Abbott St', 'Vancouver', 'BC', 'V6B 2K8', 24.50, true),

-- FAIRVIEW/SOUTH GRANVILLE STUDIOS
('f1234567-89ab-cdef-0123-456789abcdef', 'Granville Arts Academy', 'academy@granvillearts.ca', '604-736-9999', '1401 W 8th Ave', 'Vancouver', 'BC', 'V6H 1C9', 26.00, true),
('01234567-89ab-cdef-0123-456789abcd10', 'False Creek Pottery', 'pottery@falsecreek.com', '604-872-3333', '1299 W 7th Ave', 'Vancouver', 'BC', 'V6H 1B7', 25.50, true),
('01234567-89ab-cdef-0123-456789abcd11', 'South Granville Studio', 'studio@southgranville.ca', '604-733-5555', '2195 Granville St', 'Vancouver', 'BC', 'V6H 3G1', 27.50, true),

-- WEST END STUDIOS
('01234567-89ab-cdef-0123-456789abcd12', 'English Bay Arts', 'bay@englishbayarts.com', '604-682-7777', '1755 Davie St', 'Vancouver', 'BC', 'V6G 1W5', 29.50, true),
('01234567-89ab-cdef-0123-456789abcd13', 'West End Wellness', 'wellness@westendwellness.ca', '604-687-4444', '1200 Burrard St', 'Vancouver', 'BC', 'V6Z 2C7', 22.00, true),
('01234567-89ab-cdef-0123-456789abcd14', 'Denman Street Dance', 'dance@denmanstreet.com', '604-669-8888', '1823 Denman St', 'Vancouver', 'BC', 'V6G 2W5', 23.50, true),

-- BURNABY/NEW WESTMINSTER (Greater Vancouver)
('01234567-89ab-cdef-0123-456789abcd15', 'Burnaby Heights Creative', 'creative@burnabyheights.ca', '604-298-5555', '4567 Hastings St', 'Burnaby', 'BC', 'V5C 2K3', 24.50, true),
('01234567-89ab-cdef-0123-456789abcd16', 'New West River Arts', 'river@newwestarts.com', '604-525-6666', '810 Quayside Dr', 'New Westminster', 'BC', 'V3M 6B9', 26.50, true),

-- NORTH VANCOUVER STUDIOS
('01234567-89ab-cdef-0123-456789abcd17', 'North Shore Clay Co', 'clay@northshoreclay.ca', '604-985-7777', '1456 Lonsdale Ave', 'North Vancouver', 'BC', 'V7M 2H9', 25.00, true),
('01234567-89ab-cdef-0123-456789abcd18', 'Capilano Arts Centre', 'arts@capilanoarts.com', '604-987-4444', '2145 Marine Dr', 'North Vancouver', 'BC', 'V7P 1V7', 28.00, true);

-- ============================================
-- PART 2: CLASS TIERS SETUP
-- ============================================

INSERT INTO class_tiers (id, name, credit_required, price_range_min, price_range_max, description) VALUES
('11111111-1111-1111-1111-111111111111', 'Intro Classes', 1.0, 25.00, 45.00, 'Perfect for beginners, basic techniques and materials included'),
('22222222-2222-2222-2222-222222222222', 'Regular Classes', 1.5, 40.00, 75.00, 'Standard classes for developing skills, some experience helpful'),
('33333333-3333-3333-3333-333333333333', 'Advanced Classes', 2.0, 65.00, 120.00, 'Advanced techniques, requires prior experience'),
('44444444-4444-4444-4444-444444444444', 'Workshops', 2.5, 85.00, 180.00, 'Intensive workshops, special projects or guest instructors'),
('55555555-5555-5555-5555-555555555555', 'Premium Experience', 3.0, 150.00, 300.00, 'Private sessions, masterclasses, or luxury experiences');

-- ============================================
-- PART 3: UPDATE EXISTING RECORDS
-- ============================================

-- Ensure all studios have proper commission rates
UPDATE studios SET commission_rate = 25.00 WHERE commission_rate IS NULL;

-- Add some variety in commission rates based on studio type
UPDATE studios SET commission_rate = 30.00 WHERE name LIKE '%Premium%' OR name LIKE '%Luxury%';
UPDATE studios SET commission_rate = 22.50 WHERE name LIKE '%Community%' OR name LIKE '%Collective%';

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify we have studios across different neighborhoods
DO $$
DECLARE
    studio_count INTEGER;
    neighborhood_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO studio_count FROM studios WHERE is_active = true;
    
    -- Count distinct areas by postal code prefix
    SELECT COUNT(DISTINCT LEFT(postal_code, 3)) INTO neighborhood_count 
    FROM studios WHERE is_active = true;
    
    IF studio_count < 20 THEN
        RAISE EXCEPTION 'Not enough studios created: %', studio_count;
    END IF;
    
    IF neighborhood_count < 8 THEN
        RAISE EXCEPTION 'Not enough neighborhood diversity: %', neighborhood_count;
    END IF;
    
    RAISE NOTICE 'Successfully created % studios across % Vancouver neighborhoods', studio_count, neighborhood_count;
END $$;