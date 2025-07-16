-- Add support for never-expiring child invitation tokens

-- Update create_child_invitation_token to handle null expires_in_hours
CREATE OR REPLACE FUNCTION create_child_invitation_token(
    family_id_param UUID,
    created_by_id_param UUID,
    child_display_name_param TEXT DEFAULT NULL,
    expires_in_hours INTEGER DEFAULT NULL -- Changed to nullable, null means never expire
)
RETURNS TEXT AS $$
DECLARE
    invitation_token TEXT;
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
    invitation_token := generate_child_invitation_token();
    
    -- Set expiration: null means never expire
    IF expires_in_hours IS NOT NULL THEN
        expires_at := NOW() + (expires_in_hours || ' hours')::INTERVAL;
    ELSE
        expires_at := NULL; -- Never expire
    END IF;
    
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
        invitation_token,
        expires_at, -- Can be null for never expire
        child_display_name_param
    );
    
    RETURN invitation_token;
END;
$$ LANGUAGE plpgsql;

-- Update validate_child_invitation_token to handle null expires_at
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
    -- Check if token exists, is not used, and not expired (handle null expires_at)
    IF NOT EXISTS (
        SELECT 1 FROM child_invitation_tokens cit
        WHERE cit.token = token_param 
        AND NOT cit.is_used 
        AND (cit.expires_at IS NULL OR cit.expires_at > NOW()) -- Allow null (never expire) or not expired
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
    AND (cit.expires_at IS NULL OR cit.expires_at > NOW()); -- Allow null (never expire) or not expired
END;
$$ LANGUAGE plpgsql;

-- Update consume_child_invitation_token to handle null expires_at
CREATE OR REPLACE FUNCTION consume_child_invitation_token(
    token_param TEXT,
    child_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    token_family_id UUID;
BEGIN
    -- Validate token first (handle null expires_at)
    SELECT cit.family_id INTO token_family_id
    FROM child_invitation_tokens cit
    WHERE cit.token = token_param
    AND NOT cit.is_used
    AND (cit.expires_at IS NULL OR cit.expires_at > NOW()); -- Allow null (never expire) or not expired
    
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
    UPDATE profiles 
    SET family_id = token_family_id
    WHERE id = child_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Update comments
COMMENT ON FUNCTION create_child_invitation_token(UUID, UUID, TEXT, INTEGER) IS 'Creates a new invitation token for child signup. expires_in_hours=NULL means never expire';
COMMENT ON FUNCTION validate_child_invitation_token(TEXT) IS 'Validates a token and returns family information. Handles null expires_at (never expire)';
COMMENT ON FUNCTION consume_child_invitation_token(TEXT, UUID) IS 'Consumes a valid invitation token and adds child to family. Handles null expires_at (never expire)'; 