-- Fix automatic family assignment issue
-- This migration ensures that new users are not automatically assigned to families

-- First, let's check if there are any users incorrectly assigned to families
DO $$
DECLARE
    incorrect_assignments INT;
BEGIN
    -- Count profiles that have family_id but are not in family member arrays
    SELECT COUNT(*) INTO incorrect_assignments
    FROM profiles p
    JOIN families f ON p.family_id = f.id
    WHERE p.id != f.created_by_id 
      AND p.id != ALL(COALESCE(f.parent_ids, '{}')) 
      AND p.id != ALL(COALESCE(f.child_ids, '{}'));
    
    IF incorrect_assignments > 0 THEN
        RAISE NOTICE 'Found % profiles with incorrect family assignments', incorrect_assignments;
        
        -- Clear incorrect family assignments
        UPDATE profiles 
        SET family_id = NULL, updated_at = NOW()
        WHERE id IN (
            SELECT p.id
            FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE p.id != f.created_by_id 
              AND p.id != ALL(COALESCE(f.parent_ids, '{}')) 
              AND p.id != ALL(COALESCE(f.child_ids, '{}'))
        );
        
        RAISE NOTICE 'Cleared % incorrect family assignments', incorrect_assignments;
    ELSE
        RAISE NOTICE 'No incorrect family assignments found';
    END IF;
END $$;

-- Ensure the handle_new_user function does NOT assign family_id
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    -- Insert new profile WITHOUT family_id assignment
    INSERT INTO public.profiles (
        id,
        email,
        display_name,
        role,
        created_at,
        updated_at,
        last_login_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
        updated_at = NOW(),
        last_login_at = NOW()
        -- NOTE: Explicitly NOT updating family_id here
    ;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth process
        RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Create a function to safely add members to families
-- This replaces the automatic assignment in family creation
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

-- Create a function to safely remove members from families
CREATE OR REPLACE FUNCTION safe_remove_family_member(
    family_id_param UUID,
    user_id_param UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    current_parent_ids UUID[];
    current_child_ids UUID[];
BEGIN
    -- Get current member arrays
    SELECT parent_ids, child_ids INTO current_parent_ids, current_child_ids
    FROM families WHERE id = family_id_param;
    
    -- Check if user is actually a member
    IF user_id_param != ANY(COALESCE(current_parent_ids, '{}')) AND 
       user_id_param != ANY(COALESCE(current_child_ids, '{}')) THEN
        RAISE NOTICE 'User % is not a member of family %', user_id_param, family_id_param;
        RETURN FALSE;
    END IF;
    
    -- Remove from both arrays and update profile
    BEGIN
        -- Update family member arrays
        UPDATE families 
        SET 
            parent_ids = array_remove(COALESCE(current_parent_ids, '{}'), user_id_param),
            child_ids = array_remove(COALESCE(current_child_ids, '{}'), user_id_param),
            last_activity_at = NOW(),
            updated_at = NOW()
        WHERE id = family_id_param;
        
        -- Clear family_id from user profile
        UPDATE profiles 
        SET 
            family_id = NULL,
            updated_at = NOW()
        WHERE id = user_id_param;
        
        RAISE NOTICE 'Successfully removed user % from family %', user_id_param, family_id_param;
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Failed to remove user from family: %', SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Add a constraint to ensure family_id consistency
-- This will prevent profiles from having family_id without being in family arrays
CREATE OR REPLACE FUNCTION check_family_membership_consistency()
RETURNS TRIGGER AS $$
BEGIN
    -- If family_id is being set, verify the user is in the family arrays
    IF NEW.family_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM families f 
            WHERE f.id = NEW.family_id 
            AND (
                NEW.id = f.created_by_id OR
                NEW.id = ANY(COALESCE(f.parent_ids, '{}')) OR 
                NEW.id = ANY(COALESCE(f.child_ids, '{}'))
            )
        ) THEN
            RAISE EXCEPTION 'User % cannot be assigned to family % - not in family member arrays', NEW.id, NEW.family_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce family membership consistency
DROP TRIGGER IF EXISTS enforce_family_membership_consistency ON profiles;
CREATE TRIGGER enforce_family_membership_consistency
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    WHEN (OLD.family_id IS DISTINCT FROM NEW.family_id)
    EXECUTE FUNCTION check_family_membership_consistency();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Automatic family assignment fix completed successfully!';
    RAISE NOTICE '📋 Summary:';
    RAISE NOTICE '  - handle_new_user() function updated to NOT assign family_id';
    RAISE NOTICE '  - safe_add_family_member() function created for explicit family joins';
    RAISE NOTICE '  - safe_remove_family_member() function created for leaving families';
    RAISE NOTICE '  - Family membership consistency trigger added';
    RAISE NOTICE '  - Any incorrect family assignments have been cleared';
    RAISE NOTICE '💡 New users will no longer be automatically assigned to families';
END $$; 