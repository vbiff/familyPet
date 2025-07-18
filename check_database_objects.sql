-- Check Database Triggers, Functions, and Procedures
-- Run this to see what exists in the remote Supabase database

-- 1. Check all triggers
SELECT 
    'TRIGGERS:' as object_type,
    schemaname,
    tablename,
    triggername,
    definition
FROM pg_triggers 
WHERE schemaname = 'public'
ORDER BY tablename, triggername;

-- 2. Check all functions and procedures
SELECT 
    'FUNCTIONS:' as object_type,
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    CASE p.prokind
        WHEN 'f' THEN 'function'
        WHEN 'p' THEN 'procedure'
        WHEN 'a' THEN 'aggregate'
        WHEN 'w' THEN 'window'
    END as function_type
FROM pg_proc p 
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname = 'public'
  AND p.proname LIKE '%family%'
ORDER BY p.proname;

-- 3. Check all functions (broader search)
SELECT 
    'ALL_FUNCTIONS:' as object_type,
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p 
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- 4. Check RLS policies on families table
SELECT 
    'RLS_POLICIES:' as object_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'families'
ORDER BY policyname;

-- 5. Check table constraints
SELECT 
    'CONSTRAINTS:' as object_type,
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name IN ('families', 'profiles')
ORDER BY table_name, constraint_type;

-- 6. Check current family data to understand the issue
SELECT 
    'FAMILY_DATA:' as object_type,
    f.name as family_name,
    f.invite_code,
    array_length(f.parent_ids, 1) as parent_count,
    array_length(f.child_ids, 1) as child_count,
    f.parent_ids,
    f.child_ids
FROM families f
ORDER BY f.created_at DESC
LIMIT 3;

-- 7. Check profile data for users with family_id
SELECT 
    'PROFILE_DATA:' as object_type,
    p.display_name,
    p.role,
    p.family_id,
    f.name as family_name,
    CASE 
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN 'IN_PARENT_IDS'
        WHEN p.role = 'child' AND p.id = ANY(f.child_ids) THEN 'IN_CHILD_IDS'
        WHEN p.family_id IS NOT NULL THEN 'HAS_FAMILY_ID_BUT_NOT_IN_ARRAYS'
        ELSE 'NO_FAMILY'
    END as status
FROM profiles p
LEFT JOIN families f ON p.family_id = f.id
WHERE p.family_id IS NOT NULL OR p.display_name IN ('kseniia', 'Mike', 'privet')
ORDER BY p.created_at DESC; 