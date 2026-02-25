-- database/definitions/core/aaaaff_auth/aaaaft_user_roles/policies.sql

ALTER TABLE aaaaft_user_roles ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- AI CONTEXT: Role assignments dictate system security. The frontend 
-- cannot read or write to this table. The Python backend will query 
-- this via the service_role to build the user's permission session.
CREATE POLICY "Deny all access to role assignments"
ON aaaaft_user_roles
FOR ALL 
TO anon, authenticated
USING (false);