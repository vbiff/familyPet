-- Fix display names that were incorrectly set to email prefixes
-- This migration updates profiles to use proper display names from auth metadata

-- Function to fix display names from auth metadata
CREATE OR REPLACE FUNCTION fix_display_names_from_auth()
RETURNS INTEGER AS $$
DECLARE
    user_record RECORD;
    fixed_count INTEGER := 0;
    proper_display_name TEXT;
BEGIN
    -- Loop through all profiles and check if display name needs fixing
    FOR user_record IN 
        SELECT p.id, p.email, p.display_name, u.raw_user_meta_data
        FROM profiles p
        JOIN auth.users u ON p.id = u.id
    LOOP
        -- Get the proper display name from auth metadata
        proper_display_name := user_record.raw_user_meta_data->>'display_name';
        
        -- If we have a proper display name and it's different from current one
        IF proper_display_name IS NOT NULL AND 
           proper_display_name != '' AND 
           proper_display_name != user_record.display_name THEN
            
            -- Update the profile with the correct display name
            UPDATE profiles 
            SET display_name = proper_display_name,
                updated_at = NOW()
            WHERE id = user_record.id;
            
            fixed_count := fixed_count + 1;
            
            RAISE NOTICE 'Fixed display name for user %: "%" -> "%"', 
                user_record.email, user_record.display_name, proper_display_name;
        END IF;
    END LOOP;
    
    RETURN fixed_count;
END;
$$ LANGUAGE plpgsql;

-- Run the fix function
SELECT fix_display_names_from_auth() as fixed_display_names;

-- Update the handle_new_user function to prioritize display_name from metadata
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
        NEW.raw_user_meta_data->>'display_name',  -- First try metadata
        NEW.raw_user_meta_data->>'name',          -- Then try 'name' field
        split_part(NEW.email, '@', 1)             -- Finally fallback to email prefix
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
        -- NOTE: Explicitly NOT updating family_id here
    ;
    
    RAISE NOTICE 'Profile created/updated for user: % (email: %, display_name: %)', 
        NEW.id, NEW.email, user_display_name;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth process
        RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Clean up the fix function (only needed for this migration)
DROP FUNCTION IF EXISTS fix_display_names_from_auth();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Display names have been fixed!';
    RAISE NOTICE '🔧 handle_new_user trigger updated with better display name logic';
    RAISE NOTICE '💡 Future users will get proper display names from auth metadata';
    RAISE NOTICE '🔄 Try refreshing the app - the display name should now show "Mike" instead of "mbseq"';
END $$; 