ALTER TABLE public.studios
    ADD COLUMN IF NOT EXISTS profile JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS amenities TEXT[] DEFAULT ARRAY[]::TEXT[];

COMMENT ON COLUMN public.studios.profile IS 'Landing page content, tagline, description, specialties';
COMMENT ON COLUMN public.studios.social_links IS 'Website + social handles collected during onboarding';
COMMENT ON COLUMN public.studios.amenities IS 'List of amenities surfaced in the app';
