-- Review and Rating System Migration
-- Creates comprehensive review system for classes with media support, moderation, and analytics

-- Create class_reviews table for storing reviews
CREATE TABLE IF NOT EXISTS class_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    verified_booking BOOLEAN DEFAULT FALSE,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure user can only review each class once
    CONSTRAINT unique_class_user_review UNIQUE (class_id, user_id)
);

-- Create review_media table for photos and videos
CREATE TABLE IF NOT EXISTS review_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES class_reviews(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('photo', 'video')),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_size INTEGER,
    mime_type VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create review_votes table for helpful/not helpful votes
CREATE TABLE IF NOT EXISTS review_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES class_reviews(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vote_type VARCHAR(20) NOT NULL CHECK (vote_type IN ('helpful', 'not_helpful')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure user can only vote once per review
    CONSTRAINT unique_review_user_vote UNIQUE (review_id, user_id)
);

-- Create instructor_responses table for instructor replies
CREATE TABLE IF NOT EXISTS instructor_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES class_reviews(id) ON DELETE CASCADE,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    response_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure only one response per review
    CONSTRAINT unique_review_response UNIQUE (review_id)
);

-- Create review_moderation table for moderation actions
CREATE TABLE IF NOT EXISTS review_moderation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES class_reviews(id) ON DELETE CASCADE,
    moderator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('approved', 'rejected', 'flagged', 'under_review')),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create review_tags table for categorizing reviews
CREATE TABLE IF NOT EXISTS review_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES class_reviews(id) ON DELETE CASCADE,
    tag VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_class_reviews_class_id ON class_reviews(class_id);
CREATE INDEX IF NOT EXISTS idx_class_reviews_instructor_id ON class_reviews(instructor_id);
CREATE INDEX IF NOT EXISTS idx_class_reviews_user_id ON class_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_class_reviews_rating ON class_reviews(rating);
CREATE INDEX IF NOT EXISTS idx_class_reviews_created_at ON class_reviews(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_class_reviews_approved ON class_reviews(is_approved);

CREATE INDEX IF NOT EXISTS idx_review_media_review_id ON review_media(review_id);
CREATE INDEX IF NOT EXISTS idx_review_votes_review_id ON review_votes(review_id);
CREATE INDEX IF NOT EXISTS idx_instructor_responses_review_id ON instructor_responses(review_id);
CREATE INDEX IF NOT EXISTS idx_review_moderation_review_id ON review_moderation(review_id);
CREATE INDEX IF NOT EXISTS idx_review_tags_review_id ON review_tags(review_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_class_reviews_updated_at BEFORE UPDATE ON class_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_instructor_responses_updated_at BEFORE UPDATE ON instructor_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to calculate average rating for a class
CREATE OR REPLACE FUNCTION get_class_average_rating(class_uuid UUID)
RETURNS DECIMAL(3,2) AS $$
BEGIN
    RETURN COALESCE(
        (SELECT ROUND(AVG(rating)::numeric, 2) 
         FROM class_reviews 
         WHERE class_id = class_uuid AND is_approved = TRUE),
        0
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to get review statistics
CREATE OR REPLACE FUNCTION get_review_stats(instructor_uuid UUID DEFAULT NULL)
RETURNS TABLE(
    total_reviews BIGINT,
    average_rating DECIMAL(3,2),
    rating_distribution JSONB,
    response_rate DECIMAL(5,2),
    helpful_votes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(cr.id)::BIGINT as total_reviews,
        COALESCE(ROUND(AVG(cr.rating)::numeric, 2), 0) as average_rating,
        COALESCE(
            jsonb_build_object(
                '5_star', COUNT(*) FILTER (WHERE cr.rating = 5),
                '4_star', COUNT(*) FILTER (WHERE cr.rating = 4),
                '3_star', COUNT(*) FILTER (WHERE cr.rating = 3),
                '2_star', COUNT(*) FILTER (WHERE cr.rating = 2),
                '1_star', COUNT(*) FILTER (WHERE cr.rating = 1)
            ),
            '{}'::jsonb
        ) as rating_distribution,
        COALESCE(
            ROUND(
                (COUNT(ir.id)::DECIMAL / NULLIF(COUNT(cr.id), 0)) * 100,
                2
            ),
            0
        ) as response_rate,
        COALESCE(
            (SELECT COUNT(*) FROM review_votes rv 
             JOIN class_reviews cr2 ON rv.review_id = cr2.id
             WHERE rv.vote_type = 'helpful' 
             AND (instructor_uuid IS NULL OR cr2.instructor_id = instructor_uuid)),
            0
        )::BIGINT as helpful_votes
    FROM class_reviews cr
    LEFT JOIN instructor_responses ir ON cr.id = ir.review_id
    WHERE cr.is_approved = TRUE
    AND (instructor_uuid IS NULL OR cr.instructor_id = instructor_uuid);
END;
$$ LANGUAGE plpgsql;

-- Enable RLS (Row Level Security) for all tables
ALTER TABLE class_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE instructor_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_tags ENABLE ROW LEVEL SECURITY;

-- RLS Policies for class_reviews
CREATE POLICY "Users can view approved reviews" ON class_reviews
    FOR SELECT USING (is_approved = TRUE);

CREATE POLICY "Users can create their own reviews" ON class_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON class_reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Instructors can view all reviews for their classes" ON class_reviews
    FOR SELECT USING (auth.uid() = instructor_id);

-- RLS Policies for review_media
CREATE POLICY "Anyone can view approved review media" ON review_media
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM class_reviews cr 
            WHERE cr.id = review_media.review_id 
            AND cr.is_approved = TRUE
        )
    );

CREATE POLICY "Users can add media to their reviews" ON review_media
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM class_reviews cr 
            WHERE cr.id = review_media.review_id 
            AND cr.user_id = auth.uid()
        )
    );

