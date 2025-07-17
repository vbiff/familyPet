-- Fix the verify_pin function hash call
-- The hash_pin_with_salt function returns a record with pin_hash column

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
    
    -- Compute hash of provided PIN (fix the column reference)
    SELECT pin_hash INTO computed_hash
    FROM hash_pin_with_salt(pin_text, stored_salt);
    
    -- Compare hashes
    RETURN computed_hash = stored_hash;
END;
$$ LANGUAGE plpgsql;

-- Test the function is working now
DO $$
BEGIN
    RAISE NOTICE '✅ verify_pin function updated with correct hash function call';
END $$; 