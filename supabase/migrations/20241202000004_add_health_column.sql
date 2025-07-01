-- Add health column to pets table
ALTER TABLE pets 
ADD COLUMN health INTEGER NOT NULL DEFAULT 100 CHECK (health >= 0 AND health <= 100);

-- Update existing records to have health = 100
UPDATE pets SET health = 100 WHERE health IS NULL;

-- Add comment
COMMENT ON COLUMN pets.health IS 'Pet health stat (0-100)'; 