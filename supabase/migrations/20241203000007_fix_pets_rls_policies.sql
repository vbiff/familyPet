-- Fix RLS policies for pets table to allow pet creation
-- The current policies are blocking pet creation

-- Drop existing restrictive policies for pets
DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
DROP POLICY IF EXISTS "Children can create pets" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;

-- Create permissive policies for pet management
CREATE POLICY "Pets are viewable by family members"
  ON pets FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Family members can create pets"
  ON pets FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id AND
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Pet owners can update their pets"
  ON pets FOR UPDATE
  USING (
    owner_id = auth.uid() OR
    auth.uid() IN (
      SELECT id FROM profiles 
      WHERE family_id = pets.family_id AND role = 'parent'
    )
  )
  WITH CHECK (
    owner_id = auth.uid() OR
    auth.uid() IN (
      SELECT id FROM profiles 
      WHERE family_id = pets.family_id AND role = 'parent'
    )
  );

CREATE POLICY "Family members can delete pets"
  ON pets FOR DELETE
  USING (
    owner_id = auth.uid() OR
    auth.uid() IN (
      SELECT id FROM profiles 
      WHERE family_id = pets.family_id AND role = 'parent'
    )
  );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Pets RLS policies updated successfully. Pet creation should now work.';
END $$; 