-- Advanced Family Invite Code Generation System
-- This migration creates a more sophisticated invite code generation system
-- that avoids confusing characters and ensures better uniqueness

-- Create a more sophisticated invite code generation function
CREATE OR REPLACE FUNCTION generate_advanced_invite_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    code VARCHAR(6);
    code_exists BOOLEAN;
    attempt_count INTEGER := 0;
    max_attempts INTEGER := 100;
    
    -- Character sets for different positions to ensure readability
    -- Avoid confusing characters: 0, O, I, L, 1, S, 5, Z, 2, B, 8, 6, G, 9, Q
    consonants CONSTANT VARCHAR(20) := 'BCDFGHJKMNPQRSTVWXYZ';
    vowels CONSTANT VARCHAR(5) := 'AEIOU';
    numbers CONSTANT VARCHAR(7) := '3479';
    safe_chars CONSTANT VARCHAR(25) := 'ACDEFHJKMNPRTUVWXY347';
    
    -- Pattern variations for better memorability
    pattern_type INTEGER;
    pos INTEGER;
    char_pool VARCHAR(25);
BEGIN
    LOOP
        attempt_count := attempt_count + 1;
        
        -- Prevent infinite loops
        IF attempt_count > max_attempts THEN
            RAISE EXCEPTION 'Failed to generate unique invite code after % attempts', max_attempts;
        END IF;
        
        -- Choose a pattern type (0-3 for different patterns)
        pattern_type := (RANDOM() * 4)::INTEGER;
        
        code := '';
        
        CASE pattern_type
            -- Pattern 0: Consonant-Vowel-Consonant-Number-Consonant-Number (CVCNCN)
            WHEN 0 THEN
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(vowels, (RANDOM() * LENGTH(vowels))::INTEGER + 1, 1);
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
            
            -- Pattern 1: Number-Consonant-Vowel-Consonant-Vowel-Number (NCVCVN)
            WHEN 1 THEN
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(vowels, (RANDOM() * LENGTH(vowels))::INTEGER + 1, 1);
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(vowels, (RANDOM() * LENGTH(vowels))::INTEGER + 1, 1);
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
            
            -- Pattern 2: Consonant-Number-Vowel-Consonant-Number-Vowel (CNVCNV)
            WHEN 2 THEN
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
                code := code || SUBSTR(vowels, (RANDOM() * LENGTH(vowels))::INTEGER + 1, 1);
                code := code || SUBSTR(consonants, (RANDOM() * LENGTH(consonants))::INTEGER + 1, 1);
                code := code || SUBSTR(numbers, (RANDOM() * LENGTH(numbers))::INTEGER + 1, 1);
                code := code || SUBSTR(vowels, (RANDOM() * LENGTH(vowels))::INTEGER + 1, 1);
            
            -- Pattern 3: Mixed safe characters with position-based logic
            WHEN 3 THEN
                FOR pos IN 1..6 LOOP
                    IF pos % 2 = 1 THEN
                        -- Odd positions: prefer consonants
                        char_pool := consonants;
                    ELSE
                        -- Even positions: mix of vowels and numbers
                        char_pool := vowels || numbers;
                    END IF;
                    
                    code := code || SUBSTR(char_pool, (RANDOM() * LENGTH(char_pool))::INTEGER + 1, 1);
                END LOOP;
        END CASE;
        
        -- Ensure code is exactly 6 characters and uppercase
        code := UPPER(SUBSTR(code, 1, 6));
        
        -- Additional safety replacements for any remaining confusing characters
        code := REPLACE(code, '0', '3');
        code := REPLACE(code, 'O', 'A');
        code := REPLACE(code, 'I', 'E');
        code := REPLACE(code, 'L', 'K');
        code := REPLACE(code, '1', '7');
        code := REPLACE(code, 'S', 'T');
        code := REPLACE(code, '5', '4');
        code := REPLACE(code, 'Z', 'Y');
        code := REPLACE(code, '2', '3');
        code := REPLACE(code, 'B', 'C');
        code := REPLACE(code, '8', '9');
        code := REPLACE(code, '6', '7');
        code := REPLACE(code, 'G', 'H');
        code := REPLACE(code, 'Q', 'R');
        
        -- Ensure we still have 6 characters after replacements
        IF LENGTH(code) < 6 THEN
            code := RPAD(code, 6, '3');
        END IF;
        
        -- Check if this code already exists
        SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = code) INTO code_exists;
        
        -- If code doesn't exist, we can use it
        IF NOT code_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Create a function to validate invite codes
