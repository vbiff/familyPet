-- Diagnostic script to check storage setup
-- Run this in Supabase SQL Editor to diagnose the avatar upload issue

-- Check if storage buckets exist
SELECT 
    'STORAGE BUCKETS' as check_type,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE name IN ('profile-images', 'pet-images')
ORDER BY name;

-- Check storage policies
SELECT 
    'STORAGE POLICIES' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- Check if RLS is enabled on storage.objects
SELECT 
    'RLS STATUS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Check current user authentication
SELECT 
    'CURRENT AUTH' as check_type,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NOT AUTHENTICATED'
        ELSE 'AUTHENTICATED'
    END as auth_status;

-- Check if profile-images bucket exists specifically
SELECT 
    'BUCKET CHECK' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'profile-images') 
        THEN 'profile-images bucket EXISTS'
        ELSE 'profile-images bucket MISSING'
    END as bucket_status;

-- Show all storage buckets for comparison
SELECT 
    'ALL BUCKETS' as check_type,
    name,
    public,
    created_at
FROM storage.buckets 
ORDER BY created_at DESC; 