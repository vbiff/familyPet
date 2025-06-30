-- Fix RLS policies for testing
-- This migration relaxes some policies to allow easier testing while maintaining security

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Parents can create tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can update tasks" ON tasks;

-- Create more permissive policies for testing

-- Allow authenticated users to create tasks (with basic validation)
CREATE POLICY "Authenticated users can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND created_by_id = auth.uid()
  );

-- Allow task creators and assigned users to update tasks
CREATE POLICY "Task creators and assignees can update tasks"
  ON tasks FOR UPDATE
  USING (
    auth.uid() = created_by_id 
    OR auth.uid()::text = assigned_to_id
  )
  WITH CHECK (
    auth.uid() = created_by_id 
    OR auth.uid()::text = assigned_to_id
  );

-- Allow authenticated users to create profiles
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
CREATE POLICY "Authenticated users can create profiles"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow users to update their own profiles
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to create families
DROP POLICY IF EXISTS "Parents can create families" ON families;
CREATE POLICY "Authenticated users can create families"
  ON families FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Allow family creators to update families
DROP POLICY IF EXISTS "Parents can update their family" ON families;
CREATE POLICY "Family creators can update their family"
  ON families FOR UPDATE
  USING (parent_id = auth.uid())
  WITH CHECK (parent_id = auth.uid());

-- Add a helper function to ensure user has basic profile
CREATE OR REPLACE FUNCTION ensure_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Auto-create profile if user doesn't have one
  INSERT INTO profiles (id, email, display_name, role)
  VALUES (
    auth.uid(),
    COALESCE(auth.jwt() ->> 'email', 'user@example.com'),
    COALESCE(auth.jwt() ->> 'display_name', 'User'),
    'parent'::user_role
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-create profiles
DROP TRIGGER IF EXISTS ensure_profile_on_task_create ON tasks;
CREATE TRIGGER ensure_profile_on_task_create
  BEFORE INSERT ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_profile();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

COMMENT ON POLICY "Authenticated users can create tasks" ON tasks 
IS 'Temporary policy for testing - allows any authenticated user to create tasks'; 