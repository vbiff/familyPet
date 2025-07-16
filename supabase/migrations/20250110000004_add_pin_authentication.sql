-- Add PIN authentication support for children
-- This migration adds the infrastructure for PIN-based child authentication
-- Date: 2025-01-10

-- Add PIN authentication columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pin_hash TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS pin_salt TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auth_method TEXT DEFAULT 'email' CHECK (auth_method IN ('email', 'pin'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_pin_setup BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_pin_update TIMESTAMP WITH TIME ZONE;

-- Create child_invitation_tokens table for QR code authentication
CREATE TABLE IF NOT EXISTS child_invitation_tokens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    created_by_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    used_by_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    child_display_name TEXT, -- Suggested name for the child
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Add index for token lookups
CREATE INDEX IF NOT EXISTS idx_child_invitation_tokens_token ON child_invitation_tokens(token);
CREATE INDEX IF NOT EXISTS idx_child_invitation_tokens_family_id ON child_invitation_tokens(family_id);
CREATE INDEX IF NOT EXISTS idx_child_invitation_tokens_expires_at ON child_invitation_tokens(expires_at);

-- Function to generate secure invitation tokens
CREATE OR REPLACE FUNCTION generate_child_invitation_token()
RETURNS TEXT AS $$
DECLARE
    token TEXT;
    token_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a 32-character token (URL-safe base64 style)
        token := ENCODE(gen_random_bytes(24), 'base64');
        -- Make it URL-safe by replacing problematic characters
        token := REPLACE(token, '+', '-');
        token := REPLACE(token, '/', '_');
        token := REPLACE(token, '=', '');
        
        -- Check if token already exists
        SELECT EXISTS(SELECT 1 FROM child_invitation_tokens WHERE token = token) INTO token_exists;
        
        -- If token doesn't exist, we can use it
        IF NOT token_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN token;
END;
$$ LANGUAGE plpgsql;

-- Function to create child invitation token
CREATE OR REPLACE FUNCTION create_child_invitation_token(
    family_id_param UUID,
    created_by_id_param UUID,
    child_display_name_param TEXT DEFAULT NULL,
    expires_in_hours INTEGER DEFAULT 24
)
RETURNS TEXT AS $$
DECLARE
    token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Verify the creator is a parent in the family
    IF NOT EXISTS (
        SELECT 1 FROM families f
        JOIN profiles p ON p.id = created_by_id_param
        WHERE f.id = family_id_param 
        AND (f.created_by_id = created_by_id_param OR created_by_id_param = ANY(f.parent_ids))
        AND p.role = 'parent'
    ) THEN
        RAISE EXCEPTION 'Only family parents can create child invitation tokens';
    END IF;
    
    -- Generate token and expiration
    token := generate_child_invitation_token();
    expires_at := NOW() + (expires_in_hours || ' hours')::INTERVAL;
    
    -- Insert the token
    INSERT INTO child_invitation_tokens (
        family_id,
        created_by_id,
        token,
        expires_at,
        child_display_name
    ) VALUES (
        family_id_param,
        created_by_id_param,
        token,
        expires_at,
        child_display_name_param
    );
    
    RETURN token;
END;
$$ LANGUAGE plpgsql;

-- Function to validate and consume invitation token
CREATE OR REPLACE FUNCTION validate_child_invitation_token(
    token_param TEXT
)
RETURNS TABLE (
    family_id UUID,
    family_name TEXT,
    child_display_name TEXT,
    invite_code TEXT
) AS $$
BEGIN
    -- Check if token exists, is not used, and not expired
    IF NOT EXISTS (
        SELECT 1 FROM child_invitation_tokens 
        WHERE token = token_param 
        AND NOT is_used 
        AND expires_at > NOW()
    ) THEN
        RAISE EXCEPTION 'Invalid, expired, or already used invitation token';
    END IF;
    
    -- Return family information
    RETURN QUERY
    SELECT 
        f.id as family_id,
        f.name as family_name,
        cit.child_display_name,
        f.invite_code
    FROM child_invitation_tokens cit
    JOIN families f ON f.id = cit.family_id
    WHERE cit.token = token_param
    AND NOT cit.is_used
    AND cit.expires_at > NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to consume invitation token after successful signup
CREATE OR REPLACE FUNCTION consume_child_invitation_token(
    token_param TEXT,
    child_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    token_family_id UUID;
BEGIN
    -- Validate token first
    SELECT family_id INTO token_family_id
    FROM child_invitation_tokens 
    WHERE token = token_param 
    AND NOT is_used 
    AND expires_at > NOW();
    
    IF token_family_id IS NULL THEN
        RAISE EXCEPTION 'Invalid, expired, or already used invitation token';
    END IF;
    
    -- Mark token as used
    UPDATE child_invitation_tokens 
    SET 
        is_used = TRUE,
        used_by_id = child_user_id,
        used_at = NOW()
    WHERE token = token_param;
    
    -- Add child to family
    UPDATE families 
    SET 
        child_ids = array_append(child_ids, child_user_id),
        last_activity_at = NOW()
    WHERE id = token_family_id
    AND NOT (child_user_id = ANY(child_ids));
    
    -- Update child's profile
    UPDATE profiles 
    SET 
        family_id = token_family_id,
        updated_at = NOW()
    WHERE id = child_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to hash PIN with salt (server-side)
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
    -- Generate salt if not provided
    IF salt_text IS NULL THEN
        salt := ENCODE(gen_random_bytes(16), 'base64');
    ELSE
        salt := salt_text;
    END IF;
    
    -- Create hash using SHA-256 with salt
    hash := ENCODE(digest(salt || pin_text || salt, 'sha256'), 'base64');
    
    RETURN QUERY SELECT hash, salt;
END;
$$ LANGUAGE plpgsql;

-- Function to verify PIN
CREATE OR REPLACE FUNCTION verify_pin(
    user_id UUID,
    pin_text TEXT
)
RETURNS BOOLEAN AS $$
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

-- Function to setup PIN for child
CREATE OR REPLACE FUNCTION setup_child_pin(
    user_id UUID,
    pin_text TEXT,
    display_name_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    hash_result RECORD;
BEGIN
    -- Verify this is a child account
    IF NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = user_id 
        AND role = 'child'
    ) THEN
        RAISE EXCEPTION 'PIN setup is only available for child accounts';
    END IF;
    
    -- Validate PIN (4-6 digits)
    IF pin_text !~ '^\d{4,6}$' THEN
        RAISE EXCEPTION 'PIN must be 4-6 digits only';
    END IF;
    
    -- Generate hash and salt
    SELECT * INTO hash_result FROM hash_pin_with_salt(pin_text);
    
    -- Update profile with PIN
    UPDATE profiles 
    SET 
        pin_hash = hash_result.pin_hash,
        pin_salt = hash_result.pin_salt,
        auth_method = 'pin',
        is_pin_setup = TRUE,
        last_pin_update = NOW(),
        display_name = display_name_param,
        updated_at = NOW()
    WHERE id = user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Cleanup function to remove expired tokens
CREATE OR REPLACE FUNCTION cleanup_expired_child_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM child_invitation_tokens 
    WHERE expires_at < NOW() - INTERVAL '7 days'; -- Keep for 7 days after expiry for audit
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies for child_invitation_tokens
ALTER TABLE child_invitation_tokens ENABLE ROW LEVEL SECURITY;

-- Parents can view tokens they created in their families
CREATE POLICY "Parents can view their family invitation tokens" ON child_invitation_tokens
    FOR SELECT TO authenticated
    USING (
        created_by_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM families f
            WHERE f.id = family_id
            AND (f.created_by_id = auth.uid() OR auth.uid() = ANY(f.parent_ids))
        )
    );

-- Parents can create tokens for their families
CREATE POLICY "Parents can create invitation tokens" ON child_invitation_tokens
    FOR INSERT TO authenticated
    WITH CHECK (
        created_by_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM families f
            JOIN profiles p ON p.id = auth.uid()
            WHERE f.id = family_id
            AND (f.created_by_id = auth.uid() OR auth.uid() = ANY(f.parent_ids))
            AND p.role = 'parent'
        )
    );

-- Parents can update their own tokens (e.g., mark as used)
CREATE POLICY "Parents can update their invitation tokens" ON child_invitation_tokens
    FOR UPDATE TO authenticated
    USING (
        created_by_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM families f
            WHERE f.id = family_id
            AND (f.created_by_id = auth.uid() OR auth.uid() = ANY(f.parent_ids))
        )
    );

