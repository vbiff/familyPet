-- Emergency RLS disable to fix infinite recursion
-- This will temporarily disable all RLS to allow login

-- Disable RLS on all tables
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE families DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE pets DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments DISABLE ROW LEVEL SECURITY;

-- Drop ALL policies to clean slate
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view profiles in same family" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can create profiles" ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by family members" ON profiles;

DROP POLICY IF EXISTS "Users can view their family" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "Family creators can update families" ON families;
DROP POLICY IF EXISTS "Family creators can delete families" ON families;
DROP POLICY IF EXISTS "Families are viewable by members" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

DROP POLICY IF EXISTS "Tasks are viewable by family members" ON tasks;
DROP POLICY IF EXISTS "Family members can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and assignees can update tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;

DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
DROP POLICY IF EXISTS "Pet owners can create pets" ON pets;
DROP POLICY IF EXISTS "Pet owners can update their pets" ON pets;
DROP POLICY IF EXISTS "Children can create one pet" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;

DROP POLICY IF EXISTS "Task comments are viewable by family members" ON task_comments;
DROP POLICY IF EXISTS "Family members can create comments" ON task_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON task_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON task_comments;
DROP POLICY IF EXISTS "Family members can create comments on family tasks" ON task_comments;

SELECT 'All RLS policies disabled - you should now be able to login' as status; 