-- database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakg_admin_otp_req_overrides ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp req overrides"
ON aaaakg_admin_otp_req_overrides
FOR ALL
TO anon, authenticated
USING (false);