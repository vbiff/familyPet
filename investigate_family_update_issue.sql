-- Investigate Family Update Issues
-- This script checks for constraints, triggers, and RLS policies that might prevent family updates

-- 1. Check RLS policies on families table
SELECT 
    'RLS_POLICIES_FAMILIES' as type,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'families'
ORDER BY cmd, policyname;

-- 2. Check RLS policies on profiles table  
SELECT 
    'RLS_POLICIES_PROFILES' as type,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;

-- 3. Check if RLS is enabled
SELECT 
    'RLS_STATUS' as type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('families', 'profiles');

-- 4. Check current user and their permissions
SELECT 
    'CURRENT_USER' as type,
    current_user,
    session_user,
    current_setting('role') as current_role;

-- 5. Check table constraints that might prevent updates
SELECT 
    'CONSTRAINTS' as type,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name IN ('families', 'profiles')
  AND constraint_type IN ('CHECK', 'FOREIGN KEY')
ORDER BY table_name, constraint_type;

-- 6. Check triggers on families table
SELECT 
    'TRIGGERS_FAMILIES' as type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'families'
  AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 7. Check triggers on profiles table
SELECT 
    'TRIGGERS_PROFILES' as type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'profiles'
  AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 8. Try a simple test update to see what happens
-- First, let's see what we're working with
SELECT 
    'TEST_DATA_BEFORE' as type,
    f.id as family_id,
    f.name,
    f.parent_ids,
    f.child_ids,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'parent') as actual_parents,
    (SELECT COUNT(*) FROM profiles WHERE family_id = f.id AND role = 'child') as actual_children
FROM families f
ORDER BY f.created_at DESC
LIMIT 1;

-- 9. Check specific user that should be in family
SELECT 
    'USER_CHECK' as type,
    p.id,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    CASE 
        WHEN p.family_id IS NULL THEN 'NO_FAMILY'
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN 'IN_PARENT_IDS'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN 'IN_CHILD_IDS'
        ELSE 'HAS_FAMILY_BUT_NOT_IN_ARRAYS'
    END as status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.display_name IN ('kseniia', 'Mike', 'privet')
   OR p.family_id IS NOT NULL
ORDER BY p.created_at DESC; 