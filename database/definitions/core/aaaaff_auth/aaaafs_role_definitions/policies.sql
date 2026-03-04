-- database/definitions/core/aaaaff_auth/aaaafs_role_definitions/policies.sql

ALTER TABLE aaaafs_role_definitions ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access (service_role bypasses RLS by default)
-- AI CONTEXT: Only the Python backend (service_role) can read or modify role
-- definitions. Frontend cannot read role metadata directly.
CREATE POLICY "Deny all access from frontend"
ON aaaafs_role_definitions
FOR ALL
TO anon, authenticated
USING (false);
