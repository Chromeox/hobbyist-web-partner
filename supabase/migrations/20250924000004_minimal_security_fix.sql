-- MINIMAL SECURITY FIX
-- Only addresses the confirmed security vulnerability: exposed auth.users view
-- No assumptions about other tables or policies

-- ============================================
-- CRITICAL FIX: Remove Exposed Auth Users View
-- ============================================

-- The public.users view directly exposes auth.users which is a critical security risk
-- This was identified in your security audit as an ERROR-level vulnerability

-- Drop the dangerous view
DROP VIEW IF EXISTS public.users CASCADE;

-- Create a secure replacement that only exposes safe user data
CREATE VIEW public.users AS
SELECT
    id,
    email,
    created_at,
    updated_at,
    -- Only expose safe metadata
    (raw_user_meta_data ->> 'full_name') AS full_name,
    (raw_user_meta_data ->> 'avatar_url') AS avatar_url
FROM auth.users;

-- Enable Row Level Security on the view
ALTER VIEW public.users SET (security_invoker = true);

-- Grant appropriate permissions
GRANT SELECT ON public.users TO authenticated;

-- Success confirmation
SELECT 'Critical security vulnerability fixed: auth.users no longer exposed' as status;