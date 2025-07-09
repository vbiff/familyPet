-- Emergency fix for duplicate key error
-- This migration disables the trigger temporarily and fixes the database state

-- First, disable the problematic trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Check current state
DO $$
DECLARE
    profile_count INTEGER;
    auth_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    
    RAISE NOTICE '🔍 Current state before fix:';
    RAISE NOTICE '   - Profiles: %', profile_count;
    RAISE NOTICE '   - Auth users: %', auth_count;
END $$;

-- Clean up any potential duplicate or problematic profiles
DELETE FROM profiles WHERE id NOT IN (
    SELECT DISTINCT u.id 
    FROM auth.users u
);

-- Ensure we have exactly one profile for each auth user
INSERT INTO profiles (
    id,
    email,
    display_name,
    role,
    created_at,
    updated_at,
    last_login_at
)
SELECT 
    u.id,
    u.email,
    'Mike' as display_name,  -- Set display name to Mike
    'parent'::user_role as role,
    NOW(),
    NOW(),
    NOW()
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM profiles p WHERE p.id = u.id
);

-- Update existing profiles to have correct display name
UPDATE profiles 
SET display_name = 'Mike',
    updated_at = NOW()
WHERE display_name IN ('m!', 'mbseq', 'm', 'mb') OR display_name IS NULL;

-- Create a simpler, more robust trigger
CREATE OR REPLACE FUNCTION public.handle_new_user_simple()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    -- Only insert if profile doesn't exist
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
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        ),
        'parent'::user_role,
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;  -- Simply ignore conflicts
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail auth
        RAISE WARNING 'Profile creation failed for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Create the new trigger
CREATE TRIGGER on_auth_user_created_simple
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_simple();

-- Final state check
DO $$
DECLARE
    profile_count INTEGER;
    auth_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    
    RAISE NOTICE '✅ Final state after fix:';
    RAISE NOTICE '   - Profiles: %', profile_count;
    RAISE NOTICE '   - Auth users: %', auth_count;
    RAISE NOTICE '🔧 New simplified trigger created';
    RAISE NOTICE '💡 Duplicate key errors should now be resolved';
    RAISE NOTICE '🎯 Display name set to "Mike"';
END $$;

-- Show final profiles
SELECT 'Final profiles:' as info;
SELECT id, email, display_name, family_id, role, created_at FROM profiles; 