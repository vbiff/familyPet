-- Fix the PIN login function by fully qualifying column names
-- This resolves the "column reference 'email' is ambiguous" error

CREATE OR REPLACE FUNCTION authenticate_child_with_pin(
    display_name_param TEXT,
    pin_param TEXT
)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    family_id UUID,
    created_at TIMESTAMPTZ,
    last_pin_update TIMESTAMPTZ,
    metadata JSONB,
    pin_valid BOOLEAN
) 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    profile_record RECORD;
    pin_is_valid BOOLEAN;
BEGIN
    -- Find user by display name and role (child with PIN setup)
    -- Fully qualify all column names to avoid ambiguity
    SELECT 
        profiles.id,
        profiles.email,
        profiles.display_name,
        profiles.avatar_url,
        profiles.family_id,
        profiles.created_at,
        profiles.last_pin_update,
        profiles.metadata
    INTO profile_record
    FROM profiles 
    WHERE profiles.display_name = display_name_param
    AND profiles.role = 'child'
    AND profiles.auth_method = 'pin'
    AND profiles.is_pin_setup = true;
    
    -- If no user found, return empty result
    IF profile_record.id IS NULL THEN
        RETURN;
    END IF;
    
    -- Verify PIN
    SELECT verify_pin(profile_record.id, pin_param) INTO pin_is_valid;
    
    -- Update last login if PIN is valid
    IF pin_is_valid THEN
        UPDATE profiles 
        SET last_login_at = NOW()
        WHERE profiles.id = profile_record.id;
    END IF;
    
    -- Return user data with PIN validation result
    RETURN QUERY SELECT 
        profile_record.id,
        profile_record.email,
        profile_record.display_name,
        profile_record.avatar_url,
        profile_record.family_id,
        profile_record.created_at,
        profile_record.last_pin_update,
        profile_record.metadata,
        pin_is_valid;
END;
$$ LANGUAGE plpgsql;

-- Test the function again with our known user
DO $$
DECLARE
    test_result RECORD;
BEGIN
    -- Test with correct PIN
    SELECT * INTO test_result 
    FROM authenticate_child_with_pin('qrkid', '1712');
    
    IF test_result.user_id IS NOT NULL THEN
        RAISE NOTICE '✅ PIN login function working - User found: %, PIN valid: %', 
            test_result.display_name, test_result.pin_valid;
    ELSE
        RAISE NOTICE '❌ PIN login function - No user found for qrkid';
    END IF;
    
    -- Test with wrong PIN
    SELECT * INTO test_result 
    FROM authenticate_child_with_pin('qrkid', '0000');
    
    IF test_result.user_id IS NOT NULL THEN
        RAISE NOTICE '✅ PIN login function - Wrong PIN test: PIN valid = %', test_result.pin_valid;
    ELSE
        RAISE NOTICE '✅ PIN login function - Wrong PIN correctly rejected';
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ PIN login function test failed: %', SQLERRM;
END $$; 