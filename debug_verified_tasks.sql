-- Debug Verified Tasks Not Being Counted
-- This will help us see exactly what's happening with your tasks

-- Step 1: Find your user and family info
SELECT 'YOUR USER INFO' as section;
SELECT 
    id as user_id,
    display_name,
    email,
    family_id,
    role
FROM profiles 
WHERE email LIKE '%@%'  -- Get all users
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Check your family's tasks
SELECT 'FAMILY TASKS' as section;
WITH user_family AS (
    SELECT family_id 
    FROM profiles 
    WHERE email LIKE '%@%'  -- Replace with your actual email if you know it
    AND family_id IS NOT NULL 
    LIMIT 1
)
SELECT 
    t.id,
    t.title,
    t.status,
    p.display_name as assigned_to,
    t.verified_by_id,
    t.verified_at,
    t.completed_at,
    t.points,
    t.is_archived,
    CASE 
        WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN '✅ SHOULD COUNT'
        WHEN t.status = 'completed' AND t.verified_by_id IS NULL THEN '❌ NOT VERIFIED'
        WHEN t.status != 'completed' THEN '❌ NOT COMPLETED'
        WHEN t.is_archived THEN '❌ ARCHIVED'
        ELSE '❓ OTHER'
    END as count_status
FROM tasks t
JOIN profiles p ON t.assigned_to_id = p.id
CROSS JOIN user_family uf
WHERE t.family_id = uf.family_id
ORDER BY t.created_at DESC
LIMIT 10;

-- Step 3: Test the function directly with your user ID
SELECT 'FUNCTION TEST' as section;
WITH sample_user AS (
    SELECT id 
    FROM profiles 
    WHERE family_id IS NOT NULL 
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    'User ID: ' || su.id as info,
    stats.*
FROM sample_user su,
LATERAL (
    SELECT * FROM get_member_task_stats(su.id)
) stats;

-- Step 4: Check what the function query actually returns for each step
SELECT 'FUNCTION BREAKDOWN' as section;
WITH sample_user AS (
    SELECT id 
    FROM profiles 
    WHERE family_id IS NOT NULL 
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    su.id as user_id,
    COUNT(*) as total_tasks_found,
    COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END) as verified_tasks,
    COUNT(CASE WHEN t.is_archived THEN 1 END) as archived_tasks
FROM sample_user su
LEFT JOIN tasks t ON t.assigned_to_id = su.id
GROUP BY su.id;

-- Step 5: Check if there are any RLS issues
SELECT 'RLS CHECK' as section;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('tasks', 'profiles')
ORDER BY tablename, policyname;

-- Step 6: Manual count check (this bypasses the function)
SELECT 'MANUAL COUNT CHECK' as section;
WITH sample_user AS (
    SELECT id, display_name
    FROM profiles 
    WHERE family_id IS NOT NULL 
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    su.display_name,
    su.id as user_id,
    COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END), 0) as manual_verified_count,
    COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END), 0) as manual_points_count
FROM sample_user su
LEFT JOIN tasks t ON t.assigned_to_id = su.id AND NOT COALESCE(t.is_archived, false)
GROUP BY su.id, su.display_name;

SELECT '🔍 DIAGNOSTIC COMPLETE - Check results above' as status; 