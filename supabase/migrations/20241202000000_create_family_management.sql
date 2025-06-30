-- Create families table if it doesn't exist, or add missing columns
DO $$ 
BEGIN
    -- Create table if it doesn't exist
    CREATE TABLE IF NOT EXISTS families (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(50) NOT NULL,
        invite_code VARCHAR(6) NOT NULL UNIQUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Add missing columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'created_by_id') THEN
        ALTER TABLE families ADD COLUMN created_by_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'parent_ids') THEN
        ALTER TABLE families ADD COLUMN parent_ids UUID[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'families' AND column_name = 'child_ids') THEN
        ALTER TABLE families ADD COLUMN child_ids UUID[] DEFAULT '{}';
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
    
    -- Fix existing data before adding constraints
    -- Update any invalid invite codes to be 6 characters
    UPDATE families SET invite_code = UPPER(SUBSTR(MD5(RANDOM()::TEXT), 1, 6)) 
    WHERE LENGTH(invite_code) != 6;
    
    -- Add constraints if they don't exist
    BEGIN
        ALTER TABLE families ADD CONSTRAINT families_name_length_check CHECK (LENGTH(TRIM(name)) >= 2);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE families ADD CONSTRAINT families_invite_code_length_check CHECK (LENGTH(invite_code) = 6);
    EXCEPTION
        WHEN duplicate_object THEN NULL;
    END;
END $$;

-- Add family_id to profiles table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'family_id') THEN
        ALTER TABLE profiles ADD COLUMN family_id UUID REFERENCES families(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_families_invite_code ON families(invite_code);
CREATE INDEX IF NOT EXISTS idx_families_created_by_id ON families(created_by_id);
CREATE INDEX IF NOT EXISTS idx_families_created_at ON families(created_at);
CREATE INDEX IF NOT EXISTS idx_profiles_family_id ON profiles(family_id);

-- Create function to get member task statistics
CREATE OR REPLACE FUNCTION get_member_task_stats(member_id UUID)
RETURNS TABLE (
    tasks_completed INT,
    total_points INT,
    current_streak INT,
    last_task_completed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(COUNT(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN 1 END)::INT, 0) as tasks_completed,
        COALESCE(SUM(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.points ELSE 0 END)::INT, 0) as total_points,
        COALESCE(calculate_current_streak(member_id), 0) as current_streak,
        MAX(CASE WHEN t.status = 'completed' AND t.verified_by_id IS NOT NULL THEN t.verified_at END) as last_task_completed_at
    FROM tasks t
    WHERE t.assigned_to_id = member_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate current streak
CREATE OR REPLACE FUNCTION calculate_current_streak(user_id UUID)
RETURNS INT AS $$
DECLARE
    streak_count INT := 0;
    current_date DATE := CURRENT_DATE;
    check_date DATE;
BEGIN
    -- Start from today and go backwards
    check_date := current_date;
    
    -- Loop through days and check for completed tasks
    LOOP
        -- Check if user completed any task on this date
        IF EXISTS (
            SELECT 1 FROM tasks t
            WHERE t.assigned_to_id = user_id
            AND t.status = 'completed'
            AND t.verified_by_id IS NOT NULL
            AND DATE(t.verified_at) = check_date
        ) THEN
            streak_count := streak_count + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSE
            -- If it's today and no tasks completed, streak is 0
            -- If it's any other day, break the loop
            IF check_date = current_date THEN
                streak_count := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Safety break to avoid infinite loop (max 365 days)
        IF streak_count >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN streak_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to automatically update last_activity_at
CREATE OR REPLACE FUNCTION update_family_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE families 
    SET last_activity_at = NOW()
    WHERE id = (
        SELECT family_id FROM profiles 
        WHERE id = COALESCE(NEW.assigned_to_id, NEW.created_by_id, OLD.assigned_to_id, OLD.created_by_id)
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update family activity when tasks are modified
CREATE TRIGGER trigger_update_family_activity
    AFTER INSERT OR UPDATE OR DELETE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_family_activity();

-- Enable Row Level Security on families table
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for families table
CREATE POLICY "Users can view their own family" ON families
    FOR SELECT USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids) OR
        auth.uid() = ANY(child_ids)
    );

CREATE POLICY "Users can create families" ON families
    FOR INSERT WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Family creators and parents can update families" ON families
    FOR UPDATE USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids)
    );

CREATE POLICY "Only family creators can delete families" ON families
    FOR DELETE USING (auth.uid() = created_by_id);

-- Update RLS policy for profiles to allow family members to view each other
DROP POLICY IF EXISTS "Users can view family members" ON profiles;
CREATE POLICY "Users can view family members" ON profiles
    FOR SELECT USING (
        auth.uid() = id OR
        (family_id IS NOT NULL AND family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        ))
    );

-- Create function to generate unique invite code
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

-- Create trigger to auto-generate invite code
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_unique_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- Insert some helpful comments
COMMENT ON TABLE families IS 'Stores family information and member relationships';
COMMENT ON COLUMN families.invite_code IS 'Unique 6-character code for inviting family members';
COMMENT ON COLUMN families.parent_ids IS 'Array of user IDs who are parents in this family';
COMMENT ON COLUMN families.child_ids IS 'Array of user IDs who are children in this family';
COMMENT ON FUNCTION get_member_task_stats(UUID) IS 'Returns task completion statistics for a family member';
COMMENT ON FUNCTION calculate_current_streak(UUID) IS 'Calculates the current daily task completion streak for a user'; 