-- Check all triggers and functions that might be interfering with profile creation
-- Execute this in Supabase dashboard SQL editor

-- Check all triggers on auth.users table
SELECT 
    tgname as trigger_name,
    tgtype,
    tgenabled,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass 
AND tgname NOT LIKE 'RI_ConstraintTrigger%';

-- Check all triggers on profiles table
SELECT 
    tgname as trigger_name,
    tgtype,
    tgenabled,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger 
WHERE tgrelid = 'profiles'::regclass 
AND tgname NOT LIKE 'RI_ConstraintTrigger%';

-- Check for any functions that might be handling user creation
SELECT 
    proname as function_name,
    pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname LIKE '%user%' 
   OR proname LIKE '%profile%'
   OR proname LIKE '%auth%';

-- Check current RLS policies on profiles table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'; 