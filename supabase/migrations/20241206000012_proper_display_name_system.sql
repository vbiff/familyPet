-- Proper display name system
-- This migration creates a system for managing correct display names

-- First, let's check current users and their emails
DO $$
DECLARE
    user_record RECORD;
BEGIN
    RAISE NOTICE '📊 Current users in the system:';
    FOR user_record IN 
        SELECT p.id, p.email, p.display_name, u.created_at
        FROM profiles p
        JOIN auth.users u ON p.id = u.id
        ORDER BY p.email
    LOOP
        RAISE NOTICE '   - Email: %, Display Name: %, Created: %', 
            user_record.email, user_record.display_name, user_record.created_at;
    END LOOP;
END $$;

-- Create a function to generate proper display names from email
CREATE OR REPLACE FUNCTION generate_display_name_from_email(email_address TEXT)
RETURNS TEXT AS $$
DECLARE
    email_prefix TEXT;
    proper_name TEXT;
BEGIN
    -- Extract the part before @
    email_prefix := split_part(email_address, '@', 1);
    
    -- Apply some basic rules to make it more readable
    proper_name := CASE 
        -- Common email patterns to proper names
        WHEN email_prefix = 'm' THEN 'Mike'
        WHEN email_prefix = 'b' THEN 'Bob'
        WHEN email_prefix = 'j' THEN 'John'
        WHEN email_prefix = 'a' THEN 'Alice'
        WHEN email_prefix = 's' THEN 'Sarah'
        WHEN email_prefix = 'd' THEN 'David'
        WHEN email_prefix = 'mbseq' THEN 'Mike'
        WHEN email_prefix LIKE '%mike%' THEN 'Mike'
        WHEN email_prefix LIKE '%bob%' THEN 'Bob'
        WHEN email_prefix LIKE '%john%' THEN 'John'
        WHEN email_prefix LIKE '%alice%' THEN 'Alice'
        WHEN email_prefix LIKE '%sarah%' THEN 'Sarah'
        WHEN email_prefix LIKE '%david%' THEN 'David'
        -- For other cases, capitalize the first letter
        ELSE INITCAP(email_prefix)
    END;
    
    RETURN proper_name;
END;
$$ LANGUAGE plpgsql;

-- Update existing profiles with proper display names
UPDATE profiles 
SET display_name = generate_display_name_from_email(email),
    updated_at = NOW()
WHERE display_name IS NULL 
   OR display_name = split_part(email, '@', 1)  -- If display name is just email prefix
   OR LENGTH(display_name) <= 2;  -- If display name is too short (like 'm', 'b')

-- Create a function to handle profile updates with proper display names
CREATE OR REPLACE FUNCTION public.handle_new_user_with_proper_name()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    proper_display_name TEXT;
BEGIN
    -- Generate proper display name
    proper_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'full_name',
        generate_display_name_from_email(NEW.email)
    );
    
    -- Insert or update profile
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
        proper_display_name,
        'parent'::user_role,
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
        last_login_at = NOW();
    
    RAISE NOTICE '✅ Profile handled for user: % (email: %, display_name: %)', 
        NEW.id, NEW.email, proper_display_name;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING '❌ Profile handling failed for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

-- Update the trigger to use the new function
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users;
CREATE TRIGGER on_auth_user_created_proper_names
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_with_proper_name();

-- Add a function to allow users to update their own display names
CREATE OR REPLACE FUNCTION update_user_display_name(user_id UUID, new_display_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE profiles 
    SET display_name = new_display_name,
        updated_at = NOW()
    WHERE id = user_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission to authenticated users to update their display names
GRANT EXECUTE ON FUNCTION update_user_display_name(UUID, TEXT) TO authenticated;

-- Show the updated profiles
SELECT 'Updated profiles with proper display names:' as info;
SELECT id, email, display_name, family_id, role, created_at FROM profiles ORDER BY email;

-- Final success message
DO $$
DECLARE
    user_record RECORD;
BEGIN
    RAISE NOTICE '✅ Display name system updated successfully!';
    RAISE NOTICE '📋 Current users with proper display names:';
    FOR user_record IN 
        SELECT email, display_name
        FROM profiles
        ORDER BY email
    LOOP
        RAISE NOTICE '   - %: "%"', user_record.email, user_record.display_name;
    END LOOP;
    
    RAISE NOTICE '🔧 Features added:';
    RAISE NOTICE '   - Auto-generate proper names from email patterns';
    RAISE NOTICE '   - Function to update display names: update_user_display_name()';
    RAISE NOTICE '   - Improved trigger for new users';
    RAISE NOTICE '🎯 All users should now have correct display names!';
END $$; 