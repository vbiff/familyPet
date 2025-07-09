-- Simple fix for avatar upload - only create bucket
-- Run this in Supabase SQL Editor

-- Check if the profile_images bucket exists
SELECT * FROM storage.buckets WHERE name = 'profile_images';

-- Create the bucket if it doesn't exist (this should work)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile_images',
    'profile_images',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Verify the bucket was created
SELECT * FROM storage.buckets WHERE name = 'profile_images'; 