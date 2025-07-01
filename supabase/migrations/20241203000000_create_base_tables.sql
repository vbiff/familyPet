-- Create base table structure for tasks and pets
-- This migration creates the essential tables that may be missing

-- Create tasks table if it doesn't exist
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
  family_id UUID REFERENCES families(id) NOT NULL,
  assigned_to_id UUID REFERENCES profiles(id) NOT NULL,
  created_by_id UUID REFERENCES profiles(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  frequency TEXT NOT NULL DEFAULT 'once',
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create pets table if it doesn't exist
CREATE TABLE IF NOT EXISTS pets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  family_id UUID REFERENCES families(id) NOT NULL,
  mood TEXT NOT NULL DEFAULT 'neutral',
  stage TEXT NOT NULL DEFAULT 'egg',
  experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  happiness INTEGER NOT NULL DEFAULT 50 CHECK (happiness >= 0 AND happiness <= 100),
  energy INTEGER NOT NULL DEFAULT 100 CHECK (energy >= 0 AND energy <= 100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;

-- Create basic indexes
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_family_id ON pets(family_id);

-- Create basic RLS policies
DO $$
BEGIN
    -- Tasks policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tasks' AND policyname = 'Tasks are viewable by family members') THEN
        EXECUTE 'CREATE POLICY "Tasks are viewable by family members" ON tasks FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE id = auth.uid()))';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tasks' AND policyname = 'Authenticated users can create tasks') THEN
        EXECUTE 'CREATE POLICY "Authenticated users can create tasks" ON tasks FOR INSERT WITH CHECK (auth.uid() = created_by_id)';
    END IF;

    -- Pets policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'pets' AND policyname = 'Pets are viewable by family members') THEN
        EXECUTE 'CREATE POLICY "Pets are viewable by family members" ON pets FOR SELECT USING (family_id IN (SELECT family_id FROM profiles WHERE id = auth.uid()))';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'pets' AND policyname = 'Children can create pets') THEN
        EXECUTE 'CREATE POLICY "Children can create pets" ON pets FOR INSERT WITH CHECK (auth.uid() = owner_id)';
    END IF;
END $$;

-- Add tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE pets; 