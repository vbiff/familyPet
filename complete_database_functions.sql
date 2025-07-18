-- Complete Database Functions for Family Operations
-- This script creates all the atomic functions needed for family operations

-- Step 1: Create atomic family creation function
CREATE OR REPLACE FUNCTION create_family_atomic(
    family_name_param TEXT,
    creator_id_param UUID
) RETURNS UUID AS $$
DECLARE
    new_family_id UUID;
    invite_code_result TEXT;
    creator_role TEXT;
BEGIN
    -- Generate family ID and invite code
    new_family_id := gen_random_uuid();
    -- Generate 6-character invite code using allowed characters
    invite_code_result := upper(substring(replace(new_family_id::text, '-', '') from 1 for 6));
    
    -- Get creator's role
    SELECT role INTO creator_role FROM profiles WHERE id = creator_id_param;
    
    IF creator_role IS NULL THEN
        RAISE EXCEPTION 'Creator profile not found';
    END IF;
    
    -- Create family with creator immediately in the right array
    IF creator_role = 'parent' THEN
        INSERT INTO families (
            id, name, invite_code, created_by_id, 
            parent_ids, child_ids, 
            created_at, last_activity_at
        ) VALUES (
            new_family_id, family_name_param, invite_code_result, creator_id_param,
            ARRAY[creator_id_param], ARRAY[]::UUID[],
            NOW(), NOW()
        );
    ELSE
        INSERT INTO families (
            id, name, invite_code, created_by_id, 
            parent_ids, child_ids, 
            created_at, last_activity_at
        ) VALUES (
            new_family_id, family_name_param, invite_code_result, creator_id_param,
            ARRAY[]::UUID[], ARRAY[creator_id_param],
            NOW(), NOW()
        );
    END IF;
    
    -- Update creator's profile
    UPDATE profiles 
    SET family_id = new_family_id 
    WHERE id = creator_id_param;
    
    RETURN new_family_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create atomic family joining function  
CREATE OR REPLACE FUNCTION join_family_atomic(
    invite_code_param TEXT,
    joiner_id_param UUID
) RETURNS UUID AS $$
DECLARE
    target_family_id UUID;
    joiner_role TEXT;
    current_parent_ids UUID[];
    current_child_ids UUID[];
    current_family_id UUID;
BEGIN
    -- Find family by invite code
    SELECT id, parent_ids, child_ids 
    INTO target_family_id, current_parent_ids, current_child_ids
    FROM families 
    WHERE invite_code = upper(invite_code_param);
    
    IF target_family_id IS NULL THEN
        RAISE EXCEPTION 'Invalid invite code';
    END IF;
    
    -- Get joiner's role and current family
    SELECT role, family_id 
    INTO joiner_role, current_family_id
    FROM profiles 
    WHERE id = joiner_id_param;
    
    IF joiner_role IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Check if user already has a family
    IF current_family_id IS NOT NULL THEN
        IF current_family_id = target_family_id THEN
            RAISE EXCEPTION 'User is already a member of this family';
        ELSE
            RAISE EXCEPTION 'User already has a family';
        END IF;
    END IF;
    
    -- Check if user is already in the family arrays
    IF (joiner_role = 'parent' AND joiner_id_param = ANY(current_parent_ids)) THEN
        RAISE EXCEPTION 'User is already in this family';
    END IF;
    
    IF (joiner_role = 'child' AND joiner_id_param = ANY(current_child_ids)) THEN
        RAISE EXCEPTION 'User is already in this family';
    END IF;
    
    -- Add to appropriate array and update profile ATOMICALLY
    IF joiner_role = 'parent' THEN
        -- Add to parent_ids
        UPDATE families 
        SET 
            parent_ids = parent_ids || ARRAY[joiner_id_param],
            last_activity_at = NOW()
        WHERE id = target_family_id;
    ELSE
        -- Add to child_ids
        UPDATE families 
        SET 
            child_ids = child_ids || ARRAY[joiner_id_param],
            last_activity_at = NOW()
        WHERE id = target_family_id;
    END IF;
    
    -- Update user's profile
    UPDATE profiles 
    SET family_id = target_family_id 
    WHERE id = joiner_id_param;
    
    RETURN target_family_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create function to safely leave family
CREATE OR REPLACE FUNCTION leave_family_atomic(
    user_id_param UUID
) RETURNS BOOLEAN AS $$
DECLARE
    user_family_id UUID;
    user_role TEXT;
