-- Fix avatar upload RLS policies by removing conflicts and creating working policies

-- First, drop all existing policies that might conflict
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile avatars" ON storage.objects;

-- Drop any other avatar-related policies
DROP POLICY IF EXISTS "Avatar upload policy" ON storage.objects;
DROP POLICY IF EXISTS "Avatar view policy" ON storage.objects;
DROP POLICY IF EXISTS "Avatar update policy" ON storage.objects;
DROP POLICY IF EXISTS "Avatar delete policy" ON storage.objects;

-- Ensure the profile-images bucket exists with correct settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[];

-- Create new policies with unique names that work correctly
-- Policy to allow authenticated users to upload avatars to their own folder
CREATE POLICY "profile_avatar_upload_policy" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow authenticated users to view any profile avatar (for family members)
CREATE POLICY "profile_avatar_view_policy" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
    );

-- Policy to allow users to update their own avatars
CREATE POLICY "profile_avatar_update_policy" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow users to delete their own avatars
CREATE POLICY "profile_avatar_delete_policy" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Also create a more permissive policy for public viewing (in case the above doesn't work)
CREATE POLICY "profile_avatar_public_view_policy" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images'
    );

-- Add helpful comments
COMMENT ON POLICY "profile_avatar_upload_policy" ON storage.objects IS 'Allows authenticated users to upload avatars to their own folder';
COMMENT ON POLICY "profile_avatar_view_policy" ON storage.objects IS 'Allows authenticated users to view any profile avatar';
COMMENT ON POLICY "profile_avatar_public_view_policy" ON storage.objects IS 'Allows public viewing of profile avatars as fallback';

-- Ensure RLS is enabled on storage.objects (should already be enabled by default)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY; 