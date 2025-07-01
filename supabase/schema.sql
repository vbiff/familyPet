-- Complete Database Schema for Jhonny Family Task Management App
-- This schema is fully aligned with domain entities and includes all necessary functionality

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== ENUM TYPES =====

-- User roles in the family system
CREATE TYPE user_role AS ENUM ('parent', 'child');

-- Task statuses aligned with domain entity
CREATE TYPE task_status AS ENUM ('pending', 'inProgress', 'completed', 'expired');

-- Task frequency options
CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');

-- Pet mood states aligned with domain entity
CREATE TYPE pet_mood AS ENUM ('happy', 'content', 'neutral', 'sad', 'upset');

-- Pet evolution stages
CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');

-- ===== MAIN TABLES =====

-- Profiles table for user information
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  role user_role NOT NULL,
  family_id UUID, -- References families(id), added later due to circular dependency
  last_login_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Families table for family groups
CREATE TABLE families (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_code TEXT UNIQUE NOT NULL,
  created_by_id UUID REFERENCES profiles(id) NOT NULL,
  parent_ids UUID[] DEFAULT '{}',
  child_ids UUID[] DEFAULT '{}',
  last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  settings JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  pet_image_url TEXT,
  pet_stage_images JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT families_name_length_check CHECK (LENGTH(TRIM(name)) >= 2),
  CONSTRAINT families_invite_code_length_check CHECK (LENGTH(invite_code) = 6)
);

-- Add foreign key reference after families table exists
ALTER TABLE profiles ADD CONSTRAINT profiles_family_id_fkey 
FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL;

-- Tasks table for family task management
CREATE TABLE tasks (
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
  completed_at TIMESTAMP WITH TIME ZONE,
  
  -- Constraints
  CONSTRAINT tasks_points_positive_check CHECK (points >= 0)
);

-- Pets table for virtual pet system
CREATE TABLE pets (
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT pets_level_positive_check CHECK (level >= 1)
);

-- ===== INDEXES FOR PERFORMANCE =====

-- Profiles indexes
CREATE INDEX idx_profiles_family_id ON profiles(family_id);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_email ON profiles(email);

-- Families indexes
CREATE INDEX idx_families_invite_code ON families(invite_code);
CREATE INDEX idx_families_created_by_id ON families(created_by_id);
CREATE INDEX idx_families_created_at ON families(created_at);

-- Tasks indexes
CREATE INDEX idx_tasks_family_id ON tasks(family_id);
CREATE INDEX idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_frequency ON tasks(frequency);
CREATE INDEX idx_tasks_verified_by_id ON tasks(verified_by_id);

-- Pets indexes
CREATE INDEX idx_pets_owner_id ON pets(owner_id);
CREATE INDEX idx_pets_family_id ON pets(family_id);
CREATE INDEX idx_pets_stage ON pets(stage);
CREATE INDEX idx_pets_mood ON pets(mood);
CREATE INDEX idx_pets_level ON pets(level);

-- Composite indexes for common queries
CREATE INDEX idx_tasks_family_status_due ON tasks(family_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX idx_tasks_assigned_status_due ON tasks(assigned_to_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX idx_pets_family_stage ON pets(family_id, stage);
CREATE INDEX idx_tasks_active ON tasks(family_id, created_at DESC) WHERE NOT is_archived;

-- ===== ROW LEVEL SECURITY =====

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;

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

-- ===== STORAGE BUCKETS =====

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('task_images', 'Task Images', false),
  ('profile_images', 'Profile Images', true),
  ('pet_images', 'Pet Images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Task images are viewable by family members"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'task_images');

CREATE POLICY "Users can upload task images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'task_images' AND auth.uid() IS NOT NULL);

CREATE POLICY "Profile images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile_images');

CREATE POLICY "Users can upload their profile image"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'profile_images' AND auth.uid() IS NOT NULL);

CREATE POLICY "Pet images are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'pet_images');

CREATE POLICY "Authenticated users can upload pet images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'pet_images' AND auth.uid() IS NOT NULL);

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

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Triggers for updating timestamps
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

-- Trigger to auto-generate invite codes
CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- ===== REALTIME PUBLICATION =====

-- Set up realtime replication
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;

ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE families;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE pets;

-- ===== COMMENTS FOR DOCUMENTATION =====

-- Table comments
COMMENT ON TABLE profiles IS 'User profiles with roles and family associations';
COMMENT ON TABLE families IS 'Family groups with member management';
COMMENT ON TABLE tasks IS 'Family tasks with assignment and completion tracking';
COMMENT ON TABLE pets IS 'Virtual pets with evolution and care mechanics';

-- Column comments
COMMENT ON COLUMN profiles.last_login_at IS 'Timestamp of user last login';
COMMENT ON COLUMN profiles.metadata IS 'Additional user metadata stored as JSON';

COMMENT ON COLUMN families.invite_code IS 'Unique 6-character code for inviting family members';
COMMENT ON COLUMN families.parent_ids IS 'Array of parent user IDs in this family';
COMMENT ON COLUMN families.child_ids IS 'Array of child user IDs in this family';
COMMENT ON COLUMN families.last_activity_at IS 'Timestamp of last family activity';
COMMENT ON COLUMN families.settings IS 'Family settings stored as JSON';
COMMENT ON COLUMN families.metadata IS 'Additional family metadata stored as JSON';
COMMENT ON COLUMN families.pet_image_url IS 'Current family pet image URL';
COMMENT ON COLUMN families.pet_stage_images IS 'Mapping of pet stages to image URLs';

COMMENT ON COLUMN tasks.verified_by_id IS 'Parent who verified task completion';
COMMENT ON COLUMN tasks.verified_at IS 'Timestamp when task was verified by parent';
COMMENT ON COLUMN tasks.image_urls IS 'Array of image URLs for task proof/documentation';
COMMENT ON COLUMN tasks.metadata IS 'Additional task metadata stored as JSON';
COMMENT ON COLUMN tasks.is_archived IS 'Soft delete flag for completed/expired tasks';

COMMENT ON COLUMN pets.health IS 'Pet health stat (0-100)';
COMMENT ON COLUMN pets.happiness IS 'Pet happiness stat (0-100)';
COMMENT ON COLUMN pets.energy IS 'Pet energy stat (0-100)';
COMMENT ON COLUMN pets.last_fed_at IS 'Timestamp when pet was last fed';
COMMENT ON COLUMN pets.last_played_at IS 'Timestamp when pet was last played with';

-- Function comments
COMMENT ON FUNCTION generate_unique_invite_code() IS 'Generates a unique 6-character invite code for families';
COMMENT ON FUNCTION handle_new_user() IS 'Creates user profile when new user signs up';
COMMENT ON FUNCTION update_updated_at_column() IS 'Updates the updated_at timestamp on row changes';
COMMENT ON FUNCTION set_invite_code() IS 'Auto-generates invite code for new families'; 