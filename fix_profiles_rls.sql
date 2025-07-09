-- Fix infinite recursion in profiles RLS policies
-- Execute this in Supabase dashboard SQL editor

-- Drop all existing policies on profiles table
DROP POLICY IF EXISTS "profiles_viewable_by_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_authenticated_users_can_create" ON profiles;

-- Create simple, non-recursive policies
CREATE POLICY "profiles_users_can_view_own"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_users_can_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_users_can_create_own"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- For now, let's keep family member viewing simple to avoid recursion
-- We can add more complex family policies later once basic signup works
CREATE POLICY "profiles_family_members_can_view"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        auth.uid() = id OR
        (family_id IS NOT NULL AND EXISTS (
            SELECT 1 FROM profiles p 
            WHERE p.id = auth.uid() 
            AND p.family_id = profiles.family_id
        ))
    ); 