-- database/definitions/core/aaaagg_admin/aaaakj_admin_otp_counters/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakj_admin_otp_counters ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp counters"
ON aaaakj_admin_otp_counters
FOR ALL
TO anon, authenticated
USING (false);