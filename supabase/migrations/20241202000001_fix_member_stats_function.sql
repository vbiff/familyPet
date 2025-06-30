-- Fix get_member_task_stats function to use correct column names
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
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END)::INT, 0) as tasks_completed,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        COALESCE(calculate_current_streak(member_id), 0) as current_streak,
        MAX(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.verified_at END) as last_task_completed_at
    FROM tasks t
    WHERE t.assigned_to_id = member_id;
END;
$$ LANGUAGE plpgsql;

-- Fix calculate_current_streak function to use correct column names  
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
            AND t.verified_by_id IS NOT NULL
            AND DATE(t.verified_at) = check_date
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