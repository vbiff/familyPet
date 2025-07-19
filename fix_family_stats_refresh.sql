-- Fix Family Statistics Refresh Issue
-- Ensure the correct version of get_member_task_stats is active

-- Step 1: Check current function definition
SELECT 'CURRENT FUNCTION STATUS' as section;
SELECT 
    proname as function_name,
    pg_get_functiondef(oid) as definition
FROM pg_proc 
WHERE proname = 'get_member_task_stats';

-- Step 2: Ensure we have the correct version that counts completed tasks (not just verified)
CREATE OR REPLACE FUNCTION get_member_task_stats(member_id UUID)
RETURNS TABLE (
    tasks_completed INT,
    total_points INT,
    current_streak INT,
    last_task_completed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Count ALL completed tasks (not just verified ones) for display
        COALESCE(COUNT(CASE WHEN t.status = 'completed' THEN 1 END)::INT, 0) as tasks_completed,
        -- Points only count when verified by parent (for safety)
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        -- Streak calculation based on completed tasks
        COALESCE(calculate_current_streak(member_id), 0) as current_streak,
        -- Last completion time (any completed task)
        MAX(CASE WHEN t.status = 'completed' THEN COALESCE(t.verified_at, t.completed_at, t.updated_at) END) as last_task_completed_at
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Step 3: Test the function with a sample user
SELECT 'TESTING FUNCTION' as section;

-- Get a sample user ID from your family
WITH sample_user AS (
    SELECT id, display_name 
    FROM profiles 
    WHERE family_id IS NOT NULL 
    LIMIT 1
)
SELECT 
    su.display_name,
    su.id as user_id,
    stats.*
FROM sample_user su,
LATERAL (
    SELECT * FROM get_member_task_stats(su.id)
) stats;

-- Step 4: Check task data for the sample user
WITH sample_user AS (
    SELECT id 
    FROM profiles 
    WHERE family_id IS NOT NULL 
    LIMIT 1
)
SELECT 
    'SAMPLE USER TASKS' as section,
    t.id,
    t.title,
    t.status,
    t.assigned_to_id,
    t.verified_by_id,
    t.completed_at,
    t.verified_at,
    t.points,
    CASE 
        WHEN t.status = 'completed' THEN 'SHOULD COUNT'
        ELSE 'NOT COMPLETED'
    END as count_status
FROM tasks t, sample_user su
WHERE t.assigned_to_id = su.id
AND NOT COALESCE(t.is_archived, false)
ORDER BY t.created_at DESC
LIMIT 5;

-- Step 5: Check if there are any completed tasks in the system
SELECT 'SYSTEM WIDE COMPLETED TASKS' as section;
SELECT 
    COUNT(*) as total_completed_tasks,
    COUNT(CASE WHEN verified_by_id IS NOT NULL THEN 1 END) as verified_tasks,
    COUNT(CASE WHEN verified_by_id IS NULL THEN 1 END) as unverified_tasks
FROM tasks 
WHERE status = 'completed' 
AND NOT COALESCE(is_archived, false);

-- Step 6: Grant permissions to ensure function is accessible
GRANT EXECUTE ON FUNCTION get_member_task_stats(UUID) TO authenticated;

SELECT '✅ FAMILY STATS FUNCTION FIXED - CHECK RESULTS ABOVE' as status; 