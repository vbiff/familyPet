-- Fix bucket name mismatch for avatar upload
-- Your Flutter code expects 'profile-images' but dashboard shows 'Profile Avatar Images'

-- Create the correct bucket name that Flutter expects
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    false, -- Private bucket for security
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Verify the correct bucket now exists
SELECT 
    'BUCKET CHECK' as status,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE name = 'profile-images';

-- Show all buckets for comparison
SELECT 
    'ALL BUCKETS' as info,
    name,
    public,
    created_at
FROM storage.buckets 
ORDER BY created_at DESC; 