BEGIN
    -- Get user's current family and role
    SELECT family_id, role 
    INTO user_family_id, user_role
    FROM profiles 
    WHERE id = user_id_param;
    
    IF user_family_id IS NULL THEN
        RAISE EXCEPTION 'User is not in a family';
    END IF;
    
    -- Remove from appropriate family array
    IF user_role = 'parent' THEN
        UPDATE families 
        SET 
            parent_ids = array_remove(parent_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = user_family_id;
    ELSE
        UPDATE families 
        SET 
            child_ids = array_remove(child_ids, user_id_param),
            last_activity_at = NOW()
        WHERE id = user_family_id;
    END IF;
    
    -- Remove family_id from user profile
    UPDATE profiles 
    SET family_id = NULL 
    WHERE id = user_id_param;
    
    -- Check if family is now empty and delete if so
    IF NOT EXISTS (
        SELECT 1 FROM families 
        WHERE id = user_family_id 
          AND (
              array_length(parent_ids, 1) > 0 OR 
              array_length(child_ids, 1) > 0
          )
    ) THEN
        DELETE FROM families WHERE id = user_family_id;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create function to check family membership
CREATE OR REPLACE FUNCTION is_family_member(
    user_id_param UUID,
    family_id_param UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM families f
        WHERE f.id = family_id_param
          AND (
              user_id_param = ANY(f.parent_ids) OR 
              user_id_param = ANY(f.child_ids)
          )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Create function to get family members safely
CREATE OR REPLACE FUNCTION get_family_members_safe(
    family_id_param UUID
) RETURNS TABLE (
    id UUID,
    email TEXT,
    display_name TEXT,
    role user_role,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- Check if current user is a family member
    IF NOT is_family_member(auth.uid(), family_id_param) THEN
        RAISE EXCEPTION 'Access denied: Not a family member';
    END IF;
    
    RETURN QUERY
    SELECT 
        p.id,
        p.email,
        p.display_name,
        p.role,
        p.created_at
    FROM profiles p
    WHERE p.family_id = family_id_param
    ORDER BY 
        CASE p.role 
            WHEN 'parent' THEN 1 
            WHEN 'child' THEN 2 
        END,
        p.display_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 6: Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION create_family_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION join_family_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION leave_family_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION is_family_member TO authenticated;
GRANT EXECUTE ON FUNCTION get_family_members_safe TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_profile TO authenticated;

-- Step 7: Create trigger to ensure family consistency
CREATE OR REPLACE FUNCTION maintain_family_consistency()
RETURNS TRIGGER AS $$
BEGIN
    -- When a profile's family_id changes, ensure they are in the right arrays
    IF TG_OP = 'UPDATE' AND OLD.family_id IS DISTINCT FROM NEW.family_id THEN
        
        -- Remove from old family if they had one
        IF OLD.family_id IS NOT NULL THEN
            IF NEW.role = 'parent' THEN
                UPDATE families 
                SET parent_ids = array_remove(parent_ids, NEW.id)
                WHERE id = OLD.family_id;
            ELSE
                UPDATE families 
                SET child_ids = array_remove(child_ids, NEW.id)
                WHERE id = OLD.family_id;
            END IF;
        END IF;
        
        -- Add to new family if they have one
        IF NEW.family_id IS NOT NULL THEN
            IF NEW.role = 'parent' THEN
                UPDATE families 
                SET 
                    parent_ids = CASE 
                        WHEN NEW.id = ANY(parent_ids) THEN parent_ids
                        ELSE parent_ids || ARRAY[NEW.id]
                    END,
                    last_activity_at = NOW()
                WHERE id = NEW.family_id;
            ELSE
                UPDATE families 
                SET 
                    child_ids = CASE 
                        WHEN NEW.id = ANY(child_ids) THEN child_ids
                        ELSE child_ids || ARRAY[NEW.id]
                    END,
                    last_activity_at = NOW()
                WHERE id = NEW.family_id;
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS ensure_family_consistency ON profiles;
CREATE TRIGGER ensure_family_consistency
    AFTER UPDATE OF family_id ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION maintain_family_consistency();

-- Step 8: Test and report
DO $$
BEGIN
    RAISE NOTICE '✅ All atomic family functions created successfully!';
    RAISE NOTICE '🔧 Functions available:';
    RAISE NOTICE '   - create_family_atomic(name, creator_id)';
    RAISE NOTICE '   - join_family_atomic(invite_code, joiner_id)';
    RAISE NOTICE '   - leave_family_atomic(user_id)';
    RAISE NOTICE '   - is_family_member(user_id, family_id)';
    RAISE NOTICE '   - get_family_members_safe(family_id)';
    RAISE NOTICE '   - can_access_profile(profile_id)';
    RAISE NOTICE '🛡️ Consistency trigger created for automatic family sync';
    RAISE NOTICE '🔑 All permissions granted to authenticated users';
END $$; 