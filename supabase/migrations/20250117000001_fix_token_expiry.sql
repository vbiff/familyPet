-- Fix child invitation token expiry handling
-- Date: 2025-01-17
-- This fixes the issue where NULL expiry dates (never expire) are treated as expired

-- Function to create child invitation token (FIXED)
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
    
    -- Handle expiry: NULL means never expire
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
        token,
        expires_at,
        child_display_name_param
    );
    
    RETURN token;
END;
$$ LANGUAGE plpgsql;

-- Function to validate invitation token (FIXED)
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
    -- Check if token exists, is not used, and not expired (NULL means never expire)
    IF NOT EXISTS (
        SELECT 1 FROM child_invitation_tokens 
        WHERE token = token_param 
        AND NOT is_used 
        AND (expires_at IS NULL OR expires_at > NOW())
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
    AND (cit.expires_at IS NULL OR cit.expires_at > NOW());
END;
$$ LANGUAGE plpgsql; 