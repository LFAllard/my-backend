-- backend/database/definitions/core/aaaagg_admin/aaaaki_admin_otp_requests/policies.sql
-- RLS: this is admin-only telemetry; never expose to frontend roles.

alter table aaaaki_admin_otp_requests enable row level security;

drop policy if exists deny_otp_requests_frontend on aaaaki_admin_otp_requests;

create policy deny_otp_requests_frontend
  on aaaaki_admin_otp_requests
  for all
  to anon, authenticated
  using (false);

comment on policy deny_otp_requests_frontend
  on aaaaki_admin_otp_requests
  is 'Blocks client roles from accessing OTP request ledger; backend service_role only.';
