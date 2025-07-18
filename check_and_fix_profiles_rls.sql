-- Check and Fix Profiles Table RLS Policies
-- This script diagnoses and fixes RLS issues for the profiles table

-- Step 1: Check current RLS status
SELECT 
    'CURRENT_RLS_STATUS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS DISABLED - SECURITY RISK!'
    END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'profiles';

-- Step 2: Check existing policies on profiles table
SELECT 
    'EXISTING_POLICIES' as check_type,
    policyname,
    cmd as operation,
    permissive,
    roles,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE tablename = 'profiles'
  AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Step 3: Check if there are any permission issues
SELECT 
    'PERMISSION_CHECK' as check_type,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_name = 'profiles'
  AND table_schema = 'public'
  AND grantee IN ('authenticated', 'public')
ORDER BY grantee, privilege_type;

-- Step 4: Enable RLS if it's disabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop all existing problematic policies (clean slate)
DROP POLICY IF EXISTS "profiles_own_profile" ON profiles;
DROP POLICY IF EXISTS "profiles_same_family" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_create_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_delete_own" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can create profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;

-- Step 6: Create comprehensive, secure RLS policies

-- Policy 1: Users can view their own profile
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Policy 2: Users can view family members' profiles
-- This uses families table to avoid recursion issues
CREATE POLICY "profiles_select_family_members"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        -- Only if user has a family
        family_id IS NOT NULL AND 
        -- And the profile belongs to someone in the same family
        family_id IN (
            SELECT f.id 
            FROM families f 
            WHERE auth.uid() = ANY(f.parent_ids) 
               OR auth.uid() = ANY(f.child_ids)
        )
    );

-- Policy 3: Users can insert their own profile (during signup)
CREATE POLICY "profiles_insert_own"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = id
        AND email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );

-- Policy 4: Users can update their own profile
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        -- Ensure they can't change their ID
        AND id = auth.uid()
    );

-- Policy 5: Users can delete their own profile (optional, usually not needed)
CREATE POLICY "profiles_delete_own"
    ON profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Step 7: Create a function to safely check if user can access profile
CREATE OR REPLACE FUNCTION can_access_profile(profile_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- User can access their own profile
    IF auth.uid() = profile_id THEN
        RETURN TRUE;
    END IF;
    
    -- User can access family members' profiles
    RETURN EXISTS (
        SELECT 1 
        FROM profiles p1, profiles p2, families f
        WHERE p1.id = auth.uid()
          AND p2.id = profile_id
          AND p1.family_id = p2.family_id
          AND p1.family_id = f.id
          AND p1.family_id IS NOT NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON profiles TO authenticated;

-- Step 9: Test the policies
DO $$
BEGIN
    -- Check if RLS is now enabled
    IF EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'profiles' 
          AND schemaname = 'public' 
          AND rowsecurity = true
    ) THEN
        RAISE NOTICE '✅ RLS is now enabled on profiles table';
    ELSE
        RAISE NOTICE '❌ RLS failed to enable on profiles table';
    END IF;
    
    -- Count policies
    RAISE NOTICE 'Created % RLS policies for profiles table', (
        SELECT COUNT(*) 
        FROM pg_policies 
        WHERE tablename = 'profiles' 
          AND schemaname = 'public'
    );
END $$;

-- Step 10: Verify final status
SELECT 
    'FINAL_STATUS' as check_type,
    COUNT(*) as policy_count,
    'Profiles table is now secured with RLS' as message
FROM pg_policies
WHERE tablename = 'profiles'
  AND schemaname = 'public';

-- Step 11: Show all active policies
SELECT 
    'ACTIVE_POLICIES' as check_type,
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Who can view profiles'
        WHEN cmd = 'INSERT' THEN 'Who can create profiles'
        WHEN cmd = 'UPDATE' THEN 'Who can modify profiles'
        WHEN cmd = 'DELETE' THEN 'Who can delete profiles'
    END as description
FROM pg_policies
WHERE tablename = 'profiles'
  AND schemaname = 'public'
ORDER BY 
    CASE cmd 
        WHEN 'SELECT' THEN 1
        WHEN 'INSERT' THEN 2
        WHEN 'UPDATE' THEN 3
        WHEN 'DELETE' THEN 4
    END,
    policyname; 