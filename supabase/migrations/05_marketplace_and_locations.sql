-- Migration: Instructor Marketplace and Multi-Location Support
-- Description: Add support for independent instructors and multiple studio locations
-- Date: 2025-09-02

-- =====================================================
-- MULTI-LOCATION SUPPORT
-- =====================================================

-- Studio locations table
CREATE TABLE IF NOT EXISTS public.studio_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    studio_id UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Canada',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(20),
    email VARCHAR(255),
    
    -- Location-specific settings
    timezone VARCHAR(50) DEFAULT 'America/Vancouver',
    currency VARCHAR(3) DEFAULT 'CAD',
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Operating hours (JSONB for flexibility)
    operating_hours JSONB DEFAULT '{}',
    amenities TEXT[],
    capacity INTEGER,
    
    -- Manager assignment
    manager_id UUID REFERENCES auth.users(id),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(studio_id, slug)
);

-- Add location_id to existing tables
ALTER TABLE public.classes 
    ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.studio_locations(id);

ALTER TABLE public.instructors 
    ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.studio_locations(id);

ALTER TABLE public.bookings 
    ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.studio_locations(id);

-- =====================================================
-- INSTRUCTOR MARKETPLACE
-- =====================================================

-- Independent instructor profiles
CREATE TABLE IF NOT EXISTS public.instructor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Profile information
    display_name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    bio TEXT,
    tagline VARCHAR(300),
    profile_image_url TEXT,
    cover_image_url TEXT,
    
    -- Professional details
    specialties TEXT[],
    certifications JSONB DEFAULT '[]',
    years_experience INTEGER,
    languages VARCHAR(50)[],
    
    -- Verification and status
    is_verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMPTZ,
    background_check_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    
    -- Ratings and stats
    average_rating DECIMAL(3, 2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    total_classes_taught INTEGER DEFAULT 0,
    total_students INTEGER DEFAULT 0,
    
    -- Availability and preferences
    availability JSONB DEFAULT '{}',
    travel_radius_km INTEGER DEFAULT 10,
    min_class_size INTEGER DEFAULT 1,
    max_class_size INTEGER DEFAULT 20,
    
    -- Pricing
    hourly_rate DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'CAD',
    accepts_custom_rates BOOLEAN DEFAULT true,
    
    -- Social and portfolio
    website_url TEXT,
    instagram_handle VARCHAR(100),
    youtube_channel TEXT,
    portfolio_items JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instructor-Studio relationships
CREATE TABLE IF NOT EXISTS public.instructor_studio_partnerships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES public.instructor_profiles(id) ON DELETE CASCADE,
    studio_id UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.studio_locations(id),
    
    -- Partnership details
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected, suspended
    partnership_type VARCHAR(50) DEFAULT 'guest', -- guest, regular, exclusive
    
    -- Terms
    commission_rate DECIMAL(5, 2) DEFAULT 30.00, -- Studio's commission percentage
    base_rate DECIMAL(10, 2), -- Instructor's base rate for this studio
    
    -- Application/Invitation
    initiated_by VARCHAR(20), -- studio, instructor
    application_message TEXT,
    studio_notes TEXT,
    
    -- Dates
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    starts_at DATE,
    ends_at DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(instructor_id, studio_id, location_id)
);

-- Instructor reviews
CREATE TABLE IF NOT EXISTS public.instructor_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES public.instructor_profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES auth.users(id),
    booking_id UUID REFERENCES public.bookings(id),
    
    -- Review content
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    comment TEXT,
    
    -- Review metadata
    is_verified_booking BOOLEAN DEFAULT true,
    is_visible BOOLEAN DEFAULT true,
    helpful_count INTEGER DEFAULT 0,
    
    -- Response
    instructor_response TEXT,
    response_date TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(instructor_id, student_id, booking_id)
);

-- Students following instructors
CREATE TABLE IF NOT EXISTS public.instructor_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES public.instructor_profiles(id) ON DELETE CASCADE,
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Notification preferences
    notify_new_classes BOOLEAN DEFAULT true,
    notify_schedule_changes BOOLEAN DEFAULT true,
    notify_special_events BOOLEAN DEFAULT true,
    
    followed_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(instructor_id, follower_id)
);

