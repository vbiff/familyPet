-- Add pet image URL to families table
ALTER TABLE families 
ADD COLUMN pet_image_url TEXT DEFAULT NULL,
ADD COLUMN pet_stage_images JSONB DEFAULT '{}';

-- Remove image columns from pets table (not needed there)
ALTER TABLE pets 
DROP COLUMN IF EXISTS image_url,
DROP COLUMN IF EXISTS stage_images;

-- Add comments
COMMENT ON COLUMN families.pet_image_url IS 'Current pet image URL from Supabase storage';
COMMENT ON COLUMN families.pet_stage_images IS 'JSON mapping of pet stages to image URLs for this family'; 