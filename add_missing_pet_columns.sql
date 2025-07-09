-- Add missing pet columns to fix the schema mismatch

-- Add emotion column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'emotion') THEN
        ALTER TABLE pets ADD COLUMN emotion TEXT DEFAULT 'neutral';
    END IF;
END $$;

-- Check for other potentially missing columns that the app might expect
DO $$
BEGIN
    -- Add image_url if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'image_url') THEN
        ALTER TABLE pets ADD COLUMN image_url TEXT;
    END IF;
    
    -- Add last_care_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'last_care_at') THEN
        ALTER TABLE pets ADD COLUMN last_care_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Ensure all expected columns exist with proper defaults
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'pets' AND column_name = 'hunger') THEN
        ALTER TABLE pets ADD COLUMN hunger INTEGER DEFAULT 50 CHECK (hunger >= 0 AND hunger <= 100);
    END IF;
END $$;

-- Update any existing pets to have valid emotion values
UPDATE pets SET emotion = 'neutral' WHERE emotion IS NULL;

SELECT 'Missing pet columns added successfully!' as status; 