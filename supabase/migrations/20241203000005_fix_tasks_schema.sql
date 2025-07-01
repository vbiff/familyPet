-- Fix tasks table schema - remove any erroneous owner_id references
-- The error suggests there's an owner_id field constraint that shouldn't exist

-- Check if there's an owner_id column and remove it if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE tasks DROP COLUMN owner_id;
        RAISE NOTICE 'Dropped owner_id column from tasks table';
    END IF;
END $$;

-- Check for any constraints that might reference owner_id
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find constraints that might reference owner_id
    FOR constraint_name IN 
        SELECT conname FROM pg_constraint 
        WHERE conrelid = 'tasks'::regclass 
        AND conname LIKE '%owner%'
    LOOP
        EXECUTE 'ALTER TABLE tasks DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Ensure the tasks table has the correct structure
-- Add any missing columns that should be there
DO $$
BEGIN
    -- Ensure updated_at exists and has a default
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE tasks ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Ensure is_archived exists with default
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'is_archived'
    ) THEN
        ALTER TABLE tasks ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Add trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Tasks table schema cleaned up. owner_id references removed.';
END $$; 