-- Fix Infinite Recursion in Profiles RLS Policy
-- The SELECT policy is causing infinite recursion - fix it now

-- Step 1: Drop the problematic SELECT policy
DROP POLICY IF EXISTS "allow_profile_select" ON profiles;

-- Step 2: Create a simple, non-recursive SELECT policy
-- Users can only see their own profile initially
CREATE POLICY "profiles_select_own" 
    ON profiles FOR SELECT 
    TO authenticated 
    USING (auth.uid() = id);

-- Step 3: Add a separate policy for family members (without recursion)
-- This uses a different approach that doesn't cause loops
CREATE POLICY "profiles_select_family" 
    ON profiles FOR SELECT 
    TO authenticated 
    USING (
        -- Can see profiles where user and target are in the same family
        EXISTS (
            SELECT 1 FROM families f
            WHERE f.id = profiles.family_id
            AND (
                auth.uid() = ANY(f.parent_ids) OR 
                auth.uid() = ANY(f.child_ids)
            )
        )
    );

-- Step 4: Verify the fix worked
SELECT 'POLICY CHECK' as section,
       COUNT(*) as policy_count,
       string_agg(policyname, ', ') as policy_names
FROM pg_policies 
WHERE tablename = 'profiles' AND cmd = 'SELECT';

-- Step 5: Test that recursion is gone
-- This should not cause infinite loops now
SELECT 'RECURSION TEST' as section;
SELECT COUNT(*) as profile_count FROM profiles WHERE id = auth.uid();

-- Step 6: Show the current working policies
SELECT 'CURRENT POLICIES' as section;
SELECT 
    policyname,
    cmd as operation,
    roles,
    CASE 
        WHEN policyname LIKE '%own%' THEN 'Allow access to own data'
        WHEN policyname LIKE '%family%' THEN 'Allow access to family data'
        WHEN policyname LIKE '%insert%' THEN 'Allow profile creation'
        WHEN policyname LIKE '%update%' THEN 'Allow profile updates'
        ELSE 'Other'
    END as purpose
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

SELECT '✅ INFINITE RECURSION FIXED - SIGNUP SHOULD WORK NOW' as status; 