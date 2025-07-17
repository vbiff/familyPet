-- Debug script to test exact family joining steps
-- This tests the same steps that happen in the app

-- Step 1: Test if we can find family by invite code (this should work)
SELECT 
    'Step 1: Find family by invite code' as step,
    id,
    name,
    invite_code,
    created_by_id
FROM families 
WHERE invite_code = 'DEFHJK';

-- Step 2: Test if we can get user profile (replace with your actual email)
SELECT 
    'Step 2: Get current user profile' as step,
    id,
    email,
    display_name,
    role,
    family_id
FROM profiles 
WHERE email = 'your-email@example.com'; -- Replace with your actual email

-- Step 3: Test if we can query the family by ID after joining
-- First get the family ID
DO $$
DECLARE
    target_family_id UUID;
    user_email TEXT := 'your-email@example.com'; -- Replace with your actual email
BEGIN
    -- Get the family ID for DEFHJK
    SELECT id INTO target_family_id FROM families WHERE invite_code = 'DEFHJK';
    
    IF target_family_id IS NOT NULL THEN
        RAISE NOTICE 'Step 3: Testing family lookup by ID: %', target_family_id;
        
        -- This is the query that's probably failing in getFamilyById
        PERFORM id, name, invite_code FROM families WHERE id = target_family_id;
        
        RAISE NOTICE '✅ Family lookup by ID works!';
    ELSE
        RAISE NOTICE '❌ Could not find family with invite code DEFHJK';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Family lookup by ID failed: %', SQLERRM;
END $$;

-- Step 4: Show current RLS policies that might be blocking
SELECT 
    '=== CURRENT RLS POLICIES ===' as info,
    tablename,
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'families'
ORDER BY cmd;

-- Step 5: Test the exact query used in getFamilyById
-- (This is what the app is trying to do after joining)
SELECT 
    'Step 5: Test exact getFamilyById query' as step,
    id,
    name,
    invite_code,
    created_by_id,
    parent_ids,
    child_ids,
    last_activity_at,
    settings,
    metadata,
    pet_image_url,
    pet_stage_images,
    created_at,
    updated_at
FROM families 
WHERE invite_code = 'DEFHJK';

-- Step 6: Check if your user is already in the family
SELECT 
    'Step 6: Check if user is already in family' as step,
    f.name as family_name,
    f.invite_code,
    p.email,
    p.role,
    CASE 
        WHEN p.id = ANY(f.parent_ids) THEN 'parent'
        WHEN p.id = ANY(f.child_ids) THEN 'child'
        ELSE 'not in family'
    END as membership_status
FROM families f
CROSS JOIN profiles p
WHERE f.invite_code = 'DEFHJK'
AND p.email = 'your-email@example.com'; -- Replace with your actual email 