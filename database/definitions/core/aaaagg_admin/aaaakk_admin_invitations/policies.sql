-- database/definitions/core/aaaagg_admin/aaaakk_admin_invitations/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakk_admin_invitations ENABLE ROW LEVEL SECURITY;

-- 1. Strict Frontend Lockdown
-- All frontend access via anon or authenticated roles is explicitly denied.
CREATE POLICY "Deny all frontend access to invitations"
ON aaaakk_admin_invitations
FOR ALL
TO anon, authenticated
USING (false)
WITH CHECK (false);

-- 2. Explicit System Access
-- Explicitly permit the Python backend (service_role) to read and write.
CREATE POLICY "Allow service_role full access"
ON aaaakk_admin_invitations
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);