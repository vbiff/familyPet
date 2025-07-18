-- Debug Auth Issues
-- Quick diagnostic to check for authentication problems

-- Check auth schema permissions
SELECT 'AUTH SCHEMA CHECK' as section;
SELECT 
    schemaname,
    hasusage as can_use_schema
FROM pg_namespace n
JOIN pg_user u ON n.nspowner = u.usesysid
WHERE nspname IN ('auth', 'public');

-- Check if auth.users table is accessible
SELECT 'AUTH USERS TABLE CHECK' as section;
SELECT COUNT(*) as total_auth_users FROM auth.users;

-- Check profiles table structure and constraints
SELECT 'PROFILES TABLE CONSTRAINTS' as section;
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'profiles' AND table_schema = 'public';

-- Check current RLS status
SELECT 'RLS STATUS' as section;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    hasoids
FROM pg_tables 
WHERE tablename IN ('profiles', 'users') 
AND schemaname IN ('public', 'auth');

-- Check current policies
SELECT 'CURRENT POLICIES' as section;
SELECT 
    policyname,
    cmd,
    roles,
    qual as using_clause,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd;

-- Check for any triggers that might be interfering
SELECT 'TRIGGERS ON PROFILES' as section;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- Test a simple insert to see what happens
SELECT 'TESTING SIMPLE OPERATIONS' as section;

-- This should show if basic operations work
SELECT 'Can we select from profiles?' as test,
       CASE WHEN EXISTS (SELECT 1 FROM profiles LIMIT 1) THEN 'YES' ELSE 'NO DATA' END as result;
       
-- Check if we can see the auth user that just tried to sign up
SELECT 'Recent auth attempts' as section;
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'z@z.com'
ORDER BY created_at DESC 
LIMIT 3; 