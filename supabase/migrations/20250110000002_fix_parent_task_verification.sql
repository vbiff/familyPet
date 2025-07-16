-- Fix parent task verification permissions
-- This migration updates task RLS policies to allow ALL parents in a family to verify tasks
-- Date: 2025-01-10

-- Step 1: Temporarily disable RLS on tasks table to update policies
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing task policies to start fresh
DROP POLICY IF EXISTS "Tasks are viewable by family members" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and assignees can update tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;
DROP POLICY IF EXISTS "Children can update their assigned tasks" ON tasks;
DROP POLICY IF EXISTS "tasks_viewable_by_family_members" ON tasks;
DROP POLICY IF EXISTS "tasks_authenticated_users_can_create" ON tasks;
DROP POLICY IF EXISTS "tasks_creators_and_assignees_can_update" ON tasks;
DROP POLICY IF EXISTS "tasks_creators_can_delete" ON tasks;
DROP POLICY IF EXISTS "Family members can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task assignees can update their tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and parents can delete tasks" ON tasks;

-- Step 3: Create new, simplified task policies that work with our fixed profile policies

-- Allow family members to view tasks
CREATE POLICY "task_family_members_can_view"
    ON tasks FOR SELECT
    TO authenticated
    USING (
        family_id IN (
            SELECT f.id FROM families f 
            WHERE auth.uid() = f.created_by_id 
               OR auth.uid() = ANY(f.parent_ids) 
               OR auth.uid() = ANY(f.child_ids)
        )
    );

-- Allow family members to create tasks
CREATE POLICY "task_family_members_can_create"
    ON tasks FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = created_by_id AND
        family_id IN (
            SELECT f.id FROM families f 
            WHERE auth.uid() = f.created_by_id 
               OR auth.uid() = ANY(f.parent_ids) 
               OR auth.uid() = ANY(f.child_ids)
        )
    );

-- Allow task assignees to update their own tasks (mark as completed)
CREATE POLICY "task_assignees_can_update"
    ON tasks FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = assigned_to_id
        AND status IN ('pending', 'inProgress', 'completed')
    )
    WITH CHECK (
        auth.uid() = assigned_to_id
        AND status IN ('pending', 'inProgress', 'completed')
    );

-- Allow task creators to update their tasks
CREATE POLICY "task_creators_can_update"
    ON tasks FOR UPDATE
    TO authenticated
    USING (auth.uid() = created_by_id)
    WITH CHECK (auth.uid() = created_by_id);

-- CRITICAL: Allow ALL parents in the family to verify tasks (not just creators)
CREATE POLICY "task_parents_can_verify"
    ON tasks FOR UPDATE
    TO authenticated
    USING (
        -- Check if the current user is a parent in the same family as the task
        EXISTS (
            SELECT 1 FROM families f 
            WHERE f.id = tasks.family_id 
            AND (auth.uid() = f.created_by_id OR auth.uid() = ANY(f.parent_ids))
        )
        -- Additional check: ensure the user has parent role in profiles
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() 
            AND p.role = 'parent'
            AND p.family_id = tasks.family_id
        )
    )
    WITH CHECK (
        -- Same check for WITH CHECK
        EXISTS (
            SELECT 1 FROM families f 
            WHERE f.id = tasks.family_id 
            AND (auth.uid() = f.created_by_id OR auth.uid() = ANY(f.parent_ids))
        )
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() 
            AND p.role = 'parent'
            AND p.family_id = tasks.family_id
        )
    );

-- Allow parents to delete tasks they didn't create
CREATE POLICY "task_parents_can_delete"
    ON tasks FOR DELETE
    TO authenticated
    USING (
        auth.uid() = created_by_id OR 
        EXISTS (
            SELECT 1 FROM families f 
            WHERE f.id = tasks.family_id 
            AND (auth.uid() = f.created_by_id OR auth.uid() = ANY(f.parent_ids))
        )
    );

-- Step 4: Re-enable RLS on tasks table
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Step 5: Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON tasks TO authenticated;

-- Step 6: Success message
DO $$
BEGIN
    RAISE NOTICE '✅ PARENT TASK VERIFICATION FIX APPLIED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '👨‍👩‍👧‍👦 ALL parents in a family can now verify tasks';
    RAISE NOTICE '🔒 Updated RLS policies to check both families and profiles tables';
    RAISE NOTICE '✨ Kate should now be able to verify tasks alongside Jonathan';
END $$; 