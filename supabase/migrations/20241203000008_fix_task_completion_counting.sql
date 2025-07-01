-- Fix task completion counting to show completed tasks immediately
-- without requiring parent verification

-- Update the get_member_task_stats function to count completed tasks regardless of verification
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
        -- Count all completed tasks, not just verified ones
        COALESCE(COUNT(CASE WHEN t.status = 'completed' THEN 1 END)::INT, 0) as tasks_completed,
        -- Points only count when verified by parent (for safety)
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        -- Streak calculation (keep existing logic)
        COALESCE(calculate_current_streak(member_id), 0) as current_streak,
        -- Last completion time (any completed task, not just verified)
        MAX(CASE WHEN t.status = 'completed' THEN COALESCE(t.verified_at, t.completed_at, t.updated_at) END) as last_task_completed_at
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Also update the calculate_current_streak function to count completed tasks (not just verified)
CREATE OR REPLACE FUNCTION calculate_current_streak(user_id UUID)
RETURNS INT AS $$
DECLARE
    streak_count INT := 0;
    current_date DATE := CURRENT_DATE;
    check_date DATE;
BEGIN
    -- Start from today and go backwards
    check_date := current_date;
    
    -- Loop through days and check for completed tasks
    LOOP
        -- Check if user completed any task on this date (don't require verification for streak)
        IF EXISTS (
            SELECT 1 FROM tasks t
            WHERE t.assigned_to_id = user_id
            AND t.status = 'completed'
            AND NOT COALESCE(t.is_archived, false)
            AND DATE(COALESCE(t.verified_at, t.completed_at, t.updated_at)) = check_date
        ) THEN
            streak_count := streak_count + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSE
            -- If it's today and no tasks completed, streak is 0
            -- If it's any other day, break the loop
            IF check_date = current_date THEN
                streak_count := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Safety break to avoid infinite loop (max 365 days)
        IF streak_count >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN streak_count;
END;
$$ LANGUAGE plpgsql;

-- Create a separate function for verified task stats (if needed for parent dashboard)
CREATE OR REPLACE FUNCTION get_member_verified_task_stats(member_id UUID)
RETURNS TABLE (
    verified_tasks_completed INT,
    verified_total_points INT,
    pending_verification_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END)::INT, 0) as verified_tasks_completed,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as verified_total_points,
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NULL THEN 1 END)::INT, 0) as pending_verification_count
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_member_task_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_verified_task_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_current_streak(UUID) TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION get_member_task_stats(UUID) IS 'Returns task completion statistics counting all completed tasks (not just verified ones)';
COMMENT ON FUNCTION get_member_verified_task_stats(UUID) IS 'Returns verified task statistics for parent oversight';
COMMENT ON FUNCTION calculate_current_streak(UUID) IS 'Calculates current daily task completion streak based on completed tasks'; 