-- Final fix for duplicate profiles and display names
-- This migration addresses the persistent duplicate key error and display name issues

-- First, let's check the current state
DO $$
DECLARE
    profile_count INTEGER;
    auth_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    
    RAISE NOTICE '📊 Current state:';
    RAISE NOTICE '   - Profiles: %', profile_count;
    RAISE NOTICE '   - Auth users: %', auth_count;
END $$;

-- Fix the handle_new_user trigger to properly handle existing profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    user_display_name TEXT;
    profile_exists BOOLEAN;
BEGIN
    -- Check if profile already exists
    SELECT EXISTS(SELECT 1 FROM profiles WHERE id = NEW.id) INTO profile_exists;
    
    -- Get display name with proper fallback logic
    user_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',  -- First try metadata
        NEW.raw_user_meta_data->>'name',          -- Then try 'name' field
        split_part(NEW.email, '@', 1)             -- Finally fallback to email prefix
    );
    
    IF NOT profile_exists THEN
        -- Insert new profile WITHOUT family_id assignment
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
            user_display_name,
            COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ New profile created for user: % (email: %, display_name: %)', 
            NEW.id, NEW.email, user_display_name;
    ELSE
        -- Update existing profile without causing conflicts
        UPDATE public.profiles 
        SET 
            email = NEW.email,
            display_name = CASE 
                WHEN user_display_name IS NOT NULL AND user_display_name != '' 
                THEN user_display_name 
                ELSE display_name 
            END,
            updated_at = NOW(),
            last_login_at = NOW()
        WHERE id = NEW.id;
        
        RAISE NOTICE '🔄 Existing profile updated for user: % (email: %, display_name: %)', 
            NEW.id, NEW.email, user_display_name;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth process
        RAISE WARNING '❌ Failed to handle profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Update existing profiles with correct display names from auth metadata
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE profiles 
    SET display_name = COALESCE(
        (SELECT raw_user_meta_data->>'display_name' 
         FROM auth.users 
         WHERE auth.users.id = profiles.id),
        (SELECT raw_user_meta_data->>'name' 
         FROM auth.users 
         WHERE auth.users.id = profiles.id),
        split_part(email, '@', 1)
    ),
    updated_at = NOW()
    WHERE id IN (
        SELECT p.id 
        FROM profiles p 
        JOIN auth.users u ON p.id = u.id 
        WHERE (
            u.raw_user_meta_data->>'display_name' IS NOT NULL 
            AND u.raw_user_meta_data->>'display_name' != ''
            AND u.raw_user_meta_data->>'display_name' != p.display_name
        ) OR (
            u.raw_user_meta_data->>'name' IS NOT NULL 
            AND u.raw_user_meta_data->>'name' != ''
            AND u.raw_user_meta_data->>'name' != p.display_name
        )
    );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '🔧 Updated % profile display names from auth metadata', updated_count;
END $$;

-- Ensure the trigger is properly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Final status check
DO $$
DECLARE
    profile_count INTEGER;
    auth_count INTEGER;
    orphaned_profiles INTEGER;
    orphaned_auth INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    
    SELECT COUNT(*) INTO orphaned_profiles
    FROM profiles p 
    LEFT JOIN auth.users u ON p.id = u.id 
    WHERE u.id IS NULL;
    
    SELECT COUNT(*) INTO orphaned_auth
    FROM auth.users u 
    LEFT JOIN profiles p ON u.id = p.id 
    WHERE p.id IS NULL;
    
    RAISE NOTICE '✅ Final state:';
    RAISE NOTICE '   - Profiles: %', profile_count;
    RAISE NOTICE '   - Auth users: %', auth_count;
    RAISE NOTICE '   - Orphaned profiles: %', orphaned_profiles;
    RAISE NOTICE '   - Orphaned auth users: %', orphaned_auth;
    
    IF orphaned_profiles = 0 AND orphaned_auth = 0 THEN
        RAISE NOTICE '🎉 Perfect sync! No orphaned records found.';
    END IF;
    
    RAISE NOTICE '🔧 handle_new_user trigger updated and active';
    RAISE NOTICE '💡 Duplicate key errors should now be resolved';
    RAISE NOTICE '🎯 Display names should now show correctly';
END $$; 