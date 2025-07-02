-- Fix pet update policies and clean up invalid pets
-- This migration addresses the pet update failure issues

-- First, let's see if there are any pets with invalid owner_ids
DO $$
DECLARE
    invalid_pets_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO invalid_pets_count
    FROM pets p
    LEFT JOIN profiles pr ON p.owner_id = pr.id
    WHERE pr.id IS NULL;
    
    RAISE NOTICE 'Found % pets with invalid owner_ids', invalid_pets_count;
    
    -- Delete pets with invalid owner_ids
    IF invalid_pets_count > 0 THEN
        DELETE FROM pets 
        WHERE owner_id NOT IN (SELECT id FROM profiles WHERE id IS NOT NULL);
        RAISE NOTICE 'Deleted % pets with invalid owner_ids', invalid_pets_count;
    END IF;
END $$;

-- Drop existing update policy
DROP POLICY IF EXISTS "Pet owners can update their pets" ON pets;

-- Create a more permissive update policy for pets
CREATE POLICY "Family members can update pets"
  ON pets FOR UPDATE
  USING (
    -- Allow update if user is in the same family as the pet
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  )
  WITH CHECK (
    -- Same check for the updated data
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Also ensure the SELECT policy is working correctly
DROP POLICY IF EXISTS "Pets are viewable by family members" ON pets;
CREATE POLICY "Pets are viewable by family members"
  ON pets FOR SELECT
  USING (
    family_id IN (
      SELECT family_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Pet RLS policies updated successfully. Pet updates should now work.';
END $$; 