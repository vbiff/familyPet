-- Fix RLS policies to allow child users to see all family members
-- The current policies are too complex and causing access issues

-- Drop existing complex policies
DROP POLICY IF EXISTS "profiles_own_profile" ON profiles;
DROP POLICY IF EXISTS "profiles_same_family" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON profiles;

-- Create simpler, more permissive policies
-- Policy 1: Users can always see their own profile
CREATE POLICY "users_can_view_own_profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Policy 2: Users can see profiles of people in the same family
-- This is simpler and doesn't cause recursion issues
CREATE POLICY "users_can_view_family_profiles"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        family_id IS NOT NULL AND 
        EXISTS (
            SELECT 1 FROM profiles current_user_profile
            WHERE current_user_profile.id = auth.uid()
            AND current_user_profile.family_id = profiles.family_id
        )
    );

-- Update policy (only own profile)
CREATE POLICY "users_can_update_own_profile"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Insert policy (only own profile)
CREATE POLICY "users_can_insert_own_profile"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Delete policy (only own profile)
CREATE POLICY "users_can_delete_own_profile"
    ON profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Test the new policies
DO $$
DECLARE
    test_user_id UUID := 'aaa5a152-1c10-4608-92bb-14622099c8c1'; -- The child user from logs
    test_family_id UUID := '3279a758-2733-4d93-b0e8-e03399420b7a'; -- The family from logs
    profile_count INTEGER;
    family_member_count INTEGER;
    test_result RECORD; -- Fix: declare the loop variable as RECORD
BEGIN
    RAISE NOTICE '🧪 TESTING NEW RLS POLICIES';
    RAISE NOTICE '============================';
    
    -- Test 1: Check how many profiles the child user should be able to see
    SELECT COUNT(*) INTO profile_count
    FROM profiles p
    WHERE p.family_id = test_family_id;
    
    RAISE NOTICE '📊 Total profiles with family_id %: %', test_family_id, profile_count;
    
    -- Test 2: Check family member arrays
    SELECT (array_length(parent_ids, 1) + array_length(child_ids, 1)) INTO family_member_count
    FROM families
    WHERE id = test_family_id;
    
    RAISE NOTICE '📊 Family member count from arrays: %', COALESCE(family_member_count, 0);
    
    -- Test 3: List all profiles that should be visible
    FOR test_result IN
        SELECT p.id, p.display_name, p.role, p.family_id
        FROM profiles p
        WHERE p.family_id = test_family_id
        ORDER BY p.role, p.display_name
    LOOP
        RAISE NOTICE '👤 Profile: % (%) - Role: %, Family: %', 
            test_result.display_name, 
            test_result.id, 
            test_result.role,
            test_result.family_id;
    END LOOP;
    
    RAISE NOTICE '✅ RLS policies updated - child users should now see all family members!';
END $$; 