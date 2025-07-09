-- =====================================================
-- COMPLETE DATABASE RECREATION MIGRATION
-- Recreates the entire Jhonny Family Task Management App database
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- CLEAN UP EXISTING SCHEMA
-- =====================================================

-- Drop existing tables in dependency order
DROP TABLE IF EXISTS task_comments CASCADE;
DROP TABLE IF EXISTS pets CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS families CASCADE;

-- Drop existing enums
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS task_status CASCADE;
DROP TYPE IF EXISTS task_frequency CASCADE;
DROP TYPE IF EXISTS task_category CASCADE;
DROP TYPE IF EXISTS task_difficulty CASCADE;
DROP TYPE IF EXISTS pet_mood CASCADE;
DROP TYPE IF EXISTS pet_stage CASCADE;

-- =====================================================
-- ENUM TYPES
-- =====================================================

-- User roles in the family system
CREATE TYPE user_role AS ENUM ('parent', 'child');

-- Task statuses aligned with domain entity
CREATE TYPE task_status AS ENUM ('pending', 'inProgress', 'completed', 'expired');

-- Task frequency options
CREATE TYPE task_frequency AS ENUM ('once', 'daily', 'weekly', 'monthly');

-- Task categories
CREATE TYPE task_category AS ENUM ('study', 'work', 'sport', 'family', 'friends', 'other');

-- Task difficulty levels
CREATE TYPE task_difficulty AS ENUM ('easy', 'medium', 'hard');

-- Pet mood states aligned with domain entity
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

-- Pet evolution stages
CREATE TYPE pet_stage AS ENUM ('egg', 'baby', 'child', 'teen', 'adult');

-- =====================================================
-- MAIN TABLES
-- =====================================================

