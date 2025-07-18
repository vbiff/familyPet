-- Quick Check: Profiles Table RLS Status
-- Run this first to see the current security status

-- 1. Check if RLS is enabled
SELECT 
    '🔍 RLS STATUS CHECK' as section,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ENABLED'
        ELSE '❌ RLS DISABLED - MAJOR SECURITY RISK!'
    END as rls_status,
    CASE 
        WHEN rowsecurity THEN 'Table is protected by Row Level Security'
        ELSE 'ALL USERS CAN ACCESS ALL PROFILES!'
    END as security_level
FROM pg_tables 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- 2. Count existing policies
SELECT 
    '📋 POLICY COUNT' as section,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ NO POLICIES - Anyone can access any data!'
        WHEN COUNT(*) < 3 THEN '⚠️ INCOMPLETE POLICIES - Security gaps exist'
        ELSE '✅ POLICIES EXIST - Check if they are correct'
    END as policy_status
FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- 3. List current policies
SELECT 
    '📜 CURRENT POLICIES' as section,
    policyname,
    cmd as operation,
    CASE cmd
        WHEN 'SELECT' THEN 'Controls who can READ profile data'
        WHEN 'INSERT' THEN 'Controls who can create profiles'  
        WHEN 'UPDATE' THEN 'Controls who can modify profiles'
        WHEN 'DELETE' THEN 'Controls who can delete profiles'
    END as purpose
FROM pg_policies 
WHERE tablename = 'profiles' AND schemaname = 'public'
ORDER BY cmd, policyname;

-- 4. Check current permissions
SELECT 
    '🔑 TABLE PERMISSIONS' as section,
    grantee as role,
    privilege_type as permission,
    CASE 
        WHEN grantee = 'public' AND privilege_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE') 
        THEN '❌ DANGEROUS - Public has access!'
        WHEN grantee = 'authenticated' 
        THEN '✅ NORMAL - Authenticated users need this'
        ELSE '✅ OK'
    END as security_assessment
FROM information_schema.table_privileges
WHERE table_name = 'profiles' 
  AND table_schema = 'public'
  AND grantee IN ('public', 'authenticated', 'anon')
ORDER BY 
    CASE grantee 
        WHEN 'public' THEN 1 
        WHEN 'anon' THEN 2 
        WHEN 'authenticated' THEN 3 
    END,
    privilege_type;

-- 5. Security recommendations
SELECT 
    '💡 RECOMMENDATIONS' as section,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'profiles' AND rowsecurity = true)
        THEN '1. ENABLE RLS IMMEDIATELY - Run the fix script'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'profiles') = 0
        THEN '2. CREATE RLS POLICIES - No policies exist'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'profiles') < 3
        THEN '3. ADD MISSING POLICIES - Incomplete security'
        ELSE '4. VERIFY POLICIES - Check if they are working correctly'
    END as priority_action,
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'profiles' AND rowsecurity = true)
        THEN 'CRITICAL - All user data is exposed to everyone!'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'profiles') = 0
        THEN 'HIGH - Users can access any profile data'
        ELSE 'MEDIUM - Review existing policies'
    END as risk_level; 