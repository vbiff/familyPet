-- Fix ambiguous column reference in analytics functions
-- This migration fixes the "current_streak" column reference issue

-- Fix the get_member_leaderboard function to avoid ambiguous column references
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
        COALESCE(
            (SELECT stats.current_streak FROM get_member_task_stats(p.id) stats), 
            0
        ) as current_streak,
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_member_leaderboard(UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated; 