-- Fix pets table schema to match Flutter code expectations
-- Run this in the Supabase SQL Editor

-- First, let's check if the pets table has the individual columns
DO $$ 
BEGIN
    -- If individual emotion column exists, migrate data to stats JSONB
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'pets' AND column_name = 'emotion') THEN
        
        -- Update stats JSONB to include emotion and hunger from individual columns
        UPDATE pets 
        SET stats = COALESCE(stats, '{}'::jsonb) || 
                   jsonb_build_object(
                       'emotion', COALESCE(emotion, 100),
                       'hunger', COALESCE(hunger, 100),
                       'health', COALESCE(health, 100),
                       'happiness', COALESCE(happiness, 100),
                       'energy', COALESCE(energy, 100)
                   )
        WHERE stats IS NULL OR NOT (stats ? 'emotion') OR NOT (stats ? 'hunger');
        
        -- Drop the individual columns since we're using stats JSONB
        ALTER TABLE pets DROP COLUMN IF EXISTS emotion;
        ALTER TABLE pets DROP COLUMN IF EXISTS hunger;
    END IF;
    
    -- Ensure stats column exists with proper default
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'pets' AND column_name = 'stats') THEN
        ALTER TABLE pets ADD COLUMN stats JSONB DEFAULT '{
            "health": 100,
            "happiness": 100,
            "energy": 100,
            "hunger": 100,
            "emotion": 100
        }'::jsonb;
    END IF;
    
    -- Update any pets that don't have proper stats
    UPDATE pets 
    SET stats = '{
        "health": 100,
        "happiness": 100,
        "energy": 100,
        "hunger": 100,
        "emotion": 100
    }'::jsonb
    WHERE stats IS NULL OR stats = '{}'::jsonb;
    
    -- Ensure all pets have the required stats keys
    UPDATE pets 
    SET stats = stats || '{
        "health": 100,
        "happiness": 100,
        "energy": 100,
        "hunger": 100,
        "emotion": 100
    }'::jsonb
    WHERE NOT (stats ? 'health') OR NOT (stats ? 'happiness') OR 
          NOT (stats ? 'energy') OR NOT (stats ? 'hunger') OR NOT (stats ? 'emotion');
END $$;

-- Drop existing constraints that might conflict
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_emotion_range_check;
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_hunger_range_check;
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_stats_required_keys_check;
ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_stats_valid_range_check;

-- Add constraint to ensure stats has required keys
ALTER TABLE pets 
ADD CONSTRAINT pets_stats_required_keys_check 
CHECK (
    stats ? 'health' AND 
    stats ? 'happiness' AND 
    stats ? 'energy' AND 
    stats ? 'hunger' AND 
    stats ? 'emotion'
);

-- Add constraint to ensure stat values are in valid range
ALTER TABLE pets 
ADD CONSTRAINT pets_stats_valid_range_check 
CHECK (
    (stats->>'health')::int >= 0 AND (stats->>'health')::int <= 100 AND
    (stats->>'happiness')::int >= 0 AND (stats->>'happiness')::int <= 100 AND
    (stats->>'energy')::int >= 0 AND (stats->>'energy')::int <= 100 AND
    (stats->>'hunger')::int >= 0 AND (stats->>'hunger')::int <= 100 AND
    (stats->>'emotion')::int >= 0 AND (stats->>'emotion')::int <= 100
);

-- Make stats column NOT NULL
ALTER TABLE pets ALTER COLUMN stats SET NOT NULL;

-- Add comment
COMMENT ON COLUMN pets.stats IS 'Pet statistics stored as JSON: health, happiness, energy, hunger, emotion (all 0-100)';

-- Verify the schema
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'pets' 
ORDER BY ordinal_position; 