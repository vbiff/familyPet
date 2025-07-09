-- Clean all tables while preserving schema structure
-- This migration removes all data but keeps the database structure intact

-- Disable triggers temporarily to avoid cascade issues
SET session_replication_role = replica;

-- Clean all tables in the correct order (respecting foreign key constraints)
-- Start with tables that have no dependencies

-- Clean task comments first (depends on tasks)
DELETE FROM task_comments;

-- Clean tasks (depends on profiles and families)
DELETE FROM tasks;

-- Clean pets (depends on profiles and families)
DELETE FROM pets;

-- Clean profiles (depends on families for family_id, but families depend on profiles for created_by_id)
-- We need to handle this circular dependency carefully
UPDATE profiles SET family_id = NULL WHERE family_id IS NOT NULL;

-- Clean families (now safe since profiles.family_id is cleared)
DELETE FROM families;

-- Clean profiles (now safe since families are gone)
DELETE FROM profiles;

-- Clean any remaining auth-related data (be careful here)
-- Note: We typically don't delete from auth.users as it's managed by Supabase Auth
-- But we can clean up any orphaned data

-- Re-enable triggers
SET session_replication_role = DEFAULT;

-- Reset sequences to start from 1 (if any exist)
-- Most of our tables use UUIDs, but just in case

-- Note: VACUUM commands removed as they cannot run within migrations
-- You can run VACUUM manually after the migration if needed

-- Success message with statistics
DO $$
DECLARE
    profile_count INTEGER;
    family_count INTEGER;
    task_count INTEGER;
    pet_count INTEGER;
    comment_count INTEGER;
BEGIN
    -- Count remaining records (should all be 0)
    SELECT COUNT(*) INTO profile_count FROM profiles;
    SELECT COUNT(*) INTO family_count FROM families;
    SELECT COUNT(*) INTO task_count FROM tasks;
    SELECT COUNT(*) INTO pet_count FROM pets;
    SELECT COUNT(*) INTO comment_count FROM task_comments;
    
    RAISE NOTICE '🧹 Database tables cleaned successfully!';
    RAISE NOTICE '📊 Final counts:';
    RAISE NOTICE '  - Profiles: %', profile_count;
    RAISE NOTICE '  - Families: %', family_count;
    RAISE NOTICE '  - Tasks: %', task_count;
    RAISE NOTICE '  - Pets: %', pet_count;
    RAISE NOTICE '  - Comments: %', comment_count;
    
    IF profile_count = 0 AND family_count = 0 AND task_count = 0 AND pet_count = 0 AND comment_count = 0 THEN
        RAISE NOTICE '✅ All tables are now empty and ready for fresh data!';
    ELSE
        RAISE NOTICE '⚠️  Some tables still contain data - check for constraints or dependencies';
    END IF;
    
    RAISE NOTICE '🔧 Schema structure preserved';
    RAISE NOTICE '🔧 Functions and triggers remain intact';
    RAISE NOTICE '🔧 RLS policies remain active';
    RAISE NOTICE '💡 New users can now sign up fresh without automatic family assignment';
END $$; 