-- RLS Policies for review_votes
CREATE POLICY "Anyone can view votes" ON review_votes FOR SELECT USING (TRUE);

CREATE POLICY "Users can vote on reviews" ON review_votes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their votes" ON review_votes
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for instructor_responses
CREATE POLICY "Anyone can view instructor responses" ON instructor_responses FOR SELECT USING (TRUE);

CREATE POLICY "Instructors can respond to reviews" ON instructor_responses
    FOR INSERT WITH CHECK (auth.uid() = instructor_id);

CREATE POLICY "Instructors can update their responses" ON instructor_responses
    FOR UPDATE USING (auth.uid() = instructor_id);

-- RLS Policies for review_moderation (admin only)
CREATE POLICY "Admins can manage review moderation" ON review_moderation
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.id = auth.uid() 
            AND u.role = 'admin'
        )
    );

-- RLS Policies for review_tags
CREATE POLICY "Anyone can view review tags" ON review_tags FOR SELECT USING (TRUE);

CREATE POLICY "Users can tag their reviews" ON review_tags
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM class_reviews cr 
            WHERE cr.id = review_tags.review_id 
            AND cr.user_id = auth.uid()
        )
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON class_reviews TO authenticated;
GRANT SELECT, INSERT ON review_media TO authenticated;
GRANT SELECT, INSERT, UPDATE ON review_votes TO authenticated;
GRANT SELECT, INSERT, UPDATE ON instructor_responses TO authenticated;
GRANT SELECT ON review_moderation TO authenticated;
GRANT SELECT, INSERT ON review_tags TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_class_average_rating(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_review_stats(UUID) TO authenticated;

-- Add helpful comments
COMMENT ON TABLE class_reviews IS 'Stores user reviews and ratings for classes';
COMMENT ON TABLE review_media IS 'Stores photos and videos attached to reviews';
COMMENT ON TABLE review_votes IS 'Stores helpful/not helpful votes on reviews';
COMMENT ON TABLE instructor_responses IS 'Stores instructor responses to reviews';
COMMENT ON TABLE review_moderation IS 'Tracks moderation actions on reviews';
COMMENT ON TABLE review_tags IS 'Stores categorization tags for reviews';

COMMENT ON FUNCTION get_class_average_rating(UUID) IS 'Calculates average rating for a specific class';
COMMENT ON FUNCTION get_review_stats(UUID) IS 'Returns comprehensive review statistics for an instructor or globally';