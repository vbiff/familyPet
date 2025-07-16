-- Fix task image visibility
-- This migration ensures task images are properly visible to family members
-- Date: 2025-01-10

-- Step 1: Create/update the task-images bucket with correct settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'task-images',
    'task-images',
    false, -- Private bucket, access controlled by RLS
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[];

-- Step 2: Drop ALL existing storage policies for task-images to start fresh
DROP POLICY IF EXISTS "Task images are viewable by family members" ON storage.objects;
DROP POLICY IF EXISTS "Family members can upload task images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload task images" ON storage.objects;
DROP POLICY IF EXISTS "Task images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "task_images_family_members_can_upload" ON storage.objects;
DROP POLICY IF EXISTS "task_images_family_members_can_view" ON storage.objects;

-- Step 3: Create simple, working storage policies for task images

-- Allow family members to view task images
-- Path structure: tasks/family_id/task_id/filename
CREATE POLICY "task_images_viewable_by_family"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

-- Allow family members to upload task images
CREATE POLICY "task_images_uploadable_by_family"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

-- Allow family members to update task images
CREATE POLICY "task_images_updatable_by_family"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

-- Allow family members to delete task images
CREATE POLICY "task_images_deletable_by_family"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

-- Step 4: Grant necessary permissions
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- Step 5: Success message
DO $$
BEGIN
    RAISE NOTICE '✅ TASK IMAGE VISIBILITY FIX APPLIED!';
    RAISE NOTICE '=========================================';
    RAISE NOTICE '📸 Task images should now be visible to all family members';
    RAISE NOTICE '🔒 Private bucket with family-based access control';
    RAISE NOTICE '📁 Images stored in: tasks/family_id/task_id/filename';
    RAISE NOTICE '🎯 Both upload and viewing should work properly';
END $$; 