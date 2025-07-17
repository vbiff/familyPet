-- Test script to verify the validation function works

-- Test with the specific token that's failing
SELECT 'Testing with failing token:' as test_description;

SELECT * FROM validate_child_invitation_token('Df5sYS4ufUUlRzbRXQWoI9JbzGpDSDF5');

-- Test with any valid token (if any exist)
SELECT 'Testing with first available token:' as test_description;

DO $$ 
DECLARE
    test_token TEXT;
BEGIN
    -- Get first unused, non-expired token
    SELECT token INTO test_token 
    FROM child_invitation_tokens 
    WHERE NOT is_used 
    AND (expires_at IS NULL OR expires_at > NOW())
    LIMIT 1;
    
    IF test_token IS NOT NULL THEN
        RAISE NOTICE 'Testing with token: %', test_token;
        PERFORM * FROM validate_child_invitation_token(test_token);
        RAISE NOTICE 'Token validation succeeded';
    ELSE
        RAISE NOTICE 'No valid tokens found to test';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Token validation failed: %', SQLERRM;
END $$; 