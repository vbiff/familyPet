-- Execute this SQL in the Supabase dashboard SQL editor to fix the auth trigger issue

-- Remove the auth trigger that's causing conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Remove the function as well
DROP FUNCTION IF EXISTS handle_new_user();

-- Verify the trigger is gone
SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass; 