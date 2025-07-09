-- Fix invite code validation to only check format, not existence
-- This fixes the issue where family creation fails because the validation function
-- checks if the invite code exists in the database, but during creation it doesn't exist yet

-- Create a function to validate invite code format only
CREATE OR REPLACE FUNCTION validate_invite_code_format(input_code VARCHAR(6))
RETURNS BOOLEAN AS $$
DECLARE
    normalized_code VARCHAR(6);
BEGIN
    -- Normalize the input code
    normalized_code := UPPER(TRIM(input_code));
    
    -- Check length
    IF LENGTH(normalized_code) != 6 THEN
        RETURN FALSE;
    END IF;
    
    -- Check for invalid characters (only allow safe characters)
    IF normalized_code !~ '^[ACDEFHJKMNPRTUVWXY347]+$' THEN
        RETURN FALSE;
    END IF;
    
    -- Return true if format is valid (don't check existence)
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Update the existing validate_invite_code function to be clearer about what it does
CREATE OR REPLACE FUNCTION validate_invite_code(input_code VARCHAR(6))
RETURNS BOOLEAN AS $$
DECLARE
    normalized_code VARCHAR(6);
BEGIN
    -- Normalize the input code
    normalized_code := UPPER(TRIM(input_code));
    
    -- First check format
    IF NOT validate_invite_code_format(normalized_code) THEN
        RETURN FALSE;
    END IF;
    
    -- Check if code exists in database (for joining families)
    RETURN EXISTS(SELECT 1 FROM families WHERE invite_code = normalized_code);
END;
$$ LANGUAGE plpgsql;

-- Update the trigger function to use format validation only
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        -- Use the advanced generation function
        NEW.invite_code := generate_advanced_invite_code();
    ELSE
        -- Validate provided invite code FORMAT only (not existence)
        IF NOT validate_invite_code_format(NEW.invite_code) THEN
            RAISE EXCEPTION 'Invalid invite code format: %', NEW.invite_code;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update the advanced trigger function as well
CREATE OR REPLACE FUNCTION set_advanced_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_advanced_invite_code();
    ELSE
        -- Validate provided invite code FORMAT only (not existence)
        IF NOT validate_invite_code_format(NEW.invite_code) THEN
            RAISE EXCEPTION 'Invalid invite code format: %', NEW.invite_code;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Test the functions
DO $$
DECLARE
    test_code VARCHAR(6);
    is_valid_format BOOLEAN;
    is_valid_existence BOOLEAN;
BEGIN
    RAISE NOTICE '🧪 Testing invite code validation fix:';
    
    -- Test format validation with valid code
    test_code := 'HJKMNP';
    is_valid_format := validate_invite_code_format(test_code);
    RAISE NOTICE '   - Format validation for "HJKMNP": %', is_valid_format;
    
    -- Test format validation with invalid code
    test_code := 'TUVWXY';
    is_valid_format := validate_invite_code_format(test_code);
    RAISE NOTICE '   - Format validation for "TUVWXY": %', is_valid_format;
    
    -- Test existence validation (should be false for non-existent codes)
    test_code := 'HJKMNP';
    is_valid_existence := validate_invite_code(test_code);
    RAISE NOTICE '   - Existence validation for "HJKMNP": %', is_valid_existence;
    
    RAISE NOTICE '✅ Format validation should be true for valid characters';
    RAISE NOTICE '✅ Existence validation should be false for non-existent codes';
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Invite code validation fixed!';
    RAISE NOTICE '🔧 Changes made:';
    RAISE NOTICE '   - Created validate_invite_code_format() for format-only validation';
    RAISE NOTICE '   - Updated trigger functions to use format validation only';
    RAISE NOTICE '   - Kept validate_invite_code() for existence checks (joining families)';
    RAISE NOTICE '   - Character set: [ACDEFHJKMNPRTUVWXY347]';
    RAISE NOTICE '💡 Family creation should now work without false validation errors!';
END $$; 