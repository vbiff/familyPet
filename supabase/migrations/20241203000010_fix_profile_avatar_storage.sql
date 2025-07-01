-- Fix profile avatar storage bucket and RLS policies

-- Create the profile-images bucket if it doesn't exist
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

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public can view profile avatars" ON storage.objects;

-- Create RLS policies for profile-images bucket
-- Policy to allow users to upload their own avatars
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow users to view their own avatars
CREATE POLICY "Users can view their own avatar" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow users to update their own avatars
CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy to allow public viewing of profile avatars (for other family members)
CREATE POLICY "Public can view profile avatars" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'profile-images'
    );

-- Note: RLS is already enabled on storage.objects by default
-- Note: Permissions are already granted by default

-- Add helpful comments
COMMENT ON POLICY "Users can upload their own avatar" ON storage.objects IS 'Allows users to upload profile avatars to their own folder';
COMMENT ON POLICY "Public can view profile avatars" ON storage.objects IS 'Allows public viewing of profile avatars for family member display'; 