-- Fix new user family assignment issue
-- This script diagnoses and fixes the problem where new users are automatically assigned to existing families

-- First, let's check the current state
DO $$
DECLARE
    user_count INTEGER;
    family_count INTEGER;
    users_with_families INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM profiles;
    SELECT COUNT(*) INTO family_count FROM families;
    SELECT COUNT(*) INTO users_with_families FROM profiles WHERE family_id IS NOT NULL;
    
    RAISE NOTICE '=== CURRENT STATE ===';
    RAISE NOTICE 'Total users: %', user_count;
    RAISE NOTICE 'Total families: %', family_count;
    RAISE NOTICE 'Users with families: %', users_with_families;
    RAISE NOTICE '';
END $$;

-- Check if there are any users incorrectly assigned to families
DO $$
DECLARE
    incorrect_assignments INTEGER;
    rec RECORD;
BEGIN
    -- Find users who have family_id but are not in the family's member arrays
    SELECT COUNT(*) INTO incorrect_assignments
    FROM profiles p
    JOIN families f ON p.family_id = f.id
    WHERE p.id != f.created_by_id 
      AND p.id != ALL(COALESCE(f.parent_ids, '{}')) 
      AND p.id != ALL(COALESCE(f.child_ids, '{}'));
    
    IF incorrect_assignments > 0 THEN
        RAISE NOTICE '=== FOUND % INCORRECT FAMILY ASSIGNMENTS ===', incorrect_assignments;
        
        -- Show the incorrect assignments
        FOR rec IN 
            SELECT p.id, p.display_name, p.email, f.name as family_name
            FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE p.id != f.created_by_id 
              AND p.id != ALL(COALESCE(f.parent_ids, '{}')) 
              AND p.id != ALL(COALESCE(f.child_ids, '{}'))
        LOOP
            RAISE NOTICE 'User % (%) incorrectly assigned to family "%"', 
                rec.display_name, rec.email, rec.family_name;
        END LOOP;
        
        -- Fix the incorrect assignments
        UPDATE profiles 
        SET family_id = NULL, updated_at = NOW()
        WHERE id IN (
            SELECT p.id
            FROM profiles p
            JOIN families f ON p.family_id = f.id
            WHERE p.id != f.created_by_id 
              AND p.id != ALL(COALESCE(f.parent_ids, '{}')) 
              AND p.id != ALL(COALESCE(f.child_ids, '{}'))
        );
        
        RAISE NOTICE 'Fixed % incorrect family assignments', incorrect_assignments;
    ELSE
        RAISE NOTICE 'No incorrect family assignments found';
    END IF;
END $$;

-- Update the handle_new_user function to ensure it NEVER assigns family_id
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    user_display_name TEXT;
BEGIN
    -- Get display name with proper fallback logic
    user_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );
    
    -- Insert new profile WITHOUT family_id assignment
    INSERT INTO public.profiles (
        id,
        email,
        display_name,
        role,
        created_at,
        updated_at,
        last_login_at
        -- NOTE: Explicitly NOT setting family_id - it should remain NULL
    )
    VALUES (
        NEW.id,
        NEW.email,
        user_display_name,
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = CASE 
            WHEN EXCLUDED.display_name IS NOT NULL AND EXCLUDED.display_name != '' 
            THEN EXCLUDED.display_name 
            ELSE profiles.display_name 
        END,
        updated_at = NOW(),
        last_login_at = NOW()
        -- NOTE: Explicitly NOT updating family_id - preserve existing value
    ;
    
    RAISE NOTICE '✅ Profile created/updated for user: % (email: %, display_name: %, family_id: NULL)', 
        NEW.id, NEW.email, user_display_name;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ Failed to create profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Check final state
DO $$
DECLARE
    user_count INTEGER;
    family_count INTEGER;
    users_with_families INTEGER;
    users_without_families INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM profiles;
    SELECT COUNT(*) INTO family_count FROM families;
    SELECT COUNT(*) INTO users_with_families FROM profiles WHERE family_id IS NOT NULL;
    SELECT COUNT(*) INTO users_without_families FROM profiles WHERE family_id IS NULL;
    
    RAISE NOTICE '=== FINAL STATE ===';
    RAISE NOTICE 'Total users: %', user_count;
    RAISE NOTICE 'Total families: %', family_count;
    RAISE NOTICE 'Users with families: %', users_with_families;
    RAISE NOTICE 'Users without families: %', users_without_families;
    RAISE NOTICE '';
    RAISE NOTICE '✅ New user family assignment issue should now be fixed';
    RAISE NOTICE '✅ New users will not be automatically assigned to existing families';
END $$; 