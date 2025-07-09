-- Fix signup display name system
-- This migration ensures that display names entered during signup are properly stored and used

-- The issue is that the client-side signup doesn't pass display_name to auth metadata
-- So we need to update the trigger to work with the direct profile insertion from the client

-- Create a more robust trigger that handles both scenarios:
-- 1. When display_name is in auth metadata (future improvement)
-- 2. When display_name is inserted directly into profiles (current client behavior)

CREATE OR REPLACE FUNCTION public.handle_new_user_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    profile_exists BOOLEAN;
    display_name_from_metadata TEXT;
BEGIN
    -- Check if profile already exists
    SELECT EXISTS(SELECT 1 FROM profiles WHERE id = NEW.id) INTO profile_exists;
    
    -- Get display name from auth metadata if available
    display_name_from_metadata := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name'
    );
    
    -- Only create profile if it doesn't exist AND no display name in metadata
    -- This means the client will handle profile creation with the correct display name
    IF NOT profile_exists AND display_name_from_metadata IS NULL THEN
        -- Create a basic profile - client will update with correct display name
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
            split_part(NEW.email, '@', 1), -- Temporary display name
            'parent'::user_role,
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '🔄 Basic profile created for user: % (email: %, temp display_name: %)', 
            NEW.id, NEW.email, split_part(NEW.email, '@', 1);
    ELSIF NOT profile_exists AND display_name_from_metadata IS NOT NULL THEN
        -- Create profile with display name from metadata
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
            display_name_from_metadata,
            COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
            NOW(),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ Profile created with metadata display_name: % (email: %, display_name: %)', 
            NEW.id, NEW.email, display_name_from_metadata;
    ELSE
        -- Profile exists, just update login time
        UPDATE public.profiles 
        SET last_login_at = NOW()
        WHERE id = NEW.id;
        
        RAISE NOTICE '🔄 Profile login updated for existing user: %', NEW.id;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ Profile handling failed for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Update the trigger to use the new function
DROP TRIGGER IF EXISTS on_auth_user_created_proper_names ON auth.users;
CREATE TRIGGER on_auth_user_created_signup
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_signup();

-- Also create a function to update auth metadata with display name (for future client improvements)
CREATE OR REPLACE FUNCTION update_auth_metadata_display_name(user_id UUID, display_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- This function can be called from the client to update auth metadata
    -- Currently not used, but ready for future improvements
    UPDATE auth.users 
    SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
        jsonb_build_object('display_name', display_name)
    WHERE id = user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission to authenticated users
GRANT EXECUTE ON FUNCTION update_auth_metadata_display_name(UUID, TEXT) TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Signup display name system updated!';
    RAISE NOTICE '🔧 Features:';
    RAISE NOTICE '   - Trigger handles both metadata and direct profile insertion';
    RAISE NOTICE '   - Client can insert profiles with correct display names';
    RAISE NOTICE '   - Function available to update auth metadata: update_auth_metadata_display_name()';
    RAISE NOTICE '💡 Users will now see their entered display names during signup!';
END $$; 