-- Create the missing auth_method enum type
-- This is needed for PIN authentication functionality

-- Create the auth_method enum type
CREATE TYPE auth_method AS ENUM ('email', 'pin');

-- Update the profiles table to use the enum instead of TEXT with CHECK constraint
-- First, add a temporary column with the enum type
ALTER TABLE profiles ADD COLUMN auth_method_new auth_method;

-- Copy data from the old column to the new one, converting values
UPDATE profiles SET auth_method_new = 
  CASE 
    WHEN auth_method = 'email' THEN 'email'::auth_method
    WHEN auth_method = 'pin' THEN 'pin'::auth_method
    ELSE 'email'::auth_method  -- Default fallback
  END;

-- Drop the old column and rename the new one
ALTER TABLE profiles DROP COLUMN IF EXISTS auth_method;
ALTER TABLE profiles RENAME COLUMN auth_method_new TO auth_method;

-- Set default value for auth_method
ALTER TABLE profiles ALTER COLUMN auth_method SET DEFAULT 'email'::auth_method;

-- Verify the enum type exists
DO $$
BEGIN
    -- Test that we can use the auth_method enum
    PERFORM 'pin'::auth_method;
    RAISE NOTICE '✅ auth_method enum created successfully - values: email, pin';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ auth_method enum creation failed: %', SQLERRM;
END $$; 