-- Fix Child Family Joining Issue
-- Run this script in your Supabase SQL Editor to fix child user family joining

-- First, let's check what family functions already exist
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%family%'
ORDER BY routine_name;

-- Check the current state of families and their member arrays
SELECT 
    f.name as family_name,
    f.invite_code,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    (SELECT array_agg(p.display_name || ' (' || p.role || ')') 
     FROM profiles p 
     WHERE p.family_id = f.id) as actual_members
FROM families f
ORDER BY f.created_at;

-- Create safe_add_family_member function if it doesn't exist
CREATE OR REPLACE FUNCTION safe_add_family_member(
    family_id_param UUID,
    user_id_param UUID,
    role_param user_role DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_parent_ids UUID[];
    current_child_ids UUID[];
    new_parent_ids UUID[];
    new_child_ids UUID[];
    user_role_actual user_role;
BEGIN
    -- Get user's actual role if not provided
    IF role_param IS NULL THEN
        SELECT role INTO user_role_actual FROM profiles WHERE id = user_id_param;
    ELSE
        user_role_actual := role_param;
    END IF;
    
    -- Verify family exists
    IF NOT EXISTS (SELECT 1 FROM families WHERE id = family_id_param) THEN
        RAISE EXCEPTION 'Family does not exist: %', family_id_param;
    END IF;
    
    -- Verify user exists
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = user_id_param) THEN
        RAISE EXCEPTION 'User does not exist: %', user_id_param;
    END IF;
    
    -- Get current member arrays
    SELECT parent_ids, child_ids INTO current_parent_ids, current_child_ids
    FROM families WHERE id = family_id_param;
    
    -- Check if user is already a member
    IF user_id_param = ANY(COALESCE(current_parent_ids, '{}')) OR 
       user_id_param = ANY(COALESCE(current_child_ids, '{}')) THEN
        RAISE NOTICE 'User % is already a member of family %', user_id_param, family_id_param;
        RETURN FALSE;
    END IF;
    
    -- Add to appropriate array based on role
    IF user_role_actual = 'parent' THEN
        new_parent_ids := COALESCE(current_parent_ids, '{}') || user_id_param;
        new_child_ids := COALESCE(current_child_ids, '{}');
    ELSE
        new_parent_ids := COALESCE(current_parent_ids, '{}');
        new_child_ids := COALESCE(current_child_ids, '{}') || user_id_param;
    END IF;
    
    -- Update family and user profile in a transaction
    BEGIN
        -- Update family member arrays
        UPDATE families 
        SET 
            parent_ids = new_parent_ids,
            child_ids = new_child_ids,
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE id = family_id_param;
        
        -- Update user profile with family_id
        UPDATE profiles 
        SET 
            family_id = family_id_param,
            updated_at = NOW()
        WHERE id = user_id_param;
        
        RAISE NOTICE 'Successfully added user % to family %', user_id_param, family_id_param;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to add user to family: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Create safe_join_family_by_invite_code function if it doesn't exist
CREATE OR REPLACE FUNCTION safe_join_family_by_invite_code(
    invite_code_param VARCHAR(6),
    user_id_param UUID
)
RETURNS UUID AS $$
DECLARE
    family_record RECORD;
    user_record RECORD;
    current_parent_ids UUID[];
    current_child_ids UUID[];
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Normalize invite code
    invite_code_param := UPPER(TRIM(invite_code_param));
    
    -- Find the family by invite code
    SELECT * INTO family_record FROM families WHERE invite_code = invite_code_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Family not found with invite code: %', invite_code_param;
    END IF;
    
    -- Get user info
    SELECT * INTO user_record FROM profiles WHERE id = user_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', user_id_param;
    END IF;
    
    -- Check if user already has a family
    IF user_record.family_id IS NOT NULL THEN
        RAISE EXCEPTION 'User is already a member of a family';
    END IF;
    
    -- Get current member arrays
    SELECT parent_ids, child_ids INTO current_parent_ids, current_child_ids
    FROM families WHERE id = family_record.id;
    
    -- Check if user is already a member
    IF user_id_param = ANY(COALESCE(current_parent_ids, '{}')) OR 
       user_id_param = ANY(COALESCE(current_child_ids, '{}')) THEN
        RAISE EXCEPTION 'User is already a member of this family';
    END IF;
    
    -- Add to appropriate array based on role
    IF user_record.role = 'parent' THEN
        new_parent_ids := COALESCE(current_parent_ids, '{}') || user_id_param;
        new_child_ids := COALESCE(current_child_ids, '{}');
    ELSE
        new_parent_ids := COALESCE(current_parent_ids, '{}');
        new_child_ids := COALESCE(current_child_ids, '{}') || user_id_param;
    END IF;
    
    -- Update both tables in a single transaction
    BEGIN
        -- First update family member arrays
        UPDATE families 
        SET 
            parent_ids = new_parent_ids,
            child_ids = new_child_ids,
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE id = family_record.id;
        
        -- Then update user profile
        UPDATE profiles 
        SET 
            family_id = family_record.id,
            updated_at = NOW()
        WHERE id = user_id_param;
        
        RAISE NOTICE 'Successfully added user % to family %', user_id_param, family_record.id;
        RETURN family_record.id;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to join family: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Sync family member arrays with actual profile data
-- This will fix any inconsistencies where users have family_id but aren't in arrays
CREATE OR REPLACE FUNCTION sync_family_member_arrays()
RETURNS void AS $$
DECLARE
    family_record RECORD;
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Loop through all families
    FOR family_record IN SELECT id, name FROM families LOOP
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
        
        -- Update the family with correct member arrays
        UPDATE families 
        SET 
            parent_ids = new_parent_ids,
            child_ids = new_child_ids,
            updated_at = NOW()
        WHERE id = family_record.id;
        
        RAISE NOTICE 'Updated family "%" with % parents and % children', 
            family_record.name, 
            array_length(new_parent_ids, 1), 
            array_length(new_child_ids, 1);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions on the new functions
GRANT EXECUTE ON FUNCTION safe_add_family_member(UUID, UUID, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION safe_join_family_by_invite_code(VARCHAR(6), UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION sync_family_member_arrays() TO authenticated;

-- Run the sync function
SELECT sync_family_member_arrays();

-- Check the results after sync
SELECT 
    f.name as family_name,
    f.invite_code,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    (SELECT array_agg(p.display_name || ' (' || p.role || ')') 
     FROM profiles p 
     WHERE p.family_id = f.id) as actual_members
FROM families f
ORDER BY f.created_at;

-- Test message
SELECT '✅ Family joining functions created and data synchronized!' as status;
SELECT 'ℹ️  Children should now be able to join families and see family tasks!' as info; 