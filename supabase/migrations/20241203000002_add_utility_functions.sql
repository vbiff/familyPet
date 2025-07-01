-- Add utility functions and triggers for application logic

-- ===== PET CARE FUNCTIONS =====

-- Function to calculate pet mood based on stats and care
CREATE OR REPLACE FUNCTION calculate_pet_mood(
    health_val INTEGER,
    happiness_val INTEGER,
    energy_val INTEGER,
    last_fed_at_val TIMESTAMP WITH TIME ZONE,
    last_played_at_val TIMESTAMP WITH TIME ZONE
) RETURNS pet_mood AS $$
DECLARE
    hours_since_fed INTEGER;
    hours_since_played INTEGER;
    mood_score INTEGER;
BEGIN
    -- Calculate hours since last care
    hours_since_fed := EXTRACT(EPOCH FROM (NOW() - last_fed_at_val)) / 3600;
    hours_since_played := EXTRACT(EPOCH FROM (NOW() - last_played_at_val)) / 3600;
    
    -- Base mood score from stats
    mood_score := (health_val + happiness_val + energy_val) / 3;
    
    -- Adjust for neglect
    IF hours_since_fed > 12 THEN
        mood_score := mood_score - 20;
    ELSIF hours_since_fed > 6 THEN
        mood_score := mood_score - 10;
    END IF;
    
    IF hours_since_played > 18 THEN
        mood_score := mood_score - 15;
    ELSIF hours_since_played > 8 THEN
        mood_score := mood_score - 5;
    END IF;
    
    -- Return mood based on score
    IF mood_score >= 85 THEN
        RETURN 'happy'::pet_mood;
    ELSIF mood_score >= 70 THEN
        RETURN 'content'::pet_mood;
    ELSIF mood_score >= 40 THEN
        RETURN 'neutral'::pet_mood;
    ELSIF mood_score >= 20 THEN
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

-- ===== TASK MANAGEMENT FUNCTIONS =====

