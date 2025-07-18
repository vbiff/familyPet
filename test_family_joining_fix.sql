-- Test Family Joining Fix
-- This script verifies that family joining is working correctly

-- Check current state before any operations
SELECT 
    '=== CURRENT STATE ===' as status,
    f.name as family_name,
    f.invite_code,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    f.parent_ids,
    f.child_ids
FROM families f
ORDER BY f.created_at DESC
LIMIT 3;

-- Check users and their family status
SELECT 
    '=== USER STATUS ===' as status,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN '✅ CORRECTLY IN PARENT_IDS'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN '✅ CORRECTLY IN CHILD_IDS'
        WHEN p.family_id IS NOT NULL THEN '❌ HAS FAMILY_ID BUT NOT IN ARRAYS'
        ELSE '⚪ NO FAMILY ASSIGNED'
    END as array_status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL OR p.display_name IN ('kseniia', 'Mike', 'privet')
ORDER BY p.created_at DESC;

-- Show any inconsistencies that need fixing
WITH inconsistent_users AS (
    SELECT 
        p.id,
        p.display_name,
        p.role,
        p.family_id,
        f.name as family_name
    FROM profiles p
    JOIN families f ON p.family_id = f.id
    WHERE 
        (p.role = 'parent' AND NOT (p.id = ANY(f.parent_ids))) OR
        (p.role = 'child' AND NOT (p.id = ANY(f.child_ids)))
)
SELECT 
    '=== INCONSISTENCIES FOUND ===' as status,
    display_name,
    role,
    family_name,
    'User has family_id but not in family arrays' as issue
FROM inconsistent_users;

-- If no inconsistencies found
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE 
                (p.role = 'parent' AND NOT (p.id = ANY(f.parent_ids))) OR
                (p.role = 'child' AND NOT (p.id = ANY(f.child_ids)))
        ) THEN '🎉 ALL FAMILY MEMBERSHIPS ARE CONSISTENT!'
        ELSE '❌ INCONSISTENCIES STILL EXIST'
    END as final_status; 