-- Fix signin crash after app reinstall
-- This migration completely removes the problematic auth trigger and fixes RLS policies
-- Date: 2025-01-10

-- Step 1: Remove ALL auth triggers that might be causing conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;
DROP TRIGGER IF EXISTS user_signup_trigger ON auth.users;

-- Step 2: Remove ALL related functions
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS handle_new_user_simple();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_new_user_simple();

-- Step 3: Temporarily disable RLS to fix policies without recursion
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing policies on profiles table to start fresh
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view family members" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;
DROP POLICY IF EXISTS "Allow authenticated users to read profiles" ON profiles;
DROP POLICY IF EXISTS "Allow users to insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_view_family_members" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_create_own" ON profiles;
DROP POLICY IF EXISTS "profiles_users_can_delete_own" ON profiles;
DROP POLICY IF EXISTS "profiles_own_profile" ON profiles;
DROP POLICY IF EXISTS "profiles_same_family" ON profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_can_view_family_profiles" ON profiles;
DROP POLICY IF EXISTS "users_can_view_family_profiles_no_recursion" ON profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON profiles;
DROP POLICY IF EXISTS "users_can_delete_own_profile" ON profiles;

-- Step 5: Create simple, non-recursive policies
CREATE POLICY "allow_own_profile_select"
    ON profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "allow_own_profile_update"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "allow_own_profile_insert"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Step 6: Add a simple family member viewing policy using families table to avoid recursion
CREATE POLICY "allow_family_member_select"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        family_id IS NOT NULL AND 
        EXISTS (
            SELECT 1 FROM families f 
            WHERE f.id = profiles.family_id 
            AND (auth.uid() = ANY(f.parent_ids) OR auth.uid() = ANY(f.child_ids) OR auth.uid() = f.created_by_id)
        )
    );

-- Step 7: Re-enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Step 8: Ensure families table has simple policies
ALTER TABLE families DISABLE ROW LEVEL SECURITY;

-- Drop existing family policies
DROP POLICY IF EXISTS "Families are viewable by members" ON families;
DROP POLICY IF EXISTS "Authenticated users can view families" ON families;
DROP POLICY IF EXISTS "Users can view their family" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "Family creators can update families" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

-- Create simple family policies
CREATE POLICY "allow_family_member_view"
    ON families FOR SELECT
    TO authenticated
    USING (
        auth.uid() = created_by_id OR 
        auth.uid() = ANY(parent_ids) OR 
        auth.uid() = ANY(child_ids)
    );

CREATE POLICY "allow_family_creation"
    ON families FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "allow_family_update"
    ON families FOR UPDATE
    TO authenticated
    USING (auth.uid() = created_by_id OR auth.uid() = ANY(parent_ids))
    WITH CHECK (auth.uid() = created_by_id OR auth.uid() = ANY(parent_ids));

ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- Step 9: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Step 10: Success message
DO $$
BEGIN
    RAISE NOTICE '✅ SIGNIN CRASH FIX APPLIED SUCCESSFULLY!';
    RAISE NOTICE '==========================================';
    RAISE NOTICE '🔧 Removed all problematic auth triggers';
    RAISE NOTICE '🔒 Simplified RLS policies to prevent recursion';
    RAISE NOTICE '👥 Client will handle profile creation directly';
    RAISE NOTICE '🚀 App should now signin without crashing after reinstall';
END $$; 