-- Function to calculate user task completion stats
CREATE OR REPLACE FUNCTION get_user_task_stats(user_id UUID)
RETURNS TABLE (
    total_tasks INTEGER,
    completed_tasks INTEGER,
    pending_tasks INTEGER,
    overdue_tasks INTEGER,
    total_points_earned INTEGER,
    completion_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_tasks,
        COUNT(CASE WHEN status = 'completed' AND verified_by_id IS NOT NULL THEN 1 END)::INTEGER as completed_tasks,
        COUNT(CASE WHEN status = 'pending' THEN 1 END)::INTEGER as pending_tasks,
        COUNT(CASE WHEN due_date < NOW() AND status != 'completed' THEN 1 END)::INTEGER as overdue_tasks,
        COALESCE(SUM(CASE WHEN status = 'completed' AND verified_by_id IS NOT NULL THEN points ELSE 0 END), 0)::INTEGER as total_points_earned,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((COUNT(CASE WHEN status = 'completed' AND verified_by_id IS NOT NULL THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
            ELSE 0 
        END as completion_rate
    FROM tasks 
    WHERE assigned_to_id = user_id AND NOT is_archived;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-archive expired tasks
CREATE OR REPLACE FUNCTION archive_expired_tasks()
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
BEGIN
    UPDATE tasks 
    SET 
        is_archived = TRUE,
        status = 'expired',
        updated_at = NOW()
    WHERE 
        due_date < NOW() - INTERVAL '7 days'
        AND status IN ('pending', 'inProgress')
        AND NOT is_archived;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ===== FAMILY MANAGEMENT FUNCTIONS =====

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

-- ===== TRIGGERS =====

-- Trigger to auto-update pet mood when stats change
CREATE OR REPLACE FUNCTION update_pet_mood_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.mood := calculate_pet_mood(
        NEW.health,
        NEW.happiness,
        NEW.energy,
        NEW.last_fed_at,
        NEW.last_played_at
    );
    
    -- Auto-evolve if possible
    IF can_pet_evolve(NEW.id) THEN
        NEW.stage := evolve_pet(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for pet mood updates
DROP TRIGGER IF EXISTS trigger_update_pet_mood ON pets;
CREATE TRIGGER trigger_update_pet_mood
    BEFORE UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_pet_mood_trigger();

-- Trigger to update family activity when members perform actions
CREATE OR REPLACE FUNCTION update_family_activity_trigger()
RETURNS TRIGGER AS $$
DECLARE
    user_family_id UUID;
BEGIN
    -- Get family ID from user profile
    SELECT family_id INTO user_family_id
    FROM profiles 
    WHERE id = COALESCE(NEW.assigned_to_id, NEW.created_by_id, NEW.owner_id, OLD.assigned_to_id, OLD.created_by_id, OLD.owner_id);
    
    -- Update family activity timestamp
    IF user_family_id IS NOT NULL THEN
        UPDATE families 
        SET last_activity_at = NOW()
        WHERE id = user_family_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers for family activity updates
DROP TRIGGER IF EXISTS trigger_family_activity_tasks ON tasks;
CREATE TRIGGER trigger_family_activity_tasks
    AFTER INSERT OR UPDATE OR DELETE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_family_activity_trigger();

DROP TRIGGER IF EXISTS trigger_family_activity_pets ON pets;
CREATE TRIGGER trigger_family_activity_pets
    AFTER INSERT OR UPDATE ON pets
    FOR EACH ROW
    EXECUTE FUNCTION update_family_activity_trigger();

-- ===== SCHEDULED FUNCTIONS =====

-- Function to run daily maintenance tasks
CREATE OR REPLACE FUNCTION daily_maintenance()
RETURNS TEXT AS $$
DECLARE
    archived_tasks INTEGER;
    updated_pets INTEGER;
BEGIN
    -- Archive old expired tasks
    archived_tasks := archive_expired_tasks();
    
    -- Update pet stats based on neglect
    UPDATE pets 
    SET 
        happiness = GREATEST(0, happiness - 5),
        energy = GREATEST(0, energy - 10),
        health = CASE 
            WHEN EXTRACT(EPOCH FROM (NOW() - last_fed_at)) / 3600 > 24 THEN GREATEST(0, health - 15)
            WHEN EXTRACT(EPOCH FROM (NOW() - last_fed_at)) / 3600 > 12 THEN GREATEST(0, health - 5)
            ELSE health
        END,
        updated_at = NOW()
    WHERE 
        EXTRACT(EPOCH FROM (NOW() - last_fed_at)) / 3600 > 6
        OR EXTRACT(EPOCH FROM (NOW() - last_played_at)) / 3600 > 8;
    
    GET DIAGNOSTICS updated_pets = ROW_COUNT;
    
    RETURN FORMAT('Daily maintenance completed. Archived %s tasks, updated %s pets.', archived_tasks, updated_pets);
END;
$$ LANGUAGE plpgsql;

-- ===== SECURITY FUNCTIONS =====

-- Function to check if user can access family data
CREATE OR REPLACE FUNCTION user_can_access_family(user_id UUID, family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM families f
        WHERE f.id = family_id
        AND (
            f.created_by_id = user_id
            OR user_id = ANY(f.parent_ids)
            OR user_id = ANY(f.child_ids)
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Function to check if user is family parent
CREATE OR REPLACE FUNCTION user_is_family_parent(user_id UUID, family_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM families f
        WHERE f.id = family_id
        AND (f.created_by_id = user_id OR user_id = ANY(f.parent_ids))
    );
END;
$$ LANGUAGE plpgsql;

-- ===== HELPFUL VIEWS =====

-- View for family member details
CREATE OR REPLACE VIEW family_member_details AS
SELECT 
    f.id as family_id,
    f.name as family_name,
    p.id as member_id,
    p.display_name as member_name,
    p.role as member_role,
    p.avatar_url,
    p.created_at as joined_at,
    CASE 
        WHEN p.id = f.created_by_id THEN true
        WHEN p.role = 'parent' AND p.id = ANY(f.parent_ids) THEN true
        ELSE false
    END as is_parent,
    (SELECT COUNT(*) FROM tasks t WHERE t.assigned_to_id = p.id AND NOT t.is_archived) as active_tasks,
    (SELECT COUNT(*) FROM tasks t WHERE t.assigned_to_id = p.id AND t.status = 'completed' AND t.verified_by_id IS NOT NULL) as completed_tasks
FROM families f
CROSS JOIN profiles p
WHERE p.family_id = f.id;

-- View for pet details with family info
CREATE OR REPLACE VIEW pet_family_details AS
SELECT 
    pet.id as pet_id,
    pet.name as pet_name,
    pet.stage,
    pet.mood,
    pet.experience,
    pet.level,
    pet.health,
    pet.happiness,
    pet.energy,
    pet.last_fed_at,
    pet.last_played_at,
    pet.created_at,
    f.id as family_id,
    f.name as family_name,
    owner.display_name as owner_name,
    can_pet_evolve(pet.id) as can_evolve
FROM pets pet
JOIN families f ON pet.family_id = f.id
JOIN profiles owner ON pet.owner_id = owner.id;

-- ===== GRANT PERMISSIONS =====

-- Grant execute permissions on functions to authenticated users
GRANT EXECUTE ON FUNCTION calculate_pet_mood(INTEGER, INTEGER, INTEGER, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) TO authenticated;
GRANT EXECUTE ON FUNCTION can_pet_evolve(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION evolve_pet(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_task_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_family_member(UUID, UUID, user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_family_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_can_access_family(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION user_is_family_parent(UUID, UUID) TO authenticated;

-- Grant select permissions on views
GRANT SELECT ON family_member_details TO authenticated;
GRANT SELECT ON pet_family_details TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION calculate_pet_mood(INTEGER, INTEGER, INTEGER, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE) IS 'Calculates pet mood based on stats and care history';
COMMENT ON FUNCTION can_pet_evolve(UUID) IS 'Checks if pet has enough experience to evolve to next stage';
COMMENT ON FUNCTION evolve_pet(UUID) IS 'Evolves pet to next stage if possible and returns new stage';
COMMENT ON FUNCTION get_user_task_stats(UUID) IS 'Returns comprehensive task completion statistics for a user';
COMMENT ON FUNCTION add_family_member(UUID, UUID, user_role) IS 'Adds a user to a family with specified role';
COMMENT ON FUNCTION remove_family_member(UUID, UUID) IS 'Removes a user from a family';
COMMENT ON FUNCTION daily_maintenance() IS 'Performs daily maintenance tasks like archiving expired tasks and updating neglected pets';
COMMENT ON VIEW family_member_details IS 'Detailed view of family members with task statistics';
COMMENT ON VIEW pet_family_details IS 'Detailed view of pets with family and owner information';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Utility functions and triggers created successfully. Application logic support added.';
END $$; 