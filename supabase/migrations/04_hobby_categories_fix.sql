-- Migration: Fix Categories for Hobby Platform
-- Description: Replace fitness categories with actual hobby categories
-- Date: 2025-09-02

-- First, clear out the fitness categories
DELETE FROM public.categories WHERE slug IN (
    'yoga', 'pilates', 'hiit', 'dance', 'meditation', 
    'strength', 'cardio', 'martial-arts'
);

-- Insert proper hobby categories
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
    ('Music Production', 'music-production', 'DJ workshops, beat making, recording', 'music', '#FF6F91', 8),
    ('Film Making', 'film-making', 'Video production and editing', 'film', '#4E5166', 9),
    
    -- Culinary Arts
    ('Cooking', 'cooking', 'Culinary classes and food preparation', 'utensils', '#FFA502', 10),
    ('Baking', 'baking', 'Bread making, pastries, and desserts', 'cake', '#FF6348', 11),
    ('Wine & Spirits', 'wine-spirits', 'Wine tasting, cocktail making, brewing', 'wine', '#722F37', 12),
    
    -- Floral & Garden
    ('Flower Arranging', 'flower-arranging', 'Bouquet making and floral design', 'flower', '#FFA8E2', 13),
    ('Gardening', 'gardening', 'Urban gardening and plant care', 'sprout', '#6AB04C', 14),
    ('Terrarium Making', 'terrarium', 'Miniature garden and succulent arrangements', 'globe', '#7BED9F', 15),
    
    -- Performance Arts
    ('Acting', 'acting', 'Theater, improv, and performance', 'drama', '#C44569', 16),
    ('Stand-up Comedy', 'comedy', 'Comedy writing and performance', 'smile', '#F8B500', 17),
    ('Voice Acting', 'voice-acting', 'Voiceover and character work', 'mic', '#574B90', 18),
    
    -- Traditional Crafts
    ('Knitting', 'knitting', 'Knitting and crocheting', 'package', '#FD79A8', 19),
    ('Calligraphy', 'calligraphy', 'Hand lettering and penmanship', 'feather', '#2D3436', 20),
    ('Bookbinding', 'bookbinding', 'Book making and paper crafts', 'book', '#6C5CE7', 21),
    ('Candle Making', 'candle-making', 'Wax crafts and aromatherapy', 'flame', '#FDCB6E', 22),
    ('Soap Making', 'soap-making', 'Natural soap and bath products', 'droplet', '#A8E6CF', 23),
    
    -- Unique Hobbies
    ('Fencing', 'fencing', 'Classical and modern fencing', 'shield', '#34495E', 24),
    ('Archery', 'archery', 'Target shooting and traditional archery', 'target', '#16A085', 25),
    ('Glass Blowing', 'glass-blowing', 'Glass art and sculpture', 'wind', '#3498DB', 26),
    ('Leather Working', 'leather-working', 'Leather crafting and tooling', 'briefcase', '#795548', 27),
    ('3D Printing', '3d-printing', 'Digital design and fabrication', 'box', '#E91E63', 28),
    ('Board Game Design', 'game-design', 'Create your own tabletop games', 'dice', '#9B59B6', 29),
    ('Magic & Illusion', 'magic', 'Learn magic tricks and illusions', 'sparkles', '#8E44AD', 30)
ON CONFLICT (slug) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    display_order = EXCLUDED.display_order;

-- Add a few more contemporary hobbies
INSERT INTO public.categories (name, slug, description, icon, color, display_order) VALUES
    ('Podcasting', 'podcasting', 'Audio production and storytelling', 'radio', '#00B894', 31),
    ('Drone Flying', 'drone-flying', 'Aerial photography and racing', 'navigation', '#0984E3', 32),
    ('Escape Room Design', 'escape-room', 'Puzzle and game creation', 'lock', '#6C5CE7', 33),
    ('Cosplay', 'cosplay', 'Costume making and character design', 'shirt', '#FD79A8', 34),
    ('Perfume Making', 'perfume-making', 'Fragrance blending and aromatherapy', 'sparkle', '#E17055', 35)
ON CONFLICT (slug) DO NOTHING;

-- Update any existing class data that might reference old categories
-- This ensures data integrity if any test data was created
UPDATE public.studio_classes 
SET category_id = NULL 
WHERE category_id IN (
    SELECT id FROM public.categories 
    WHERE slug IN ('yoga', 'pilates', 'hiit', 'dance', 'meditation', 'strength', 'cardio', 'martial-arts')
);