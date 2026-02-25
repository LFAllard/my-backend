-- ✅ RLS: deny frontend
ALTER TABLE aaaakf_admin_otp_req_policies ENABLE ROW LEVEL SECURITY;
CREATE POLICY deny_otp_policies_frontend ON aaaakf_admin_otp_req_policies
  FOR ALL TO anon, authenticated
  USING (false);