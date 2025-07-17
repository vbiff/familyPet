-- Check the family table directly to see the actual child_ids array
-- Run this in your Supabase SQL Editor

-- Get privet's actual user ID first
SELECT 
    'Privet User Details:' as info;

SELECT 
    id as privet_user_id,
    display_name,
    role,
    family_id
FROM profiles 
WHERE display_name = 'privet';

-- Now check the family table directly for the OUR BANDA family
SELECT 
    'OUR BANDA Family Table Data:' as info;

SELECT 
    id as family_id,
    name as family_name,
    invite_code,
    parent_ids,
    child_ids,
    array_length(parent_ids, 1) as parent_count,
    array_length(child_ids, 1) as child_count,
    updated_at
FROM families 
WHERE name = 'OUR BANDA';

-- Check if privet's ID is actually in the child_ids array
-- Let's see the raw data
SELECT 
    'Raw Array Comparison:' as info;

WITH privet_info AS (
    SELECT id as privet_id FROM profiles WHERE display_name = 'privet'
),
family_info AS (
    SELECT child_ids FROM families WHERE name = 'OUR BANDA'
)
SELECT 
    pi.privet_id,
    fi.child_ids,
    pi.privet_id = ANY(fi.child_ids) as is_privet_in_array,
    array_position(fi.child_ids, pi.privet_id) as position_in_array
FROM privet_info pi, family_info fi;

-- Also show all family members with their actual IDs
SELECT 
    'All Family Members with IDs:' as info;

SELECT 
    p.id as user_id,
    p.display_name,
    p.role,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' THEN 
            CASE WHEN p.id = ANY(f.parent_ids) THEN '✅ YES' ELSE '❌ NO' END
        WHEN p.role = 'child' THEN 
            CASE WHEN p.id = ANY(f.child_ids) THEN '✅ YES' ELSE '❌ NO' END
    END as in_correct_array
FROM profiles p
JOIN families f ON p.family_id = f.id
WHERE f.name = 'OUR BANDA'
ORDER BY p.role, p.display_name; 