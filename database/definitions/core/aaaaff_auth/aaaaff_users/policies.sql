-- database/definitions/core/aaaaff_auth/aaaaff_users/policies.sql

-- Enable RLS on the core identity tables
ALTER TABLE aaaaff_users ENABLE ROW LEVEL SECURITY;

-- Deny all web/frontend access (force traffic through the Python API)
CREATE POLICY "Deny all access from frontend"
ON aaaaff_users
FOR ALL
TO anon, authenticated
USING (false);
