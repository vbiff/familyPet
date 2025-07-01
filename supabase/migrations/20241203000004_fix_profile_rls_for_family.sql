-- Fix profile RLS policies for family creation workflow
-- The issue might be in profile updates during family creation

-- Check existing profile policies and add missing ones
DO $$
BEGIN
    -- Allow users to update their own family_id
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'Users can update their own profile') THEN
        CREATE POLICY "Users can update their own profile"
        ON profiles FOR UPDATE
        USING (auth.uid() = id)
        WITH CHECK (auth.uid() = id);
    END IF;

    -- Ensure users can read their own profile
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' AND policyname = 'Users can read their own profile') THEN
        CREATE POLICY "Users can read their own profile"
        ON profiles FOR SELECT
        USING (auth.uid() = id);
    END IF;
END $$;

-- Temporary: Allow more permissive family operations during creation
-- We can tighten these later once family creation is working
DROP POLICY IF EXISTS "Families are viewable by members" ON families;
CREATE POLICY "Families are viewable by members"
  ON families FOR SELECT
  USING (
    auth.uid() IS NOT NULL AND (
      created_by_id = auth.uid()
      OR auth.uid() = ANY(parent_ids)
      OR auth.uid() = ANY(child_ids)
      OR auth.uid() IN (
        SELECT id FROM profiles WHERE family_id = families.id
      )
    )
  );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Profile and family RLS policies updated for family creation workflow.';
END $$; 