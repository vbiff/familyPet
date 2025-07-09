-- Fix pet column data types to match app expectations

-- First, let's check what columns exist and fix their types
DO $$
BEGIN
    -- Convert emotion from TEXT to INTEGER if it exists as TEXT
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'emotion' 
        AND data_type = 'text'
    ) THEN
        -- Drop the TEXT emotion column and recreate as INTEGER
        ALTER TABLE pets DROP COLUMN IF EXISTS emotion;
        ALTER TABLE pets ADD COLUMN emotion INTEGER DEFAULT 0 CHECK (emotion >= 0 AND emotion <= 4);
    END IF;
    
    -- Ensure emotion column exists as INTEGER if it doesn't exist at all
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'emotion'
    ) THEN
        ALTER TABLE pets ADD COLUMN emotion INTEGER DEFAULT 0 CHECK (emotion >= 0 AND emotion <= 4);
    END IF;
    
    -- Ensure mood column is using the enum type properly
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'mood' 
        AND data_type != 'USER-DEFINED'
    ) THEN
        -- Convert mood to proper enum type
        ALTER TABLE pets ALTER COLUMN mood TYPE pet_mood USING mood::pet_mood;
    END IF;
    
    -- Ensure stage column is using the enum type properly  
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'stage' 
        AND data_type != 'USER-DEFINED'
    ) THEN
        -- Convert stage to proper enum type
        ALTER TABLE pets ALTER COLUMN stage TYPE pet_stage USING stage::pet_stage;
    END IF;
END $$;

-- Update any existing pets with valid values
UPDATE pets SET 
    emotion = 0,  -- neutral emotion
    mood = 'neutral'::pet_mood,
    stage = 'egg'::pet_stage
WHERE emotion IS NULL OR mood IS NULL OR stage IS NULL;

-- Let's also make sure all integer columns are properly typed
DO $$
BEGIN
    -- Ensure all stat columns are integers
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'happiness' 
        AND data_type != 'integer'
    ) THEN
        ALTER TABLE pets ALTER COLUMN happiness TYPE INTEGER USING happiness::INTEGER;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'energy' 
        AND data_type != 'integer'
    ) THEN
        ALTER TABLE pets ALTER COLUMN energy TYPE INTEGER USING energy::INTEGER;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'health' 
        AND data_type != 'integer'
    ) THEN
        ALTER TABLE pets ALTER COLUMN health TYPE INTEGER USING health::INTEGER;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'experience' 
        AND data_type != 'integer'
    ) THEN
        ALTER TABLE pets ALTER COLUMN experience TYPE INTEGER USING experience::INTEGER;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pets' 
        AND column_name = 'level' 
        AND data_type != 'integer'
    ) THEN
        ALTER TABLE pets ALTER COLUMN level TYPE INTEGER USING level::INTEGER;
    END IF;
END $$;

SELECT 'Pet column types fixed successfully!' as status; 