-- Instructor availability calendar
CREATE TABLE IF NOT EXISTS public.instructor_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instructor_id UUID NOT NULL REFERENCES public.instructor_profiles(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.studio_locations(id),
    
    -- Availability window
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- Specific date overrides
    specific_date DATE,
    is_available BOOLEAN DEFAULT true,
    
    -- Preferences
    preferred_categories UUID[],
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Instructor specialties lookup table
CREATE TABLE IF NOT EXISTS public.instructor_specialties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50),
    description TEXT,
    icon VARCHAR(50),
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert common instructor specialties
INSERT INTO public.instructor_specialties (name, slug, category, icon) VALUES
    ('Pottery Wheel Throwing', 'pottery-wheel', 'Pottery', 'circle'),
    ('Hand Building Ceramics', 'hand-building', 'Pottery', 'hand'),
    ('Oil Painting', 'oil-painting', 'Painting', 'palette'),
    ('Watercolor Techniques', 'watercolor', 'Painting', 'droplet'),
    ('DJ Mixing', 'dj-mixing', 'Music', 'disc'),
    ('Music Production', 'music-production', 'Music', 'headphones'),
    ('Classical Fencing', 'classical-fencing', 'Sports', 'sword'),
    ('Sport Fencing', 'sport-fencing', 'Sports', 'medal'),
    ('Traditional Archery', 'traditional-archery', 'Sports', 'bow'),
    ('Sewing Basics', 'sewing-basics', 'Textiles', 'needle'),
    ('Pattern Making', 'pattern-making', 'Textiles', 'ruler'),
    ('Jewelry Design', 'jewelry-design', 'Crafts', 'gem'),
    ('Wire Wrapping', 'wire-wrapping', 'Crafts', 'link'),
    ('Flower Arrangement', 'flower-arrangement', 'Floral', 'flower'),
    ('Ikebana', 'ikebana', 'Floral', 'branch'),
    ('Bread Baking', 'bread-baking', 'Culinary', 'bread'),
    ('Pastry Making', 'pastry-making', 'Culinary', 'cake'),
    ('Glass Blowing', 'glass-blowing', 'Glass', 'fire'),
    ('Stained Glass', 'stained-glass', 'Glass', 'window'),
    ('Calligraphy', 'calligraphy', 'Writing', 'pen')
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_studio_locations_studio_id ON public.studio_locations(studio_id);
CREATE INDEX IF NOT EXISTS idx_studio_locations_is_active ON public.studio_locations(is_active);
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_user_id ON public.instructor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_slug ON public.instructor_profiles(slug);
CREATE INDEX IF NOT EXISTS idx_instructor_profiles_average_rating ON public.instructor_profiles(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_instructor_partnerships_studio ON public.instructor_studio_partnerships(studio_id, status);
CREATE INDEX IF NOT EXISTS idx_instructor_partnerships_instructor ON public.instructor_studio_partnerships(instructor_id, status);
CREATE INDEX IF NOT EXISTS idx_instructor_reviews_instructor ON public.instructor_reviews(instructor_id, is_visible);
CREATE INDEX IF NOT EXISTS idx_instructor_followers_instructor ON public.instructor_followers(instructor_id);
CREATE INDEX IF NOT EXISTS idx_instructor_followers_follower ON public.instructor_followers(follower_id);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- Studio Locations
ALTER TABLE public.studio_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Studio locations viewable by everyone" 
    ON public.studio_locations FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Studio owners can manage their locations" 
    ON public.studio_locations FOR ALL 
    USING (studio_id IN (
        SELECT id FROM public.studios WHERE owner_id = auth.uid()
    ));

-- Instructor Profiles
ALTER TABLE public.instructor_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructor profiles viewable by everyone" 
    ON public.instructor_profiles FOR SELECT 
    USING (is_active = true);

CREATE POLICY "Instructors can manage their own profile" 
    ON public.instructor_profiles FOR ALL 
    USING (user_id = auth.uid());

-- Instructor Reviews
ALTER TABLE public.instructor_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviews viewable by everyone" 
    ON public.instructor_reviews FOR SELECT 
    USING (is_visible = true);

CREATE POLICY "Students can write reviews for verified bookings" 
    ON public.instructor_reviews FOR INSERT 
    WITH CHECK (
        student_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.bookings 
            WHERE id = booking_id 
            AND user_id = auth.uid()
            AND status = 'completed'
        )
    );

-- Instructor Followers
ALTER TABLE public.instructor_followers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own follows" 
    ON public.instructor_followers FOR ALL 
    USING (follower_id = auth.uid());

-- Grant permissions
GRANT SELECT ON public.studio_locations TO anon, authenticated;
GRANT ALL ON public.studio_locations TO authenticated;

GRANT SELECT ON public.instructor_profiles TO anon, authenticated;
GRANT ALL ON public.instructor_profiles TO authenticated;

GRANT SELECT ON public.instructor_reviews TO anon, authenticated;
GRANT ALL ON public.instructor_reviews TO authenticated;

GRANT SELECT ON public.instructor_followers TO anon, authenticated;
GRANT ALL ON public.instructor_followers TO authenticated;

GRANT SELECT ON public.instructor_specialties TO anon, authenticated;

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update instructor rating after new review
CREATE OR REPLACE FUNCTION update_instructor_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.instructor_profiles
    SET 
        average_rating = (
            SELECT AVG(rating)::DECIMAL(3,2)
            FROM public.instructor_reviews
            WHERE instructor_id = NEW.instructor_id
            AND is_visible = true
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM public.instructor_reviews
            WHERE instructor_id = NEW.instructor_id
            AND is_visible = true
        )
    WHERE id = NEW.instructor_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger for updating ratings
CREATE TRIGGER update_instructor_rating_trigger
AFTER INSERT OR UPDATE ON public.instructor_reviews
FOR EACH ROW
EXECUTE FUNCTION update_instructor_rating();

-- Function to get instructor's upcoming classes across all locations
CREATE OR REPLACE FUNCTION get_instructor_schedule(
    p_instructor_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_end_date DATE DEFAULT CURRENT_DATE + INTERVAL '30 days'
)
RETURNS TABLE (
    class_id UUID,
    class_name VARCHAR,
    studio_name VARCHAR,
    location_name VARCHAR,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    available_spots INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        s.name,
        sl.name,
        cs.scheduled_for as start_time,
        cs.scheduled_for + INTERVAL '1 hour' as end_time,
        cs.spots_total - cs.spots_used as available_spots
    FROM public.classes c
    JOIN public.class_schedules cs ON cs.class_id = c.id
    JOIN public.studios s ON s.id = c.studio_id
    LEFT JOIN public.studio_locations sl ON sl.id = c.location_id
    WHERE c.instructor_id = p_instructor_id
    AND cs.scheduled_for::DATE BETWEEN p_start_date AND p_end_date
    AND cs.status = 'scheduled'
    ORDER BY cs.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;