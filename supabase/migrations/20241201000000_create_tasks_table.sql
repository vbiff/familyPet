-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL CHECK (length(trim(title)) > 0),
    description TEXT NOT NULL CHECK (length(trim(description)) > 0),
    points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'inProgress', 'completed', 'expired')),
    assigned_to_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    due_date TIMESTAMPTZ NOT NULL,
    frequency TEXT NOT NULL DEFAULT 'once' CHECK (frequency IN ('once', 'daily', 'weekly', 'monthly')),
    verified_by_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    family_id UUID NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    is_archived BOOLEAN NOT NULL DEFAULT FALSE
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_family_status ON tasks(family_id, status) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status ON tasks(assigned_to_id, status) WHERE NOT is_archived;

-- Create partial indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_active ON tasks(family_id, created_at DESC) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_overdue ON tasks(family_id, due_date) WHERE status IN ('pending', 'inProgress') AND due_date < NOW() AND NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_pending_verification ON tasks(family_id, completed_at) WHERE status = 'completed' AND verified_by_id IS NULL AND NOT is_archived;

-- Create trigger to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to automatically expire overdue tasks
CREATE OR REPLACE FUNCTION expire_overdue_tasks()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE tasks 
    SET status = 'expired', updated_at = NOW()
    WHERE status IN ('pending', 'inProgress') 
        AND due_date < NOW() 
        AND NOT is_archived;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Create RLS (Row Level Security) policies
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see tasks within their family
CREATE POLICY "Users can view tasks in their family" ON tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
        )
    );

-- Policy: Users can create tasks in their family
CREATE POLICY "Users can create tasks in their family" ON tasks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
        )
        AND created_by_id = auth.uid()
    );

-- Policy: Users can update tasks they created or are assigned to
CREATE POLICY "Users can update their tasks" ON tasks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
        )
        AND (created_by_id = auth.uid() OR assigned_to_id = auth.uid())
    );

-- Policy: Parents can update any task in their family
CREATE POLICY "Parents can update any family task" ON tasks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
            AND profiles.role = 'parent'
        )
    );

-- Policy: Users can delete tasks they created
CREATE POLICY "Users can delete tasks they created" ON tasks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
        )
        AND created_by_id = auth.uid()
    );

-- Policy: Parents can delete any task in their family
CREATE POLICY "Parents can delete any family task" ON tasks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.family_id = tasks.family_id
            AND profiles.role = 'parent'
        )
    );

-- Create function to validate task completion
CREATE OR REPLACE FUNCTION validate_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Ensure completed_at is set when status is completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = COALESCE(NEW.completed_at, NOW());
    END IF;
    
    -- Ensure verified_at is set when verified_by_id is set
    IF NEW.verified_by_id IS NOT NULL AND OLD.verified_by_id IS NULL THEN
        NEW.verified_at = COALESCE(NEW.verified_at, NOW());
    END IF;
    
    -- Clear completed_at if status is changed from completed
    IF NEW.status != 'completed' AND OLD.status = 'completed' THEN
        NEW.completed_at = NULL;
        NEW.verified_by_id = NULL;
        NEW.verified_at = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_task_completion_trigger
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION validate_task_completion();

-- Create view for task statistics
CREATE OR REPLACE VIEW task_stats AS
SELECT 
    family_id,
    COUNT(*) as total_tasks,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_tasks,
    COUNT(*) FILTER (WHERE status = 'inProgress') as in_progress_tasks,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_tasks,
    COUNT(*) FILTER (WHERE status = 'expired') as expired_tasks,
    COUNT(*) FILTER (WHERE due_date < NOW() AND status IN ('pending', 'inProgress')) as overdue_tasks,
    COUNT(*) FILTER (WHERE status = 'completed' AND verified_by_id IS NULL) as unverified_tasks,
    COALESCE(SUM(points) FILTER (WHERE status = 'completed'), 0) as total_points_earned,
    COALESCE(AVG(points) FILTER (WHERE status = 'completed'), 0) as avg_points_per_task
FROM tasks 
WHERE NOT is_archived
GROUP BY family_id;

-- Grant permissions
GRANT SELECT ON task_stats TO authenticated;

-- Create function to get user task statistics
CREATE OR REPLACE FUNCTION get_user_task_stats(user_id UUID)
RETURNS TABLE (
    total_assigned INTEGER,
    pending INTEGER,
    in_progress INTEGER,
    completed INTEGER,
    expired INTEGER,
    overdue INTEGER,
    total_points INTEGER,
    completion_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_assigned,
        COUNT(*) FILTER (WHERE status = 'pending')::INTEGER as pending,
        COUNT(*) FILTER (WHERE status = 'inProgress')::INTEGER as in_progress,
        COUNT(*) FILTER (WHERE status = 'completed')::INTEGER as completed,
        COUNT(*) FILTER (WHERE status = 'expired')::INTEGER as expired,
        COUNT(*) FILTER (WHERE due_date < NOW() AND status IN ('pending', 'inProgress'))::INTEGER as overdue,
        COALESCE(SUM(points) FILTER (WHERE status = 'completed'), 0)::INTEGER as total_points,
        CASE 
            WHEN COUNT(*) > 0 THEN ROUND((COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
            ELSE 0
        END as completion_rate
    FROM tasks 
    WHERE assigned_to_id = user_id AND NOT is_archived;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_user_task_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION expire_overdue_tasks() TO authenticated;

-- Insert sample data for testing (optional - remove in production)
-- INSERT INTO tasks (
--     title, 
--     description, 
--     points, 
--     assigned_to_id, 
--     created_by_id, 
--     due_date, 
--     frequency, 
--     family_id
-- ) VALUES (
--     'Clean your room',
--     'Make your bed, organize your toys, and vacuum the floor',
--     10,
--     '00000000-0000-0000-0000-000000000001', -- Replace with actual user ID
--     '00000000-0000-0000-0000-000000000002', -- Replace with actual parent ID
--     NOW() + INTERVAL '1 day',
--     'weekly',
--     '00000000-0000-0000-0000-000000000003'  -- Replace with actual family ID
-- );

-- Comments for documentation
COMMENT ON TABLE tasks IS 'Stores family tasks with assignment, due dates, and completion tracking';
COMMENT ON COLUMN tasks.points IS 'Points awarded for completing the task (must be non-negative)';
COMMENT ON COLUMN tasks.status IS 'Current status: pending, inProgress, completed, or expired';
COMMENT ON COLUMN tasks.frequency IS 'How often the task repeats: once, daily, weekly, or monthly';
COMMENT ON COLUMN tasks.verified_by_id IS 'Parent who verified task completion (for validation)';
COMMENT ON COLUMN tasks.is_archived IS 'Soft delete flag - archived tasks are hidden but preserved';
COMMENT ON COLUMN tasks.metadata IS 'Additional task data stored as JSON (categories, difficulty, etc.)';
COMMENT ON FUNCTION expire_overdue_tasks() IS 'Batch function to mark overdue tasks as expired';
COMMENT ON FUNCTION get_user_task_stats(UUID) IS 'Returns comprehensive task statistics for a specific user'; 