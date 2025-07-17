-- Fix verify_pin function to bypass RLS policies
-- This function also needs SECURITY DEFINER to read profiles table

CREATE OR REPLACE FUNCTION verify_pin(
    user_id UUID,
    pin_text TEXT
)
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    stored_hash TEXT;
    stored_salt TEXT;
    computed_hash TEXT;
BEGIN
    -- Get stored PIN hash and salt
    SELECT pin_hash, pin_salt INTO stored_hash, stored_salt
    FROM profiles 
    WHERE id = user_id
    AND auth_method = 'pin'
    AND is_pin_setup = TRUE;
    
    IF stored_hash IS NULL OR stored_salt IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Compute hash of provided PIN
    SELECT hash INTO computed_hash
    FROM hash_pin_with_salt(pin_text, stored_salt);
    
    -- Compare hashes
    RETURN computed_hash = stored_hash;
END;
$$ LANGUAGE plpgsql;

-- Test the verify_pin function with a known user
DO $$
DECLARE
    test_user_id UUID;
    test_result BOOLEAN;
BEGIN
    -- Get a child user ID if any exists
    SELECT id INTO test_user_id
    FROM profiles 
    WHERE role = 'child' 
    AND auth_method = 'pin' 
    AND is_pin_setup = TRUE
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Test with dummy PIN (will fail but function should work)
        SELECT verify_pin(test_user_id, '0000') INTO test_result;
        RAISE NOTICE '✅ verify_pin function working - Test returned: %', test_result;
    ELSE
        RAISE NOTICE '✅ verify_pin function updated - No child users to test with yet';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ verify_pin function test failed: %', SQLERRM;
END $$; 