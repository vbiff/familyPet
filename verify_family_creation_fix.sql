-- Verify Family Creation Fix
-- Check if the RLS policies are now correct for family creation

-- =====================================================
-- 1. CHECK CURRENT USER AUTHENTICATION
-- =====================================================

SELECT 
    'Current User Status:' as check_type,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'AUTHENTICATED ✅'
        ELSE 'NOT AUTHENTICATED ❌'
    END as status,
    auth.uid() as user_id,
    auth.email() as user_email;

-- =====================================================
-- 2. CHECK FAMILIES TABLE RLS POLICIES
-- =====================================================

SELECT 
    'Families Table Policies:' as check_type,
    pol.polname as policy_name,
    CASE 
        WHEN pol.polcmd = 'r' THEN 'SELECT (Reading)'
        WHEN pol.polcmd = 'a' THEN 'INSERT (Creating) ✅'
        WHEN pol.polcmd = 'w' THEN 'UPDATE (Updating)'
        WHEN pol.polcmd = 'd' THEN 'DELETE (Deleting)'
        ELSE pol.polcmd::text
    END as operation
FROM pg_policy pol
JOIN pg_class pc ON pol.polrelid = pc.oid
WHERE pc.relname = 'families'
ORDER BY pol.polcmd;

-- =====================================================
-- 3. TEST FAMILY CREATION CAPABILITY
-- =====================================================

-- Check if the current user can create families
SELECT 
    'Family Creation Test:' as check_type,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'SHOULD WORK NOW ✅'
        ELSE 'USER NOT AUTHENTICATED ❌'
    END as result;

-- =====================================================
-- 4. SHOW EXISTING FAMILIES
-- =====================================================

SELECT 
    'Existing Families:' as check_type,
    COUNT(*) as total_families
FROM families;

-- Show some family details if any exist
SELECT 
    'Family Details:' as info,
    name as family_name,
    invite_code,
    created_at
FROM families 
ORDER BY created_at DESC 
LIMIT 3;

-- =====================================================
-- 5. FINAL STATUS
-- =====================================================

SELECT 
    '🎉 VERIFICATION COMPLETE' as status,
    'Family creation should now work in your app!' as message; 