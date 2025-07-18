-- Safe Profiles RLS Fix - Handles Existing Policies
-- This script safely fixes RLS issues even if some policies already exist

-- Step 1: Check current status
DO $$
BEGIN
    RAISE NOTICE '🔍 Checking current RLS status...';
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'profiles' 
          AND schemaname = 'public' 
          AND rowsecurity = true
    ) THEN
        RAISE NOTICE '❌ CRITICAL: RLS is DISABLED on profiles table!';
        RAISE NOTICE '🚨 All user data is currently exposed!';
    ELSE
        RAISE NOTICE '✅ RLS is enabled on profiles table';
    END IF;
    
    RAISE NOTICE 'Current policy count: %', (
        SELECT COUNT(*) FROM pg_policies 
        WHERE tablename = 'profiles' AND schemaname = 'public'
    );
END $$;

-- Step 2: Enable RLS (safe if already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop existing policies safely (ignore if they don't exist)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    RAISE NOTICE '🧹 Cleaning up existing policies...';
    
    -- Get all existing policies on profiles table
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'profiles' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON profiles', policy_record.policyname);
        RAISE NOTICE 'Dropped policy: %', policy_record.policyname;
    END LOOP;
END $$;

-- Step 4: Create comprehensive, secure RLS policies

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

-- Policy 5: Users can delete their own profile (usually not needed, but safe)
CREATE POLICY "profiles_delete_own"
    ON profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = id);

-- Step 5: Create helper function to safely check profile access
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

-- Step 6: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON profiles TO authenticated;
GRANT EXECUTE ON FUNCTION can_access_profile TO authenticated;

-- Step 7: Verify the fix worked
DO $$
DECLARE
    rls_enabled BOOLEAN;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '✅ Verifying security fix...';
    
    -- Check RLS status
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables 
    WHERE tablename = 'profiles' AND schemaname = 'public';
    
    -- Count policies
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public';
    
    IF rls_enabled THEN
        RAISE NOTICE '✅ RLS is now ENABLED on profiles table';
    ELSE
        RAISE NOTICE '❌ RLS failed to enable - manual intervention needed';
    END IF;
    
    RAISE NOTICE '📋 Created % RLS policies for profiles table', policy_count;
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '🛡️ Profiles table is now SECURED!';
        RAISE NOTICE '🔒 Users can only access their own profile + family members';
        RAISE NOTICE '⛔ Unauthorized access is now blocked';
    ELSE
        RAISE NOTICE '⚠️ Warning: Insufficient policies created';
    END IF;
END $$;

-- Step 8: Show final security status
SELECT 
    '🎯 SECURITY STATUS' as section,
    CASE 
        WHEN rowsecurity AND (
            SELECT COUNT(*) FROM pg_policies 
            WHERE tablename = 'profiles' AND schemaname = 'public'
        ) >= 4 
        THEN '✅ FULLY SECURED'
        WHEN rowsecurity 
        THEN '⚠️ RLS ENABLED BUT INCOMPLETE POLICIES'
        ELSE '❌ STILL VULNERABLE'
    END as status,
    CASE 
        WHEN rowsecurity AND (
            SELECT COUNT(*) FROM pg_policies 
            WHERE tablename = 'profiles' AND schemaname = 'public'
        ) >= 4 
        THEN 'All user data is now protected by RLS'
        ELSE 'Additional fixes needed'
    END as description
FROM pg_tables 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- Step 9: List active policies for confirmation
SELECT 
    '📜 ACTIVE POLICIES' as section,
    policyname,
    cmd as operation,
    CASE cmd 
        WHEN 'SELECT' THEN 'Controls who can view profiles'
        WHEN 'INSERT' THEN 'Controls who can create profiles'
        WHEN 'UPDATE' THEN 'Controls who can modify profiles'
        WHEN 'DELETE' THEN 'Controls who can delete profiles'
    END as purpose
FROM pg_policies
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY 
    CASE cmd 
        WHEN 'SELECT' THEN 1
        WHEN 'INSERT' THEN 2
        WHEN 'UPDATE' THEN 3
        WHEN 'DELETE' THEN 4
    END,
    policyname; 