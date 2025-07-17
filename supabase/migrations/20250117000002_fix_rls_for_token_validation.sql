-- Fix RLS blocking token validation during child signup
-- Make validation function run with security definer to bypass RLS

-- Recreate validation function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION validate_child_invitation_token(
    token_param TEXT
)
RETURNS TABLE (
    family_id UUID,
    family_name TEXT,
    child_display_name TEXT,
    invite_code TEXT
) 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
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

-- Also fix consume function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION consume_child_invitation_token(
    token_param TEXT,
    child_user_id UUID
)
RETURNS BOOLEAN 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
DECLARE
    token_family_id UUID;
BEGIN
    -- Validate token first (handle null expires_at)
    SELECT cit.family_id INTO token_family_id
    FROM child_invitation_tokens cit
    WHERE cit.token = token_param
    AND NOT cit.is_used
    AND (cit.expires_at IS NULL OR cit.expires_at > NOW());
    
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

-- Update function comments
COMMENT ON FUNCTION validate_child_invitation_token(TEXT) IS 'Validates a token and returns family information. Uses SECURITY DEFINER to bypass RLS for unauthenticated child signup.';
COMMENT ON FUNCTION consume_child_invitation_token(TEXT, UUID) IS 'Consumes a valid invitation token and adds child to family. Uses SECURITY DEFINER to bypass RLS.'; 