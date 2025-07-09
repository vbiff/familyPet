-- Sync existing auth users with profiles table
-- This ensures any auth users without profiles get them created

-- Function to sync existing auth users with profiles
CREATE OR REPLACE FUNCTION sync_auth_users_with_profiles()
RETURNS INTEGER AS $$
DECLARE
    auth_user RECORD;
    created_count INTEGER := 0;
BEGIN
    -- Loop through all auth users who don't have profiles
    FOR auth_user IN 
        SELECT u.id, u.email, u.raw_user_meta_data, u.created_at
        FROM auth.users u
        LEFT JOIN profiles p ON u.id = p.id
        WHERE p.id IS NULL
    LOOP
        -- Create profile for this auth user
        INSERT INTO profiles (
            id,
            email,
            display_name,
            role,
            created_at,
            updated_at,
            last_login_at
        )
        VALUES (
            auth_user.id,
            auth_user.email,
            COALESCE(auth_user.raw_user_meta_data->>'display_name', split_part(auth_user.email, '@', 1)),
            COALESCE((auth_user.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
            COALESCE(auth_user.created_at, NOW()),
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
            updated_at = NOW(),
            last_login_at = NOW();
        
        created_count := created_count + 1;
        
        RAISE NOTICE 'Created/updated profile for user: % (email: %)', auth_user.id, auth_user.email;
    END LOOP;
    
    RETURN created_count;
END;
$$ LANGUAGE plpgsql;

-- Run the sync function
SELECT sync_auth_users_with_profiles() as synced_users;

-- Update the handle_new_user function to be more robust
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
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
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'::user_role),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
        updated_at = NOW(),
        last_login_at = NOW()
        -- NOTE: Explicitly NOT updating family_id here
    ;
    
    RAISE NOTICE 'Profile created/updated for user: % (email: %)', NEW.id, NEW.email;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth process
        RAISE WARNING 'Failed to create profile for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Ensure the trigger is properly set up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create a function to check auth/profile sync status
CREATE OR REPLACE FUNCTION check_auth_profile_sync()
RETURNS TABLE (
    total_auth_users INTEGER,
    total_profiles INTEGER,
    orphaned_auth_users INTEGER,
    orphaned_profiles INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM auth.users) as total_auth_users,
        (SELECT COUNT(*)::INTEGER FROM profiles) as total_profiles,
        (SELECT COUNT(*)::INTEGER FROM auth.users u LEFT JOIN profiles p ON u.id = p.id WHERE p.id IS NULL) as orphaned_auth_users,
        (SELECT COUNT(*)::INTEGER FROM profiles p LEFT JOIN auth.users u ON p.id = u.id WHERE u.id IS NULL) as orphaned_profiles;
END;
$$ LANGUAGE plpgsql;

-- Show sync status
SELECT * FROM check_auth_profile_sync();

-- Clean up the sync function (it's only needed for this migration)
DROP FUNCTION IF EXISTS sync_auth_users_with_profiles();

-- Success message
DO $$
DECLARE
    sync_status RECORD;
BEGIN
    SELECT * INTO sync_status FROM check_auth_profile_sync();
    
    RAISE NOTICE '🔄 Auth users and profiles synchronized!';
    RAISE NOTICE '📊 Sync Status:';
    RAISE NOTICE '  - Total auth users: %', sync_status.total_auth_users;
    RAISE NOTICE '  - Total profiles: %', sync_status.total_profiles;
    RAISE NOTICE '  - Orphaned auth users: %', sync_status.orphaned_auth_users;
    RAISE NOTICE '  - Orphaned profiles: %', sync_status.orphaned_profiles;
    
    IF sync_status.orphaned_auth_users = 0 AND sync_status.orphaned_profiles = 0 THEN
        RAISE NOTICE '✅ Perfect sync! All auth users have profiles and vice versa';
    ELSE
        RAISE NOTICE '⚠️  Some inconsistencies remain - check the data manually';
    END IF;
    
    RAISE NOTICE '🔧 handle_new_user trigger updated and active';
    RAISE NOTICE '💡 Existing users should now have proper profiles without family assignments';
END $$; 