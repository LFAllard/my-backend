-- database/definitions/core/aaaagg_admin/aaaakm_user_invitation_entitlements/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakm_user_invitation_entitlements ENABLE ROW LEVEL SECURITY;

-- 1. USER ACCESS: Read-Only for Own Entitlements
-- Allows authenticated users to see their own "gas tank" of invites.
CREATE POLICY "Allow users to select their own entitlements"
ON aaaakm_user_invitation_entitlements
FOR SELECT
TO authenticated
USING ( user_id = current_setting('app.current_user_id', true)::BIGINT );

-- 2. HARD WALL: Explicitly Deny Frontend Mutations
-- ALL covers INSERT, UPDATE, and DELETE. 
-- Explicitly documented to show the frontend cannot grant itself invites.
CREATE POLICY "Deny all frontend write access to entitlements"
ON aaaakm_user_invitation_entitlements
FOR ALL
TO authenticated
USING (false)
WITH CHECK (false);

-- 3. SYSTEM ACCESS: Full access for service_role
-- Required for the Python backend to grant entitlements and increment usage.
CREATE POLICY "Allow service_role full access to entitlements"
ON aaaakm_user_invitation_entitlements
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);