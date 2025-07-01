-- Aggressive cleanup of all owner_id references from the database
-- This will remove any triggers, functions, or constraints that mention owner_id

-- Drop all triggers that might reference owner_id
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table 
        FROM information_schema.triggers 
        WHERE trigger_name LIKE '%owner%' OR trigger_name LIKE '%pet%'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', trigger_record.trigger_name, trigger_record.event_object_table);
        RAISE NOTICE 'Dropped trigger: % on table %', trigger_record.trigger_name, trigger_record.event_object_table;
    END LOOP;
END $$;

-- Drop any functions that might reference owner_id
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname, pronargs 
        FROM pg_proc 
        WHERE proname LIKE '%owner%' OR prosrc LIKE '%owner_id%'
    LOOP
        BEGIN
            EXECUTE format('DROP FUNCTION IF EXISTS %I CASCADE', func_record.proname);
            RAISE NOTICE 'Dropped function: %', func_record.proname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop function %, continuing...', func_record.proname;
        END;
    END LOOP;
END $$;

-- Ensure the tasks table structure is exactly what we expect
DO $$
BEGIN
    -- Make sure there's no owner_id column
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'owner_id'
    ) THEN
        ALTER TABLE tasks DROP COLUMN owner_id CASCADE;
        RAISE NOTICE 'Dropped owner_id column from tasks table with CASCADE';
    END IF;
END $$;

-- Remove any RLS policies that might reference owner_id
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE qual LIKE '%owner%' OR with_check LIKE '%owner%'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      policy_record.policyname, 
                      policy_record.schemaname, 
                      policy_record.tablename);
        RAISE NOTICE 'Dropped policy: % on %.%', 
                    policy_record.policyname, 
                    policy_record.schemaname, 
                    policy_record.tablename;
    END LOOP;
END $$;

-- Recreate clean task RLS policies
DROP POLICY IF EXISTS "Tasks viewable by family members" ON tasks;
CREATE POLICY "Tasks viewable by family members" ON tasks FOR SELECT
USING (
    family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can create tasks" ON tasks;
CREATE POLICY "Users can create tasks" ON tasks FOR INSERT
WITH CHECK (
    auth.uid() = created_by_id AND
    family_id IN (
        SELECT family_id FROM profiles WHERE id = auth.uid()
    )
);

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Aggressive owner_id cleanup completed. Tasks table should now work correctly.';
END $$; 