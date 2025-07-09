-- Comprehensive fix for avatar upload issue
-- Run this in Supabase SQL Editor

-- Step 1: Create the profile-images bucket with all necessary settings
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    false,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 2: Create the pet-images bucket as well
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'pet-images',
    'pet-images',
    true, -- Public bucket
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 3: Verify buckets were created
SELECT 
    'BUCKETS CREATED' as status,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE name IN ('profile-images', 'pet-images')
ORDER BY name;

-- Step 4: Show instructions for next steps
SELECT 
    'NEXT STEPS' as action,
    'Go to Supabase Dashboard → Storage → profile-images → Policies → New Policy' as step_1,
    'Create policy: Name="Allow authenticated users", Operation="All", Target="authenticated", Definition="bucket_id = ''profile-images''"' as step_2,
    'Test avatar upload in your app' as step_3;

-- Step 5: Show current auth status (should show your user ID when run in dashboard)
SELECT 
    'CURRENT USER' as info,
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NOT AUTHENTICATED - Login to dashboard first'
        ELSE 'AUTHENTICATED - Ready to test'
    END as auth_status; 