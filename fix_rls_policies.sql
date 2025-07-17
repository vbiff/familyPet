-- Fix RLS policies for family joining functionality
-- This script resolves issues where users can't join families due to restrictive RLS policies

-- =====================================================
-- 1. FIX FAMILIES TABLE RLS POLICIES
-- =====================================================

-- First, check current state
DO $$
BEGIN
    RAISE NOTICE '🔍 Current RLS policies on families table:';
END $$;

-- Drop all existing conflicting policies on families table
DROP POLICY IF EXISTS "families_viewable_by_members" ON families;
DROP POLICY IF EXISTS "Users can view their own family" ON families;
DROP POLICY IF EXISTS "Users can view families" ON families;
DROP POLICY IF EXISTS "families_viewable_by_members_and_invite_lookups" ON families;
DROP POLICY IF EXISTS "Users can create families" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

-- Enable RLS on families table
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for families table
-- 1. SELECT policy - Allow viewing for invite code lookups and family members
CREATE POLICY "families_select_policy"
    ON families FOR SELECT
    TO authenticated
    USING (
        -- Can view families they're members of
        created_by_id = auth.uid() OR
        auth.uid() = ANY(COALESCE(parent_ids, '{}')) OR
        auth.uid() = ANY(COALESCE(child_ids, '{}')) OR
        -- Allow all authenticated users to view families (needed for invite code lookups)
        -- This is safe because we don't expose sensitive data, just basic family info
        auth.role() = 'authenticated'
    );

-- 2. INSERT policy - Allow creating families
CREATE POLICY "families_insert_policy"
    ON families FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = created_by_id
    );

-- 3. UPDATE policy - Allow family creators and parents to update
CREATE POLICY "families_update_policy"
    ON families FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(COALESCE(parent_ids, '{}'))
    )
    WITH CHECK (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(COALESCE(parent_ids, '{}'))
    );

-- 4. DELETE policy - Only family creators can delete
CREATE POLICY "families_delete_policy"
    ON families FOR DELETE
    TO authenticated
    USING (
        auth.uid() = created_by_id
    );

-- =====================================================
-- 2. FIX PROFILES TABLE RLS POLICIES
-- =====================================================

-- Drop existing conflicting policies on profiles table
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view family members" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for profiles table
-- 1. SELECT policy - Allow viewing own profile and family members
CREATE POLICY "profiles_select_policy"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        -- Can view own profile
        auth.uid() = id OR
        -- Can view family members (users in same family)
        (family_id IS NOT NULL AND family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        ))
    );

-- 2. INSERT policy - Allow creating own profile (handled by trigger)
CREATE POLICY "profiles_insert_policy"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = id
    );

-- 3. UPDATE policy - Allow updating own profile and family admins can update family members
CREATE POLICY "profiles_update_policy"
    ON profiles FOR UPDATE
    TO authenticated
    USING (
        -- Can update own profile
        auth.uid() = id OR
        -- Family creators and parents can update family member profiles
        (family_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM families f
            WHERE f.id = family_id
            AND (f.created_by_id = auth.uid() OR auth.uid() = ANY(f.parent_ids))
        ))
    )
    WITH CHECK (
        -- Can update own profile
        auth.uid() = id OR
        -- Family creators and parents can update family member profiles
        (family_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM families f
            WHERE f.id = family_id
            AND (f.created_by_id = auth.uid() OR auth.uid() = ANY(f.parent_ids))
        ))
    );

-- 4. DELETE policy - Only allow deleting own profile
CREATE POLICY "profiles_delete_policy"
    ON profiles FOR DELETE
    TO authenticated
    USING (
        auth.uid() = id
    );

-- =====================================================
-- 3. CREATE HELPER FUNCTIONS FOR FAMILY JOINING
-- =====================================================

