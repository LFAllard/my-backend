-- database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaaki_admin_otp_requests ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp requests"
ON aaaaki_admin_otp_requests
FOR ALL
TO anon, authenticated
USING (false);