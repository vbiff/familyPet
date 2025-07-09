-- Final fix for auth signup issue
-- Remove the auth trigger that's causing conflicts with client-side profile creation

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop the function if it exists
DROP FUNCTION IF EXISTS handle_new_user(); 