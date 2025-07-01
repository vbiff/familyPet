-- Debug migration to troubleshoot get_member_task_stats function

-- First, let's check what data is actually in the tasks table
-- This will help us understand why the stats function returns 0

-- Create a debug view to see task data clearly
CREATE OR REPLACE VIEW debug_task_completion AS
SELECT 
    t.id,
    t.title,
    t.status,
    t.assigned_to_id,
    t.verified_by_id,
    t.verified_at,
    t.completed_at,
    t.is_archived,
    p.display_name as assigned_to_name,
    CASE 
        WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 'SHOULD COUNT'
        WHEN t.status = 'completed' AND t.verified_by_id IS NULL THEN 'NOT VERIFIED'
        ELSE 'NOT COMPLETED'
    END as count_status
FROM tasks t
LEFT JOIN profiles p ON t.assigned_to_id = p.id
WHERE NOT COALESCE(t.is_archived, false)
ORDER BY t.created_at DESC;

-- Create a debug function to test the stats logic directly
CREATE OR REPLACE FUNCTION debug_member_task_stats(member_id UUID)
RETURNS TABLE (
    total_tasks_count BIGINT,
    completed_tasks_count BIGINT,
    verified_tasks_count BIGINT,
    tasks_completed INT,
    total_points INT,
    sample_task_ids TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_tasks_count,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks_count,
        COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END) as verified_tasks_count,
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END)::INT, 0) as tasks_completed,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        ARRAY(SELECT t.id::TEXT FROM tasks t WHERE t.assigned_to_id = member_id AND NOT COALESCE(t.is_archived, false) ORDER BY t.created_at DESC LIMIT 5) as sample_task_ids
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Create a simple function to show all user IDs and their task counts
CREATE OR REPLACE FUNCTION debug_all_user_task_counts()
RETURNS TABLE (
    user_id UUID,
    display_name TEXT,
    total_tasks BIGINT,
    completed_tasks BIGINT,
    verified_tasks BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as user_id,
        p.display_name,
        COALESCE(task_counts.total_tasks, 0) as total_tasks,
        COALESCE(task_counts.completed_tasks, 0) as completed_tasks,
        COALESCE(task_counts.verified_tasks, 0) as verified_tasks
    FROM profiles p
    LEFT JOIN (
        SELECT 
            t.assigned_to_id,
            COUNT(*) as total_tasks,
            COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
            COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END) as verified_tasks
        FROM tasks t
        WHERE NOT COALESCE(t.is_archived, false)
        GROUP BY t.assigned_to_id
    ) task_counts ON p.id = task_counts.assigned_to_id
    WHERE p.family_id IS NOT NULL
    ORDER BY p.display_name;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT ON debug_task_completion TO authenticated;
GRANT EXECUTE ON FUNCTION debug_member_task_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION debug_all_user_task_counts() TO authenticated;

-- Add comments
COMMENT ON VIEW debug_task_completion IS 'Debug view to see task completion status and what should count toward statistics';
COMMENT ON FUNCTION debug_member_task_stats(UUID) IS 'Debug function to test task statistics logic with detailed breakdown';
COMMENT ON FUNCTION debug_all_user_task_counts() IS 'Debug function to show task counts for all family members'; 