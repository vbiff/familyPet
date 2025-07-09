-- Create simple RLS policy for profile-images bucket
-- This should work even if the dashboard method failed

-- First, let's try to create a very permissive policy for testing
DO $$
BEGIN
    -- Drop existing policy if it exists
    DROP POLICY IF EXISTS "Allow all authenticated users profile images" ON storage.objects;
    
    -- Create a simple policy that allows all authenticated users
    CREATE POLICY "Allow all authenticated users profile images"
    ON storage.objects
    FOR ALL
    TO authenticated
    USING (bucket_id = 'profile-images')
    WITH CHECK (bucket_id = 'profile-images');
    
    RAISE NOTICE 'Policy created successfully';
    
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Cannot create policy via SQL - must use dashboard';
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating policy: %', SQLERRM;
END $$;

-- Verify the policy was created
SELECT 
    'POLICY CHECK' as status,
    policyname,
    cmd as operation,
    roles,
    qual as policy_definition
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage' 
  AND policyname = 'Allow all authenticated users profile images';

-- If no policy shows up, you'll need to create it via the dashboard 