-- Add helpful comments
COMMENT ON TABLE child_invitation_tokens IS 'Stores temporary tokens for inviting children via QR codes';
COMMENT ON COLUMN child_invitation_tokens.token IS 'Unique token embedded in QR codes for child signup';
COMMENT ON COLUMN child_invitation_tokens.child_display_name IS 'Suggested display name for the child account';
COMMENT ON FUNCTION create_child_invitation_token(UUID, UUID, TEXT, INTEGER) IS 'Creates a new invitation token for child signup';
COMMENT ON FUNCTION validate_child_invitation_token(TEXT) IS 'Validates a token and returns family information';
COMMENT ON FUNCTION consume_child_invitation_token(TEXT, UUID) IS 'Marks token as used and adds child to family';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Added PIN authentication support for children!';
    RAISE NOTICE '🔧 Changes made:';
    RAISE NOTICE '   - Added PIN columns to profiles table';
    RAISE NOTICE '   - Created child_invitation_tokens table for QR codes';
    RAISE NOTICE '   - Added functions for token generation, validation, and PIN management';
    RAISE NOTICE '   - Implemented secure PIN hashing with salt';
    RAISE NOTICE '   - Added RLS policies for security';
    RAISE NOTICE '💡 Next: Implement client-side QR generation and PIN auth flows!';
END $$; 