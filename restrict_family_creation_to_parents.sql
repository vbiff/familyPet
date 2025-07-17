-- Restrict family creation to parents only
-- This enforces proper business logic for family management

-- =====================================================
-- 1. UPDATE RLS POLICY TO CHECK USER ROLE
-- =====================================================

-- Drop the permissive policy that allows any authenticated user to create families
DROP POLICY IF EXISTS "authenticated_users_can_create_families" ON families;
DROP POLICY IF EXISTS "Authenticated users can create families" ON families;

-- Create a new policy that only allows parents to create families
CREATE POLICY "only_parents_can_create_families" ON families
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        auth.uid() = created_by_id AND
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'parent'
        )
    );

-- =====================================================
-- 2. ADD APPLICATION-LEVEL VALIDATION FUNCTION
-- =====================================================

-- Create a function to validate family creation business rules
CREATE OR REPLACE FUNCTION validate_family_creation(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_role user_role;
    existing_family_id UUID;
BEGIN
    -- Check if user exists and get their role
    SELECT role, family_id INTO user_role, existing_family_id
    FROM profiles 
    WHERE id = user_id;
    
    -- User must exist
    IF user_role IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- User must be a parent
    IF user_role != 'parent' THEN
        RAISE EXCEPTION 'Only parents can create families. Children should join existing families using invite codes.';
    END IF;
    
    -- User must not already be in a family
    IF existing_family_id IS NOT NULL THEN
        RAISE EXCEPTION 'User is already a member of a family';
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. CREATE HELPER FUNCTION FOR CHILD SIGNUP FLOW
-- =====================================================

-- Function to help children understand the proper flow
CREATE OR REPLACE FUNCTION get_child_signup_instructions()
RETURNS TABLE (
    instruction TEXT,
    action TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES 
        ('Children cannot create families', 'Ask your parent to create a family and share the invite code'),
        ('Use the invite code to join', 'Tap "Join Family" and scan the QR code or enter the invite code'),
        ('Get access to family tasks', 'Once joined, you can see and complete tasks assigned by parents');
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. TEST THE NEW RESTRICTIONS
-- =====================================================

-- Test query to check if current user can create families
SELECT 
    'Family Creation Permission Check:' as test,
    auth.uid() as user_id,
    p.role as user_role,
    CASE 
        WHEN p.role = 'parent' AND p.family_id IS NULL THEN 'CAN CREATE FAMILY ✅'
        WHEN p.role = 'parent' AND p.family_id IS NOT NULL THEN 'ALREADY IN FAMILY ⚠️'
        WHEN p.role = 'child' THEN 'MUST JOIN EXISTING FAMILY 👶'
        ELSE 'UNKNOWN STATUS ❌'
    END as permission_status
FROM profiles p
WHERE p.id = auth.uid();

-- =====================================================
-- 5. VERIFICATION
-- =====================================================

SELECT 'Family creation restricted to parents only! ✅' as status; 