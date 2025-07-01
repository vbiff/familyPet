-- Create storage bucket for pet images
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-images', 'pet-images', true)
ON CONFLICT (id) DO NOTHING;

-- Create RLS policies for pet-images bucket (drop if exists first)
DROP POLICY IF EXISTS "Pet images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload pet images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their family's pet images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their family's pet images" ON storage.objects;

CREATE POLICY "Pet images are publicly viewable" ON storage.objects 
FOR SELECT USING (bucket_id = 'pet-images');

CREATE POLICY "Authenticated users can upload pet images" ON storage.objects 
FOR INSERT WITH CHECK (
  bucket_id = 'pet-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their family's pet images" ON storage.objects 
FOR UPDATE USING (
  bucket_id = 'pet-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can delete their family's pet images" ON storage.objects 
FOR DELETE USING (
  bucket_id = 'pet-images' 
  AND auth.role() = 'authenticated'
); 