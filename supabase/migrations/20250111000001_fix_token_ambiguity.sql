-- Fix token column ambiguity in child invitation functions

-- Function to validate and consume invitation token (FIXED)
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
        SELECT 1 FROM child_invitation_tokens cit
        WHERE cit.token = token_param 
        AND NOT cit.is_used 
        AND cit.expires_at > NOW()
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

-- Function to consume invitation token after successful signup (FIXED)
CREATE OR REPLACE FUNCTION consume_child_invitation_token(
    token_param TEXT,
    child_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    token_family_id UUID;
BEGIN
    -- Validate token first
    SELECT cit.family_id INTO token_family_id
    FROM child_invitation_tokens cit
    WHERE cit.token = token_param 
    AND NOT cit.is_used 
    AND cit.expires_at > NOW();
    
    IF token_family_id IS NULL THEN
        RAISE EXCEPTION 'Invalid, expired, or already used invitation token';
    END IF;
    
    -- Mark token as used
    UPDATE child_invitation_tokens 
    SET 
        is_used = TRUE,
        used_by_id = child_user_id,
        used_at = NOW()
    WHERE child_invitation_tokens.token = token_param;
    
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