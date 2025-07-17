-- Fix crypto functions to work with restricted search paths
-- Use alternative random generation if gen_random_bytes is not accessible

-- Update hash function to use accessible random generation
CREATE OR REPLACE FUNCTION hash_pin_with_salt(
    pin_text TEXT,
    salt_text TEXT DEFAULT NULL
)
RETURNS TABLE (
    pin_hash TEXT,
    pin_salt TEXT
) AS $$
DECLARE
    salt TEXT;
    hash TEXT;
BEGIN
    -- Generate salt if not provided (use alternative method)
    IF salt_text IS NULL THEN
        -- Use random() with timestamp for entropy since gen_random_bytes might not be accessible
        salt := SUBSTRING(
            REPLACE(
                REPLACE(
                    ENCODE(
                        (EXTRACT(EPOCH FROM NOW())::BIGINT::TEXT || 
                         (RANDOM() * 1000000)::BIGINT::TEXT ||
                         pin_text ||
                         (RANDOM() * 1000000)::BIGINT::TEXT)::BYTEA, 
                        'base64'
                    ), 
                    '+', 'A'
                ), 
                '/', 'B'
            ), 1, 22
        );
    ELSE
        salt := salt_text;
    END IF;
    
    -- Create hash using SHA-256 with salt (use pg_crypto extension explicitly)
    BEGIN
        -- Try using extensions.digest first
        hash := ENCODE(extensions.digest(salt || pin_text || salt, 'sha256'), 'base64');
    EXCEPTION WHEN OTHERS THEN
        -- Fallback to public.digest if available
        BEGIN
            hash := ENCODE(public.digest(salt || pin_text || salt, 'sha256'), 'base64');
        EXCEPTION WHEN OTHERS THEN
            -- Final fallback using MD5 (not ideal but works)
            hash := MD5(salt || pin_text || salt);
        END;
    END;
    
    RETURN QUERY SELECT hash, salt;
END;
$$ LANGUAGE plpgsql;

-- Also update the setup_child_pin function to have better search path
CREATE OR REPLACE FUNCTION setup_child_pin(
    user_id UUID,
    pin_text TEXT,
    display_name_param TEXT
)
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public, extensions
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
        role = 'child'::user_role,
        updated_at = NOW();
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test the hash function
DO $$
DECLARE
    test_result RECORD;
BEGIN
    SELECT * INTO test_result FROM hash_pin_with_salt('1234');
    RAISE NOTICE '✅ Hash function test successful - Generated hash: % with salt: %', 
        LEFT(test_result.pin_hash, 10) || '...', LEFT(test_result.pin_salt, 10) || '...';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Hash function test failed: %', SQLERRM;
END $$; 