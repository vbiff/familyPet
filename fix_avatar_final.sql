-- Final fix for avatar upload issue
-- Run this directly in the Supabase SQL Editor

-- Create the profile-images bucket (the correct name used by Flutter code)
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

-- Create the pet-images bucket (also used by Flutter code)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'pet-images',
    'pet-images',
    true, -- Public bucket for pet images
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Verify both buckets were created
SELECT 
    name, 
    public, 
    file_size_limit,
    allowed_mime_types,
    'Bucket created successfully' as status
FROM storage.buckets 
WHERE name IN ('profile-images', 'pet-images')
ORDER BY name;

-- Show message
SELECT 'Storage buckets created! Now you need to create RLS policies via the Supabase dashboard.' as next_step; 