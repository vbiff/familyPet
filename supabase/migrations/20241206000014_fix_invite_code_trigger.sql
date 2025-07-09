-- Fix invite code trigger to use advanced generation
-- This migration ensures all invite code generation uses the same character set

-- First, let's check what triggers are currently active
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    RAISE NOTICE '🔍 Current triggers on families table:';
    FOR trigger_rec IN 
        SELECT tgname, proname 
        FROM pg_trigger t 
        JOIN pg_proc p ON t.tgfoid = p.oid 
        WHERE tgrelid = 'families'::regclass
    LOOP
        RAISE NOTICE '   - Trigger: %, Function: %', trigger_rec.tgname, trigger_rec.proname;
    END LOOP;
END $$;

-- Update the old generate_unique_invite_code function to use the same character set
CREATE OR REPLACE FUNCTION generate_unique_invite_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    code VARCHAR(6);
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Use the same character set as the advanced function: [ACDEFHJKMNPRTUVWXY347]
        code := '';
        FOR i IN 1..6 LOOP
            code := code || SUBSTR('ACDEFHJKMNPRTUVWXY347', (RANDOM() * 21)::INTEGER + 1, 1);
        END LOOP;
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM families WHERE invite_code = code) INTO code_exists;
        
        -- If code doesn't exist, we can use it
        IF NOT code_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql;

-- Update the trigger function to use advanced generation
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        -- Use the advanced generation function
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

-- Make sure the correct trigger is active
DROP TRIGGER IF EXISTS trigger_set_invite_code ON families;
DROP TRIGGER IF EXISTS trigger_set_advanced_invite_code ON families;

-- Create the trigger with the updated function
CREATE TRIGGER trigger_set_invite_code
    BEFORE INSERT ON families
    FOR EACH ROW
    EXECUTE FUNCTION set_invite_code();

-- Test the functions
DO $$
DECLARE
    test_code VARCHAR(6);
    is_valid BOOLEAN;
BEGIN
    RAISE NOTICE '🧪 Testing invite code generation:';
    
    -- Test old function
    test_code := generate_unique_invite_code();
    RAISE NOTICE '   - generate_unique_invite_code(): %', test_code;
    
    -- Test advanced function
    test_code := generate_advanced_invite_code();
    RAISE NOTICE '   - generate_advanced_invite_code(): %', test_code;
    
    -- Test validation
    is_valid := validate_invite_code(test_code);
    RAISE NOTICE '   - Code validation: %', is_valid;
    
    -- Test invalid code
    is_valid := validate_invite_code('TUVWXY');
    RAISE NOTICE '   - Invalid code "TUVWXY" validation: %', is_valid;
END $$;

-- Clean up any families with invalid invite codes
DO $$
DECLARE
    family_rec RECORD;
    new_code VARCHAR(6);
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🔧 Checking for families with invalid invite codes:';
    
    FOR family_rec IN 
        SELECT id, name, invite_code 
        FROM families 
        WHERE NOT validate_invite_code(invite_code)
    LOOP
        new_code := generate_advanced_invite_code();
        
        UPDATE families 
        SET invite_code = new_code, updated_at = NOW()
        WHERE id = family_rec.id;
        
        updated_count := updated_count + 1;
        
        RAISE NOTICE '   - Updated family "%" from "%" to "%"', 
            family_rec.name, family_rec.invite_code, new_code;
    END LOOP;
    
    IF updated_count = 0 THEN
        RAISE NOTICE '   - No invalid invite codes found';
    ELSE
        RAISE NOTICE '   - Updated % families with new invite codes', updated_count;
    END IF;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Invite code trigger system fixed!';
    RAISE NOTICE '🔧 Changes made:';
    RAISE NOTICE '   - generate_unique_invite_code() updated to use safe character set';
    RAISE NOTICE '   - set_invite_code() trigger function updated to use advanced generation';
    RAISE NOTICE '   - All existing invalid invite codes have been regenerated';
    RAISE NOTICE '   - Character set: [ACDEFHJKMNPRTUVWXY347]';
    RAISE NOTICE '💡 Family creation should now work without invite code format errors!';
END $$; 