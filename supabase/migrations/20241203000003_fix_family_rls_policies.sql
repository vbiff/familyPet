-- Fix RLS policies for family creation
-- The current policies are too restrictive and prevent family creation

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Parents can create families" ON families;
DROP POLICY IF EXISTS "Parents can update their family" ON families;

-- Create more permissive policies for family creation
CREATE POLICY "Authenticated users can create families"
  ON families FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Family creators can update their family"
  ON families FOR UPDATE
  USING (
    created_by_id = auth.uid()
    OR auth.uid() = ANY(parent_ids)
  )
  WITH CHECK (
    created_by_id = auth.uid()
    OR auth.uid() = ANY(parent_ids)
  );

-- Allow family members to delete families (for cleanup)
CREATE POLICY "Family creators can delete their family"
  ON families FOR DELETE
  USING (
    created_by_id = auth.uid()
    OR auth.uid() = ANY(parent_ids)
  );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Family RLS policies updated successfully. Family creation should now work.';
END $$; 