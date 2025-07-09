-- =====================================================
-- COMPLETE DATABASE REBUILD MIGRATION
-- This migration rebuilds the entire database from scratch
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUM TYPES
-- =====================================================

-- Create enum types (skip if they already exist)
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('parent', 'child');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_status AS ENUM ('pending', 'inProgress', 'completed', 'expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_category AS ENUM ('study', 'work', 'sport', 'family', 'friends', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE task_difficulty AS ENUM ('easy', 'medium', 'hard');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE pet_mood AS ENUM (
        'veryVeryHappy',
        'veryHappy', 
        'happy',
        'content',
        'neutral',
        'sad',
        'upset',
        'hungry',
        'veryHungry',
        'veryVeryHungry'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- TABLES
-- =====================================================

-- Create families table
CREATE TABLE IF NOT EXISTS families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    invite_code VARCHAR(6) NOT NULL UNIQUE,
    created_by_id UUID,
    parent_ids UUID[] DEFAULT '{}',
    child_ids UUID[] DEFAULT '{}',
    pet_image_url TEXT,
    pet_stage_images JSONB DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    role user_role NOT NULL,
    family_id UUID REFERENCES families(id) ON DELETE SET NULL,
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add constraints if they don't exist
DO $$ BEGIN
    ALTER TABLE families ADD CONSTRAINT families_name_length_check CHECK (LENGTH(TRIM(name)) >= 2);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE families ADD CONSTRAINT families_invite_code_length_check CHECK (LENGTH(invite_code) = 6);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add foreign key constraint to families table after profiles exists
DO $$ BEGIN
    ALTER TABLE families ADD CONSTRAINT families_created_by_id_fkey 
        FOREIGN KEY (created_by_id) REFERENCES profiles(id) ON DELETE CASCADE;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    points INTEGER NOT NULL DEFAULT 0,
    status task_status NOT NULL DEFAULT 'pending',
    assigned_to_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_by_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    verified_by_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    frequency task_frequency NOT NULL DEFAULT 'once',
    category task_category NOT NULL DEFAULT 'other',
    difficulty task_difficulty NOT NULL DEFAULT 'medium',
    tags TEXT[] DEFAULT '{}',
    image_urls TEXT[] DEFAULT '{}',
    rewards JSONB DEFAULT '[]',
    next_due_date TIMESTAMP WITH TIME ZONE,
    streak_count INTEGER DEFAULT 0,
    is_template BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    verified_at TIMESTAMP WITH TIME ZONE
);

-- Add missing columns to tasks table if they don't exist
DO $$ BEGIN
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS category task_category DEFAULT 'other';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS difficulty task_difficulty DEFAULT 'medium';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS rewards JSONB DEFAULT '[]';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS next_due_date TIMESTAMP WITH TIME ZONE;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_template BOOLEAN DEFAULT FALSE;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS parent_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
END $$;

