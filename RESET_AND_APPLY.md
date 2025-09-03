# Quick Fix: Reset Password & Apply Migration

The password authentication is failing. This happens when:
- The password was recently changed
- The password contains special characters that need escaping
- The database connection is using a different password

## Fastest Solution: Use SQL Editor (No Password Needed!)

### Step 1: Open SQL Editor
**Click here:** https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql/new

### Step 2: Copy This Entire Block and Run It

```sql
-- Create categories table
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

-- Insert categories
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

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Categories are viewable by everyone" 
    ON public.categories FOR SELECT 
    USING (true);

-- Grant permissions
GRANT SELECT ON public.categories TO anon, authenticated;
```

### Step 3: Verify It Worked

Run this query:
```sql
SELECT * FROM categories;
```

You should see 8 fitness categories.

## That's It! 

Once you run the SQL above:
1. Go back to your dashboard: http://localhost:3000/dashboard
2. The connection test will show "Connected to Supabase ✓"
3. All features will work!

## If You Still Want to Reset Your Password:

1. Go here: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/settings/database
2. Click "Reset Database Password"
3. Click "Generate a new password" 
4. Click "Copy" to copy the new password
5. Save it in your password manager

But honestly, the SQL Editor method above is faster and works immediately!