-- Debug query to check task and family statistics
-- Run this in your Supabase SQL editor

-- 1. Check all tasks and their verification status
SELECT 
    id,
    title,
    status,
    verified_by_id,
    verified_at,
    assigned_to_id,
    created_at
FROM tasks 
WHERE NOT COALESCE(is_archived, false)
ORDER BY created_at DESC;

-- 2. Check what the debug view shows
SELECT * FROM debug_task_completion LIMIT 10;

-- 3. Check family member statistics
SELECT * FROM debug_all_user_task_counts();

-- 4. Test the original get_member_task_stats function
-- (Replace 'your-user-id' with your actual user ID)
SELECT * FROM get_member_task_stats('your-user-id-here'::uuid);

-- 5. Test the debug version 
SELECT * FROM debug_member_task_stats('your-user-id-here'::uuid); 