-- Add task constraints
DO $$ BEGIN
    ALTER TABLE tasks ADD CONSTRAINT tasks_points_positive_check CHECK (points >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE tasks ADD CONSTRAINT tasks_streak_count_check CHECK (streak_count >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create pets table
CREATE TABLE IF NOT EXISTS pets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    stage pet_stage NOT NULL DEFAULT 'egg',
    mood pet_mood NOT NULL DEFAULT 'happy',
    experience INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    health INTEGER NOT NULL DEFAULT 100,
    happiness INTEGER NOT NULL DEFAULT 100,
    energy INTEGER NOT NULL DEFAULT 100,
    hunger INTEGER NOT NULL DEFAULT 100,
    emotion INTEGER NOT NULL DEFAULT 100,
    last_fed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_care_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to pets table if they don't exist
DO $$ BEGIN
    ALTER TABLE pets ADD COLUMN IF NOT EXISTS hunger INTEGER DEFAULT 100;
    ALTER TABLE pets ADD COLUMN IF NOT EXISTS emotion INTEGER DEFAULT 100;
    ALTER TABLE pets ADD COLUMN IF NOT EXISTS last_care_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
END $$;

-- Add pet constraints
DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_level_positive_check CHECK (level >= 1);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_experience_check CHECK (experience >= 0);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_health_range_check CHECK (health >= 0 AND health <= 100);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_happiness_range_check CHECK (happiness >= 0 AND happiness <= 100);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_energy_range_check CHECK (energy >= 0 AND energy <= 100);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_hunger_range_check CHECK (hunger >= 0 AND hunger <= 100);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER TABLE pets ADD CONSTRAINT pets_emotion_range_check CHECK (emotion >= 0 AND emotion <= 100);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create task_comments table
CREATE TABLE IF NOT EXISTS task_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add task comments constraint
DO $$ BEGIN
    ALTER TABLE task_comments ADD CONSTRAINT task_comments_content_length_check CHECK (LENGTH(TRIM(content)) >= 1 AND LENGTH(TRIM(content)) <= 1000);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- INDEXES
-- =====================================================

-- Families indexes
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);
CREATE INDEX IF NOT EXISTS idx_families_created_by_id ON families(created_by_id);
CREATE INDEX IF NOT EXISTS idx_families_created_at ON families(created_at);

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_family_id ON profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_family_id ON tasks(family_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_id ON tasks(assigned_to_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_id ON tasks(created_by_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_frequency ON tasks(frequency);
CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);
CREATE INDEX IF NOT EXISTS idx_tasks_is_archived ON tasks(is_archived);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id ON tasks(parent_task_id);

-- Pets indexes
CREATE INDEX IF NOT EXISTS idx_pets_family_id ON pets(family_id);
CREATE INDEX IF NOT EXISTS idx_pets_owner_id ON pets(owner_id);
CREATE INDEX IF NOT EXISTS idx_pets_stage ON pets(stage);
CREATE INDEX IF NOT EXISTS idx_pets_mood ON pets(mood);

-- Task comments indexes
CREATE INDEX IF NOT EXISTS idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_author_id ON task_comments(author_id);
CREATE INDEX IF NOT EXISTS idx_task_comments_created_at ON task_comments(created_at);
CREATE INDEX IF NOT EXISTS idx_task_comments_task_created ON task_comments(task_id, created_at);

-- =====================================================
-- STORAGE BUCKETS
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('task_images', 'Task Images', false),
    ('profile_images', 'Profile Images', false),
    ('pet_images', 'Pet Images', false)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to generate unique invite code
CREATE OR REPLACE FUNCTION generate_unique_invite_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    code VARCHAR(6);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a random 6-character code
        code := UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6));
        
        -- Replace some confusing characters
        code := REPLACE(code, '0', '2');
        code := REPLACE(code, 'O', '3');
        code := REPLACE(code, 'I', '4');
        code := REPLACE(code, 'L', '5');
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = code) INTO code_exists;
        
        -- If code doesn't exist, we can use it
        IF NOT code_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate pet mood based on stats
CREATE OR REPLACE FUNCTION calculate_pet_mood(
    health_val INTEGER,
    happiness_val INTEGER,
    energy_val INTEGER,
    hunger_val INTEGER,
    emotion_val INTEGER
) RETURNS pet_mood AS $$
BEGIN
    -- If very hungry, mood is based on hunger level
    IF hunger_val <= 10 THEN
        RETURN 'veryVeryHungry'::pet_mood;
    ELSIF hunger_val <= 20 THEN
        RETURN 'veryHungry'::pet_mood;
    ELSIF hunger_val <= 30 THEN
        RETURN 'hungry'::pet_mood;
    END IF;
    
    -- If not hungry, base mood on emotion
    IF emotion_val >= 90 THEN
        RETURN 'veryVeryHappy'::pet_mood;
    ELSIF emotion_val >= 80 THEN
        RETURN 'veryHappy'::pet_mood;
    ELSIF emotion_val >= 70 THEN
        RETURN 'happy'::pet_mood;
    ELSIF emotion_val >= 60 THEN
        RETURN 'content'::pet_mood;
    ELSIF emotion_val >= 40 THEN
        RETURN 'neutral'::pet_mood;
    ELSIF emotion_val >= 20 THEN
        RETURN 'sad'::pet_mood;
    ELSE
        RETURN 'upset'::pet_mood;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to check if pet can evolve
