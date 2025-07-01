-- Migration to align database schema with domain entities
-- This fixes enum mismatches, missing columns, and ensures data consistency

-- ===== ENUM UPDATES =====

-- Update task_status enum to match domain entity
DO $$ 
BEGIN
    -- First, check if we need to update the enum
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum e 
        JOIN pg_type t ON e.enumtypid = t.oid 
        WHERE t.typname = 'task_status' 
        AND e.enumlabel = 'inProgress'
    ) THEN
        -- Add missing values
        ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'inProgress';
        ALTER TYPE task_status ADD VALUE IF NOT EXISTS 'expired';
    END IF;
END $$;

-- Update pet_mood enum to match domain entity  
DO $$
BEGIN
    -- Add missing mood values
    ALTER TYPE pet_mood ADD VALUE IF NOT EXISTS 'content';
    ALTER TYPE pet_mood ADD VALUE IF NOT EXISTS 'upset';
END $$;

-- ===== PROFILES TABLE UPDATES =====

-- Add missing columns to profiles table
DO $$
BEGIN
    -- Add last_login_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'last_login_at') THEN
        ALTER TABLE profiles ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add metadata column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'metadata') THEN
        ALTER TABLE profiles ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;

    -- Ensure display_name is not null
    UPDATE profiles SET display_name = email WHERE display_name IS NULL;
    ALTER TABLE profiles ALTER COLUMN display_name SET NOT NULL;
END $$;

-- ===== FAMILIES TABLE UPDATES =====

-- Ensure all family columns exist (some may be from previous migrations)
DO $$
BEGIN
    -- Add parent_ids array if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'parent_ids') THEN
        ALTER TABLE families ADD COLUMN parent_ids UUID[] DEFAULT '{}';
    END IF;

    -- Add child_ids array if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'child_ids') THEN
        ALTER TABLE families ADD COLUMN child_ids UUID[] DEFAULT '{}';
    END IF;

    -- Add last_activity_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'last_activity_at') THEN
        ALTER TABLE families ADD COLUMN last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add settings if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'settings') THEN
        ALTER TABLE families ADD COLUMN settings JSONB DEFAULT '{}';
    END IF;

    -- Add metadata if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'metadata') THEN
        ALTER TABLE families ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;

    -- Add pet image fields if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'pet_image_url') THEN
        ALTER TABLE families ADD COLUMN pet_image_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'families' AND column_name = 'pet_stage_images') THEN
        ALTER TABLE families ADD COLUMN pet_stage_images JSONB DEFAULT '{}';
    END IF;

    -- Rename parent_id to created_by_id if needed
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'families' AND column_name = 'parent_id') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'families' AND column_name = 'created_by_id') THEN
        ALTER TABLE families RENAME COLUMN parent_id TO created_by_id;
    END IF;
END $$;

-- ===== TASKS TABLE UPDATES =====

-- Add missing task columns  
DO $$
BEGIN
    -- Add verified_by_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'verified_by_id') THEN
        ALTER TABLE tasks ADD COLUMN verified_by_id UUID REFERENCES profiles(id);
    END IF;

    -- Add verified_at if missing  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'verified_at') THEN
        ALTER TABLE tasks ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Add image_urls array if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'image_urls') THEN
        ALTER TABLE tasks ADD COLUMN image_urls TEXT[] DEFAULT '{}';
    END IF;

    -- Add metadata if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'metadata') THEN
        ALTER TABLE tasks ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;

    -- Add is_archived if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'is_archived') THEN
        ALTER TABLE tasks ADD COLUMN is_archived BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add completed_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'completed_at') THEN
        ALTER TABLE tasks ADD COLUMN completed_at TIMESTAMP WITH TIME ZONE;
    END IF;

    -- Convert status column to use enum if it's currently text
    BEGIN
        ALTER TABLE tasks ALTER COLUMN status TYPE task_status USING status::task_status;
    EXCEPTION
        WHEN OTHERS THEN NULL; -- Already correct type
    END;

    -- Convert frequency column to use enum if it's currently text
    BEGIN
        ALTER TABLE tasks ALTER COLUMN frequency TYPE task_frequency USING frequency::task_frequency;
    EXCEPTION
        WHEN OTHERS THEN NULL; -- Already correct type
    END;

    -- Remove old single image_url and completion_note if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'tasks' AND column_name = 'image_url') THEN
        -- Migrate single image_url to image_urls array
        UPDATE tasks SET image_urls = ARRAY[image_url] WHERE image_url IS NOT NULL AND image_url != '';
        ALTER TABLE tasks DROP COLUMN image_url;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'tasks' AND column_name = 'completion_note') THEN
        ALTER TABLE tasks DROP COLUMN completion_note;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'tasks' AND column_name = 'approved_at') THEN
        -- Migrate approved_at to verified_at
        UPDATE tasks SET verified_at = approved_at WHERE approved_at IS NOT NULL;
        ALTER TABLE tasks DROP COLUMN approved_at;
    END IF;
END $$;

-- ===== PETS TABLE UPDATES =====

