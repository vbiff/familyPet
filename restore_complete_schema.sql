-- Complete Database Schema Restoration for Jhonny App
-- Run this in Supabase SQL Editor to restore all tables and functionality

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== ENUM TYPES =====
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('parent', 'child');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('pending', 'inProgress', 'completed', 'expired');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_frequency') THEN
        CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pet_mood') THEN
        CREATE TYPE pet_mood AS ENUM ('happy', 'content', 'neutral', 'sad', 'upset');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pet_stage') THEN
        CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');
    END IF;
END $$;

-- ===== MAIN TABLES =====

-- Families table (should already exist but ensure it has all columns)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'parent_ids') THEN
        ALTER TABLE families ADD COLUMN parent_ids UUID[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'child_ids') THEN
        ALTER TABLE families ADD COLUMN child_ids UUID[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'created_by_id') THEN
        ALTER TABLE families ADD COLUMN created_by_id UUID REFERENCES profiles(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'last_activity_at') THEN
        ALTER TABLE families ADD COLUMN last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'settings') THEN
        ALTER TABLE families ADD COLUMN settings JSONB DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'metadata') THEN
        ALTER TABLE families ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'pet_image_url') THEN
        ALTER TABLE families ADD COLUMN pet_image_url TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'pet_stage_images') THEN
        ALTER TABLE families ADD COLUMN pet_stage_images JSONB DEFAULT '{}';
    END IF;
END $$;

-- Profiles table (should already exist but ensure it has all columns)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'family_id') THEN
        ALTER TABLE profiles ADD COLUMN family_id UUID REFERENCES families(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role') THEN
        ALTER TABLE profiles ADD COLUMN role user_role NOT NULL DEFAULT 'parent';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_login_at') THEN
        ALTER TABLE profiles ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'metadata') THEN
        ALTER TABLE profiles ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
END $$;

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  points INTEGER NOT NULL CHECK (points >= 0),
  family_id UUID REFERENCES families(id) NOT NULL,
  assigned_to_id UUID REFERENCES profiles(id) NOT NULL,
  created_by_id UUID REFERENCES profiles(id) NOT NULL,
  status task_status NOT NULL DEFAULT 'pending',
  frequency task_frequency NOT NULL,
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  verified_by_id UUID REFERENCES profiles(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  image_urls TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Pets table
CREATE TABLE IF NOT EXISTS pets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  family_id UUID REFERENCES families(id) NOT NULL,
  mood pet_mood NOT NULL DEFAULT 'neutral',
  stage pet_stage NOT NULL DEFAULT 'egg',
  experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  happiness INTEGER NOT NULL DEFAULT 50 CHECK (happiness >= 0 AND happiness <= 100),
  energy INTEGER NOT NULL DEFAULT 100 CHECK (energy >= 0 AND energy <= 100),
  health INTEGER NOT NULL DEFAULT 100 CHECK (health >= 0 AND health <= 100),
  last_fed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_played_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Task Comments table
CREATE TABLE IF NOT EXISTS task_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  author_id UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT task_comments_content_length_check CHECK (LENGTH(TRIM(content)) >= 1 AND LENGTH(TRIM(content)) <= 1000)
);

-- ===== INDEXES FOR PERFORMANCE =====

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_family_id ON profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);

-- Families indexes
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);
CREATE INDEX IF NOT EXISTS idx_families_created_by_id ON families(created_by_id);
CREATE INDEX IF NOT EXISTS idx_families_created_at ON families(created_at);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_frequency ON tasks(frequency);
CREATE INDEX IF NOT EXISTS idx_tasks_verified_by_id ON tasks(verified_by_id);

-- Pets indexes
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_family_id ON pets(family_id);
CREATE INDEX IF NOT EXISTS idx_pets_stage ON pets(stage);
CREATE INDEX IF NOT EXISTS idx_pets_mood ON pets(mood);
CREATE INDEX IF NOT EXISTS idx_pets_level ON pets(level);

