-- Fix avatar upload storage bucket and policies
-- This migration creates the profile-images bucket and sets up proper RLS policies

-- Create the profile-images bucket if it doesn't exist
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

-- Create storage policies for profile images
-- Note: These policies are created using the storage schema functions

-- Function to create storage policies (if they don't exist)
DO $$ 
BEGIN
    -- Drop existing policies if they exist to avoid conflicts
    DROP POLICY IF EXISTS "Allow authenticated users to upload avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to view avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to update avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to delete avatars" ON storage.objects;
    
    -- Create new policies
    CREATE POLICY "Allow authenticated users to upload avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-images' 
        AND auth.uid() IS NOT NULL
    );

    CREATE POLICY "Allow authenticated users to view avatars"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'profile-images' 
        AND auth.uid() IS NOT NULL
    );

    CREATE POLICY "Allow authenticated users to update avatars"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'profile-images' 
        AND auth.uid() IS NOT NULL
    );

    CREATE POLICY "Allow authenticated users to delete avatars"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'profile-images' 
        AND auth.uid() IS NOT NULL
    );

EXCEPTION
    WHEN insufficient_privilege THEN
        -- If we can't create policies directly, we'll use a different approach
        RAISE NOTICE 'Cannot create storage policies directly in migration. Please create them manually in the dashboard.';
END $$;

-- Ensure RLS is enabled on storage.objects
DO $$
BEGIN
    ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Cannot enable RLS on storage.objects. This may already be enabled.';
END $$;

-- Verify the bucket was created
SELECT 'profile-images bucket created successfully' as message
WHERE EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'profile-images'); 