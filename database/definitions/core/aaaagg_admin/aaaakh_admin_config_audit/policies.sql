-- database/definitions/core/aaaagg_admin/aaaakh_admin_config_audit/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakh_admin_config_audit ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin config audit"
ON aaaakh_admin_config_audit
FOR ALL
TO anon, authenticated
USING (false);