-- database/definitions/core/aaaaff_auth/aaaafp_user_core_data/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaafp_user_core_data ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- AI CONTEXT: This table contains sensitive PII (names, birthdates, phones) 
-- encrypted at the app level. Access is strictly restricted to the 
-- service_role (Python backend). All frontend access via anon or 
-- authenticated roles is denied by default to prevent exposure of binary blobs.
CREATE POLICY "Deny all access to user core data"
ON aaaafp_user_core_data
FOR ALL 
TO anon, authenticated
USING (false);