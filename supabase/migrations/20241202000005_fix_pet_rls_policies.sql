-- Drop the problematic pet policies
DROP POLICY IF EXISTS "Children can create one pet" ON pets;
DROP POLICY IF EXISTS "Children can update their own pet" ON pets;
DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;

-- Create simpler, non-recursive policies
CREATE POLICY "Anyone can view pets in their family"
  ON pets FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can create pets"
  ON pets FOR INSERT
  WITH CHECK (
    owner_id = auth.uid()
  );

CREATE POLICY "Users can update their own pets"
  ON pets FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid()); 