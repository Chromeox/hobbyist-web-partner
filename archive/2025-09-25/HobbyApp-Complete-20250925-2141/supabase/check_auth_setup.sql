-- Check if auth schema and users view exist
DO $$
BEGIN
    -- Check if auth.users table exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) THEN
        RAISE NOTICE 'auth.users table does not exist - this is a core Supabase table that should exist';
    ELSE
        RAISE NOTICE 'auth.users table exists';
    END IF;

    -- Check if public.users view exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.views 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ) THEN
        -- Create a simple users view in public schema
        CREATE OR REPLACE VIEW public.users AS
        SELECT 
            id,
            email,
            created_at,
            updated_at,
            last_sign_in_at,
            raw_user_meta_data->>'full_name' as full_name,
            raw_user_meta_data->>'avatar_url' as avatar_url
        FROM auth.users;
        
        COMMENT ON VIEW public.users IS 'Public view of user data for application access';
        
        -- Grant appropriate permissions
        GRANT SELECT ON public.users TO authenticated;
        GRANT SELECT ON public.users TO anon;
        
        RAISE NOTICE 'Created public.users view';
    ELSE
        RAISE NOTICE 'public.users view already exists';
    END IF;
END $$;

-- Create user_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text,
    avatar_url text,
    bio text,
    phone text,
    user_type text DEFAULT 'student' CHECK (user_type IN ('student', 'instructor', 'admin')),
    preferences jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile" 
    ON public.user_profiles 
    FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.user_profiles 
    FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON public.user_profiles 
    FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Create trigger to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.user_profiles (id, full_name, avatar_url)
    VALUES (
        new.id,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'avatar_url'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.user_profiles TO authenticated;
GRANT SELECT ON public.user_profiles TO anon;