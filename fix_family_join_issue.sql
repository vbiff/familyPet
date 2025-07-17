-- Quick fix for family joining issue
-- This addresses the problem where family joining succeeds but final query fails

-- Option 1: Use the helper function directly in the app
-- Test the join function that bypasses RLS issues
SELECT 
    'Testing direct join function' as test,
    success,
    family_id,
    family_name,
    error_message
FROM join_family_by_invite_code('DEFHJK');

-- If the above works, then the issue is in the repository's final getFamilyById call

-- Option 2: Create a simpler join function that handles the return better
CREATE OR REPLACE FUNCTION simple_join_family(
    invite_code_param TEXT,
    user_id_param UUID DEFAULT auth.uid()
)
RETURNS TABLE (
    family_id UUID,
    family_name TEXT,
    invite_code TEXT,
    user_role TEXT,
    join_successful BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    target_family RECORD;
    user_profile RECORD;
BEGIN
    -- Normalize invite code
    invite_code_param := UPPER(TRIM(invite_code_param));
    
    -- Find family
    SELECT * INTO target_family FROM families WHERE invite_code = invite_code_param;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Family not found with invite code: %', invite_code_param;
    END IF;
    
    -- Get user
    SELECT * INTO user_profile FROM profiles WHERE id = user_id_param;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', user_id_param;
    END IF;
    
    -- Check if already in family
    IF user_profile.family_id IS NOT NULL THEN
        RAISE EXCEPTION 'User is already in a family';
    END IF;
    
    -- Add to family arrays
    IF user_profile.role = 'parent' THEN
        UPDATE families 
        SET parent_ids = array_append(parent_ids, user_id_param)
        WHERE id = target_family.id
        AND NOT (user_id_param = ANY(parent_ids));
    ELSE
        UPDATE families 
        SET child_ids = array_append(child_ids, user_id_param)
        WHERE id = target_family.id
        AND NOT (user_id_param = ANY(child_ids));
    END IF;
    
    -- Update user profile
    UPDATE profiles 
    SET family_id = target_family.id
    WHERE id = user_id_param;
    
    -- Return the family info (this avoids the problematic getFamilyById call)
    RETURN QUERY
    SELECT 
        target_family.id,
        target_family.name,
        target_family.invite_code,
        user_profile.role::TEXT,
        true;
END;
$$ LANGUAGE plpgsql;

-- Test the new function
SELECT 
    'Testing simple join function' as test,
    family_id,
    family_name,
    invite_code,
    user_role,
    join_successful
FROM simple_join_family('DEFHJK');

-- Option 3: Temporarily disable RLS to test
-- UNCOMMENT THESE LINES TO TEST:
-- ALTER TABLE families DISABLE ROW LEVEL SECURITY;
-- SELECT 'RLS disabled - try joining family in app now' as message;
-- (Remember to re-enable afterwards with: ALTER TABLE families ENABLE ROW LEVEL SECURITY;) 