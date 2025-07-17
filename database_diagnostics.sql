-- Comprehensive Database Diagnostics
-- Run this in Supabase SQL Editor to diagnose family joining issues

-- =====================================================
-- 1. CHECK BASIC DATABASE STATE
-- =====================================================

SELECT '=== BASIC DATABASE CHECKS ===' as section;

-- Count all families
SELECT 
    'Total families in database' as check_name,
    COUNT(*) as result
FROM families;

-- Check the specific family we're trying to join
SELECT 
    'Family with invite code DEFHJK' as check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN 'EXISTS ✅'
        ELSE 'NOT FOUND ❌'
    END as result
FROM families 
WHERE invite_code = 'DEFHJK';

-- Show all families with their details
SELECT 
    '=== ALL FAMILIES IN DATABASE ===' as section,
    name,
    invite_code,
    created_by_id,
    array_length(parent_ids, 1) as parent_count,
    array_length(child_ids, 1) as child_count,
    created_at
FROM families 
ORDER BY created_at DESC;

-- =====================================================
-- 2. CHECK CURRENT USER CONTEXT
-- =====================================================

SELECT '=== USER AUTHENTICATION CHECKS ===' as section;

-- Check auth.uid() - this should return your user ID when authenticated
SELECT 
    'Current authenticated user ID' as check_name,
    COALESCE(auth.uid()::text, 'NULL - NOT AUTHENTICATED ❌') as result;

-- Check auth.role() 
SELECT 
    'Current auth role' as check_name,
    COALESCE(auth.role(), 'NULL') as result;

-- Find all profiles (to see if your user exists)
SELECT 
    '=== ALL USER PROFILES ===' as section,
    id,
    email,
    display_name,
    role,
    family_id,
    created_at
FROM profiles 
ORDER BY created_at DESC;

-- =====================================================
-- 3. CHECK RLS POLICIES
-- =====================================================

SELECT '=== RLS POLICY CHECKS ===' as section;

-- Check if RLS is enabled
SELECT 
    'RLS enabled on families table' as check_name,
    CASE 
        WHEN relrowsecurity THEN 'ENABLED ✅'
        ELSE 'DISABLED ❌'
    END as result
FROM pg_class 
WHERE relname = 'families';

SELECT 
    'RLS enabled on profiles table' as check_name,
    CASE 
        WHEN relrowsecurity THEN 'ENABLED ✅'
        ELSE 'DISABLED ❌'
    END as result
FROM pg_class 
WHERE relname = 'profiles';

-- Show all current RLS policies
SELECT 
    '=== CURRENT RLS POLICIES ===' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('families', 'profiles')
ORDER BY tablename, cmd;

-- =====================================================
-- 4. TEST FAMILY LOOKUP DIRECTLY
-- =====================================================

SELECT '=== DIRECT FAMILY LOOKUP TESTS ===' as section;

-- Test 1: Can we see any families at all?
SELECT 
    'Can query families table (any rows)' as test_name,
    COUNT(*) as families_visible,
    CASE 
        WHEN COUNT(*) > 0 THEN 'SUCCESS ✅'
        ELSE 'BLOCKED BY RLS ❌'
    END as result
FROM families;

-- Test 2: Can we find the specific family?
SELECT 
    'Can find family DEFHJK specifically' as test_name,
    COUNT(*) as families_found,
    CASE 
        WHEN COUNT(*) > 0 THEN 'SUCCESS ✅'
        ELSE 'NOT FOUND/BLOCKED ❌'
    END as result
FROM families 
WHERE invite_code = 'DEFHJK';

-- Test 3: Show what families we CAN see
SELECT 
    '=== FAMILIES VISIBLE TO CURRENT USER ===' as section,
    name,
    invite_code,
    created_by_id,
    CASE 
        WHEN created_by_id = auth.uid() THEN 'You are creator'
        WHEN auth.uid() = ANY(parent_ids) THEN 'You are parent'
        WHEN auth.uid() = ANY(child_ids) THEN 'You are child'
        ELSE 'No direct relationship'
    END as your_relationship
FROM families;

-- =====================================================
-- 5. TEST FAMILY JOINING CONDITIONS
-- =====================================================

SELECT '=== FAMILY JOINING CONDITION CHECKS ===' as section;

-- Check if current user has a profile
SELECT 
    'Current user has profile' as check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN 'YES ✅'
        ELSE 'NO PROFILE FOUND ❌'
    END as result
FROM profiles 
WHERE id = auth.uid();

-- Check if current user already has a family
SELECT 
    'Current user already in a family' as check_name,
    CASE 
        WHEN family_id IS NOT NULL THEN 'YES - Already in family: ' || family_id::text || ' ❌'
        ELSE 'NO - Can join new family ✅'
    END as result
