-- Remove auth trigger to prevent conflicts with client-side profile creation
-- The client will handle profile creation directly

-- Drop the trigger that's causing conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop the function as well since we're not using it
DROP FUNCTION IF EXISTS handle_new_user(); 