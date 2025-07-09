-- Fix display name for the correct user
-- Based on the app screenshot, the user with b@b.com should be "Mike"

-- Update the display name for the user with b@b.com email
UPDATE profiles 
SET display_name = 'Mike',
    updated_at = NOW()
WHERE email = 'b@b.com';

-- Show the updated profiles
SELECT 'Updated profiles:' as info;
SELECT id, email, display_name, family_id, role, created_at FROM profiles ORDER BY email;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Display name updated to "Mike" for user b@b.com';
    RAISE NOTICE '🔄 Try refreshing the app - it should now show "Good night, Mike!"';
END $$; 