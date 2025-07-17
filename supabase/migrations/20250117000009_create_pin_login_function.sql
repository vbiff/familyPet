-- Create PIN login function that bypasses RLS policies
-- This solves the chicken-and-egg problem of needing to be authenticated to authenticate

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
    SELECT 
        id,
        email,
        display_name,
        avatar_url,
        family_id,
        created_at,
        last_pin_update,
        metadata
    INTO profile_record
    FROM profiles 
    WHERE profiles.display_name = display_name_param
    AND role = 'child'
    AND auth_method = 'pin'
    AND is_pin_setup = true;
    
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
        WHERE id = profile_record.id;
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

-- Test the function with our known user
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
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ PIN login function test failed: %', SQLERRM;
END $$;

-- Update function comment
COMMENT ON FUNCTION authenticate_child_with_pin(TEXT, TEXT) IS 'Authenticates child with PIN, bypassing RLS policies. Returns user data and PIN validation result.'; 