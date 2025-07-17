-- Debug script to check child profile that was just created

-- Check for profiles with display_name 'qrkid'
SELECT 
    id,
    email,
    display_name,
    role,
    auth_method,
    is_pin_setup,
    pin_hash IS NOT NULL as has_pin_hash,
    pin_salt IS NOT NULL as has_pin_salt,
    family_id,
    created_at,
    last_pin_update
FROM profiles 
WHERE display_name = 'qrkid'
ORDER BY created_at DESC;

-- Check all child profiles to see what we have
SELECT 
    id,
    email,
    display_name,
    role,
    auth_method,
    is_pin_setup,
    pin_hash IS NOT NULL as has_pin_hash,
    pin_salt IS NOT NULL as has_pin_salt,
    family_id,
    created_at
FROM profiles 
WHERE role = 'child'
ORDER BY created_at DESC
LIMIT 5;

-- Check the exact conditions the login function is looking for
SELECT 
    id,
    display_name,
    role,
    auth_method,
    is_pin_setup,
    'Login conditions match: ' || 
    CASE WHEN (display_name = 'qrkid' AND role = 'child' AND auth_method = 'pin' AND is_pin_setup = true) 
         THEN 'YES' 
         ELSE 'NO' 
    END as login_ready
FROM profiles 
WHERE display_name = 'qrkid'; 