-- Families table for family groups
CREATE TABLE families (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by_id UUID, -- Will be set as FK after profiles table exists
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

-- Profiles table for user information
CREATE TABLE profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    role user_role NOT NULL,
    family_id UUID REFERENCES families(id) ON DELETE SET NULL,
    last_login_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Add foreign key reference to families table after profiles exists
ALTER TABLE families ADD CONSTRAINT families_created_by_id_fkey 
    FOREIGN KEY (created_by_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- Tasks table for family task management
CREATE TABLE tasks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    points INTEGER NOT NULL DEFAULT 0 CHECK (points >= 0),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
    assigned_to_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    created_by_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    status task_status NOT NULL DEFAULT 'pending',
    frequency task_frequency NOT NULL DEFAULT 'once',
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_by_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    image_urls TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Phase 2 enhancements
    category task_category NOT NULL DEFAULT 'other',
    difficulty task_difficulty NOT NULL DEFAULT 'medium',
    tags TEXT[] DEFAULT '{}',
    rewards JSONB DEFAULT '[]',
    next_due_date TIMESTAMP WITH TIME ZONE,
    streak_count INTEGER DEFAULT 0 CHECK (streak_count >= 0),
    is_template BOOLEAN DEFAULT FALSE,
    parent_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL
);

-- Pets table for virtual pet system
CREATE TABLE pets (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE NOT NULL,
    mood pet_mood NOT NULL DEFAULT 'neutral',
    stage pet_stage NOT NULL DEFAULT 'egg',
    experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
    level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
    happiness INTEGER NOT NULL DEFAULT 50 CHECK (happiness >= 0 AND happiness <= 100),
    energy INTEGER NOT NULL DEFAULT 100 CHECK (energy >= 0 AND energy <= 100),
    health INTEGER NOT NULL DEFAULT 100 CHECK (health >= 0 AND health <= 100),
    last_fed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_played_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_care_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- Additional pet stats stored as JSONB for flexibility
    stats JSONB DEFAULT '{"hunger": 100, "emotion": 100}'::jsonb,
    
    -- Constraints
    CONSTRAINT pets_level_positive_check CHECK (level >= 1)
);

-- Task comments table for task discussion
CREATE TABLE task_comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

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
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_is_archived ON tasks(is_archived);
CREATE INDEX idx_tasks_parent_task_id ON tasks(parent_task_id);

-- Pets indexes
CREATE INDEX idx_pets_owner_id ON pets(owner_id);
CREATE INDEX idx_pets_family_id ON pets(family_id);
CREATE INDEX idx_pets_stage ON pets(stage);
CREATE INDEX idx_pets_mood ON pets(mood);
CREATE INDEX idx_pets_level ON pets(level);

-- Task comments indexes
CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_author_id ON task_comments(author_id);
CREATE INDEX idx_task_comments_created_at ON task_comments(created_at);

-- Composite indexes for common queries
CREATE INDEX idx_tasks_family_status_due ON tasks(family_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX idx_tasks_assigned_status_due ON tasks(assigned_to_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX idx_pets_family_stage ON pets(family_id, stage);
CREATE INDEX idx_tasks_active ON tasks(family_id, created_at DESC) WHERE NOT is_archived;
CREATE INDEX idx_task_comments_task_created ON task_comments(task_id, created_at DESC);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "profiles_viewable_by_family_members"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        auth.uid() = id OR
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "profiles_users_can_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_authenticated_users_can_create"
    ON profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Families policies
CREATE POLICY "families_viewable_by_members"
    ON families FOR SELECT
    TO authenticated
    USING (
        created_by_id = auth.uid() OR
        auth.uid() = ANY(parent_ids) OR
        auth.uid() = ANY(child_ids)
    );

CREATE POLICY "families_authenticated_users_can_create"
    ON families FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "families_creators_and_parents_can_update"
    ON families FOR UPDATE
    TO authenticated
    USING (
        created_by_id = auth.uid() OR
        auth.uid() = ANY(parent_ids)
    )
    WITH CHECK (
        created_by_id = auth.uid() OR
        auth.uid() = ANY(parent_ids)
    );

CREATE POLICY "families_only_creators_can_delete"
    ON families FOR DELETE
    TO authenticated
    USING (created_by_id = auth.uid());

-- Tasks policies
CREATE POLICY "tasks_viewable_by_family_members"
    ON tasks FOR SELECT
    TO authenticated
    USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "tasks_authenticated_users_can_create"
    ON tasks FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = created_by_id AND
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "tasks_creators_and_assignees_can_update"
    ON tasks FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = created_by_id OR
        auth.uid() = assigned_to_id OR
        EXISTS (
            SELECT 1 FROM profiles p1
            JOIN profiles p2 ON p1.family_id = p2.family_id
            WHERE p1.id = auth.uid()
            AND p1.role = 'parent'
            AND p2.id = tasks.assigned_to_id
        )
    )
    WITH CHECK (
        auth.uid() = created_by_id OR
        auth.uid() = assigned_to_id OR
        EXISTS (
            SELECT 1 FROM profiles p1
            JOIN profiles p2 ON p1.family_id = p2.family_id
            WHERE p1.id = auth.uid()
            AND p1.role = 'parent'
            AND p2.id = tasks.assigned_to_id
        )
    );

CREATE POLICY "tasks_creators_can_delete"
    ON tasks FOR DELETE
    TO authenticated
    USING (auth.uid() = created_by_id);

-- Pets policies
CREATE POLICY "pets_viewable_by_family_members"
    ON pets FOR SELECT
    TO authenticated
    USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "pets_authenticated_users_can_create"
    ON pets FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = owner_id AND
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "pets_family_members_can_update"
    ON pets FOR UPDATE
    TO authenticated
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

CREATE POLICY "pets_owners_can_delete"
    ON pets FOR DELETE
    TO authenticated
    USING (auth.uid() = owner_id);

-- Task comments policies
CREATE POLICY "task_comments_viewable_by_family_members"
    ON task_comments FOR SELECT
    TO authenticated
    USING (
        task_id IN (
            SELECT t.id FROM tasks t
            JOIN profiles p ON p.id = auth.uid()
            WHERE t.family_id = p.family_id
        )
    );

CREATE POLICY "task_comments_authenticated_users_can_create"
    ON task_comments FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = author_id AND
        task_id IN (
            SELECT t.id FROM tasks t
            JOIN profiles p ON p.id = auth.uid()
            WHERE t.family_id = p.family_id
        )
    );

CREATE POLICY "task_comments_authors_can_update"
    ON task_comments FOR UPDATE
    TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "task_comments_authors_can_delete"
    ON task_comments FOR DELETE
    TO authenticated
    USING (auth.uid() = author_id);

-- =====================================================
-- STORAGE BUCKETS AND POLICIES
-- =====================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    (
        'profile-images',
        'profile-images',
        true,
        5242880, -- 5MB limit
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
    ),
    (
        'task-images',
        'task-images',
        false,
        10485760, -- 10MB limit
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
    ),
    (
        'pet-images',
        'pet-images',
        true,
        5242880, -- 5MB limit
        ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
    )
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage RLS policies for profile images
CREATE POLICY "profile_images_authenticated_users_can_upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "profile_images_authenticated_users_can_view"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
    );

CREATE POLICY "profile_images_users_can_update_own"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "profile_images_users_can_delete_own"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'profile-images'
        AND auth.uid() IS NOT NULL
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "profile_images_public_viewing"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'profile-images');

-- Storage RLS policies for task images
CREATE POLICY "task_images_family_members_can_upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

CREATE POLICY "task_images_family_members_can_view"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'task-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

-- Storage RLS policies for pet images
CREATE POLICY "pet_images_family_members_can_upload"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'pet-images'
        AND auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.family_id IS NOT NULL
        )
    );