CREATE OR REPLACE FUNCTION can_pet_evolve(pet_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    pet_experience INTEGER;
    pet_current_stage pet_stage;
    required_exp INTEGER;
BEGIN
    -- Get pet's current stats
    SELECT experience, stage INTO pet_experience, pet_current_stage
    FROM pets WHERE id = pet_id;
    
    -- Check if already at max stage
    IF pet_current_stage = 'adult' THEN
        RETURN FALSE;
    END IF;
    
    -- Define experience thresholds
    required_exp := CASE pet_current_stage
        WHEN 'egg' THEN 100
        WHEN 'baby' THEN 300
        WHEN 'child' THEN 600
        WHEN 'teen' THEN 1000
        ELSE 9999
    END;
    
    RETURN pet_experience >= required_exp;
END;
$$ LANGUAGE plpgsql;

-- Function to evolve pet to next stage
CREATE OR REPLACE FUNCTION evolve_pet(pet_id UUID)
RETURNS pet_stage AS $$
DECLARE
    current_stage pet_stage;
    new_stage pet_stage;
BEGIN
    -- Get current stage
    SELECT stage INTO current_stage FROM pets WHERE id = pet_id;
    
    -- Determine next stage
    new_stage := CASE current_stage
        WHEN 'egg' THEN 'baby'::pet_stage
        WHEN 'baby' THEN 'child'::pet_stage
        WHEN 'child' THEN 'teen'::pet_stage
        WHEN 'teen' THEN 'adult'::pet_stage
        ELSE current_stage
    END;
    
    -- Update pet stage if evolution is possible
    IF new_stage != current_stage AND can_pet_evolve(pet_id) THEN
        UPDATE pets 
        SET stage = new_stage,
            level = level + 1,
            updated_at = NOW()
        WHERE id = pet_id;
        
        RETURN new_stage;
    END IF;
    
    RETURN current_stage;
END;
$$ LANGUAGE plpgsql;

-- Function to add member to family
CREATE OR REPLACE FUNCTION add_family_member(
    family_id_param UUID,
    user_id_param UUID,
    role_param user_role
)
RETURNS BOOLEAN AS $$
DECLARE
    current_parent_ids UUID[];
    current_child_ids UUID[];
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Get current member arrays
    SELECT parent_ids, child_ids INTO current_parent_ids, current_child_ids
    FROM families WHERE id = family_id_param;
    
    -- Check if user is already a member
    IF user_id_param = ANY(current_parent_ids) OR user_id_param = ANY(current_child_ids) THEN
        RETURN FALSE; -- Already a member
    END IF;
    
    -- Add to appropriate array based on role
    IF role_param = 'parent' THEN
        new_parent_ids := current_parent_ids || user_id_param;
        new_child_ids := current_child_ids;
    ELSE
        new_parent_ids := current_parent_ids;
        new_child_ids := current_child_ids || user_id_param;
    END IF;
    
    -- Update family and user profile
    UPDATE families 
    SET 
        parent_ids = new_parent_ids,
        child_ids = new_child_ids,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = family_id_param;
    
    UPDATE profiles 
    SET 
        family_id = family_id_param,
        updated_at = NOW()
    WHERE id = user_id_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to remove member from family
CREATE OR REPLACE FUNCTION remove_family_member(
    family_id_param UUID,
    user_id_param UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    current_parent_ids UUID[];
    current_child_ids UUID[];
BEGIN
    -- Get current member arrays
    SELECT parent_ids, child_ids INTO current_parent_ids, current_child_ids
    FROM families WHERE id = family_id_param;
    
    -- Remove from both arrays
    UPDATE families 
    SET 
        parent_ids = array_remove(current_parent_ids, user_id_param),
        child_ids = array_remove(current_child_ids, user_id_param),
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE id = family_id_param;
    
    -- Clear family_id from user profile
    UPDATE profiles 
    SET 
        family_id = NULL,
        updated_at = NOW()
    WHERE id = user_id_param;
    
    RETURN TRUE;
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
        last_login_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        (NEW.raw_user_meta_data->>'role')::user_role,
        NOW(),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$;

-- Function to set invite code
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_unique_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update pet mood trigger
CREATE OR REPLACE FUNCTION update_pet_mood_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.mood := calculate_pet_mood(
        NEW.health,
        NEW.happiness,
        NEW.energy,
        NEW.hunger,
        NEW.emotion
    );
    
    -- Auto-evolve if possible
    IF can_pet_evolve(NEW.id) THEN
        NEW.stage := evolve_pet(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Create triggers for updating timestamps
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_families_updated_at ON families;
CREATE TRIGGER update_families_updated_at
    BEFORE UPDATE ON families
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pets_updated_at ON pets;
CREATE TRIGGER update_pets_updated_at
    BEFORE UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_task_comments_updated_at ON task_comments;
CREATE TRIGGER update_task_comments_updated_at
    BEFORE UPDATE ON task_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create trigger to auto-generate invite code
DROP TRIGGER IF EXISTS trigger_set_invite_code ON families;
CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- Create trigger for pet mood updates
DROP TRIGGER IF EXISTS trigger_update_pet_mood ON pets;
CREATE TRIGGER trigger_update_pet_mood
    BEFORE UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_pet_mood_trigger();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view family members" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on id" ON profiles;

DROP POLICY IF EXISTS "Users can view their own family" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;
DROP POLICY IF EXISTS "Family creators and parents can update families" ON families;
DROP POLICY IF EXISTS "Family creators can delete families" ON families;
DROP POLICY IF EXISTS "Families are viewable by members" ON families;
DROP POLICY IF EXISTS "Parents can create families" ON families;
DROP POLICY IF EXISTS "Parents can update their family" ON families;
DROP POLICY IF EXISTS "Users can view families" ON families;
DROP POLICY IF EXISTS "Users can create families" ON families;
DROP POLICY IF EXISTS "Family creators can update their family" ON families;
DROP POLICY IF EXISTS "Only family creators can delete families" ON families;

DROP POLICY IF EXISTS "Tasks are viewable by family members" ON tasks;
DROP POLICY IF EXISTS "Family members can create tasks" ON tasks;
DROP POLICY IF EXISTS "Task assignees can update their tasks" ON tasks;
DROP POLICY IF EXISTS "Task creators and parents can delete tasks" ON tasks;
DROP POLICY IF EXISTS "Authenticated users can create tasks" ON tasks;
DROP POLICY IF EXISTS "Children can update their assigned tasks" ON tasks;
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;

DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
DROP POLICY IF EXISTS "Family members can create pets" ON pets;
DROP POLICY IF EXISTS "Family members can update pets" ON pets;
DROP POLICY IF EXISTS "Family members can delete pets" ON pets;
DROP POLICY IF EXISTS "Children can create pets" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;
DROP POLICY IF EXISTS "Pet owners can update their pets" ON pets;
DROP POLICY IF EXISTS "Users can view pets in their family" ON pets;
DROP POLICY IF EXISTS "Users can create pets" ON pets;
DROP POLICY IF EXISTS "Users can update their own pets" ON pets;
DROP POLICY IF EXISTS "Anyone can view pets in their family" ON pets;

DROP POLICY IF EXISTS "Task comments are viewable by family members" ON task_comments;
DROP POLICY IF EXISTS "Family members can create comments on family tasks" ON task_comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON task_comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON task_comments;

-- =====================================================
-- RLS POLICIES - PROFILES
-- =====================================================

CREATE POLICY "Users can read their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view family members"
    ON profiles FOR SELECT
    USING (
        auth.uid() = id OR
        (family_id IS NOT NULL AND family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        ))
    );

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- =====================================================
-- RLS POLICIES - FAMILIES
-- =====================================================

CREATE POLICY "Users can view their own family"
    ON families FOR SELECT
    USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids) OR
        auth.uid() = ANY(child_ids) OR
        auth.uid() IN (
            SELECT id FROM profiles WHERE family_id = families.id
        )
    );

