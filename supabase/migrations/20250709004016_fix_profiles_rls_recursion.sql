-- Fix infinite recursion in profiles RLS policies
-- The issue is that policies are referencing the profiles table in a way that creates loops

-- Drop all existing policies on profiles table
DROP POLICY IF EXISTS "profiles_viewable_by_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_authenticated_users_can_create" ON profiles;

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
        family_id IS NOT NULL AND family_id IN (
            SELECT p.family_id 
            FROM profiles p 
            WHERE p.id = auth.uid() AND p.family_id IS NOT NULL
        )
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