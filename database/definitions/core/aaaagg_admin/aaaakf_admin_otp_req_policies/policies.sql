-- database/definitions/core/aaaagg_admin/aaaakf_admin_otp_req_policies/policies.sql

-- Enable Row Level Security
ALTER TABLE aaaakf_admin_otp_req_policies ENABLE ROW LEVEL SECURITY;

-- Strict Frontend Lockdown
-- Access is strictly restricted to the service_role (Python backend).
-- All frontend access via anon or authenticated roles is denied.
CREATE POLICY "Deny all access to admin otp req policies"
ON aaaakf_admin_otp_req_policies
FOR ALL
TO anon, authenticated
USING (false);