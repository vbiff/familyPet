-- Fix token ambiguity in generate_child_invitation_token function

CREATE OR REPLACE FUNCTION generate_child_invitation_token()
RETURNS TEXT AS $$
DECLARE
    new_token TEXT;  -- Renamed to avoid ambiguity
    token_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a 32-character token (URL-safe base64 style)
        new_token := ENCODE(gen_random_bytes(24), 'base64');
        -- Make it URL-safe by replacing problematic characters
        new_token := REPLACE(new_token, '+', '-');
        new_token := REPLACE(new_token, '/', '_');
        new_token := REPLACE(new_token, '=', '');
        
        -- Check if token already exists (now unambiguous)
        SELECT EXISTS(
            SELECT 1 FROM child_invitation_tokens 
            WHERE child_invitation_tokens.token = new_token
        ) INTO token_exists;
        
        -- If token doesn't exist, we can use it
        IF NOT token_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN new_token;
END;
$$ LANGUAGE plpgsql; 