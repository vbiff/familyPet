-- SAFE FIX: Only fix the emotion column issue
-- Run this in Supabase SQL Editor

-- Check current pets table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'pets' 
ORDER BY ordinal_position;

-- If the emotion column exists as individual column, we need to ensure it's accessible
-- Let's add it back if it's missing or fix the schema cache issue

-- First, ensure the emotion column exists
ALTER TABLE pets ADD COLUMN IF NOT EXISTS emotion INTEGER DEFAULT 100 CHECK (emotion >= 0 AND emotion <= 100);

-- Update any null values
UPDATE pets SET emotion = 100 WHERE emotion IS NULL;

-- Also ensure hunger column exists
ALTER TABLE pets ADD COLUMN IF NOT EXISTS hunger INTEGER DEFAULT 100 CHECK (hunger >= 0 AND hunger <= 100);

-- Update any null values
UPDATE pets SET hunger = 100 WHERE hunger IS NULL;

-- Verify the columns now exist
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'pets' AND column_name IN ('emotion', 'hunger')
ORDER BY column_name; 