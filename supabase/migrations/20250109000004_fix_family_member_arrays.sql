-- Fix family member arrays to ensure all family members are properly included
-- This fixes the issue where users join families but aren't added to parent_ids/child_ids arrays

-- Function to sync family member arrays with profile data
CREATE OR REPLACE FUNCTION sync_family_member_arrays()
RETURNS void AS $$
DECLARE
    family_record RECORD;
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Loop through all families
    FOR family_record IN SELECT id, name FROM families LOOP
        -- Get all parents for this family
        SELECT array_agg(p.id) INTO new_parent_ids
        FROM profiles p
        WHERE p.family_id = family_record.id AND p.role = 'parent';
        
        -- Get all children for this family
        SELECT array_agg(p.id) INTO new_child_ids
        FROM profiles p
        WHERE p.family_id = family_record.id AND p.role = 'child';
        
        -- Handle null arrays
        new_parent_ids := COALESCE(new_parent_ids, '{}');
        new_child_ids := COALESCE(new_child_ids, '{}');
        
        -- Update the family with correct member arrays
        UPDATE families 
        SET 
            parent_ids = new_parent_ids,
            child_ids = new_child_ids,
            updated_at = NOW()
        WHERE id = family_record.id;
        
        RAISE NOTICE 'Updated family "%" with % parents and % children', 
            family_record.name, 
            array_length(new_parent_ids, 1), 
            array_length(new_child_ids, 1);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Run the sync function
SELECT sync_family_member_arrays();

-- Create a trigger to automatically maintain family member arrays
CREATE OR REPLACE FUNCTION maintain_family_member_arrays()
RETURNS TRIGGER AS $$
DECLARE
    target_family_id UUID;
    new_parent_ids UUID[];
    new_child_ids UUID[];
BEGIN
    -- Determine which family to update
    IF TG_OP = 'DELETE' THEN
        target_family_id := OLD.family_id;
    ELSE
        target_family_id := NEW.family_id;
    END IF;
    
    -- Skip if no family_id
    IF target_family_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Get current parents and children for this family
    SELECT array_agg(p.id) INTO new_parent_ids
    FROM profiles p
    WHERE p.family_id = target_family_id AND p.role = 'parent';
    
    SELECT array_agg(p.id) INTO new_child_ids
    FROM profiles p
    WHERE p.family_id = target_family_id AND p.role = 'child';
    
    -- Handle null arrays
    new_parent_ids := COALESCE(new_parent_ids, '{}');
    new_child_ids := COALESCE(new_child_ids, '{}');
    
    -- Update the family
    UPDATE families 
    SET 
        parent_ids = new_parent_ids,
        child_ids = new_child_ids,
        updated_at = NOW()
    WHERE id = target_family_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_maintain_family_member_arrays ON profiles;

-- Create trigger to automatically sync family arrays when profiles change
CREATE TRIGGER trigger_maintain_family_member_arrays
    AFTER INSERT OR UPDATE OR DELETE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION maintain_family_member_arrays();

-- Show results
DO $$
DECLARE
    family_info RECORD;
BEGIN
    RAISE NOTICE '✅ Family member arrays have been synchronized!';
    RAISE NOTICE '📊 Current family status:';
    
    FOR family_info IN 
        SELECT 
            f.name,
            f.invite_code,
            array_length(f.parent_ids, 1) as parent_count,
            array_length(f.child_ids, 1) as child_count,
            f.parent_ids,
            f.child_ids
        FROM families f
        ORDER BY f.name
    LOOP
        RAISE NOTICE '   Family: % (Code: %) - Parents: %, Children: %', 
            family_info.name, 
            family_info.invite_code,
            COALESCE(family_info.parent_count, 0),
            COALESCE(family_info.child_count, 0);
    END LOOP;
    
    RAISE NOTICE '🔧 Auto-sync trigger installed for future changes';
    RAISE NOTICE '💡 Family members should now appear correctly in the app!';
END $$; 