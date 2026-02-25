-- backend/database/definitions/core/aaaagg_admin/aaaakg_admin_otp_req_overrides/policies.sql
-- RLS: deny frontend access to overrides; service_role bypasses RLS

alter table aaaakg_admin_otp_req_overrides enable row level security;

-- Clean up any prior policy names (idempotent)
drop policy if exists deny_otp_overrides_frontend on aaaakg_admin_otp_req_overrides;

-- Block all access for Supabase client roles
create policy deny_otp_overrides_frontend
  on aaaakg_admin_otp_req_overrides
  for all
  to anon, authenticated
  using (false);

comment on policy deny_otp_overrides_frontend
  on aaaakg_admin_otp_req_overrides
  is 'Prevents frontend roles (anon, authenticated) from accessing OTP rate-limit overrides. Only backend service_role can access.';
