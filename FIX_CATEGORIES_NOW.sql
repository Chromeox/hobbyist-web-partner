-- Quick Fix: Replace Fitness with Hobby Categories
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mcjqvdzdhtcvbrejvrtp/sql/new

-- Clear fitness categories if they exist
DELETE FROM public.categories;

-- Insert proper hobby categories for Hobbyist platform
INSERT INTO public.categories (name, slug, description, icon, color, display_order) VALUES
    -- Arts & Crafts
    ('Painting', 'painting', 'Oil, acrylic, watercolor painting classes', 'palette', '#FF6B6B', 1),
    ('Pottery', 'pottery', 'Ceramics, wheel throwing, and clay sculpting', 'coffee', '#4ECDC4', 2),
    ('Sewing', 'sewing', 'Sewing, embroidery, and textile arts', 'scissors', '#95E1D3', 3),
    ('Jewelry Making', 'jewelry-making', 'Beading, wire wrapping, metalsmithing', 'gem', '#F38181', 4),
    ('Woodworking', 'woodworking', 'Carpentry, carving, and furniture making', 'hammer', '#8B7355', 5),
    
    -- Creative Arts
    ('Photography', 'photography', 'Digital and film photography workshops', 'camera', '#5C7CFA', 6),
    ('Creative Writing', 'creative-writing', 'Fiction, poetry, and storytelling', 'pen-tool', '#845EC2', 7),
    ('DJ Workshops', 'dj-workshops', 'Mixing, beat making, music production', 'music', '#FF6F91', 8),
    
    -- Culinary Arts
    ('Cooking', 'cooking', 'Culinary classes and food preparation', 'utensils', '#FFA502', 9),
    ('Baking', 'baking', 'Bread making, pastries, and desserts', 'cake', '#FF6348', 10),
    
    -- Floral & Garden
    ('Flower Arranging', 'flower-arranging', 'Bouquet making and floral design', 'flower', '#FFA8E2', 11),
    ('Gardening', 'gardening', 'Urban gardening and plant care', 'sprout', '#6AB04C', 12),
    
    -- Traditional Crafts
    ('Knitting', 'knitting', 'Knitting and crocheting', 'package', '#FD79A8', 13),
    ('Calligraphy', 'calligraphy', 'Hand lettering and penmanship', 'feather', '#2D3436', 14),
    ('Candle Making', 'candle-making', 'Wax crafts and aromatherapy', 'flame', '#FDCB6E', 15),
    
    -- Unique Hobbies
    ('Fencing', 'fencing', 'Classical and modern fencing', 'shield', '#34495E', 16),
    ('Archery', 'archery', 'Target shooting and traditional archery', 'target', '#16A085', 17),
    ('Glass Blowing', 'glass-blowing', 'Glass art and sculpture', 'wind', '#3498DB', 18),
    ('Leather Working', 'leather-working', 'Leather crafting and tooling', 'briefcase', '#795548', 19),
    ('Board Game Design', 'game-design', 'Create your own tabletop games', 'dice', '#9B59B6', 20)
ON CONFLICT (slug) DO NOTHING;

-- Verify the categories were added
SELECT name, description FROM public.categories ORDER BY display_order;