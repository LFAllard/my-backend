-- database/definitions/core/aaaaff_auth/aaaafm_email_lookup/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaafm_email_lookup ENABLE ROW LEVEL SECURITY;

-- Deny all frontend access
-- This ensures the PII in this table is only accessible via the Python backend
CREATE POLICY "Deny access to email lookup"
ON aaaafm_email_lookup
FOR ALL
TO anon, authenticated
USING (false);