-- Add missing pet columns
DO $$
BEGIN
    -- Add health if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'pets' AND column_name = 'health') THEN
        ALTER TABLE pets ADD COLUMN health INTEGER DEFAULT 100 CHECK (health >= 0 AND health <= 100);
    END IF;

    -- Add last_fed_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'pets' AND column_name = 'last_fed_at') THEN
        ALTER TABLE pets ADD COLUMN last_fed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Add last_played_at if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'pets' AND column_name = 'last_played_at') THEN
        ALTER TABLE pets ADD COLUMN last_played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;

    -- Convert mood column to use enum if it's currently text
    BEGIN
        ALTER TABLE pets ALTER COLUMN mood TYPE pet_mood USING mood::pet_mood;
    EXCEPTION
        WHEN OTHERS THEN NULL; -- Already correct type
    END;

    -- Convert stage column to use enum if it's currently text
    BEGIN
        ALTER TABLE pets ALTER COLUMN stage TYPE pet_stage USING stage::pet_stage;
    EXCEPTION
        WHEN OTHERS THEN NULL; -- Already correct type
    END;

    -- Rename last_fed to last_fed_at for consistency if needed
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'pets' AND column_name = 'last_fed') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'pets' AND column_name = 'last_fed_at') THEN
        ALTER TABLE pets RENAME COLUMN last_fed TO last_fed_at;
    END IF;

    -- Rename last_interaction to last_played_at for consistency if needed
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'pets' AND column_name = 'last_interaction') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'pets' AND column_name = 'last_played_at') THEN
        ALTER TABLE pets RENAME COLUMN last_interaction TO last_played_at;
    END IF;
END $$;

-- ===== INDEXES FOR PERFORMANCE =====

-- Create additional indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_frequency ON tasks(frequency);
CREATE INDEX IF NOT EXISTS idx_tasks_verified_by_id ON tasks(verified_by_id);
CREATE INDEX IF NOT EXISTS idx_pets_stage ON pets(stage);
CREATE INDEX IF NOT EXISTS idx_pets_mood ON pets(mood);
CREATE INDEX IF NOT EXISTS idx_pets_level ON pets(level);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_tasks_family_status_due ON tasks(family_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_status_due ON tasks(assigned_to_id, status, due_date) WHERE NOT is_archived;
CREATE INDEX IF NOT EXISTS idx_pets_family_stage ON pets(family_id, stage);

-- ===== UPDATE CONSTRAINTS =====

-- Add or update constraints
DO $$
BEGIN
    -- Family invite code length constraint
    BEGIN
        ALTER TABLE families ADD CONSTRAINT families_invite_code_length_check 
        CHECK (LENGTH(invite_code) = 6);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    -- Family name length constraint
    BEGIN
        ALTER TABLE families ADD CONSTRAINT families_name_length_check 
        CHECK (LENGTH(TRIM(name)) >= 2);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    -- Task points constraint
    BEGIN
        ALTER TABLE tasks ADD CONSTRAINT tasks_points_positive_check 
        CHECK (points >= 0);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;

    -- Pet level constraint
    BEGIN
        ALTER TABLE pets ADD CONSTRAINT pets_level_positive_check 
        CHECK (level >= 1);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;
END $$;

-- ===== RLS POLICY UPDATES =====

-- Update RLS policies to handle new columns
DROP POLICY IF EXISTS "Children can update their assigned tasks" ON tasks;
CREATE POLICY "Children can update their assigned tasks"
  ON tasks FOR UPDATE
  USING (
    assigned_to_id = auth.uid()
    AND status IN ('pending', 'inProgress', 'completed')
  )
  WITH CHECK (
    assigned_to_id = auth.uid()
    AND status IN ('pending', 'inProgress', 'completed')
  );

-- Allow parents to verify tasks
DROP POLICY IF EXISTS "Parents can verify tasks" ON tasks;
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

-- Add pet update policies
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;
CREATE POLICY "Children can update their own pet"
  ON pets FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- ===== STORAGE BUCKET UPDATES =====

-- Ensure all required storage buckets exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('pet_images', 'Pet Images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('task_images', 'Task Images', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile_images', 'Profile Images', true)
ON CONFLICT (id) DO NOTHING;

-- ===== DATA MIGRATION AND CLEANUP =====

-- Update existing data to match new schema
UPDATE families SET 
    parent_ids = COALESCE(parent_ids, '{}'),
    child_ids = COALESCE(child_ids, '{}'),
    settings = COALESCE(settings, '{}'),
    metadata = COALESCE(metadata, '{}'),
    pet_stage_images = COALESCE(pet_stage_images, '{}')
WHERE parent_ids IS NULL OR child_ids IS NULL OR settings IS NULL OR metadata IS NULL OR pet_stage_images IS NULL;

UPDATE profiles SET 
    metadata = COALESCE(metadata, '{}'),
    last_login_at = COALESCE(last_login_at, created_at)
WHERE metadata IS NULL OR last_login_at IS NULL;

UPDATE tasks SET 
    image_urls = COALESCE(image_urls, '{}'),
    metadata = COALESCE(metadata, '{}'),
    is_archived = COALESCE(is_archived, FALSE)
WHERE image_urls IS NULL OR metadata IS NULL OR is_archived IS NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Schema alignment completed successfully. All domain entities now match database schema.';
END $$; 