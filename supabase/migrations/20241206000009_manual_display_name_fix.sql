-- Manual fix for display name
-- This migration manually sets the display name to 'Mike' for the current user

-- Check current auth metadata
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT u.id, u.email, u.raw_user_meta_data, p.display_name as current_display_name
        FROM auth.users u
        JOIN profiles p ON u.id = p.id
    LOOP
        RAISE NOTICE '📊 User: % (email: %)', user_record.id, user_record.email;
        RAISE NOTICE '   Current display name: %', user_record.current_display_name;
        RAISE NOTICE '   Auth metadata: %', user_record.raw_user_meta_data;
        RAISE NOTICE '   Metadata display_name: %', user_record.raw_user_meta_data->>'display_name';
        RAISE NOTICE '   Metadata name: %', user_record.raw_user_meta_data->>'name';
    END LOOP;
END $$;

-- Manually update the display name to 'Mike' for the user with email containing 'mbseq'
UPDATE profiles 
SET display_name = 'Mike',
    updated_at = NOW()
WHERE email LIKE '%mbseq%' OR display_name LIKE '%mbseq%' OR display_name = 'm!';

-- Check the result
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '🔧 Updated % profile(s) to display name "Mike"', updated_count;
END $$;

-- Show final state
SELECT 'Final profiles:' as info;
SELECT id, email, display_name, family_id, created_at FROM profiles;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Display name manually fixed to "Mike"';
    RAISE NOTICE '🔄 Try refreshing the app - it should now show "Good night, Mike!" instead of "Good night, m!"';
END $$; 