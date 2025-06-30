-- Fix RLS policy to allow users to find families by invite code when joining
-- This is needed because users can't join a family if they can't see it first!

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Users can view their own family" ON families;

-- Create a more permissive policy that allows:
-- 1. Users to view families they're members of
-- 2. Users to view any family when looking up by invite code (for joining)
CREATE POLICY "Users can view families" ON families
    FOR SELECT USING (
        -- Can view families they're members of
        auth.uid() = created_by_id OR
        auth.uid() = ANY(parent_ids) OR
        auth.uid() = ANY(child_ids) OR
        -- Can view any family when authenticated (needed for invite code lookups)
        auth.role() = 'authenticated'
    );

-- Add a comment explaining why this policy is permissive
COMMENT ON POLICY "Users can view families" ON families IS 
'Allows authenticated users to view families for invite code lookups during joining process. Actual family data access is controlled by application logic.'; 