-- Debug script for token: Df5sYS4ufUUlRzbRXQWoI9JbzGpDSDF5

-- Check if token exists in database
SELECT 
    token,
    family_id,
    child_display_name,
    is_used,
    expires_at,
    created_at,
    used_at,
    used_by_id
FROM child_invitation_tokens 
WHERE token = 'Df5sYS4ufUUlRzbRXQWoI9JbzGpDSDF5';

-- Check token validation conditions explicitly
SELECT 
    token,
    is_used,
    expires_at,
    (expires_at IS NULL) as never_expires,
    (expires_at IS NULL OR expires_at > NOW()) as not_expired,
    NOT is_used as not_used,
    (NOT is_used AND (expires_at IS NULL OR expires_at > NOW())) as should_be_valid
FROM child_invitation_tokens 
WHERE token = 'Df5sYS4ufUUlRzbRXQWoI9JbzGpDSDF5';

-- Show all tokens for comparison (if needed)
SELECT 
    token,
    child_display_name,
    is_used,
    expires_at,
    created_at
FROM child_invitation_tokens 
ORDER BY created_at DESC
LIMIT 10; 