CREATE POLICY "pet_images_public_viewing"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'pet-images');

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Function to generate invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    characters TEXT := 'ACDEFHJKMNPRTUVWXY347';
    result TEXT := '';
    i INTEGER := 0;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(characters, floor(random() * length(characters) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- Extract display name from email or metadata
    DECLARE
        display_name TEXT;
        email_parts TEXT[];
    BEGIN
        -- Try to get display name from metadata first
        IF NEW.raw_user_meta_data ? 'display_name' THEN
            display_name := NEW.raw_user_meta_data->>'display_name';
        ELSE
            -- Generate from email
            email_parts := string_to_array(split_part(NEW.email, '@', 1), '.');
            display_name := initcap(email_parts[1]);
        END IF;

        -- Insert into profiles table
        INSERT INTO profiles (id, email, display_name, role, last_login_at)
        VALUES (
            NEW.id,
            NEW.email,
            display_name,
            COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'),
            NOW()
        )
        ON CONFLICT (id) DO NOTHING;

        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update pet mood based on stats
CREATE OR REPLACE FUNCTION update_pet_mood()
RETURNS TRIGGER AS $$
DECLARE
    new_mood pet_mood;
    hunger_val INTEGER;
    emotion_val INTEGER;
BEGIN
    -- Get current stats
    hunger_val := COALESCE((NEW.stats->>'hunger')::INTEGER, 100);
    emotion_val := COALESCE((NEW.stats->>'emotion')::INTEGER, NEW.happiness);

    -- Calculate mood based on hunger and emotion
    IF hunger_val <= 10 THEN
        new_mood := 'veryVeryHungry';
    ELSIF hunger_val <= 20 THEN
        new_mood := 'veryHungry';
    ELSIF hunger_val <= 30 THEN
        new_mood := 'hungry';
    ELSIF emotion_val >= 90 THEN
        new_mood := 'veryVeryHappy';
    ELSIF emotion_val >= 80 THEN
        new_mood := 'veryHappy';
    ELSIF emotion_val >= 70 THEN
        new_mood := 'happy';
    ELSIF emotion_val >= 60 THEN
        new_mood := 'content';
    ELSIF emotion_val >= 40 THEN
        new_mood := 'neutral';
    ELSIF emotion_val >= 20 THEN
        new_mood := 'sad';
    ELSE
        new_mood := 'upset';
    END IF;

    NEW.mood := new_mood;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to set invite code on family creation
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_invite_code();
        
        -- Ensure uniqueness
        WHILE EXISTS (SELECT 1 FROM families WHERE invite_code = NEW.invite_code) LOOP
            NEW.invite_code := generate_invite_code();
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to maintain family member consistency
CREATE OR REPLACE FUNCTION maintain_family_membership()
RETURNS TRIGGER AS $$
BEGIN
    -- When a user joins a family, add them to the appropriate array
    IF TG_OP = 'UPDATE' AND OLD.family_id IS DISTINCT FROM NEW.family_id THEN
        -- Remove from old family if exists
        IF OLD.family_id IS NOT NULL THEN
            IF OLD.role = 'parent' THEN
                UPDATE families 
                SET parent_ids = array_remove(parent_ids, OLD.id)
                WHERE id = OLD.family_id;
            ELSE
                UPDATE families 
                SET child_ids = array_remove(child_ids, OLD.id)
                WHERE id = OLD.family_id;
            END IF;
        END IF;
        
        -- Add to new family if exists
        IF NEW.family_id IS NOT NULL THEN
            IF NEW.role = 'parent' THEN
                UPDATE families 
                SET parent_ids = array_append(parent_ids, NEW.id)
                WHERE id = NEW.family_id
                AND NOT (NEW.id = ANY(parent_ids));
            ELSE
                UPDATE families 
                SET child_ids = array_append(child_ids, NEW.id)
                WHERE id = NEW.family_id
                AND NOT (NEW.id = ANY(child_ids));
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger for pet mood updates
DROP TRIGGER IF EXISTS trigger_update_pet_mood ON pets;
CREATE TRIGGER trigger_update_pet_mood
    BEFORE UPDATE ON pets
    FOR EACH ROW EXECUTE FUNCTION update_pet_mood();

-- Trigger for invite code generation
DROP TRIGGER IF EXISTS trigger_set_invite_code ON families;
CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW EXECUTE FUNCTION set_invite_code();

-- Trigger for family membership consistency
DROP TRIGGER IF EXISTS trigger_maintain_family_membership ON profiles;
CREATE TRIGGER trigger_maintain_family_membership
    AFTER UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION maintain_family_membership();

-- =====================================================
-- COMMENTS
-- =====================================================

-- Table comments
COMMENT ON TABLE profiles IS 'User profiles with family associations and roles';
COMMENT ON TABLE families IS 'Family groups with invite codes and member management';
COMMENT ON TABLE tasks IS 'Family task management with gamification';
COMMENT ON TABLE pets IS 'Virtual pet system with evolution and care mechanics';
COMMENT ON TABLE task_comments IS 'Comments and discussions on tasks';

-- Function comments
COMMENT ON FUNCTION generate_invite_code() IS 'Generates unique 6-character invite codes for families';
COMMENT ON FUNCTION handle_new_user() IS 'Creates profile entry when new user signs up';
COMMENT ON FUNCTION update_pet_mood() IS 'Updates pet mood based on hunger and emotion stats';
COMMENT ON FUNCTION set_invite_code() IS 'Sets unique invite code for new families';
COMMENT ON FUNCTION maintain_family_membership() IS 'Maintains consistency between profiles and family member arrays';

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- This migration recreates the complete database schema
-- All user data will need to be recreated through the app 