FROM profiles 
WHERE id = auth.uid();

-- Check current user's role
SELECT 
    'Current user role' as check_name,
    COALESCE(role::text, 'NO ROLE SET ❌') as result
FROM profiles 
WHERE id = auth.uid();

-- =====================================================
-- 6. TEST THE JOIN FUNCTION
-- =====================================================

SELECT '=== TESTING FAMILY JOIN FUNCTION ===' as section;

-- Test the join function (this should work regardless of RLS)
SELECT 
    'Testing join_family_by_invite_code function' as test_name,
    success,
    family_id,
    family_name,
    error_message
FROM join_family_by_invite_code('DEFHJK');

-- =====================================================
-- 7. CHECK FOR COMMON ISSUES
-- =====================================================

SELECT '=== COMMON ISSUE CHECKS ===' as section;

-- Check for orphaned users (users without profiles)
SELECT 
    'Users in auth.users but not in profiles' as check_name,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'None found ✅'
        ELSE 'Found orphaned users ❌'
    END as result
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Check for duplicate invite codes
SELECT 
    'Duplicate invite codes' as check_name,
    COUNT(*) as duplicates,
    CASE 
        WHEN COUNT(*) = 0 THEN 'None found ✅'
        ELSE 'Found duplicates ❌'
    END as result
FROM (
    SELECT invite_code 
    FROM families 
    GROUP BY invite_code 
    HAVING COUNT(*) > 1
) dups;

-- Check for families without proper creator relationships
SELECT 
    'Families with invalid creator_id' as check_name,
    COUNT(*) as invalid_families,
    CASE 
        WHEN COUNT(*) = 0 THEN 'All valid ✅'
        ELSE 'Found invalid creators ❌'
    END as result
FROM families f
LEFT JOIN profiles p ON f.created_by_id = p.id
WHERE p.id IS NULL;

-- =====================================================
-- 8. RECOMMEND NEXT STEPS
-- =====================================================

SELECT '=== RECOMMENDED ACTIONS ===' as section;

-- Create a summary and recommendations
DO $$
DECLARE
    auth_user_id UUID;
    user_profile_exists BOOLEAN := FALSE;
    user_has_family BOOLEAN := FALSE;
    can_see_families BOOLEAN := FALSE;
    target_family_exists BOOLEAN := FALSE;
    family_count INTEGER;
    recommendations TEXT := '';
BEGIN
    -- Get current auth user
    auth_user_id := auth.uid();
    
    -- Check various conditions
    SELECT COUNT(*) INTO family_count FROM families;
    can_see_families := family_count > 0;
    
    SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = 'DEFHJK') INTO target_family_exists;
    
    IF auth_user_id IS NOT NULL THEN
        SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth_user_id) INTO user_profile_exists;
        IF user_profile_exists THEN
            SELECT family_id IS NOT NULL INTO user_has_family FROM profiles WHERE id = auth_user_id;
        END IF;
    END IF;
    
    -- Generate recommendations
    IF auth_user_id IS NULL THEN
        recommendations := recommendations || '1. ❌ You are not authenticated. Please log in to your app first.' || chr(10);
    ELSE
        recommendations := recommendations || '1. ✅ You are authenticated (User ID: ' || auth_user_id || ')' || chr(10);
    END IF;
    
    IF NOT user_profile_exists THEN
        recommendations := recommendations || '2. ❌ No profile found. The trigger may not have created your profile.' || chr(10);
    ELSE
        recommendations := recommendations || '2. ✅ User profile exists' || chr(10);
    END IF;
    
    IF user_has_family THEN
        recommendations := recommendations || '3. ❌ You are already in a family. Leave current family first.' || chr(10);
    ELSE
        recommendations := recommendations || '3. ✅ You are not in a family yet' || chr(10);
    END IF;
    
    IF NOT can_see_families THEN
        recommendations := recommendations || '4. ❌ RLS is blocking family queries. Run the RLS fix script again.' || chr(10);
    ELSE
        recommendations := recommendations || '4. ✅ Can query families table' || chr(10);
    END IF;
    
    IF NOT target_family_exists THEN
        recommendations := recommendations || '5. ❌ Family with invite code DEFHJK not found or not visible.' || chr(10);
    ELSE
        recommendations := recommendations || '5. ✅ Target family exists and is visible' || chr(10);
    END IF;
    
    RAISE NOTICE '%', recommendations;
    
    -- Final recommendation
    IF auth_user_id IS NOT NULL AND user_profile_exists AND NOT user_has_family AND can_see_families AND target_family_exists THEN
        RAISE NOTICE '🎉 All conditions met! Try using the join_family_by_invite_code function or the app should work.';
    ELSE
        RAISE NOTICE '🔧 Issues found above need to be resolved first.';
    END IF;
END $$; 