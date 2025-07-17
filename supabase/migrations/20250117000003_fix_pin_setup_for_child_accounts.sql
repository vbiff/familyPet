-- Fix PIN setup for child accounts
-- Make setup_child_pin more robust to handle profile creation timing issues

CREATE OR REPLACE FUNCTION setup_child_pin(
    user_id UUID,
    pin_text TEXT,
    display_name_param TEXT
)
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    hash_result RECORD;
    user_role TEXT;
    user_email TEXT;
BEGIN
    -- Get user info from auth.users to check role and email
    SELECT 
        COALESCE(au.raw_user_meta_data->>'role', 'parent') as role,
        au.email
    INTO user_role, user_email
    FROM auth.users au 
    WHERE au.id = user_id;
    
    -- Verify this is a child account (check both profile and auth metadata)
    IF user_role != 'child' AND NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id 
        AND role = 'child'
    ) THEN
        RAISE EXCEPTION 'PIN setup is only available for child accounts. Current role: %', user_role;
    END IF;
    
    -- Validate PIN (4-6 digits)
    IF pin_text !~ '^\d{4,6}$' THEN
        RAISE EXCEPTION 'PIN must be 4-6 digits only';
    END IF;
    
    -- Generate hash and salt
    SELECT * INTO hash_result FROM hash_pin_with_salt(pin_text);
    
    -- Ensure profile exists with correct role (upsert)
    INSERT INTO profiles (
        id,
        email,
        display_name,
        role,
        auth_method,
        pin_hash,
        pin_salt,
        is_pin_setup,
        last_pin_update,
        created_at,
        updated_at,
        last_login_at
    ) VALUES (
        user_id,
        user_email,
        display_name_param,
        'child'::user_role,
        'pin'::auth_method,
        hash_result.pin_hash,
        hash_result.pin_salt,
        TRUE,
        NOW(),
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET 
        pin_hash = hash_result.pin_hash,
        pin_salt = hash_result.pin_salt,
        auth_method = 'pin'::auth_method,
        is_pin_setup = TRUE,
        last_pin_update = NOW(),
        display_name = display_name_param,
        role = 'child'::user_role, -- Ensure role is child
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Update function comment
COMMENT ON FUNCTION setup_child_pin(UUID, TEXT, TEXT) IS 'Sets up PIN for child accounts. Uses SECURITY DEFINER and handles profile creation/updates robustly.'; 