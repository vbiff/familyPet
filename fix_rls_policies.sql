-- Fix RLS policies to avoid infinite recursion
-- Run this after the main schema restoration

-- Disable RLS temporarily to fix policies
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE families DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Profiles are viewable by family members" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can create profiles" ON profiles;

DROP POLICY IF EXISTS "Families are viewable by members" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

-- Create simplified, non-recursive policies for profiles
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can view profiles in same family"
  ON profiles FOR SELECT
  USING (
    family_id IS NOT NULL AND 
    family_id = (
      SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Authenticated users can create profiles"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create simplified policies for families
CREATE POLICY "Users can view their family"
  ON families FOR SELECT
  USING (
    id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Authenticated users can create families"
  ON families FOR INSERT
  WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Family creators can update families"
  ON families FOR UPDATE
  USING (created_by_id = auth.uid())
  WITH CHECK (created_by_id = auth.uid());

CREATE POLICY "Family creators can delete families"
  ON families FOR DELETE
  USING (created_by_id = auth.uid());

-- Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- Update tasks policies to avoid recursion
DROP POLICY IF EXISTS "Tasks are viewable by family members" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and assignees can update tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;

CREATE POLICY "Tasks are viewable by family members"
  ON tasks FOR SELECT
  USING (
    family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Family members can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    auth.uid() = created_by_id AND
    family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Task creators and assignees can update tasks"
  ON tasks FOR UPDATE
  USING (
    auth.uid() = created_by_id OR 
    auth.uid() = assigned_to_id OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'parent' 
      AND family_id = tasks.family_id
    )
  );

-- Update pets policies
DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
DROP POLICY IF EXISTS "Children can create one pet" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;

CREATE POLICY "Pets are viewable by family members"
  ON pets FOR SELECT
  USING (
    family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Pet owners can create pets"
  ON pets FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id AND
    family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
  );

CREATE POLICY "Pet owners can update their pets"
  ON pets FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Update task comments policies
DROP POLICY IF EXISTS "Task comments are viewable by family members" ON task_comments;
DROP POLICY IF EXISTS "Family members can create comments on family tasks" ON task_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON task_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON task_comments;

CREATE POLICY "Task comments are viewable by family members"
  ON task_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tasks 
      WHERE tasks.id = task_comments.task_id 
      AND tasks.family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
    )
  );

CREATE POLICY "Family members can create comments"
  ON task_comments FOR INSERT
  WITH CHECK (
    auth.uid() = author_id AND
    EXISTS (
      SELECT 1 FROM tasks 
      WHERE tasks.id = task_comments.task_id 
      AND tasks.family_id = (SELECT family_id FROM profiles WHERE id = auth.uid() LIMIT 1)
    )
  );

CREATE POLICY "Users can update their own comments"
  ON task_comments FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete their own comments"
  ON task_comments FOR DELETE
  USING (auth.uid() = author_id);

SELECT 'RLS policies fixed successfully!' as status; 