-- Add stripe_account_id to studios table
ALTER TABLE studios 
ADD COLUMN IF NOT EXISTS stripe_account_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_studios_stripe_account_id ON studios(stripe_account_id);
