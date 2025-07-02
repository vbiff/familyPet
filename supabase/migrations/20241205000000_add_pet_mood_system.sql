-- Add new columns for pet mood system
ALTER TABLE pets 
ADD COLUMN IF NOT EXISTS hunger INTEGER DEFAULT 100 CHECK (hunger >= 0 AND hunger <= 100),
ADD COLUMN IF NOT EXISTS emotion INTEGER DEFAULT 100 CHECK (emotion >= 0 AND emotion <= 100),
ADD COLUMN IF NOT EXISTS last_care_at TIMESTAMPTZ DEFAULT NOW();

-- Update existing pets to have the new stats
UPDATE pets 
SET 
  hunger = 100,
  emotion = 100,
  last_care_at = NOW()
WHERE hunger IS NULL OR emotion IS NULL OR last_care_at IS NULL;

-- Update the mood enum to include new mood states
ALTER TYPE pet_mood RENAME TO pet_mood_old;

CREATE TYPE pet_mood AS ENUM (
  'veryVeryHappy',
  'veryHappy', 
  'happy',
  'content',
  'neutral',
  'sad',
  'upset',
  'hungry',
  'veryHungry',
  'veryVeryHungry'
);

-- Update the pets table to use the new enum
ALTER TABLE pets ALTER COLUMN mood TYPE pet_mood USING mood::text::pet_mood;

-- Drop the old enum
DROP TYPE pet_mood_old;

-- Create function to apply time decay to pet stats
CREATE OR REPLACE FUNCTION apply_pet_time_decay(pet_id UUID)
RETURNS void AS $$
DECLARE
  pet_record pets%ROWTYPE;
  hours_since_care INTEGER;
  decay_periods INTEGER;
  new_energy INTEGER;
  new_hunger INTEGER;
  new_emotion INTEGER;
  emotion_decay INTEGER := 0;
BEGIN
  -- Get the pet record
  SELECT * INTO pet_record FROM pets WHERE id = pet_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pet not found';
  END IF;
  
  -- Calculate hours since last care
  hours_since_care := EXTRACT(EPOCH FROM (NOW() - pet_record.last_care_at)) / 3600;
  
  -- Only apply decay if it's been at least 3 hours
  IF hours_since_care >= 3 THEN
    decay_periods := hours_since_care / 3; -- Every 3 hours
    
    -- Apply decay: 10% energy, 15% hunger per 3-hour period
    new_energy := GREATEST(0, pet_record.energy - (decay_periods * 10));
    new_hunger := GREATEST(0, pet_record.hunger - (decay_periods * 15));
    
    -- Calculate emotion decay: 20% for every 30% hunger lost
    IF pet_record.hunger >= 70 AND new_hunger < 70 THEN
      emotion_decay := emotion_decay + 20;
    END IF;
    IF pet_record.hunger >= 40 AND new_hunger < 40 THEN
      emotion_decay := emotion_decay + 20;
    END IF;
    IF pet_record.hunger >= 10 AND new_hunger < 10 THEN
      emotion_decay := emotion_decay + 20;
    END IF;
    
    new_emotion := GREATEST(0, pet_record.emotion - emotion_decay);
    
    -- Update the pet with new stats
    UPDATE pets 
    SET 
      energy = new_energy,
      hunger = new_hunger,
      emotion = new_emotion,
      last_care_at = NOW(),
      mood = CASE
        WHEN new_hunger <= 10 THEN 'veryVeryHungry'::pet_mood
        WHEN new_hunger <= 20 THEN 'veryHungry'::pet_mood
        WHEN new_hunger <= 30 THEN 'hungry'::pet_mood
        WHEN new_emotion >= 90 THEN 'veryVeryHappy'::pet_mood
        WHEN new_emotion >= 80 THEN 'veryHappy'::pet_mood
        WHEN new_emotion >= 70 THEN 'happy'::pet_mood
        WHEN new_emotion >= 60 THEN 'content'::pet_mood
        WHEN new_emotion >= 40 THEN 'neutral'::pet_mood
        WHEN new_emotion >= 20 THEN 'sad'::pet_mood
        ELSE 'upset'::pet_mood
      END
    WHERE id = pet_id;
  END IF;
END;
$$ LANGUAGE plpgsql; 