-- Add any missing columns to existing tasks table (if they don't exist)
-- This migration safely adds features without breaking existing schema

-- Add missing columns (only if they don't already exist)
DO $$ 
BEGIN
    -- Add is_archived column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'is_archived') THEN
        ALTER TABLE tasks ADD COLUMN is_archived BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
    
    -- Add metadata column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'metadata') THEN
        ALTER TABLE tasks ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
    
    -- Add image_urls column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'image_urls') THEN
        ALTER TABLE tasks ADD COLUMN image_urls TEXT[] DEFAULT '{}';
    END IF;
    
    -- Add verified_by_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'verified_by_id') THEN
        ALTER TABLE tasks ADD COLUMN verified_by_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;
    
    -- Add verified_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'verified_at') THEN
        ALTER TABLE tasks ADD COLUMN verified_at TIMESTAMPTZ;
    END IF;
END $$;

-- Create missing indexes (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_family_status ON tasks(family_id, status) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status ON tasks(assigned_to_id, status) WHERE NOT is_archived;

-- Create partial indexes for performance (using flexible status check)
CREATE INDEX IF NOT EXISTS idx_tasks_active ON tasks(family_id, created_at DESC) WHERE NOT is_archived;

-- Create trigger for updated_at if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tasks_updated_at') THEN
        -- Create trigger function if it doesn't exist
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $trigger$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $trigger$ language 'plpgsql';

        -- Create trigger
        CREATE TRIGGER update_tasks_updated_at 
            BEFORE UPDATE ON tasks 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Enable RLS if not already enabled
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON tasks TO authenticated;

-- Add helpful comments
COMMENT ON TABLE tasks IS 'Family tasks with assignment, due dates, and completion tracking';
COMMENT ON COLUMN tasks.points IS 'Points awarded for completing the task (must be non-negative)';
COMMENT ON COLUMN tasks.frequency IS 'How often the task repeats: once, daily, weekly, or monthly';
COMMENT ON COLUMN tasks.verified_by_id IS 'Parent who verified task completion (for validation)';
COMMENT ON COLUMN tasks.is_archived IS 'Soft delete flag - archived tasks are hidden but preserved';
COMMENT ON COLUMN tasks.metadata IS 'Additional task data stored as JSON (categories, difficulty, etc.)'; 