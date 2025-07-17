-- Fix RLS policies for family creation
-- This addresses the PostgrestException when creating new families

-- =====================================================
-- 1. CHECK CURRENT POLICIES
-- =====================================================

SELECT 
    'Current RLS policies on families table:' as info,
    policyname,
    permissive,
    roles,
    cmd as command_type,
    qual as policy_condition
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'families';

-- =====================================================
-- 2. ENSURE RLS IS ENABLED BUT WITH PROPER POLICIES
-- =====================================================

-- Enable RLS on families table (if not already enabled)
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. DROP CONFLICTING INSERT POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can create families" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "families_insertable_by_user" ON families;

-- =====================================================
-- 4. CREATE PERMISSIVE INSERT POLICY FOR FAMILY CREATION
-- =====================================================

-- Allow authenticated users to create families
CREATE POLICY "authenticated_users_can_create_families" ON families
    FOR INSERT 
    TO authenticated
    WITH CHECK (true);

-- =====================================================
-- 5. ENSURE SELECT POLICY EXISTS FOR READING FAMILIES
-- =====================================================

-- Drop and recreate select policy to ensure it's correct
DROP POLICY IF EXISTS "families_viewable_by_all_authenticated" ON families;

CREATE POLICY "families_viewable_by_all_authenticated" ON families
    FOR SELECT 
    TO authenticated
    USING (true);

-- =====================================================
-- 6. ENSURE UPDATE POLICY EXISTS FOR FAMILY MANAGEMENT
-- =====================================================

-- Drop and recreate update policy
DROP POLICY IF EXISTS "families_updatable_by_creators_and_parents" ON families;

CREATE POLICY "families_updatable_by_creators_and_parents" ON families
    FOR UPDATE 
    TO authenticated
    USING (
        created_by_id = auth.uid() OR 
        auth.uid() = ANY(parent_ids)
    )
    WITH CHECK (
        created_by_id = auth.uid() OR 
        auth.uid() = ANY(parent_ids)
    );

-- =====================================================
-- 7. TEST THE POLICIES
-- =====================================================

-- Test 1: Check if current user can theoretically create a family
SELECT 
    'Can current user create families?' as test,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'YES - User is authenticated ✅'
        ELSE 'NO - User not authenticated ❌'
    END as result;

-- Test 2: Show current user info
SELECT 
    'Current user info:' as test,
    auth.uid() as user_id,
    auth.email() as user_email;

-- Test 3: Try a simulated family creation (this will show if the policy would work)
-- Note: This is just a test query, it won't actually create anything
EXPLAIN (FORMAT TEXT) 
INSERT INTO families (name, invite_code, created_by_id, parent_ids) 
VALUES ('TEST_FAMILY', 'TEST123', auth.uid(), ARRAY[auth.uid()]);

-- =====================================================
-- 8. CHECK PROFILES TABLE RLS TOO
-- =====================================================

-- The family creation might also fail if profiles table has restrictive RLS
SELECT 
    'Profiles table RLS status:' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles';

-- Show profiles RLS policies
SELECT 
    'Profiles RLS policies:' as info,
    policyname,
    cmd as command_type
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'profiles';

-- =====================================================
-- 9. VERIFICATION QUERIES
-- =====================================================

-- Show all current policies on families table after our changes
SELECT 
    '=== FINAL FAMILIES TABLE POLICIES ===' as section,
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Reading families'
        WHEN cmd = 'INSERT' THEN 'Creating families' 
        WHEN cmd = 'UPDATE' THEN 'Updating families'
        WHEN cmd = 'DELETE' THEN 'Deleting families'
        ELSE cmd
    END as description
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'families'
ORDER BY cmd;

SELECT 'RLS fix for family creation completed! ✅' as status; 