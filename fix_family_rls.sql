-- Fix RLS policies to allow invite code lookups for joining families

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Users can view families" ON families;
DROP POLICY IF EXISTS "Users can view their own family" ON families;

-- Create a new policy that allows viewing families for invite code lookups
CREATE POLICY "Users can view families for invite codes" ON families
    FOR SELECT USING (
        -- Can view families they're members of
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids) OR
        auth.uid() = ANY(child_ids) OR
        -- Can view any family when authenticated (needed for invite code lookups)
        (auth.uid() IS NOT NULL)
    );

-- Ensure other policies exist
CREATE POLICY "Users can create families" ON families
    FOR INSERT WITH CHECK (auth.uid() = created_by_id);

CREATE POLICY "Family creators and parents can update families" ON families
    FOR UPDATE USING (
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids)
    );

CREATE POLICY "Only family creators can delete families" ON families
    FOR DELETE USING (auth.uid() = created_by_id); 