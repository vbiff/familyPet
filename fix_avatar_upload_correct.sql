-- Fix avatar upload for the correct bucket name
-- Run this in Supabase SQL Editor

-- Check if the profile-images bucket exists (note: hyphen, not underscore)
SELECT * FROM storage.buckets WHERE name = 'profile-images';

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Verify the bucket was created
SELECT * FROM storage.buckets WHERE name = 'profile-images';

-- Check current storage policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname; 