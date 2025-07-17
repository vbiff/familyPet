-- Debug script for invite code "DEFHJK"

-- Check if any families exist in the database
SELECT 
    'Total families in database: ' || COUNT(*) as info
FROM families;

-- Check if the specific invite code exists
SELECT 
    id,
    name,
    invite_code,
    created_by_id,
    parent_ids,
    child_ids,
    created_at
FROM families 
WHERE invite_code = 'DEFHJK';

-- Check if the invite code format is valid according to our validation function
SELECT 
    'DEFHJK' as test_code,
    validate_invite_code_format('DEFHJK') as format_valid,
    validate_invite_code('DEFHJK') as exists_in_db;

-- Show all existing families and their invite codes
SELECT 
    name,
    invite_code,
    created_at,
    array_length(parent_ids, 1) as parent_count,
    array_length(child_ids, 1) as child_count
FROM families 
ORDER BY created_at DESC;

-- Test character validation for DEFHJK
SELECT 
    'Character validation for DEFHJK:' as info,
    'DEFHJK' ~ '^[ACDEFHJKMNPRTUVWXY347]+$' as matches_pattern;

-- Show current RLS policies on families table
SELECT 
    pol.policyname,
    pol.permissive,
    pol.roles,
    pol.cmd,
    pol.qual
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'families'; 