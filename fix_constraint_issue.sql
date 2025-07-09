-- Fix the constraint issue for pet creation
-- Run this in Supabase SQL Editor

-- Drop the problematic constraint
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_stats_required_keys_check;

-- Also drop the stats valid range check if it exists
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_stats_valid_range_check;

-- Ensure all required columns exist with proper defaults
ALTER TABLE pets ADD COLUMN IF NOT EXISTS emotion INTEGER DEFAULT 100 CHECK (emotion >= 0 AND emotion <= 100);
ALTER TABLE pets ADD COLUMN IF NOT EXISTS hunger INTEGER DEFAULT 100 CHECK (hunger >= 0 AND hunger <= 100);
ALTER TABLE pets ADD COLUMN IF NOT EXISTS health INTEGER DEFAULT 100 CHECK (health >= 0 AND health <= 100);
ALTER TABLE pets ADD COLUMN IF NOT EXISTS happiness INTEGER DEFAULT 100 CHECK (happiness >= 0 AND happiness <= 100);
ALTER TABLE pets ADD COLUMN IF NOT EXISTS energy INTEGER DEFAULT 100 CHECK (energy >= 0 AND energy <= 100);

-- Update any existing pets to have default values
UPDATE pets SET emotion = 100 WHERE emotion IS NULL;
UPDATE pets SET hunger = 100 WHERE hunger IS NULL;
UPDATE pets SET health = 100 WHERE health IS NULL;
UPDATE pets SET happiness = 100 WHERE happiness IS NULL;
UPDATE pets SET energy = 100 WHERE energy IS NULL;

-- Make sure the stats column exists but is optional
ALTER TABLE pets ADD COLUMN IF NOT EXISTS stats JSONB DEFAULT NULL;

-- Check the current table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'pets' 
ORDER BY ordinal_position; 