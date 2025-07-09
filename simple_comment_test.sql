-- Simple comment functionality test

-- 1. Check if task_comments table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'task_comments'
) as table_exists;

-- 2. Check table structure
\d task_comments;

-- 3. Check if we have any tasks
SELECT COUNT(*) as task_count FROM tasks;

-- 4. Check if we have any profiles  
SELECT COUNT(*) as profile_count FROM profiles;

-- 5. Get the first task and user to test with
SELECT 
    t.id as task_id,
    t.title,
    p.id as user_id,
    p.email
FROM tasks t
CROSS JOIN profiles p
LIMIT 1;

-- 6. Try inserting a test comment (you'll need to replace with actual IDs)
-- Uncomment and modify this line with real IDs from the query above:
-- INSERT INTO task_comments (task_id, author_id, content) 
-- SELECT 
--     (SELECT id FROM tasks LIMIT 1),
--     (SELECT id FROM profiles LIMIT 1),
--     'Test comment from SQL'
-- WHERE EXISTS (SELECT 1 FROM tasks) AND EXISTS (SELECT 1 FROM profiles);

-- 7. Check if the insert worked
SELECT COUNT(*) as comment_count FROM task_comments; 