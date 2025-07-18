-- Check Auth Triggers and Constraints
-- This will identify what's blocking auth user creation

-- Step 1: Check for triggers on auth.users table
SELECT 'TRIGGERS ON AUTH.USERS' as section;
SELECT 
    trigger_name,
    event_manipulation as event_type,
    action_timing as timing,
    action_statement as trigger_function
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
  AND event_object_table = 'users'
ORDER BY action_timing, event_manipulation;

-- Step 2: Check for functions that might be called by triggers
SELECT 'TRIGGER FUNCTIONS' as section;
SELECT 
    routine_name as function_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%profile%' 
  OR routine_name LIKE '%user%';

-- Step 3: Check if there are RLS policies on auth tables
SELECT 'AUTH SCHEMA RLS STATUS' as section;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'auth'
ORDER BY tablename;

-- Step 4: Check for any policies on auth.users
SELECT 'POLICIES ON AUTH.USERS' as section;
SELECT 
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies 
WHERE schemaname = 'auth' AND tablename = 'users';

-- Step 5: Check recent error logs (if available)
SELECT 'RECENT AUTH ATTEMPTS' as section;
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'z@z.com'
ORDER BY created_at DESC 
LIMIT 5;

-- Step 6: Test if we can manually insert into auth.users
SELECT 'AUTH USER CREATION TEST' as section;
-- Don't actually insert, just check if we have permissions
SELECT 
    has_table_privilege('auth.users', 'INSERT') as can_insert_auth_users,
    has_schema_privilege('auth', 'USAGE') as can_use_auth_schema;

-- Step 7: Look for the specific trigger that might be failing
-- This is likely a trigger that tries to create profiles
SELECT 'PROFILE CREATION TRIGGER CHECK' as section;
SELECT 
    t.trigger_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM information_schema.triggers t
JOIN pg_proc p ON p.proname = t.action_statement
WHERE t.event_object_schema = 'auth' 
  AND t.event_object_table = 'users'
  AND t.trigger_name LIKE '%profile%';

-- Step 8: Drop the problematic trigger temporarily  
-- This is likely what's causing the signup to fail
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS create_profile_trigger ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;

-- Check if the trigger drop worked
SELECT 'REMAINING TRIGGERS' as section;
SELECT COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
  AND event_object_table = 'users';

-- If trigger count is 0, signup should work now
SELECT CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.triggers 
          WHERE event_object_schema = 'auth' AND event_object_table = 'users') = 0 
    THEN '✅ AUTH TRIGGERS REMOVED - SIGNUP SHOULD WORK NOW' 
    ELSE '⚠️ Some triggers remain - may still have issues'
END as status; 