CREATE POLICY "Authenticated users can create families"
    ON families FOR INSERT
    WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Family creators and parents can update families"
    ON families FOR UPDATE
    USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids)
    )
    WITH CHECK (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids)
    );

CREATE POLICY "Family creators can delete families"
    ON families FOR DELETE
    USING (auth.uid() = created_by_id);

-- =====================================================
-- RLS POLICIES - TASKS
-- =====================================================

CREATE POLICY "Tasks are viewable by family members"
    ON tasks FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Family members can create tasks"
    ON tasks FOR INSERT
    WITH CHECK (
        auth.uid() = created_by_id AND
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Task assignees can update their tasks"
    ON tasks FOR UPDATE
    USING (
        assigned_to_id = auth.uid() OR
        created_by_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM profiles 
            WHERE family_id = tasks.family_id AND role = 'parent'
        )
    )
    WITH CHECK (
        assigned_to_id = auth.uid() OR
        created_by_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM profiles 
            WHERE family_id = tasks.family_id AND role = 'parent'
        )
    );

CREATE POLICY "Task creators and parents can delete tasks"
    ON tasks FOR DELETE
    USING (
        created_by_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM profiles 
            WHERE family_id = tasks.family_id AND role = 'parent'
        )
    );

-- =====================================================
-- RLS POLICIES - PETS
-- =====================================================

CREATE POLICY "Pets are viewable by family members"
    ON pets FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Family members can create pets"
    ON pets FOR INSERT
    WITH CHECK (
        auth.uid() = owner_id AND
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Family members can update pets"
    ON pets FOR UPDATE
    USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Family members can delete pets"
    ON pets FOR DELETE
    USING (
        owner_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM profiles 
            WHERE family_id = pets.family_id AND role = 'parent'
        )
    );

