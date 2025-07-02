-- Add new columns for pet mood system (safe approach)
-- This migration adds the new columns without breaking existing functionality

-- Add new columns as nullable first
ALTER TABLE pets 
ADD COLUMN IF NOT EXISTS hunger INTEGER,
ADD COLUMN IF NOT EXISTS emotion INTEGER,
ADD COLUMN IF NOT EXISTS last_care_at TIMESTAMPTZ;

-- Update existing pets to have default values for new columns
UPDATE pets 
SET 
  hunger = CASE WHEN hunger IS NULL THEN 100 ELSE hunger END,
  emotion = CASE WHEN emotion IS NULL THEN 100 ELSE emotion END,
  last_care_at = CASE WHEN last_care_at IS NULL THEN created_at ELSE last_care_at END;

-- Add constraints after setting default values
ALTER TABLE pets 
ADD CONSTRAINT check_hunger_range CHECK (hunger IS NULL OR (hunger >= 0 AND hunger <= 100)),
ADD CONSTRAINT check_emotion_range CHECK (emotion IS NULL OR (emotion >= 0 AND emotion <= 100));

-- Create function to safely update pet mood based on stats
CREATE OR REPLACE FUNCTION update_pet_mood_safe(pet_id UUID)
RETURNS void AS $$
DECLARE
  pet_record pets%ROWTYPE;
  new_mood TEXT;
BEGIN
  -- Get the pet record
  SELECT * INTO pet_record FROM pets WHERE id = pet_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pet not found';
  END IF;
  
  -- Calculate new mood based on hunger and emotion
  IF COALESCE(pet_record.hunger, 100) <= 10 THEN
    new_mood := 'veryVeryHungry';
  ELSIF COALESCE(pet_record.hunger, 100) <= 20 THEN
    new_mood := 'veryHungry';
  ELSIF COALESCE(pet_record.hunger, 100) <= 30 THEN
    new_mood := 'hungry';
  ELSIF COALESCE(pet_record.emotion, 100) >= 90 THEN
    new_mood := 'veryVeryHappy';
  ELSIF COALESCE(pet_record.emotion, 100) >= 80 THEN
    new_mood := 'veryHappy';
  ELSIF COALESCE(pet_record.emotion, 100) >= 70 THEN
    new_mood := 'happy';
  ELSIF COALESCE(pet_record.emotion, 100) >= 60 THEN
    new_mood := 'content';
  ELSIF COALESCE(pet_record.emotion, 100) >= 40 THEN
    new_mood := 'neutral';
  ELSIF COALESCE(pet_record.emotion, 100) >= 20 THEN
    new_mood := 'sad';
  ELSE
    new_mood := 'upset';
  END IF;
  
  -- Only update mood if it's a valid enum value, otherwise keep current mood
  UPDATE pets 
  SET mood = CASE 
    WHEN new_mood IN ('happy', 'content', 'neutral', 'sad', 'upset') THEN new_mood::pet_mood
    ELSE mood
  END
  WHERE id = pet_id;
END;
$$ LANGUAGE plpgsql; 