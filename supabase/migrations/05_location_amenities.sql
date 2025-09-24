-- Missing Location Amenities table from migration 05

-- Location amenities for detailed features
CREATE TABLE IF NOT EXISTS public.location_amenities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES public.studio_locations(id) ON DELETE CASCADE,
    
    -- Amenity details
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50), -- parking, equipment, facilities, accessibility
    description TEXT,
    icon VARCHAR(50), -- icon name for UI
    
    -- Availability
    is_available BOOLEAN DEFAULT true,
    additional_cost DECIMAL(10, 2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(location_id, name)
);

-- Enable RLS
ALTER TABLE public.location_amenities ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone can view amenities
CREATE POLICY "View location amenities" ON public.location_amenities
    FOR SELECT USING (true);

-- Studios can manage their amenities (simplified policy)
CREATE POLICY "Studios manage own amenities" ON public.location_amenities
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.studio_locations sl
            WHERE sl.id = location_amenities.location_id
            -- Note: Full ownership validation would require user-studio relationship
        )
    );

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_location_amenities_location ON public.location_amenities(location_id);
CREATE INDEX IF NOT EXISTS idx_location_amenities_category ON public.location_amenities(category);

-- Grant permissions
GRANT SELECT ON public.location_amenities TO anon, authenticated;
GRANT ALL ON public.location_amenities TO authenticated;