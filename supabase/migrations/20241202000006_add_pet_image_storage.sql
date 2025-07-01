-- Add image URL columns back to pets table
ALTER TABLE pets 
ADD COLUMN image_url TEXT DEFAULT NULL,
ADD COLUMN stage_images JSONB DEFAULT '{}';

-- Create pet_images storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet_images', 'Pet Images', true);

-- Create storage policy for pet images (public read access)
CREATE POLICY "Pet images are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'pet_images');

-- Create storage policy for uploading pet images (authenticated users only)
CREATE POLICY "Authenticated users can upload pet images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'pet_images' 
    AND auth.uid() IS NOT NULL
  );

-- Create storage policy for updating pet images (owner only)
CREATE POLICY "Users can update their pet images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'pet_images'
    AND auth.uid() IS NOT NULL
  );

-- Add comments
COMMENT ON COLUMN pets.image_url IS 'Current pet image URL from Supabase storage';
COMMENT ON COLUMN pets.stage_images IS 'JSON mapping of stage names to image URLs'; 