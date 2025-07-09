-- Migration to add task comments functionality
-- This allows family members to communicate about tasks

-- Create task_comments table
CREATE TABLE task_comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  author_id UUID REFERENCES profiles(id) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT task_comments_content_length_check CHECK (LENGTH(TRIM(content)) >= 1 AND LENGTH(TRIM(content)) <= 1000)
);

-- Indexes for performance
CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
CREATE INDEX idx_task_comments_author_id ON task_comments(author_id);
CREATE INDEX idx_task_comments_created_at ON task_comments(created_at);

-- Composite index for common queries
CREATE INDEX idx_task_comments_task_created ON task_comments(task_id, created_at);

-- Enable RLS
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Task comments are viewable by family members"
  ON task_comments FOR SELECT
  USING (
    task_id IN (
      SELECT t.id FROM tasks t
      JOIN profiles p ON p.family_id = t.family_id
      WHERE p.id = auth.uid()
    )
  );

CREATE POLICY "Family members can create comments on family tasks"
  ON task_comments FOR INSERT
  WITH CHECK (
    auth.uid() = author_id AND
    task_id IN (
      SELECT t.id FROM tasks t
      JOIN profiles p ON p.family_id = t.family_id
      WHERE p.id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own comments"
  ON task_comments FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete their own comments"
  ON task_comments FOR DELETE
  USING (auth.uid() = author_id);

-- Function to update timestamps
CREATE TRIGGER update_task_comments_updated_at
  BEFORE UPDATE ON task_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE task_comments;

-- Table comment
COMMENT ON TABLE task_comments IS 'Comments on family tasks for communication and coordination';
COMMENT ON COLUMN task_comments.content IS 'The comment text content, limited to 1000 characters'; 