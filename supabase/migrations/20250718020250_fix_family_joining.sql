-- Debug Family Joining Process
-- This script helps diagnose and fix family joining issues

-- Step 1: Check current families and their member arrays
SELECT 
    f.id,
    f.name,
    f.invite_code,
    f.parent_ids,
    f.child_ids,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count
FROM families f
ORDER BY f.created_at DESC
LIMIT 5;

-- Step 2: Check profiles and their family_id assignments
SELECT 
    p.id,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN '✅ In parent_ids'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN '✅ In child_ids'
        WHEN p.family_id IS NOT NULL THEN '❌ Has family_id but not in arrays'
        ELSE '⚪ No family assigned'
    END as array_status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL OR p.display_name IN ('kseniia', 'Mike', 'privet')
ORDER BY p.created_at DESC;

-- Step 3: Look for inconsistencies where family_id is set but user not in arrays
WITH inconsistent_members AS (
    SELECT 
        p.id,
        p.display_name,
        p.role,
        p.family_id,
        f.name as family_name,
        f.parent_ids,
        f.child_ids
    FROM profiles p
    JOIN families f ON p.family_id = f.id
    WHERE 
        (p.role = 'parent' AND NOT (p.id = ANY(f.parent_ids))) OR
        (p.role = 'child' AND NOT (p.id = ANY(f.child_ids)))
)
SELECT 
    'INCONSISTENCY FOUND!' as status,
    *
FROM inconsistent_members;

-- Step 4: Create safe functions for family joining if they don't exist
CREATE OR REPLACE FUNCTION safe_join_family_by_invite_code(
    invite_code_param TEXT,
    user_id_param UUID
) RETURNS UUID AS $$
DECLARE
    family_record RECORD;
    user_record RECORD;
    family_id_result UUID;
BEGIN
    -- Find the family by invite code
    SELECT id, name, parent_ids, child_ids 
    INTO family_record
    FROM families 
    WHERE invite_code = UPPER(invite_code_param);
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Family not found with invite code: %', invite_code_param;
    END IF;
    
    -- Get user details
    SELECT id, role, family_id 
    INTO user_record
    FROM profiles 
    WHERE id = user_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', user_id_param;
    END IF;
    
    -- Check if user already has a family
    IF user_record.family_id IS NOT NULL THEN
        RAISE EXCEPTION 'User already has a family';
    END IF;
    
    -- Check if user is already a member
    IF (user_record.role = 'parent' AND user_id_param = ANY(family_record.parent_ids)) OR
       (user_record.role = 'child' AND user_id_param = ANY(family_record.child_ids)) THEN
        RAISE EXCEPTION 'User is already a member of this family';
    END IF;
    
    family_id_result := family_record.id;
    
    -- Add user to appropriate array and update profile atomically
    IF user_record.role = 'parent' THEN
        -- Update family to add parent
        UPDATE families 
        SET 
            parent_ids = array_append(parent_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = family_id_result;
    ELSE
        -- Update family to add child
        UPDATE families 
        SET 
            child_ids = array_append(child_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = family_id_result;
    END IF;
    
    -- Update user profile
    UPDATE profiles 
    SET family_id = family_id_result
    WHERE id = user_id_param;
    
    RETURN family_id_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create safe function for adding family members
CREATE OR REPLACE FUNCTION safe_add_family_member(
    family_id_param UUID,
    user_id_param UUID
) RETURNS BOOLEAN AS $$
DECLARE
    user_record RECORD;
    family_record RECORD;
BEGIN
    -- Get user details
    SELECT id, role, family_id 
    INTO user_record
    FROM profiles 
    WHERE id = user_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', user_id_param;
    END IF;
    
    -- Get family details
    SELECT id, parent_ids, child_ids 
    INTO family_record
    FROM families 
    WHERE id = family_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Family not found: %', family_id_param;
    END IF;
    
    -- Check if user is already a member
    IF (user_record.role = 'parent' AND user_id_param = ANY(family_record.parent_ids)) OR
       (user_record.role = 'child' AND user_id_param = ANY(family_record.child_ids)) THEN
        RETURN FALSE; -- Already a member, not an error
    END IF;
    
    -- Add user to appropriate array
    IF user_record.role = 'parent' THEN
        UPDATE families 
        SET 
            parent_ids = array_append(parent_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = family_id_param;
    ELSE
        UPDATE families 
        SET 
            child_ids = array_append(child_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = family_id_param;
    END IF;
    
    -- Update user profile
    UPDATE profiles 
    SET family_id = family_id_param
    WHERE id = user_id_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Fix any existing inconsistencies
UPDATE families 
SET parent_ids = array_append(parent_ids, p.id)
FROM profiles p
WHERE p.family_id = families.id 
  AND p.role = 'parent' 
  AND NOT (p.id = ANY(families.parent_ids));

UPDATE families 
SET child_ids = array_append(child_ids, p.id)
FROM profiles p
WHERE p.family_id = families.id 
  AND p.role = 'child' 
  AND NOT (p.id = ANY(families.child_ids));

-- Step 7: Final verification
SELECT 
    'AFTER FIX:' as status,
    p.id,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN '✅ In parent_ids'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN '✅ In child_ids'
        WHEN p.family_id IS NOT NULL THEN '❌ Still inconsistent'
        ELSE '⚪ No family assigned'
    END as array_status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL
ORDER BY p.created_at DESC; 