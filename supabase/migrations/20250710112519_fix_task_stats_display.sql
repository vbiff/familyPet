-- Fix task statistics display in family tab
-- This migration ensures completed tasks are counted correctly for family statistics

-- Update get_member_task_stats to count completed tasks regardless of verification for display purposes
-- Points still require verification for safety, but task completion counts should show immediately
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
        -- Count all completed tasks for display purposes
        COALESCE(COUNT(CASE WHEN t.status = 'completed' THEN 1 END)::INT, 0) as tasks_completed,
        -- Points only count when verified by parent (for safety and gamification)
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        -- Streak calculation based on completed tasks (not just verified)
        COALESCE(calculate_current_streak(member_id), 0) as current_streak,
        -- Last completion time (any completed task, not just verified)
        MAX(CASE WHEN t.status = 'completed' THEN COALESCE(t.verified_at, t.completed_at, t.updated_at) END) as last_task_completed_at
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Update the streak calculation to use completed tasks (not just verified)
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
        -- Check if user completed any task on this date
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

-- Create a function specifically for verified stats (if needed for parent dashboard)
CREATE OR REPLACE FUNCTION get_member_verified_stats(member_id UUID)
RETURNS TABLE (
    verified_tasks INT,
    verified_points INT,
    pending_verification INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END)::INT, 0) as verified_tasks,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as verified_points,
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NULL THEN 1 END)::INT, 0) as pending_verification
    FROM tasks t
    WHERE t.assigned_to_id = member_id 
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Test the updated function with a debug query
-- This will help verify the function is working correctly
DO $$
DECLARE
    test_user_id UUID;
    test_result RECORD;
BEGIN
    -- Get a test user from profiles
    SELECT id INTO test_user_id FROM profiles WHERE family_id IS NOT NULL LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Test the updated function
        SELECT * INTO test_result FROM get_member_task_stats(test_user_id);
        
        RAISE NOTICE 'Test user: %, Tasks completed: %, Total points: %, Streak: %',
            test_user_id, test_result.tasks_completed, test_result.total_points, test_result.current_streak;
    ELSE
        RAISE NOTICE 'No family members found for testing';
    END IF;
END $$; 