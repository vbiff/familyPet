-- Fix Family Arrays Synchronization
-- This script fixes all the inconsistencies where users have family_id but aren't in family arrays

-- Step 1: Check current inconsistencies
SELECT 
    'BEFORE_FIX' as status,
    COUNT(*) as inconsistent_count
FROM profiles p
JOIN families f ON p.family_id = f.id
WHERE 
    (p.role = 'parent' AND NOT (p.id = ANY(f.parent_ids))) OR
    (p.role = 'child' AND NOT (p.id = ANY(f.child_ids)));

-- Step 2: Fix parent inconsistencies - add missing parents to parent_ids arrays
UPDATE families 
SET 
    parent_ids = array_append(parent_ids, p.id),
    last_activity_at = NOW()
FROM profiles p
WHERE p.family_id = families.id 
  AND p.role = 'parent' 
  AND NOT (p.id = ANY(families.parent_ids));

-- Step 3: Fix child inconsistencies - add missing children to child_ids arrays  
UPDATE families 
SET 
    child_ids = array_append(child_ids, p.id),
    last_activity_at = NOW()
FROM profiles p
WHERE p.family_id = families.id 
  AND p.role = 'child' 
  AND NOT (p.id = ANY(families.child_ids));

-- Step 4: Remove duplicates from parent_ids arrays (just in case)
UPDATE families 
SET parent_ids = (
    SELECT array_agg(DISTINCT unnest_val)
    FROM unnest(parent_ids) AS unnest_val
)
WHERE array_length(parent_ids, 1) > 0;

-- Step 5: Remove duplicates from child_ids arrays (just in case)
UPDATE families 
SET child_ids = (
    SELECT array_agg(DISTINCT unnest_val)
    FROM unnest(child_ids) AS unnest_val
)
WHERE array_length(child_ids, 1) > 0;

-- Step 6: Verify the fix worked
SELECT 
    'AFTER_FIX' as status,
    COUNT(*) as remaining_inconsistencies
FROM profiles p
JOIN families f ON p.family_id = f.id
WHERE 
    (p.role = 'parent' AND NOT (p.id = ANY(f.parent_ids))) OR
    (p.role = 'child' AND NOT (p.id = ANY(f.child_ids)));

-- Step 7: Show final state of families
SELECT 
    'FINAL_FAMILY_STATE' as status,
    f.name as family_name,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'parent') as actual_parent_count,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'child') as actual_child_count,
    CASE 
        WHEN array_length(f.parent_ids, 1) = (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'parent')
         AND array_length(f.child_ids, 1) = (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'child')
        THEN '✅ SYNCHRONIZED'
        ELSE '❌ STILL_INCONSISTENT'
    END as sync_status
FROM families f
ORDER BY f.created_at DESC;

-- Step 8: Show final user status
SELECT 
    'FINAL_USER_STATUS' as status,
    p.display_name,
    p.role,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN '✅ IN_PARENT_IDS'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN '✅ IN_CHILD_IDS'
        WHEN p.family_id IS NOT NULL THEN '❌ HAS_FAMILY_BUT_NOT_IN_ARRAYS'
        ELSE '⚪ NO_FAMILY'
    END as final_status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL OR p.display_name IN ('kseniia', 'Mike', 'privet', 'pop')
ORDER BY p.created_at DESC; 