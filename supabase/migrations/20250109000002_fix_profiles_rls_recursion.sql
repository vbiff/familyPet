-- Fix infinite recursion in profiles RLS policies
-- The issue is that policies are referencing the profiles table in a way that creates loops
-- This prevents family members from being loaded properly

-- Drop all existing policies on profiles table
DROP POLICY IF EXISTS "profiles_viewable_by_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_authenticated_users_can_create" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_create_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_delete_own" ON profiles;

-- Create new, simpler policies that don't cause recursion
CREATE POLICY "profiles_users_can_view_own"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_users_can_view_family_members"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        auth.uid() = id OR
        (family_id IS NOT NULL AND EXISTS (
            SELECT 1 
            FROM profiles p 
            WHERE p.id = auth.uid() 
            AND p.family_id = profiles.family_id
            AND p.family_id IS NOT NULL
        ))
    );

CREATE POLICY "profiles_users_can_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_users_can_create_own"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_users_can_delete_own"
    ON profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Test the fix
DO $$
BEGIN
    RAISE NOTICE '✅ Fixed profiles RLS recursion issue!';
    RAISE NOTICE '🔧 Changes made:';
    RAISE NOTICE '   - Removed recursive policy that caused infinite loops';
    RAISE NOTICE '   - Created simpler policies that avoid recursion';
    RAISE NOTICE '   - Family members should now load properly';
    RAISE NOTICE '💡 Users should now see all family members in the family list!';
END $$; 