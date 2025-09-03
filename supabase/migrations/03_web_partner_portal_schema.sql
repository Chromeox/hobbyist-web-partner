-- Migration: Web Partner Portal Schema
-- Description: Creates tables needed for the partner portal dashboard
-- Date: 2025-09-01

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Categories table for class categorization
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default categories
INSERT INTO public.categories (name, slug, description, icon, color, display_order) VALUES
    ('Yoga', 'yoga', 'Yoga and mindfulness classes', 'yoga', '#4F46E5', 1),
    ('Pilates', 'pilates', 'Core strengthening and flexibility', 'activity', '#06B6D4', 2),
    ('HIIT', 'hiit', 'High-intensity interval training', 'zap', '#EF4444', 3),
    ('Dance', 'dance', 'Dance and movement classes', 'music', '#EC4899', 4),
    ('Meditation', 'meditation', 'Mindfulness and meditation', 'brain', '#8B5CF6', 5),
    ('Strength', 'strength', 'Strength training and weights', 'dumbbell', '#F59E0B', 6),
    ('Cardio', 'cardio', 'Cardiovascular fitness', 'heart', '#10B981', 7),
    ('Martial Arts', 'martial-arts', 'Boxing, kickboxing, and martial arts', 'shield', '#DC2626', 8)
ON CONFLICT (slug) DO NOTHING;

-- Studios table (partner accounts)
CREATE TABLE IF NOT EXISTS public.studios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    website VARCHAR(255),
    description TEXT,
    logo_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    
    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',
    timezone VARCHAR(50) DEFAULT 'America/Los_Angeles',
    
    -- Business details
    business_type VARCHAR(50),
    tax_id VARCHAR(50),
    
    -- Settings
    payment_model VARCHAR(20) DEFAULT 'hybrid', -- credits, cash, hybrid
    commission_rate DECIMAL(5,2) DEFAULT 15.00,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- pending, active, suspended, closed
    is_verified BOOLEAN DEFAULT false,
    verification_date TIMESTAMPTZ,
    
    -- Metadata
    settings JSONB DEFAULT '{}',
    features JSONB DEFAULT '[]',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Studio staff members
CREATE TABLE IF NOT EXISTS public.studio_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    studio_id UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    
    role VARCHAR(50) NOT NULL DEFAULT 'instructor', -- owner, admin, manager, instructor, staff
    specialties TEXT[],
    bio TEXT,
    avatar_url VARCHAR(500),
    
    -- Permissions
    permissions JSONB DEFAULT '{}',
    
    -- Payroll
    payroll_info JSONB DEFAULT '{}',
    commission_rate DECIMAL(5,2),
    
    -- Performance
    performance_metrics JSONB DEFAULT '{}',
    
    -- Schedule
    schedule_preferences JSONB DEFAULT '{}',
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- pending, active, inactive, suspended
    invitation_token VARCHAR(255),
    invitation_sent_at TIMESTAMPTZ,
    invitation_accepted_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(studio_id, email)
);

-- Classes offered by studios
CREATE TABLE IF NOT EXISTS public.studio_classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    studio_id UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    instructor_id UUID REFERENCES public.studio_staff(id),
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Pricing
    price DECIMAL(10,2),
    credit_cost INTEGER DEFAULT 2,
    
    -- Schedule
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    capacity INTEGER NOT NULL DEFAULT 20,
    
    -- Location
    location VARCHAR(255),
    is_online BOOLEAN DEFAULT false,
    meeting_url VARCHAR(500),
    
    -- Media
    image_url VARCHAR(500),
    video_url VARCHAR(500),
    
    -- Settings
    level VARCHAR(20), -- beginner, intermediate, advanced, all
    tags TEXT[],
    requirements TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'draft', -- draft, published, archived
    is_featured BOOLEAN DEFAULT false,
    
    -- Stats
    total_bookings INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0,
    total_reviews INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Class schedules/sessions
CREATE TABLE IF NOT EXISTS public.class_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID NOT NULL REFERENCES public.studio_classes(id) ON DELETE CASCADE,
    instructor_id UUID REFERENCES public.studio_staff(id),
    
    -- Schedule
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    
    -- Capacity
    capacity INTEGER NOT NULL,
    enrolled_count INTEGER DEFAULT 0,
    waitlist_count INTEGER DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
    cancellation_reason TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Student profiles
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    
    -- Profile
    avatar_url VARCHAR(500),
    bio TEXT,
    emergency_contact JSONB,
    medical_notes TEXT,
    
    -- Credits
    credit_balance INTEGER DEFAULT 0,
    total_credits_purchased INTEGER DEFAULT 0,
    total_credits_used INTEGER DEFAULT 0,
    
    -- Preferences
    preferences JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}',
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, suspended
    member_since DATE DEFAULT CURRENT_DATE,
    last_active_at TIMESTAMPTZ,
    
    -- Stats
    total_classes_attended INTEGER DEFAULT 0,
    favorite_categories TEXT[],
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reservations/Bookings
CREATE TABLE IF NOT EXISTS public.reservations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.class_sessions(id),
    student_id UUID NOT NULL REFERENCES public.students(id),
    
    -- Payment
    payment_method VARCHAR(20), -- credits, cash, card
    amount_paid DECIMAL(10,2),
    credits_used INTEGER,
    
    -- Status
    status VARCHAR(20) DEFAULT 'confirmed', -- pending, confirmed, waitlisted, cancelled, completed, no_show
    check_in_time TIMESTAMPTZ,
    cancellation_time TIMESTAMPTZ,
    cancellation_reason TEXT,
    
    -- Waitlist
    waitlist_position INTEGER,
    waitlist_joined_at TIMESTAMPTZ,
    promoted_from_waitlist_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(session_id, student_id)
);

