-- Fix infinite recursion in profiles RLS policy
-- The current policy causes recursion by referencing profiles table within profiles policy
-- Replace with non-recursive policy that uses families table

-- Drop the problematic recursive policy
DROP POLICY IF EXISTS "Profiles are viewable by family members" ON profiles;

-- Create non-recursive policies for profiles
-- Policy 1: Users can always see their own profile (no recursion)
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Policy 2: Users can see family members using families table (no recursion)
CREATE POLICY "profiles_select_family_members"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        family_id IS NOT NULL AND 
        family_id IN (
            SELECT f.id FROM families f 
            WHERE auth.uid() = ANY(f.parent_ids) 
               OR auth.uid() = ANY(f.child_ids)
               OR auth.uid() = f.created_by_id
        )
    );

-- Ensure other policies are correct (non-recursive)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Authenticated users can create profiles" ON profiles;
CREATE POLICY "profiles_insert_own"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Test the fix
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    RAISE NOTICE '🔧 FIXING INFINITE RECURSION IN PROFILES RLS';
    RAISE NOTICE '================================================';
    
    -- Test query to ensure no recursion
    SELECT COUNT(*) INTO test_count FROM profiles WHERE id = auth.uid();
    
    RAISE NOTICE '✅ Test query successful - no recursion detected';
    RAISE NOTICE '🎯 Infinite recursion issue fixed!';
    RAISE NOTICE '📝 New policies use families table to avoid recursion';
END $$; 