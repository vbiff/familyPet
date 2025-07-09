-- Debug comments functionality

-- Check if task_comments table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'task_comments'
ORDER BY ordinal_position;

-- Check if there are any tasks to comment on
SELECT id, title, family_id, created_by_id FROM tasks LIMIT 5;

-- Check current user's profile
SELECT id, email, family_id FROM profiles WHERE email = 'current_user_email';

-- Try to manually insert a test comment (replace the UUIDs with actual values)
-- This will help us see if there are any database-level issues
-- INSERT INTO task_comments (task_id, author_id, content) 
-- VALUES ('your-task-id', 'your-user-id', 'Test comment');

-- Check if there are any existing comments
SELECT * FROM task_comments LIMIT 5;

-- Check if the table has proper permissions (should be accessible since RLS is disabled)
SELECT tablename, tableowner FROM pg_tables WHERE tablename = 'task_comments'; 