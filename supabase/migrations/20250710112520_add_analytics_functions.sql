-- Add analytics functions for family dashboard
-- This migration creates database functions to support real analytics data

-- Function to get family analytics for a specific period
CREATE OR REPLACE FUNCTION get_family_analytics(
    family_id_param UUID,
    start_date_param TIMESTAMP WITH TIME ZONE,
    end_date_param TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    total_tasks BIGINT,
    completed_tasks BIGINT,
    total_points BIGINT,
    completion_rate NUMERIC,
    active_members BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_tasks,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END), 0) as total_points,
        CASE 
            WHEN COUNT(*) > 0 THEN ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC * 100, 2)
            ELSE 0
        END as completion_rate,
        COUNT(DISTINCT t.assigned_to_id) as active_members
    FROM tasks t
    WHERE t.family_id = family_id_param
    AND t.created_at >= start_date_param
    AND t.created_at <= end_date_param
    AND NOT COALESCE(t.is_archived, false);
END;
$$ LANGUAGE plpgsql;

-- Function to get daily task statistics for charts
CREATE OR REPLACE FUNCTION get_daily_task_stats(
    family_id_param UUID,
    start_date_param TIMESTAMP WITH TIME ZONE,
    end_date_param TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    stat_date DATE,
    total_tasks BIGINT,
    completed_tasks BIGINT,
    points_earned BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH date_series AS (
        SELECT generate_series(
            start_date_param::DATE,
            end_date_param::DATE,
            '1 day'::INTERVAL
        )::DATE as stat_date
    ),
    daily_stats AS (
        SELECT 
            t.created_at::DATE as task_date,
            COUNT(*) as total_tasks,
            COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
            COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END), 0) as points_earned
        FROM tasks t
        WHERE t.family_id = family_id_param
        AND t.created_at >= start_date_param
        AND t.created_at <= end_date_param
        AND NOT COALESCE(t.is_archived, false)
        GROUP BY t.created_at::DATE
    )
    SELECT 
        ds.stat_date,
        COALESCE(daily_stats.total_tasks, 0) as total_tasks,
        COALESCE(daily_stats.completed_tasks, 0) as completed_tasks,
        COALESCE(daily_stats.points_earned, 0) as points_earned
    FROM date_series ds
    LEFT JOIN daily_stats ON ds.stat_date = daily_stats.task_date
    ORDER BY ds.stat_date;
END;
$$ LANGUAGE plpgsql;

-- Function to get task category distribution
CREATE OR REPLACE FUNCTION get_task_category_distribution(
    family_id_param UUID,
    start_date_param TIMESTAMP WITH TIME ZONE,
    end_date_param TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    category TEXT,
    task_count BIGINT,
    completed_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(t.category::TEXT, 'other') as category,
        COUNT(*) as task_count,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_count
    FROM tasks t
    WHERE t.family_id = family_id_param
    AND t.created_at >= start_date_param
    AND t.created_at <= end_date_param
    AND NOT COALESCE(t.is_archived, false)
    GROUP BY t.category
    ORDER BY task_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get member leaderboard with detailed statistics
CREATE OR REPLACE FUNCTION get_member_leaderboard(
    family_id_param UUID,
    start_date_param TIMESTAMP WITH TIME ZONE,
    end_date_param TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
    member_id UUID,
    member_name TEXT,
    member_role TEXT,
    avatar_url TEXT,
    total_tasks BIGINT,
    completed_tasks BIGINT,
    points_earned BIGINT,
    completion_rate NUMERIC,
    current_streak INT,
    last_completed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as member_id,
        p.display_name as member_name,
        p.role::TEXT as member_role,
        p.avatar_url,
        COUNT(t.id) as total_tasks,
        COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed_tasks,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END), 0) as points_earned,
        CASE 
            WHEN COUNT(t.id) > 0 THEN ROUND(COUNT(CASE WHEN t.status = 'completed' THEN 1 END)::NUMERIC / COUNT(t.id)::NUMERIC * 100, 2)
            ELSE 0
        END as completion_rate,
        COALESCE((SELECT current_streak FROM get_member_task_stats(p.id)), 0) as current_streak,
        MAX(CASE WHEN t.status = 'completed' THEN COALESCE(t.verified_at, t.completed_at, t.updated_at) END) as last_completed_at
    FROM profiles p
    LEFT JOIN tasks t ON t.assigned_to_id = p.id 
        AND t.family_id = family_id_param
        AND t.created_at >= start_date_param
        AND t.created_at <= end_date_param
        AND NOT COALESCE(t.is_archived, false)
    WHERE p.family_id = family_id_param
    GROUP BY p.id, p.display_name, p.role, p.avatar_url
    ORDER BY points_earned DESC, completed_tasks DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get recent task completions for insights
CREATE OR REPLACE FUNCTION get_recent_task_completions(
    family_id_param UUID,
    limit_param INT DEFAULT 10
)
RETURNS TABLE (
    task_id UUID,
    task_title TEXT,
    assigned_to_name TEXT,
    points_earned INT,
    completed_at TIMESTAMP WITH TIME ZONE,
    category TEXT,
    difficulty TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as task_id,
        t.title as task_title,
        p.display_name as assigned_to_name,
        t.points as points_earned,
        COALESCE(t.verified_at, t.completed_at, t.updated_at) as completed_at,
        COALESCE(t.category::TEXT, 'other') as category,
        COALESCE(t.difficulty::TEXT, 'medium') as difficulty
    FROM tasks t
    JOIN profiles p ON t.assigned_to_id = p.id
    WHERE t.family_id = family_id_param
    AND t.status = 'completed'
    AND NOT COALESCE(t.is_archived, false)
    ORDER BY COALESCE(t.verified_at, t.completed_at, t.updated_at) DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_family_analytics(UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_task_stats(UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_task_category_distribution(UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_member_leaderboard(UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_task_completions(UUID, INT) TO authenticated; 