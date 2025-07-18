-- IMMEDIATE SIGNUP FIX
-- Run this script right now to fix signup

-- Step 1: Temporarily disable RLS on profiles for testing
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 2: Re-enable RLS but with permissive policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop all existing restrictive policies
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;  
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
DROP POLICY IF EXISTS "profiles_select_family" ON profiles;

-- Step 4: Create simple, working policies
-- Allow authenticated users to insert their own profile
CREATE POLICY "allow_profile_insert" 
    ON profiles FOR INSERT 
    TO authenticated 
    WITH CHECK (auth.uid() = id);

-- Allow users to read their own profile and family members
CREATE POLICY "allow_profile_select" 
    ON profiles FOR SELECT 
    TO authenticated 
    USING (
        auth.uid() = id OR 
        family_id = (SELECT family_id FROM profiles WHERE id = auth.uid())
    );

-- Allow users to update their own profile
CREATE POLICY "allow_profile_update" 
    ON profiles FOR UPDATE 
    TO authenticated 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Step 5: Grant proper permissions
GRANT ALL ON profiles TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Step 6: Verify the fix
SELECT 'SUCCESS: Policies created' as status,
       COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'profiles';

-- Show current policies
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd; 