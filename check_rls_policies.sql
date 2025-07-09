-- Check RLS policies for storage buckets
-- Run this to see what policies exist and diagnose the issue

-- Check if profile-images bucket exists
SELECT 
    'BUCKET STATUS' as check_type,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE name = 'profile-images';

-- Check current storage policies
SELECT 
    'STORAGE POLICIES' as check_type,
    policyname,
    cmd as operation,
    roles,
    qual as policy_definition
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- Check if there are ANY policies for profile-images bucket
SELECT 
    'PROFILE-IMAGES POLICIES' as check_type,
    policyname,
    cmd as operation,
    qual as policy_definition
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage' 
  AND qual LIKE '%profile-images%'
ORDER BY policyname;

-- Check current user authentication
SELECT 
    'CURRENT AUTH' as check_type,
    auth.uid() as user_id,
    auth.role() as user_role,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NOT AUTHENTICATED'
        ELSE 'AUTHENTICATED'
    END as auth_status;

-- Check RLS status on storage.objects
SELECT 
    'RLS STATUS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects'; 