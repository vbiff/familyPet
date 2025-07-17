-- Debug Family Update Issue - FIXED VERSION
-- Run this in your Supabase SQL Editor to diagnose why child_ids isn't updating

-- Step 1: Check current user and permissions
SELECT 
    current_user as current_db_user,
    current_setting('role') as current_role;

-- Step 2: Find the specific family and child we're working with
SELECT 
    f.id as family_id,
    f.name as family_name,
    f.parent_ids,
    f.child_ids,
    p.id as child_id,
    p.display_name as child_name,
    p.role as child_role,
    p.family_id as child_family_id
FROM families f
JOIN profiles p ON p.family_id = f.id
WHERE p.display_name = 'privet' AND p.role = 'child';

-- Step 3: Check if there are any triggers on the families table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'families';

-- Step 4: Check RLS policies on families table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'families';

-- Step 5: Let's try to manually update the specific family
-- First, get the exact family ID and child ID
DO $$
DECLARE
    target_family_id UUID;
    target_child_id UUID;
    current_child_ids UUID[];
    new_child_ids UUID[];
    updated_rows INTEGER; -- Fixed: properly declared the variable
BEGIN
    -- Get the family ID and child ID
    SELECT f.id, p.id INTO target_family_id, target_child_id
    FROM families f
    JOIN profiles p ON p.family_id = f.id
    WHERE p.display_name = 'privet' AND p.role = 'child'
    LIMIT 1;
    
    IF target_family_id IS NULL THEN
        RAISE NOTICE 'Could not find family with child named privet';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Found family ID: %, child ID: %', target_family_id, target_child_id;
    
    -- Get current child_ids array
    SELECT child_ids INTO current_child_ids
    FROM families 
    WHERE id = target_family_id;
    
    RAISE NOTICE 'Current child_ids: %', current_child_ids;
    
    -- Check if child is already in the array
    IF target_child_id = ANY(COALESCE(current_child_ids, '{}')) THEN
        RAISE NOTICE 'Child is already in child_ids array!';
    ELSE
        RAISE NOTICE 'Child is NOT in child_ids array, attempting to add...';
        
        -- Add child to array
        new_child_ids := COALESCE(current_child_ids, '{}') || target_child_id;
        
        -- Try to update
        BEGIN
            UPDATE families 
            SET 
                child_ids = new_child_ids,
                updated_at = NOW()
            WHERE id = target_family_id;
            
            GET DIAGNOSTICS updated_rows = ROW_COUNT;
            RAISE NOTICE 'Update successful! Rows affected: %', updated_rows;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Update failed with error: %', SQLERRM;
        END;
    END IF;
END $$;

-- Step 6: Check the result
SELECT 
    f.id as family_id,
    f.name as family_name,
    f.parent_ids,
    f.child_ids,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    p.id as child_id,
    p.display_name as child_name
FROM families f
JOIN profiles p ON p.family_id = f.id
WHERE p.display_name = 'privet' AND p.role = 'child';

-- Step 7: Alternative approach - use direct SQL update
-- Get the specific family and child IDs, then update manually
WITH family_child AS (
    SELECT 
        f.id as family_id,
        p.id as child_id,
        f.child_ids as current_child_ids
    FROM families f
    JOIN profiles p ON p.family_id = f.id
    WHERE p.display_name = 'privet' AND p.role = 'child'
)
UPDATE families 
SET 
    child_ids = CASE 
        WHEN fc.child_id = ANY(COALESCE(families.child_ids, '{}')) 
        THEN families.child_ids  -- Already in array, no change
        ELSE COALESCE(families.child_ids, '{}') || fc.child_id  -- Add to array
    END,
    updated_at = NOW()
FROM family_child fc
WHERE families.id = fc.family_id
RETURNING 
    families.id,
    families.name,
    families.child_ids;

-- Final verification
SELECT '=== FINAL VERIFICATION ===' as step;

SELECT 
    f.name as family_name,
    p.display_name as member_name,
    p.role,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(COALESCE(f.parent_ids, '{}')) THEN '✅ Correctly in parent_ids'
        WHEN p.role = 'child' AND p.id = ANY(COALESCE(f.child_ids, '{}')) THEN '✅ Correctly in child_ids'
        WHEN p.role = 'parent' THEN '❌ MISSING from parent_ids'
        WHEN p.role = 'child' THEN '❌ MISSING from child_ids'
        ELSE '❓ Unknown status'
    END as array_status
FROM families f
JOIN profiles p ON p.family_id = f.id
WHERE f.name IS NOT NULL
ORDER BY f.name, p.role, p.display_name; 