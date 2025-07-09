-- Fix auth trigger conflict
-- This migration ensures the auth trigger doesn't conflict with client-side profile creation

-- Drop the existing trigger that might be causing conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Update the handle_new_user function to be more robust
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    -- Only create profile if it doesn't already exist
    -- This prevents conflicts with client-side profile creation
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.id) THEN
        DECLARE
            display_name TEXT;
            email_parts TEXT[];
        BEGIN
            -- Try to get display name from metadata first
            IF NEW.raw_user_meta_data ? 'display_name' THEN
                display_name := NEW.raw_user_meta_data->>'display_name';
            ELSE
                -- Generate from email
                email_parts := string_to_array(split_part(NEW.email, '@', 1), '.');
                display_name := initcap(email_parts[1]);
            END IF;

            -- Insert into profiles table with ON CONFLICT DO NOTHING for safety
            INSERT INTO profiles (id, email, display_name, role, last_login_at)
            VALUES (
                NEW.id,
                NEW.email,
                display_name,
                COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'parent'),
                NOW()
            )
            ON CONFLICT (id) DO NOTHING;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Alternative approach: Remove the trigger entirely and let client handle profile creation
-- This is commented out but can be used if the above doesn't work
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS handle_new_user(); 