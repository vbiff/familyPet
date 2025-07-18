-- Manual Family Update Test
-- This tests if we can manually update family arrays

-- Step 1: Find a family and a user to test with
WITH test_data AS (
    SELECT 
        f.id as family_id,
        f.name as family_name,
        f.parent_ids,
        f.child_ids,
        p.id as user_id,
        p.display_name,
        p.role,
        p.family_id as user_family_id
    FROM families f
    CROSS JOIN profiles p
    WHERE p.display_name IN ('kseniia', 'Mike', 'privet')
      AND (p.family_id = f.id OR p.family_id IS NULL)
    ORDER BY f.created_at DESC, p.created_at DESC
    LIMIT 1
)
SELECT 
    'TEST_SETUP' as step,
    family_id,
    family_name,
    user_id,
    display_name,
    role,
    CASE 
        WHEN role = 'parent' AND user_id = ANY(parent_ids) THEN 'ALREADY_IN_PARENT_IDS'
        WHEN role = 'child' AND user_id = ANY(child_ids) THEN 'ALREADY_IN_CHILD_IDS'
        ELSE 'NOT_IN_ARRAYS'
    END as current_status
FROM test_data;

-- Step 2: Try to add a user to the appropriate array
-- First, let's see if we can do a simple select with array operations
SELECT 
    'ARRAY_TEST' as step,
    f.id,
    f.parent_ids,
    f.child_ids,
    array_append(f.parent_ids, 'test-id') as test_parent_append,
    array_append(f.child_ids, 'test-id') as test_child_append
FROM families f
ORDER BY f.created_at DESC
LIMIT 1;

-- Step 3: Check what we get when selecting from profiles
SELECT 
    'PROFILE_FAMILY_CHECK' as step,
    p.id,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    f.parent_ids,
    f.child_ids
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.display_name IN ('kseniia', 'Mike', 'privet')
ORDER BY p.created_at DESC;

-- Step 4: Show current family membership discrepancies
SELECT 
    'DISCREPANCY_CHECK' as step,
    f.name as family_name,
    array_length(f.parent_ids, 1) as parent_ids_count,
    array_length(f.child_ids, 1) as child_ids_count,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'parent') as actual_parent_count,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'child') as actual_child_count,
    CASE 
        WHEN array_length(f.parent_ids, 1) != (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'parent') THEN 'PARENT_MISMATCH'
        WHEN array_length(f.child_ids, 1) != (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'child') THEN 'CHILD_MISMATCH'
        ELSE 'COUNTS_MATCH'
    END as status
FROM families f
WHERE f.created_at > (CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY f.created_at DESC; 