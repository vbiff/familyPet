-- Drastically simplified RLS policies to isolate the issue

-- Disable RLS temporarily
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE families DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE pets DISABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies to ensure a clean slate
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

-- Create ultra-simple policies
CREATE POLICY "Users can see their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
  
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- For now, let's keep RLS disabled on other tables until login is fixed
-- ALTER TABLE families ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

SELECT 'Simplified RLS policies applied. Please test login.' as status; 