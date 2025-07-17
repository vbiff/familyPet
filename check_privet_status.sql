-- Check the specific status of user "privet"
-- Run this in your Supabase SQL Editor

-- Find privet user and their family details
SELECT 
    'Current Status of privet user:' as info;

SELECT 
    p.id as privet_user_id,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    f.id as family_id_full,
    f.parent_ids,
    f.child_ids,
    CASE 
        WHEN p.id = ANY(COALESCE(f.child_ids, '{}')) THEN '✅ YES - privet is in child_ids array'
        ELSE '❌ NO - privet is NOT in child_ids array'
    END as is_in_child_ids_array
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.display_name = 'privet';

-- Also check all members of the family that privet belongs to
SELECT 
    'All members of privet''s family:' as info;

SELECT 
    f.name as family_name,
    f.invite_code,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    p.display_name,
    p.role,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(COALESCE(f.parent_ids, '{}')) THEN '✅ In parent_ids'
        WHEN p.role = 'child' AND p.id = ANY(COALESCE(f.child_ids, '{}')) THEN '✅ In child_ids'
        ELSE '❌ MISSING from arrays'
    END as array_status
FROM profiles p
JOIN families f ON p.family_id = f.id
WHERE f.id = (
    SELECT family_id FROM profiles WHERE display_name = 'privet'
)
ORDER BY p.role, p.display_name; 