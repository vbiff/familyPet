-- Debug and fix family member data consistency
-- This migration identifies and fixes discrepancies between family member arrays and profile data

-- Function to debug family member data
CREATE OR REPLACE FUNCTION debug_family_members(target_family_id UUID)
RETURNS TABLE (
    issue_type TEXT,
    issue_description TEXT,
    family_parent_ids UUID[],
    family_child_ids UUID[],
    profiles_with_family_id UUID[],
    profiles_without_family_id UUID[]
) AS $$
DECLARE
    family_record RECORD;
    profile_record RECORD;
    all_profiles UUID[];
    profiles_in_family UUID[];
    profiles_missing_family UUID[];
BEGIN
    -- Get family data
    SELECT f.parent_ids, f.child_ids, f.name INTO family_record
    FROM families f WHERE f.id = target_family_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 
            'error'::TEXT,
            'Family not found'::TEXT,
            '{}'::UUID[],
            '{}'::UUID[],
            '{}'::UUID[],
            '{}'::UUID[];
        RETURN;
    END IF;
    
    -- Get all profiles that should be in this family (from family arrays)
    all_profiles := COALESCE(family_record.parent_ids, '{}') || COALESCE(family_record.child_ids, '{}');
    
    -- Get all profiles that have this family_id set
    SELECT array_agg(p.id) INTO profiles_in_family
    FROM profiles p 
    WHERE p.family_id = target_family_id;
    
    -- Get profiles that are in family arrays but don't have family_id set
    SELECT array_agg(p.id) INTO profiles_missing_family
    FROM profiles p 
    WHERE p.id = ANY(all_profiles) AND (p.family_id IS NULL OR p.family_id != target_family_id);
    
    -- Return diagnostic information
    RETURN QUERY SELECT 
        'diagnostic'::TEXT,
        format('Family "%s" - Parent IDs: %s, Child IDs: %s, Profiles with family_id: %s, Missing family_id: %s',
            family_record.name,
            COALESCE(family_record.parent_ids::TEXT, 'none'),
            COALESCE(family_record.child_ids::TEXT, 'none'),
            COALESCE(profiles_in_family::TEXT, 'none'),
            COALESCE(profiles_missing_family::TEXT, 'none')
        ),
        COALESCE(family_record.parent_ids, '{}'),
        COALESCE(family_record.child_ids, '{}'),
        COALESCE(profiles_in_family, '{}'),
        COALESCE(profiles_missing_family, '{}');
END;
$$ LANGUAGE plpgsql;

-- Function to fix family member inconsistencies
CREATE OR REPLACE FUNCTION fix_family_member_consistency(target_family_id UUID)
RETURNS TEXT AS $$
DECLARE
    family_record RECORD;
    profile_record RECORD;
    all_family_members UUID[];
    parent_members UUID[];
    child_members UUID[];
    fixed_count INTEGER := 0;
BEGIN
    -- Get family data
    SELECT f.parent_ids, f.child_ids, f.name INTO family_record
    FROM families f WHERE f.id = target_family_id;
    
    IF NOT FOUND THEN
        RETURN 'ERROR: Family not found';
    END IF;
    
    -- Get all members from family arrays
    all_family_members := COALESCE(family_record.parent_ids, '{}') || COALESCE(family_record.child_ids, '{}');
    
    -- Fix profiles that should have family_id but don't
    FOR profile_record IN 
        SELECT p.id, p.display_name, p.role
        FROM profiles p 
        WHERE p.id = ANY(all_family_members) 
        AND (p.family_id IS NULL OR p.family_id != target_family_id)
    LOOP
        UPDATE profiles 
        SET family_id = target_family_id
        WHERE id = profile_record.id;
        
        fixed_count := fixed_count + 1;
        RAISE NOTICE 'Fixed profile % (%) - set family_id to %', 
            profile_record.display_name, profile_record.id, target_family_id;
    END LOOP;
    
    -- Rebuild family member arrays from current profile data
    SELECT array_agg(p.id) INTO parent_members
    FROM profiles p 
    WHERE p.family_id = target_family_id AND p.role = 'parent';
    
    SELECT array_agg(p.id) INTO child_members
    FROM profiles p 
    WHERE p.family_id = target_family_id AND p.role = 'child';
    
    -- Update family with correct member arrays
    UPDATE families 
    SET 
        parent_ids = COALESCE(parent_members, '{}'),
        child_ids = COALESCE(child_members, '{}'),
        updated_at = NOW()
    WHERE id = target_family_id;
    
    RETURN format('Fixed %s profiles. Updated family arrays: parents=%s, children=%s',
        fixed_count,
        COALESCE(parent_members::TEXT, 'none'),
        COALESCE(child_members::TEXT, 'none')
    );
END;
$$ LANGUAGE plpgsql;

-- Debug the specific family from the logs
DO $$
DECLARE
    target_family UUID := '3279a758-2733-4d93-b0e8-e03399420b7a';
    debug_result RECORD;
    fix_result TEXT;
BEGIN
    RAISE NOTICE '🔍 DEBUGGING FAMILY MEMBER CONSISTENCY';
    RAISE NOTICE '=====================================';
    
    -- Run diagnostic
    FOR debug_result IN SELECT * FROM debug_family_members(target_family) LOOP
        RAISE NOTICE '📊 %: %', debug_result.issue_type, debug_result.issue_description;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '🛠️ FIXING INCONSISTENCIES';
    RAISE NOTICE '========================';
    
    -- Apply fix
    SELECT fix_family_member_consistency(target_family) INTO fix_result;
    RAISE NOTICE '✅ %', fix_result;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔍 POST-FIX VERIFICATION';
    RAISE NOTICE '=======================';
    
    -- Verify fix
    FOR debug_result IN SELECT * FROM debug_family_members(target_family) LOOP
        RAISE NOTICE '📊 %: %', debug_result.issue_type, debug_result.issue_description;
    END LOOP;
END $$; 