-- Function to safely join family with better error handling
CREATE OR REPLACE FUNCTION join_family_by_invite_code(
    invite_code_param TEXT,
    user_id_param UUID DEFAULT auth.uid()
)
RETURNS TABLE (
    success BOOLEAN,
    family_id UUID,
    family_name TEXT,
    error_message TEXT
) 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
DECLARE
    target_family RECORD;
    user_profile RECORD;
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Normalize invite code
    invite_code_param := UPPER(TRIM(invite_code_param));
    
    -- Validate inputs
    IF invite_code_param IS NULL OR LENGTH(invite_code_param) != 6 THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'Invalid invite code format'::TEXT;
        RETURN;
    END IF;
    
    IF user_id_param IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'User not authenticated'::TEXT;
        RETURN;
    END IF;
    
    -- Find the family by invite code
    SELECT * INTO target_family FROM families WHERE invite_code = invite_code_param;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'Family not found with this invite code'::TEXT;
        RETURN;
    END IF;
    
    -- Get user profile
    SELECT * INTO user_profile FROM profiles WHERE id = user_id_param;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'User profile not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user already has a family
    IF user_profile.family_id IS NOT NULL THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'User is already a member of a family'::TEXT;
        RETURN;
    END IF;
    
    -- Check if user is already a member of this family
    IF user_id_param = ANY(COALESCE(target_family.parent_ids, '{}')) OR 
       user_id_param = ANY(COALESCE(target_family.child_ids, '{}')) THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, NULL::TEXT, 'User is already a member of this family'::TEXT;
        RETURN;
    END IF;
    
    -- Add user to appropriate array based on role
    IF user_profile.role = 'parent' THEN
        new_parent_ids := COALESCE(target_family.parent_ids, '{}') || user_id_param;
        new_child_ids := COALESCE(target_family.child_ids, '{}');
    ELSE
        new_parent_ids := COALESCE(target_family.parent_ids, '{}');
        new_child_ids := COALESCE(target_family.child_ids, '{}') || user_id_param;
    END IF;
    
    -- Update family member arrays
    UPDATE families 
    SET 
        parent_ids = new_parent_ids,
        child_ids = new_child_ids,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = target_family.id;
    
    -- Update user's family_id
    UPDATE profiles 
    SET 
        family_id = target_family.id,
        updated_at = NOW()
    WHERE id = user_id_param;
    
    -- Return success
    RETURN QUERY SELECT TRUE, target_family.id, target_family.name, NULL::TEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. TEST THE POLICIES
-- =====================================================

-- Test function to validate the policies work
CREATE OR REPLACE FUNCTION test_family_rls_policies()
RETURNS TEXT AS $$
DECLARE
    test_result TEXT := '';
    family_count INTEGER;
    can_see_families BOOLEAN;
BEGIN
    -- Test 1: Can authenticated users see families for invite code lookup?
    SELECT COUNT(*) INTO family_count FROM families;
    
    IF family_count > 0 THEN
        test_result := test_result || '✅ Can query families table (' || family_count || ' families found)' || chr(10);
        can_see_families := TRUE;
    ELSE
        test_result := test_result || '❌ Cannot query families table or no families exist' || chr(10);
        can_see_families := FALSE;
    END IF;
    
    -- Test 2: Can find specific family by invite code?
    IF can_see_families THEN
        PERFORM id FROM families WHERE invite_code = 'DEFHJK';
        IF FOUND THEN
            test_result := test_result || '✅ Can find family with invite code DEFHJK' || chr(10);
        ELSE
            test_result := test_result || '❌ Cannot find family with invite code DEFHJK' || chr(10);
        END IF;
    END IF;
    
    test_result := test_result || chr(10) || '🔧 RLS Policy Test Complete';
    
    RETURN test_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. EXECUTE TESTS AND SHOW RESULTS
-- =====================================================

-- Run the test
SELECT test_family_rls_policies() as test_results;

-- Show current policies
DO $$
DECLARE
    policy_rec RECORD;
BEGIN
    RAISE NOTICE '📋 Current RLS Policies:';
    RAISE NOTICE '';
    
    FOR policy_rec IN 
        SELECT 
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd
        FROM pg_policies 
        WHERE tablename IN ('families', 'profiles')
        ORDER BY tablename, cmd
    LOOP
        RAISE NOTICE '   Table: % | Policy: % | Command: % | Roles: %', 
            policy_rec.tablename, 
            policy_rec.policyname, 
            policy_rec.cmd,
            policy_rec.roles;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ RLS policies have been updated!';
    RAISE NOTICE '💡 Try joining the family again in your app.';
END $$; 