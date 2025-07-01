-- Create storage policies for profile avatars
-- Note: The bucket must be created manually in Supabase dashboard

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

-- Add helpful comments
COMMENT ON POLICY "Users can upload their own avatar" ON storage.objects IS 'Allows users to upload profile avatars to their own folder';
COMMENT ON POLICY "Public can view profile avatars" ON storage.objects IS 'Allows public viewing of profile avatars for family member display'; 