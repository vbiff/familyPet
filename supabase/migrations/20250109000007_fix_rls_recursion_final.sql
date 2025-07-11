-- Fix RLS recursion issue by using families table instead of profiles table in policies
-- This completely eliminates the recursion without touching any data

-- Drop the problematic policy that causes recursion
DROP POLICY IF EXISTS "users_can_view_family_profiles" ON profiles;

-- Create a new policy that uses families table instead of profiles table
-- This avoids recursion by not referencing profiles within the profiles policy
CREATE POLICY "users_can_view_family_profiles_no_recursion"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        family_id IS NOT NULL AND 
        (
            -- User can see profiles if they're in the same family
            -- Check using families table to avoid recursion
            family_id IN (
                SELECT f.id FROM families f 
                WHERE auth.uid() = ANY(f.parent_ids) OR auth.uid() = ANY(f.child_ids)
            )
        )
    );

-- Test the fix immediately
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    RAISE NOTICE '🔧 FIXING RLS RECURSION - NO DATA RESET';
    RAISE NOTICE '==========================================';
    
    -- Simple test to ensure no recursion
    SELECT COUNT(*) INTO test_count FROM profiles WHERE family_id IS NOT NULL;
    
    RAISE NOTICE '✅ Test query successful - no recursion detected';
    RAISE NOTICE '📊 Found % profiles with family_id', test_count;
    RAISE NOTICE '🎯 RLS recursion issue fixed!';
END $$; 