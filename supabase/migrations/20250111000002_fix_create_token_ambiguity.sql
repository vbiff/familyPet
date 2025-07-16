-- Fix token ambiguity in create_child_invitation_token function

CREATE OR REPLACE FUNCTION create_child_invitation_token(
    family_id_param UUID,
    created_by_id_param UUID,
    child_display_name_param TEXT DEFAULT NULL,
    expires_in_hours INTEGER DEFAULT 24
)
RETURNS TEXT AS $$
DECLARE
    invitation_token TEXT;  -- Renamed to avoid ambiguity
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
    expires_at := NOW() + (expires_in_hours || ' hours')::INTERVAL;
    
    -- Insert the token (with explicit column qualification)
    INSERT INTO child_invitation_tokens (
        family_id,
        created_by_id,
        token,
        expires_at,
        child_display_name
    ) VALUES (
        family_id_param,
        created_by_id_param,
        invitation_token,  -- Use the renamed variable
        expires_at,
        child_display_name_param
    );
    
    RETURN invitation_token;
END;
$$ LANGUAGE plpgsql; 