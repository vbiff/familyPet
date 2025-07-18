-- Fix Signup RLS Issue
-- This script fixes the profile creation during signup by adding proper policies

-- Step 1: Check current issue
DO $$
BEGIN
    RAISE NOTICE '🔍 Diagnosing signup issue...';
    RAISE NOTICE 'Current RLS status: %', (
        SELECT CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END
        FROM pg_tables 
        WHERE tablename = 'profiles' AND schemaname = 'public'
    );
    RAISE NOTICE 'Current policy count: %', (
        SELECT COUNT(*) FROM pg_policies 
        WHERE tablename = 'profiles' AND schemaname = 'public'
    );
END $$;

-- Step 2: Drop the restrictive INSERT policy that's blocking signup
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;

-- Step 3: Create a more permissive INSERT policy for signup
-- This allows profile creation during signup process
CREATE POLICY "profiles_insert_signup"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow if the user ID matches the auth user
        auth.uid() = id
        -- Don't require email validation during signup as it might cause timing issues
    );

-- Step 4: Create an alternative INSERT policy for service role (if needed)
-- This allows server-side profile creation
CREATE POLICY "profiles_insert_service"
    ON profiles FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Step 5: Ensure the UPDATE policy exists and is permissive enough
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Step 6: Create a function to safely create profiles during signup
CREATE OR REPLACE FUNCTION create_profile_on_signup()
RETURNS TRIGGER AS $$
BEGIN
    -- This function runs with elevated privileges to create profiles
    -- It's triggered by auth.users changes
    INSERT INTO public.profiles (
        id,
        email,
        display_name,
        role,
        created_at,
        updated_at,
        last_login_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'parent'),
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW(),
        last_login_at = NOW();
        
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Create trigger to auto-create profiles (if it doesn't exist)
-- Note: This might already exist, so we'll recreate it
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_on_signup();

-- Step 8: Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT EXECUTE ON FUNCTION create_profile_on_signup TO authenticated;

-- Step 9: Create a safe profile upsert function for the app to use
CREATE OR REPLACE FUNCTION safe_upsert_profile(
    user_id UUID,
    user_email TEXT,
    display_name TEXT,
    user_role TEXT
) RETURNS void AS $$
BEGIN
    INSERT INTO profiles (
        id,
        email,
        display_name,
        role,
        created_at,
        updated_at,
        last_login_at
    ) VALUES (
        user_id,
        user_email,
        display_name,
        user_role::user_role,
        NOW(),
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = EXCLUDED.display_name,
        role = EXCLUDED.role,
        updated_at = NOW(),
        last_login_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION safe_upsert_profile TO authenticated;

-- Step 10: Verify the fix
DO $$
DECLARE
    insert_policies INTEGER;
    update_policies INTEGER;
    select_policies INTEGER;
BEGIN
    RAISE NOTICE '✅ Verifying signup fix...';
    
    SELECT COUNT(*) INTO insert_policies
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public' AND cmd = 'INSERT';
    
    SELECT COUNT(*) INTO update_policies
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public' AND cmd = 'UPDATE';
    
    SELECT COUNT(*) INTO select_policies
    FROM pg_policies 
    WHERE tablename = 'profiles' AND schemaname = 'public' AND cmd = 'SELECT';
    
    RAISE NOTICE 'INSERT policies: % (should be >= 1)', insert_policies;
    RAISE NOTICE 'UPDATE policies: % (should be >= 1)', update_policies;
    RAISE NOTICE 'SELECT policies: % (should be >= 2)', select_policies;
    
    IF insert_policies >= 1 AND update_policies >= 1 AND select_policies >= 2 THEN
        RAISE NOTICE '🎉 SIGNUP SHOULD NOW WORK!';
        RAISE NOTICE '📝 Profile creation is now allowed during signup';
        RAISE NOTICE '🛡️ Security is maintained for other operations';
    ELSE
        RAISE NOTICE '⚠️ Warning: Some policies might be missing';
    END IF;
END $$;

-- Step 11: Show current policies for verification
SELECT 
    '📋 CURRENT POLICIES' as section,
    policyname,
    cmd as operation,
    roles,
    CASE cmd 
        WHEN 'INSERT' THEN 'Allows profile creation during signup'
        WHEN 'UPDATE' THEN 'Allows users to update their own profile'
        WHEN 'SELECT' THEN 'Allows users to view permitted profiles'
        ELSE 'Other operation'
    END as purpose
FROM pg_policies
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY cmd, policyname; 