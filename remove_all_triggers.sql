-- Remove all triggers and functions that might be interfering with profile creation
-- Execute this in Supabase dashboard SQL editor

-- Drop all possible triggers on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;
DROP TRIGGER IF EXISTS user_signup_trigger ON auth.users;

-- Drop all possible triggers on profiles table
DROP TRIGGER IF EXISTS trigger_maintain_family_membership ON profiles;
DROP TRIGGER IF EXISTS maintain_family_membership_trigger ON profiles;
DROP TRIGGER IF EXISTS update_profiles_trigger ON profiles;

-- Drop all possible functions
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS handle_new_user_signup();
DROP FUNCTION IF EXISTS maintain_family_membership();
DROP FUNCTION IF EXISTS update_user_profile();

-- Check if there are any remaining triggers
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name
FROM pg_trigger 
WHERE (tgrelid = 'auth.users'::regclass OR tgrelid = 'profiles'::regclass)
AND tgname NOT LIKE 'RI_ConstraintTrigger%';

-- Temporarily disable RLS on profiles to test
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Test profile creation manually
-- INSERT INTO profiles (id, email, display_name, role) VALUES ('test-user-id', 'test@test.com', 'Test User', 'parent');
-- SELECT * FROM profiles WHERE email = 'test@test.com';
-- DELETE FROM profiles WHERE email = 'test@test.com'; 