-- Waitlist entries
CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.class_sessions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    
    position INTEGER NOT NULL,
    priority VARCHAR(20) DEFAULT 'standard', -- vip, premium, standard
    
    -- Notifications
    notification_preference VARCHAR(20) DEFAULT 'email', -- email, sms, both, app
    notification_sent_at TIMESTAMPTZ,
    notification_expires_at TIMESTAMPTZ,
    
    -- Auto-enrollment
    auto_enroll BOOLEAN DEFAULT true,
    
    -- Status
    status VARCHAR(20) DEFAULT 'waiting', -- waiting, notified, enrolled, expired, cancelled
    
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    enrolled_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    
    UNIQUE(session_id, student_id)
);

-- Marketing campaigns
CREATE TABLE IF NOT EXISTS public.campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    studio_id UUID NOT NULL REFERENCES public.studios(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL, -- email, sms, push, multi
    
    -- Content
    subject VARCHAR(255),
    preview_text VARCHAR(500),
    content TEXT NOT NULL,
    cta_text VARCHAR(100),
    cta_url VARCHAR(500),
    
    -- Audience
    audience_segment VARCHAR(50),
    audience_filters JSONB DEFAULT '[]',
    recipient_count INTEGER DEFAULT 0,
    
    -- Schedule
    schedule_type VARCHAR(20) DEFAULT 'immediate', -- immediate, scheduled, recurring
    send_at TIMESTAMPTZ,
    timezone VARCHAR(50),
    frequency VARCHAR(50),
    
    -- Performance
    sent_count INTEGER DEFAULT 0,
    delivered_count INTEGER DEFAULT 0,
    opened_count INTEGER DEFAULT 0,
    clicked_count INTEGER DEFAULT 0,
    converted_count INTEGER DEFAULT 0,
    revenue_generated DECIMAL(10,2) DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'draft', -- draft, scheduled, active, paused, completed
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ
);

-- Note: Using the existing credit_packs table from migration 01
-- We'll add a studio_id column if needed for multi-tenant support

-- Add studio_id to existing credit_packs table if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'credit_packs' 
                   AND column_name = 'studio_id') THEN
        ALTER TABLE public.credit_packs ADD COLUMN studio_id UUID REFERENCES public.studios(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Note: Default credit packages are already inserted by migration 01

-- Analytics/metrics table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    studio_id UUID REFERENCES public.studios(id) ON DELETE CASCADE,
    
    event_type VARCHAR(50) NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_data JSONB DEFAULT '{}',
    
    -- Context
    user_id UUID,
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_studios_status ON public.studios(status);
CREATE INDEX IF NOT EXISTS idx_studios_slug ON public.studios(slug);
CREATE INDEX IF NOT EXISTS idx_studio_staff_studio_id ON public.studio_staff(studio_id);
CREATE INDEX IF NOT EXISTS idx_studio_staff_user_id ON public.studio_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_studio_classes_studio_id ON public.studio_classes(studio_id);
CREATE INDEX IF NOT EXISTS idx_studio_classes_category_id ON public.studio_classes(category_id);
CREATE INDEX IF NOT EXISTS idx_class_sessions_class_id ON public.class_sessions(class_id);
CREATE INDEX IF NOT EXISTS idx_class_sessions_start_time ON public.class_sessions(start_time);
CREATE INDEX IF NOT EXISTS idx_reservations_session_id ON public.reservations(session_id);
CREATE INDEX IF NOT EXISTS idx_reservations_student_id ON public.reservations(student_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_session_id ON public.waitlist(session_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_student_id ON public.waitlist(student_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_studio_id ON public.campaigns(studio_id);
CREATE INDEX IF NOT EXISTS idx_analytics_studio_id ON public.analytics_events(studio_id);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON public.analytics_events(created_at);

-- Enable Row Level Security
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.studios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.studio_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.studio_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
-- RLS for credit_packs is already enabled in migration 01
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for categories (public read)
CREATE POLICY "Categories are viewable by everyone" 
    ON public.categories FOR SELECT 
    USING (true);

-- Create RLS policies for studios
CREATE POLICY "Studios are viewable by everyone" 
    ON public.studios FOR SELECT 
    USING (true);

CREATE POLICY "Studios can update their own data" 
    ON public.studios FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM public.studio_staff 
            WHERE studio_id = studios.id 
            AND user_id = auth.uid() 
            AND role IN ('owner', 'admin')
        )
    );

-- Create RLS policies for studio_staff
CREATE POLICY "Staff can view their studio members" 
    ON public.studio_staff FOR SELECT 
    USING (
        studio_id IN (
            SELECT studio_id FROM public.studio_staff 
            WHERE user_id = auth.uid()
        )
    );

-- Create RLS policies for students
CREATE POLICY "Students can view their own profile" 
    ON public.students FOR SELECT 
    USING (user_id = auth.uid());

CREATE POLICY "Students can update their own profile" 
    ON public.students FOR UPDATE 
    USING (user_id = auth.uid());

-- Create trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_studios_updated_at BEFORE UPDATE ON public.studios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_studio_staff_updated_at BEFORE UPDATE ON public.studio_staff
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_studio_classes_updated_at BEFORE UPDATE ON public.studio_classes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_class_sessions_updated_at BEFORE UPDATE ON public.class_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_reservations_updated_at BEFORE UPDATE ON public.reservations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON public.campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
-- Trigger for credit_packs updated_at (if not already exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_credit_packs_updated_at') THEN
        CREATE TRIGGER update_credit_packs_updated_at BEFORE UPDATE ON public.credit_packs
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;