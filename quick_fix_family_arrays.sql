-- Quick Fix: Sync Family Member Arrays
-- Run this in your Supabase SQL Editor

-- First, let's see the current state
SELECT 
    f.name as family_name,
    f.invite_code,
    f.parent_ids,
    f.child_ids,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count
FROM families f 
WHERE f.name IS NOT NULL
ORDER BY f.created_at;

-- Check what profiles are actually in families
SELECT 
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL
ORDER BY f.name, p.role, p.display_name;

-- Sync the family member arrays with actual profile data
DO $$
DECLARE
    family_record RECORD;
    new_parent_ids UUID[];
    new_child_ids UUID[];
    parent_count INTEGER;
    child_count INTEGER;
BEGIN
    -- Loop through all families
    FOR family_record IN SELECT id, name FROM families WHERE name IS NOT NULL LOOP
        -- Get all parents for this family
        SELECT array_agg(p.id) INTO new_parent_ids
        FROM profiles p
        WHERE p.family_id = family_record.id AND p.role = 'parent';
        
        -- Get all children for this family
        SELECT array_agg(p.id) INTO new_child_ids
        FROM profiles p
        WHERE p.family_id = family_record.id AND p.role = 'child';
        
        -- Handle null arrays
        new_parent_ids := COALESCE(new_parent_ids, '{}');
        new_child_ids := COALESCE(new_child_ids, '{}');
        
        -- Get counts
        parent_count := array_length(new_parent_ids, 1);
        child_count := array_length(new_child_ids, 1);
        
        -- Update the family with correct member arrays
        UPDATE families 
        SET 
            parent_ids = new_parent_ids,
            child_ids = new_child_ids,
            updated_at = NOW()
        WHERE id = family_record.id;
        
        RAISE NOTICE 'Updated family "%" with % parents and % children', 
            family_record.name, 
            COALESCE(parent_count, 0), 
            COALESCE(child_count, 0);
    END LOOP;
END $$;

-- Check the results after sync
SELECT 
    f.name as family_name,
    f.invite_code,
    f.parent_ids,
    f.child_ids,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count
FROM families f 
WHERE f.name IS NOT NULL
ORDER BY f.created_at;

-- Verify that all family members are now in the arrays
SELECT 
    f.name as family_name,
    p.display_name,
    p.role,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN '✅ In parent_ids'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN '✅ In child_ids'
        ELSE '❌ MISSING from family arrays'
    END as status
FROM families f
JOIN profiles p ON p.family_id = f.id
WHERE f.name IS NOT NULL
ORDER BY f.name, p.role, p.display_name;

SELECT '✅ Family member arrays synchronized!' as result; 