-- Task Comments indexes
CREATE INDEX IF NOT EXISTS idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_author_id ON task_comments(author_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_created_at ON task_comments(created_at);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_family_status_due ON tasks(family_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status_due ON tasks(assigned_to_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_pets_family_stage ON pets(family_id, stage);
CREATE INDEX IF NOT EXISTS idx_tasks_active ON tasks(family_id, created_at DESC) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_task_comments_task_created ON task_comments(task_id, created_at);

-- ===== ROW LEVEL SECURITY =====

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Profiles are viewable by family members" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can create profiles" ON profiles;

DROP POLICY IF EXISTS "Families are viewable by members" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

DROP POLICY IF EXISTS "Tasks are viewable by family members" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and assignees can update tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;

DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
DROP POLICY IF EXISTS "Children can create one pet" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;

DROP POLICY IF EXISTS "Task comments are viewable by family members" ON task_comments;
DROP POLICY IF EXISTS "Family members can create comments on family tasks" ON task_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON task_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON task_comments;

-- Profiles policies
CREATE POLICY "Profiles are viewable by family members"
  ON profiles FOR SELECT
  USING (
    auth.uid() = id OR
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Authenticated users can create profiles"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Families policies
CREATE POLICY "Families are viewable by members"
  ON families FOR SELECT
  USING (
    created_by_id = auth.uid() OR
    auth.uid() = ANY(parent_ids) OR
    auth.uid() = ANY(child_ids)
  );

CREATE POLICY "Authenticated users can create families"
  ON families FOR INSERT
  WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Family creators and parents can update families"
  ON families FOR UPDATE
  USING (
    created_by_id = auth.uid() OR
    auth.uid() = ANY(parent_ids)
  )
  WITH CHECK (
    created_by_id = auth.uid() OR
    auth.uid() = ANY(parent_ids)
  );

CREATE POLICY "Only family creators can delete families"
  ON families FOR DELETE
  USING (created_by_id = auth.uid());

-- Tasks policies
CREATE POLICY "Tasks are viewable by family members"
  ON tasks FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create tasks"
  ON tasks FOR INSERT
  WITH CHECK (
    auth.uid() = created_by_id AND
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Task creators and assignees can update tasks"
  ON tasks FOR UPDATE
  USING (
    auth.uid() = created_by_id OR
    auth.uid() = assigned_to_id
  )
  WITH CHECK (
    auth.uid() = created_by_id OR
    auth.uid() = assigned_to_id
  );

CREATE POLICY "Parents can verify tasks"
  ON tasks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles p1
      JOIN profiles p2 ON p1.family_id = p2.family_id
      WHERE p1.id = auth.uid()
      AND p1.role = 'parent'
      AND p2.id = tasks.assigned_to_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p1
      JOIN profiles p2 ON p1.family_id = p2.family_id
      WHERE p1.id = auth.uid()
      AND p1.role = 'parent'
      AND p2.id = tasks.assigned_to_id
    )
  );

-- Pets policies
CREATE POLICY "Pets are viewable by family members"
  ON pets FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Children can create one pet"
  ON pets FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role = 'child'
    ) AND
    NOT EXISTS (
      SELECT 1 FROM pets WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "Children can update their own pet"
  ON pets FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Task Comments policies
CREATE POLICY "Task comments are viewable by family members"
  ON task_comments FOR SELECT
  USING (
    task_id IN (
      SELECT t.id FROM tasks t
      JOIN profiles p ON p.family_id = t.family_id
      WHERE p.id = auth.uid()
    )
  );

CREATE POLICY "Family members can create comments on family tasks"
  ON task_comments FOR INSERT
  WITH CHECK (
    auth.uid() = author_id AND
    task_id IN (
      SELECT t.id FROM tasks t
      JOIN profiles p ON p.family_id = t.family_id
      WHERE p.id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own comments"
  ON task_comments FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete their own comments"
  ON task_comments FOR DELETE
  USING (auth.uid() = author_id);

-- ===== STORAGE BUCKETS =====

-- Create storage buckets (if they don't exist)
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('task_images', 'Task Images', false),
  ('profile_images', 'Profile Images', true),
  ('pet_images', 'Pet Images', true)
ON CONFLICT (id) DO NOTHING;

-- ===== FUNCTIONS =====

-- Function to generate unique invite codes
CREATE OR REPLACE FUNCTION generate_unique_invite_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    code VARCHAR(6);
    code_exists BOOLEAN;
BEGIN
    LOOP
        code := UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6));
        code := REPLACE(code, '0', '2');
        code := REPLACE(code, 'O', '3');
        code := REPLACE(code, 'I', '4');
        code := REPLACE(code, 'L', '5');
        
        SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = code) INTO code_exists;
        
        IF NOT code_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        display_name,
        role,
        created_at,
        updated_at,
        last_login_at,
        metadata
    )
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'display_name', new.email),
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
        timezone('utc'::text, now()),
        timezone('utc'::text, now()),
        timezone('utc'::text, now()),
        COALESCE(new.raw_user_meta_data, '{}')
    );
    RETURN new;
END;
$$;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-generate invite codes
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_unique_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===== TRIGGERS =====

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
DROP TRIGGER IF EXISTS update_families_updated_at ON families;
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP TRIGGER IF EXISTS update_pets_updated_at ON pets;
DROP TRIGGER IF EXISTS update_task_comments_updated_at ON task_comments;
DROP TRIGGER IF EXISTS trigger_set_invite_code ON families;

-- Create triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_families_updated_at
  BEFORE UPDATE ON families
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pets_updated_at
  BEFORE UPDATE ON pets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_task_comments_updated_at
  BEFORE UPDATE ON task_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- ===== REALTIME PUBLICATION =====

-- Set up realtime replication
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE families;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE pets;
ALTER PUBLICATION supabase_realtime ADD TABLE task_comments;

-- Success message
SELECT 'Database schema restoration completed successfully!' as status; 