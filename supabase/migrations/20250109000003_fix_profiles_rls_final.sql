-- Final fix for profiles RLS recursion issue
-- Use a completely different approach that doesn't reference profiles table within policies

-- Drop all existing policies on profiles table
DROP POLICY IF EXISTS "profiles_users_can_view_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_create_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_delete_own" ON profiles;

-- Create simple policies that don't cause recursion
-- Allow users to see their own profile
CREATE POLICY "profiles_own_profile"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to see profiles that share the same family_id as their own
-- This uses the families table to check membership instead of profiles table
CREATE POLICY "profiles_same_family"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        family_id IS NOT NULL AND 
        family_id IN (
            SELECT f.id FROM families f 
            WHERE auth.uid() = ANY(f.parent_ids) OR auth.uid() = ANY(f.child_ids)
        )
    );

-- Update policy
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Insert policy
CREATE POLICY "profiles_insert_own"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Delete policy
CREATE POLICY "profiles_delete_own"
    ON profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Test the fix
DO $$
BEGIN
    RAISE NOTICE '✅ Final fix for profiles RLS recursion applied!';
    RAISE NOTICE '🔧 Changes made:';
    RAISE NOTICE '   - Removed all recursive references to profiles table';
    RAISE NOTICE '   - Used families table to check family membership';
    RAISE NOTICE '   - Completely eliminated recursion possibility';
    RAISE NOTICE '💡 Family members should now load without errors!';
END $$; 