-- =====================================================
-- RLS POLICIES - TASK COMMENTS
-- =====================================================

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

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Drop existing storage policies
DROP POLICY IF EXISTS "Task images are viewable by family members" ON storage.objects;
DROP POLICY IF EXISTS "Family members can upload task images" ON storage.objects;
DROP POLICY IF EXISTS "Profile images are viewable by family members" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Pet images are viewable by family members" ON storage.objects;
DROP POLICY IF EXISTS "Family members can upload pet images" ON storage.objects;

-- Task images storage policies
CREATE POLICY "Task images are viewable by family members"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'task_images' AND
        auth.uid() IN (
            SELECT p.id FROM profiles p
            JOIN tasks t ON p.family_id = t.family_id
            WHERE t.id::text = split_part(name, '/', 1)
        )
    );

CREATE POLICY "Family members can upload task images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'task_images' AND
        auth.uid() IN (
            SELECT p.id FROM profiles p
            JOIN tasks t ON p.family_id = t.family_id
            WHERE t.id::text = split_part(name, '/', 1)
        )
    );

-- Profile images storage policies
CREATE POLICY "Profile images are viewable by family members"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'profile_images' AND
        (
            auth.uid()::text = split_part(name, '/', 1) OR
            auth.uid() IN (
                SELECT p2.id FROM profiles p1
                JOIN profiles p2 ON p1.family_id = p2.family_id
                WHERE p1.id::text = split_part(name, '/', 1)
            )
        )
    );

CREATE POLICY "Users can upload their own profile images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'profile_images' AND
        auth.uid()::text = split_part(name, '/', 1)
    );

-- Pet images storage policies
CREATE POLICY "Pet images are viewable by family members"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'pet_images' AND
        auth.uid() IN (
            SELECT p.id FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE f.id::text = split_part(name, '/', 1)
        )
    );

CREATE POLICY "Family members can upload pet images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'pet_images' AND
        auth.uid() IN (
            SELECT p.id FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE f.id::text = split_part(name, '/', 1)
        )
    );

-- =====================================================
-- REALTIME SUBSCRIPTIONS
-- =====================================================

-- Set up realtime replication
BEGIN;
    DROP PUBLICATION IF EXISTS supabase_realtime;
    CREATE PUBLICATION supabase_realtime;
COMMIT;

-- Add tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE families;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE pets;
ALTER PUBLICATION supabase_realtime ADD TABLE task_comments;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION generate_unique_invite_code() TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_pet_mood(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION can_pet_evolve(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION evolve_pet(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_family_member(UUID, UUID, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_family_member(UUID, UUID) TO authenticated;

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON TABLE families IS 'Stores family information and member relationships';
COMMENT ON TABLE profiles IS 'User profiles with family relationships';
COMMENT ON TABLE tasks IS 'Family tasks and chores with rewards and tracking';
COMMENT ON TABLE pets IS 'Virtual family pets with mood and evolution system';
COMMENT ON TABLE task_comments IS 'Comments on tasks for family communication';

COMMENT ON COLUMN families.invite_code IS 'Unique 6-character code for inviting family members';
COMMENT ON COLUMN families.parent_ids IS 'Array of user IDs who are parents in this family';
COMMENT ON COLUMN families.child_ids IS 'Array of user IDs who are children in this family';
COMMENT ON COLUMN families.pet_image_url IS 'Current pet image URL from Supabase storage';
COMMENT ON COLUMN families.pet_stage_images IS 'JSON mapping of pet stages to image URLs for this family';

COMMENT ON FUNCTION generate_unique_invite_code() IS 'Generates a unique 6-character invite code for families';
COMMENT ON FUNCTION calculate_pet_mood(INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) IS 'Calculates pet mood based on stats';
COMMENT ON FUNCTION can_pet_evolve(UUID) IS 'Checks if pet has enough experience to evolve to next stage';
COMMENT ON FUNCTION evolve_pet(UUID) IS 'Evolves pet to next stage if possible and returns new stage';
COMMENT ON FUNCTION add_family_member(UUID, UUID, user_role) IS 'Adds a user to a family with specified role';
COMMENT ON FUNCTION remove_family_member(UUID, UUID) IS 'Removes a user from a family';

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE 'Database rebuild completed successfully!';
    RAISE NOTICE 'Created tables: profiles, families, tasks, pets, task_comments';
    RAISE NOTICE 'Created storage buckets: task_images, profile_images, pet_images';
    RAISE NOTICE 'Configured RLS policies for all tables';
    RAISE NOTICE 'Set up realtime subscriptions';
    RAISE NOTICE 'Ready for application use!';
END $$; 