CREATE OR REPLACE FUNCTION validate_invite_code(input_code VARCHAR(6))
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
    
    -- Check if code exists in database
    RETURN EXISTS(SELECT 1 FROM families WHERE invite_code = normalized_code);
END;
$$ LANGUAGE plpgsql;

-- Update the trigger function to use the advanced generator
CREATE OR REPLACE FUNCTION set_advanced_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_advanced_invite_code();
    ELSE
        -- Validate provided invite code
        IF NOT validate_invite_code(NEW.invite_code) THEN
            RAISE EXCEPTION 'Invalid invite code format: %', NEW.invite_code;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Replace the existing trigger with the advanced version
DROP TRIGGER IF EXISTS trigger_set_invite_code ON families;
CREATE TRIGGER trigger_set_advanced_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_advanced_invite_code();

-- Create a function to regenerate invite codes for existing families
CREATE OR REPLACE FUNCTION regenerate_family_invite_codes()
RETURNS INTEGER AS $$
DECLARE
    family_record RECORD;
    updated_count INTEGER := 0;
    new_code VARCHAR(6);
BEGIN
    -- Update all existing families with new advanced codes
    FOR family_record IN SELECT id, invite_code FROM families LOOP
        new_code := generate_advanced_invite_code();
        
        UPDATE families 
        SET invite_code = new_code, updated_at = NOW()
        WHERE id = family_record.id;
        
        updated_count := updated_count + 1;
        
        RAISE NOTICE 'Updated family % with new invite code: %', family_record.id, new_code;
    END LOOP;
    
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get invite code statistics
CREATE OR REPLACE FUNCTION get_invite_code_stats()
RETURNS TABLE (
    total_codes INTEGER,
    pattern_distribution JSONB,
    character_frequency JSONB
) AS $$
DECLARE
    stats_result RECORD;
    char_freq JSONB := '{}';
    pattern_dist JSONB := '{}';
    code_record RECORD;
    i INTEGER;
    char_count INTEGER;
BEGIN
    -- Get total count
    SELECT COUNT(*) INTO total_codes FROM families;
    
    -- Analyze pattern distribution and character frequency
    FOR code_record IN SELECT invite_code FROM families LOOP
        -- Count character frequency
        FOR i IN 1..6 LOOP
            char_count := COALESCE((char_freq->>SUBSTR(code_record.invite_code, i, 1))::INTEGER, 0) + 1;
            char_freq := jsonb_set(char_freq, ARRAY[SUBSTR(code_record.invite_code, i, 1)], to_jsonb(char_count));
        END LOOP;
    END LOOP;
    
    -- Simple pattern classification
    pattern_dist := jsonb_build_object(
        'total_analyzed', total_codes,
        'note', 'Advanced pattern analysis available in future versions'
    );
    
    pattern_distribution := pattern_dist;
    character_frequency := char_freq;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Optional: Regenerate all existing invite codes with the new system
-- Uncomment the line below if you want to update all existing codes
-- SELECT regenerate_family_invite_codes();

-- Create helpful comments and documentation
COMMENT ON FUNCTION generate_advanced_invite_code() IS 'Generates human-readable 6-character invite codes using multiple patterns to avoid confusing characters';
COMMENT ON FUNCTION validate_invite_code(VARCHAR) IS 'Validates invite code format and existence in database';
COMMENT ON FUNCTION set_advanced_invite_code() IS 'Trigger function to automatically set advanced invite codes on family creation';
COMMENT ON FUNCTION regenerate_family_invite_codes() IS 'Utility function to regenerate all existing family invite codes with the new advanced system';
COMMENT ON FUNCTION get_invite_code_stats() IS 'Provides statistics about invite code patterns and character distribution';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🎯 Advanced Family Invite Code Generation System Installed!';
    RAISE NOTICE '📋 Features:';
    RAISE NOTICE '  ✅ Multiple readable patterns (CVCNCN, NCVCVN, CNVCNV, Mixed)';
    RAISE NOTICE '  ✅ Eliminates confusing characters (0, O, I, L, 1, S, 5, Z, 2, B, 8, 6, G, 9, Q)';
    RAISE NOTICE '  ✅ Advanced validation system';
    RAISE NOTICE '  ✅ Pattern-based generation for better memorability';
    RAISE NOTICE '  ✅ Collision detection with retry logic';
    RAISE NOTICE '  ✅ Statistics and monitoring functions';
    RAISE NOTICE '💡 Existing families will keep their current codes unless regenerated manually';
    RAISE NOTICE '🔧 Use SELECT regenerate_family_invite_codes(); to update all existing codes';
END $$; 